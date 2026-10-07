# Nordvik notification job. Runs as an event-triggered Container Apps Job: it
# starts when messages appear in the "notiser" queue, drains the queue, and exits
# (so nothing is paid for while the queue is empty).
#
# For every ticket it
#   1) sends an e-mail through Azure Communication Services (managed identity):
#        urgent category  -> property manager + shared mailbox (+ AKUT_MAIL_EXTRA)
#        ordinary report  -> shared mailbox only (nothing if SHARED_MAILBOX is empty)
#   2) posts the ticket (incl. photo as base64) to Power Automate, which creates the
#      list item (only if FLOW_URL is set).
# Each step records a flag on the ticket, so a retry never repeats a finished step.
# After 5 failed attempts the message moves to the "<queue>-poison" queue. When Azure
# throttles e-mail sending (HTTP 429) the message is simply retried later and never
# counts as failed; while throttled, ordinary mails wait so urgent ones get through first.

import base64
import html
import json
import logging
import urllib.request
from datetime import datetime, timezone

from azure.communication.email import EmailClient
from azure.core.exceptions import HttpResponseError
from azure.data.tables import UpdateMode

import V41_common as c

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("worker")

MAX_ATTEMPTS = 5
THROTTLE_RETRY_SECONDS = 600


class Throttled(Exception):
    """E-mail sending is rate limited; try again later."""


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
        headers={
            "Content-Type": "application/json; charset=utf-8",
            "User-Agent": "NordvikWorker/1.0"
        },
        method="POST",
    )
    urllib.request.urlopen(req, timeout=30).read()


def _send_ticket_mail(entity, recipients, urgent):
    e = lambda k: html.escape(str(entity.get(k, "")))
    link = c.PORTAL_URL or ""
    prefix = "AKUT felanmälan" if urgent else "Ny felanmälan"
    plain = (
        "{p}: {kat}\nFastighet: {f}, enhet {en}\nHyresgäst: {n} ({m})\n\n{b}\n\nÄrende: {i}\n{l}"
    ).format(p=prefix, kat=entity.get("kategoriNamn", ""), f=entity["PartitionKey"], en=entity.get("enhet", ""),
             n=entity.get("hyresgastNamn", ""), m=entity.get("hyresgastMail", ""),
             b=entity.get("beskrivning", ""), i=entity["RowKey"], l=link)
    body = (
        "<h2>{p}: {kat}</h2><p><b>Fastighet:</b> {f}, enhet {en}<br>"
        "<b>Hyresgäst:</b> {n} ({m})</p><p>{b}</p><p>Ärende: <code>{i}</code></p><p><a href='{l}'>Öppna portalen</a></p>"
    ).format(p=prefix, kat=e("kategoriNamn"), f=html.escape(entity["PartitionKey"]), en=e("enhet"),
             n=e("hyresgastNamn"), m=e("hyresgastMail"), b=e("beskrivning"),
             i=html.escape(entity["RowKey"]), l=html.escape(link))
    subject = "{0}: {1} - {2}".format("AKUT" if urgent else "Felanmälan", entity.get("kategoriNamn", ""), entity["PartitionKey"])
    message = {
        "senderAddress": c.MAIL_SENDER,
        "recipients": {"to": [{"address": a} for a in recipients]},
        "content": {"subject": subject, "plainText": plain, "html": body},
    }
    try:
        EmailClient(c.ACS_ENDPOINT, c.credential).begin_send(message).result()
    except HttpResponseError as ex:
        if getattr(ex, "status_code", None) == 429:
            raise Throttled(str(ex)) from ex
        raise


def _recipients(entity, manager_mail):
    if entity.get("akut"):
        raw = [manager_mail, c.SHARED_MAILBOX] + c.AKUT_MAIL_EXTRA
    else:
        raw = [c.SHARED_MAILBOX]
    seen, out = set(), []
    for a in raw:
        if a and a.lower() not in seen:
            seen.add(a.lower()); out.append(a)
    return out


def handle(msg, state):
    tbl = c.table(c.TICKETS_TABLE)
    entity = tbl.get_entity(msg["fastighet"], msg["id"])
    ticket_id = entity["RowKey"]
    urgent = bool(entity.get("akut"))
    manager_mail = c.list_properties().get(entity["PartitionKey"], {}).get("forvaltarMail", "")
    done, errors = {}, []

    # E-mail first, and independent of Power Automate: a broken flow must not stop
    # a report from reaching the manager or the shared mailbox.
    if not entity.get("mailSkickad"):
        recipients = _recipients(entity, manager_mail)
        if not recipients:
            if urgent:
                log.error("Urgent ticket %s has no recipients (property manager e-mail missing?)", ticket_id)
                errors.append(ValueError("No recipients for urgent ticket {0}".format(ticket_id)))
            else:
                log.info("Ticket %s: no shared mailbox configured, no mail sent", ticket_id)
        elif not urgent and state["throttled"]:
            errors.append(Throttled("Ordinary mail deferred while sending is throttled"))
        else:
            try:
                _send_ticket_mail(entity, recipients, urgent)
                done["mailSkickad"] = True
                log.info("%s mail sent for ticket %s (%s recipient(s))", "Urgent" if urgent else "Ordinary", ticket_id, len(recipients))
            except Throttled as ex:
                state["throttled"] = True
                log.warning("E-mail sending is throttled; ticket %s will be retried", ticket_id)
                errors.append(ex)
            except Exception as ex:
                log.exception("Mail FAILED for ticket %s (%s recipient(s))", ticket_id, len(recipients))
                errors.append(ex)

    if c.FLOW_URL and not entity.get("flowSkickad"):
        try:
            _post_flow(entity, manager_mail)
            done["flowSkickad"] = True
            log.info("Power Automate notified for ticket %s", ticket_id)
        except Exception as ex:
            log.exception("Power Automate call FAILED for ticket %s", ticket_id)
            errors.append(ex)

    # Record what succeeded, so a retry only repeats the step that failed.
    update = dict(done, PartitionKey=entity["PartitionKey"], RowKey=ticket_id)
    if not errors:
        update.update({"notis": "klar", "notisTid": datetime.now(timezone.utc).isoformat(), "notisFel": ""})
    else:
        update["notisFel"] = str(errors[0])[:500]
    tbl.update_entity(update, mode=UpdateMode.MERGE)
    if errors:
        # Real failures count towards the poison queue, throttling never does.
        raise next((x for x in errors if not isinstance(x, Throttled)), errors[0])


def main():
    q = c.queue(c.QUEUE_NAME)
    poison = c.queue(c.QUEUE_NAME + "-poison")
    handled, state = 0, {"throttled": False}
    log.info("Worker started, reading queue %s", c.QUEUE_NAME)
    while True:
        batch = list(q.receive_messages(messages_per_page=5, visibility_timeout=300, max_messages=5))
        if not batch:
            break
        deferred = 0
        for m in batch:
            try:
                handle(json.loads(m.content), state)
                q.delete_message(m)
                handled += 1
            except Throttled:
                q.update_message(m, visibility_timeout=THROTTLE_RETRY_SECONDS)
                deferred += 1
            except Exception:
                log.exception("Failed (attempt %s) for message %s", m.dequeue_count, m.id)
                if m.dequeue_count >= MAX_ATTEMPTS:
                    poison.send_message(m.content)
                    q.delete_message(m)
        if deferred == len(batch):
            break  # everything left is waiting for the rate limit; stop and let the job end
    log.info("Done, %s message(s) handled", handled)


if __name__ == "__main__":
    main()
