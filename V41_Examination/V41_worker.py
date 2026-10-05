# Nordvik notification job. Runs as an event-triggered Container Apps Job: it
# starts when messages appear in the "notiser" queue, drains the queue, and exits
# (so nothing is paid for while the queue is empty).
#
# For every ticket it
#   1) posts the ticket (incl. photo as base64) to Power Automate, which creates the
#      list item and notifies the responsible manager (only if FLOW_URL is set),
#   2) sends an e-mail straight away for urgent categories (Azure Communication
#      Services, managed identity).
# Each step records a flag on the ticket, so a retry never repeats a finished step.
# After 5 failed attempts the message moves to the "<queue>-poison" queue.

import base64
import html
import json
import logging
import urllib.request
from datetime import datetime, timezone

from azure.communication.email import EmailClient
from azure.data.tables import UpdateMode

import V41_common as c

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("worker")

MAX_ATTEMPTS = 5


def _image_b64(entity):
    if not entity.get("bild"):
        return ""
    data = c.blob_service.get_blob_client(c.IMAGES_CONTAINER, entity["bild"]).download_blob().readall()
    return base64.b64encode(data).decode("ascii")


def _post_flow(entity, manager_mail):
    payload = {
        "id": entity["RowKey"], "fastighet": entity["PartitionKey"], "enhet": entity.get("enhet", ""),
        "name": entity.get("hyresgastNamn", ""), "mail": entity.get("hyresgastMail", ""),
        "kategori": entity.get("kategoriNamn", ""), "akut": bool(entity.get("akut", False)),
        "rubrik": entity.get("rubrik", ""), "message": entity.get("beskrivning", ""),
        "created": entity.get("skapad", ""), "forvaltare_mail": manager_mail,
        "image": entity.get("bild", ""),
        "image_content_type": entity.get("bildTyp", ""),
        "image_base64": _image_b64(entity),
    }
    req = urllib.request.Request(
        c.FLOW_URL, data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"}, method="POST",
    )
    urllib.request.urlopen(req, timeout=30).read()


def _send_urgent_mail(entity, recipients):
    if not recipients:
        raise ValueError("No recipients for urgent ticket {0}".format(entity["RowKey"]))
    e = lambda k: html.escape(str(entity.get(k, "")))
    link = c.PORTAL_URL or ""
    plain = (
        "AKUT felanmälan: {kat}\nFastighet: {f}, enhet {en}\nHyresgäst: {n} ({m})\n\n{b}\n\nÄrende: {i}\n{l}"
    ).format(kat=entity.get("kategoriNamn", ""), f=entity["PartitionKey"], en=entity.get("enhet", ""),
             n=entity.get("hyresgastNamn", ""), m=entity.get("hyresgastMail", ""),
             b=entity.get("beskrivning", ""), i=entity["RowKey"], l=link)
    body = (
        "<h2>AKUT felanmälan: {kat}</h2><p><b>Fastighet:</b> {f}, enhet {en}<br>"
        "<b>Hyresgäst:</b> {n} ({m})</p><p>{b}</p><p>Ärende: <code>{i}</code></p><p><a href='{l}'>Öppna portalen</a></p>"
    ).format(kat=e("kategoriNamn"), f=html.escape(entity["PartitionKey"]), en=e("enhet"),
             n=e("hyresgastNamn"), m=e("hyresgastMail"), b=e("beskrivning"),
             i=html.escape(entity["RowKey"]), l=html.escape(link))
    client = EmailClient(c.ACS_ENDPOINT, c.credential)
    message = {
        "senderAddress": c.MAIL_SENDER,
        "recipients": {"to": [{"address": a} for a in recipients]},
        "content": {"subject": "AKUT: {0} - {1}".format(entity.get("kategoriNamn", ""), entity["PartitionKey"]),
                    "plainText": plain, "html": body},
    }
    client.begin_send(message).result()


def handle(msg):
    tbl = c.table(c.TICKETS_TABLE)
    entity = tbl.get_entity(msg["fastighet"], msg["id"])
    manager_mail = c.list_properties().get(entity["PartitionKey"], {}).get("forvaltarMail", "")
    done = {}

    if c.FLOW_URL and not entity.get("flowSkickad"):
        _post_flow(entity, manager_mail)
        done["flowSkickad"] = True
    if entity.get("akut") and not entity.get("mailSkickad"):
        _send_urgent_mail(entity, [a for a in [manager_mail] + c.AKUT_MAIL_EXTRA if a])
        done["mailSkickad"] = True

    done.update({"PartitionKey": entity["PartitionKey"], "RowKey": entity["RowKey"],
                 "notis": "klar", "notisTid": datetime.now(timezone.utc).isoformat()})
    tbl.update_entity(done, mode=UpdateMode.MERGE)


def main():
    q = c.queue(c.QUEUE_NAME)
    poison = c.queue(c.QUEUE_NAME + "-poison")
    handled = 0
    while True:
        batch = list(q.receive_messages(messages_per_page=5, visibility_timeout=300, max_messages=5))
        if not batch:
            break
        for m in batch:
            try:
                handle(json.loads(m.content))
                q.delete_message(m)
                handled += 1
            except Exception:
                log.exception("Failed (attempt %s) for message %s", m.dequeue_count, m.id)
                if m.dequeue_count >= MAX_ATTEMPTS:
                    poison.send_message(m.content)
                    q.delete_message(m)
    log.info("Done, %s message(s) handled", handled)


if __name__ == "__main__":
    main()
