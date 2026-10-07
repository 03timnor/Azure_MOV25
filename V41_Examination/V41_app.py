# Nordvik tenant portal (container version).
# Tenants report faults and follow their own tickets, property managers handle
# tickets for their properties, finance sees anonymous statistics only.
#
# Storage (managed identity, no account keys):
#   Blob   felanmalan  photos, path <property>/<ticket id>/bild.<ext>
#   Blob   avtal       contracts / protocols, path <property>/<unit>/<file>
#   Table  Arenden     one row per ticket (PartitionKey = property)
#   Queue  notiser     work for the notification job (Power Automate + urgent e-mail)
#
# Sign-in is handled by Container Apps built-in authentication ("Easy Auth") against
# your Entra ID tenant. It passes the signed-in user's UPN in X-MS-CLIENT-PRINCIPAL-NAME.
# Role, property and unit come from the Anvandare table (RowKey = lower-case UPN).
# Without that header every API call is rejected.

import base64
import functools
import json
import logging
import os
import time
import uuid
from datetime import datetime, timedelta, timezone

from azure.core.exceptions import ResourceNotFoundError
from azure.data.tables import UpdateMode
from azure.storage.blob import ContentSettings
from flask import Flask, Response, g, jsonify, redirect, request, send_from_directory

import V41_common as c

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
MAX_IMAGE_BYTES = 8 * 1024 * 1024
IMAGE_TYPES = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".webp": "image/webp", ".heic": "image/heic",
}

app = Flask(__name__, static_folder=None)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
app.logger.setLevel(logging.INFO)


# --------------------------------------------------------------------------
# Helpers: errors, security headers, authentication
# --------------------------------------------------------------------------
def _err(status, message):
    return jsonify({"fel": message}), status


@app.errorhandler(413)
def _too_large(_):
    return _err(413, "Filen är för stor (max 10 MB).")


@app.before_request
def _csrf_guard():
    # Easy Auth uses cookies, so state-changing calls must carry a header that a
    # cross-site form cannot set.
    if request.method in ("POST", "PUT", "PATCH", "DELETE"):
        if request.headers.get("X-Requested-With") != "nordvik-portal":
            return _err(403, "Ogiltig begäran.")


@app.after_request
def _headers(resp):
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["Referrer-Policy"] = "same-origin"
    if request.path.startswith("/api/"):
        resp.headers.setdefault("Cache-Control", "no-store")
    if request.path == "/":
        resp.headers["Cache-Control"] = "no-store"
        resp.headers["Content-Security-Policy"] = (
            "default-src 'self'; img-src 'self' blob:; style-src 'self'; "
            "script-src 'self'; frame-ancestors 'none'"
        )
    return resp


def _principal_id():
    if c.AUTH_MODE == "demo":
        key = request.cookies.get("demo_user", "hyresgast")
        return key if key in c.DEMO_USERS else None
    # Easy Auth passes the signed-in user's claims base64-encoded. The Anvandare table
    # is keyed by the lower-case UPN (claim preferred_username); the name header is
    # the fallback.
    raw = request.headers.get("X-MS-CLIENT-PRINCIPAL", "")
    if raw:
        try:
            claims = json.loads(base64.b64decode(raw + "=" * (-len(raw) % 4))).get("claims", [])
            for want in ("preferred_username",
                         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"):
                for cl in claims:
                    if cl.get("typ") == want and cl.get("val"):
                        return cl["val"].strip().lower()
        except (ValueError, TypeError):
            pass
    return request.headers.get("X-MS-CLIENT-PRINCIPAL-NAME", "").strip().lower() or None


def needs_roles(*roles):
    def deco(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            uid = _principal_id()
            if not uid:
                return _err(401, "Du måste logga in.")
            user = c.get_user(uid)
            if not user or user["roll"] not in c.ROLES:
                return _err(403, "Ditt konto är inte kopplat till någon roll i portalen.")
            if roles and user["roll"] not in roles:
                return _err(403, "Du saknar behörighet.")
            g.user = user
            return fn(*args, **kwargs)
        return wrapper
    return deco


# --------------------------------------------------------------------------
# Helpers: tickets
# --------------------------------------------------------------------------
def _public_ticket(e, role):
    out = {
        "id": e["RowKey"],
        "fastighet": e["PartitionKey"],
        "enhet": e.get("enhet", ""),
        "kategori": e.get("kategori", ""),
        "kategoriNamn": e.get("kategoriNamn", ""),
        "akut": bool(e.get("akut", False)),
        "rubrik": e.get("rubrik", ""),
        "beskrivning": e.get("beskrivning", ""),
        "status": e.get("status", "ny"),
        "skapad": e.get("skapad", ""),
        "uppdaterad": e.get("uppdaterad", ""),
        "harBild": bool(e.get("bild", "")),
        "losning": e.get("losning", ""),
        "losningTid": e.get("losningTid", ""),
    }
    if role == "forvaltare":
        out["losningAv"] = e.get("losningAv", "")
        out["hyresgastNamn"] = e.get("hyresgastNamn", "")
        out["hyresgastMail"] = e.get("hyresgastMail", "")
    return out


def _get_ticket(user, ticket_id):
    """Returns the ticket entity if this user may see it, else None."""
    if user["roll"] == "hyresgast":
        partitions = [user["fastighet"]]
    elif user["roll"] == "forvaltare":
        partitions = user["fastigheter"]
    else:
        return None
    for pid in partitions:
        try:
            e = c.table(c.TICKETS_TABLE).get_entity(pid, ticket_id)
        except ResourceNotFoundError:
            continue
        if user["roll"] == "hyresgast" and e.get("hyresgastId") != user["id"]:
            return None
        return e
    return None


# --------------------------------------------------------------------------
# Pages
# --------------------------------------------------------------------------
@app.get("/")
def index():
    return send_from_directory(STATIC_DIR, "V41_index.html")


@app.get("/static/<path:filename>")
def static_files(filename):
    return send_from_directory(STATIC_DIR, filename, max_age=3600)


@app.get("/demo/byt")
def demo_switch():
    # Persona switcher, only available in test/demo environments.
    if c.AUTH_MODE != "demo":
        return _err(404, "Finns inte.")
    key = request.args.get("roll", "hyresgast")
    resp = redirect("/")
    if key in c.DEMO_USERS:
        resp.set_cookie("demo_user", key, samesite="Lax", httponly=True, secure=True)
    return resp


# --------------------------------------------------------------------------
# API
# --------------------------------------------------------------------------
@app.get("/api/me")
@needs_roles()
def me():
    u = g.user
    props = c.list_properties()
    if u["roll"] == "hyresgast":
        scope = [u["fastighet"]]
    elif u["roll"] == "forvaltare":
        scope = u["fastigheter"]
    else:
        scope = list(props.keys())
    return jsonify({
        "id": u["id"], "namn": u["namn"], "roll": u["roll"],
        "fastighet": u["fastighet"], "enhet": u["enhet"],
        "fastigheter": [{"id": p, "namn": props.get(p, {}).get("namn", p)} for p in scope],
        "demo": c.AUTH_MODE == "demo",
        "kategorier": c.CATEGORIES,
    })


@app.post("/api/arenden")
@needs_roles("hyresgast")
def create_ticket():
    u = g.user
    cat = c.CATEGORY_BY_ID.get(request.form.get("kategori", ""))
    beskrivning = request.form.get("beskrivning", "").strip()[:4000]
    rubrik = request.form.get("rubrik", "").strip()[:120] or (cat["namn"] if cat else "")
    if not cat or not beskrivning:
        return _err(400, "Välj kategori och beskriv felet.")
    if not u["fastighet"]:
        return _err(400, "Ditt konto saknar koppling till en fastighet.")

    image = request.files.get("bild")
    image_bytes, image_ext, image_type = None, "", ""
    if image is not None and image.filename:
        image_ext = os.path.splitext(image.filename)[1].lower()
        image_type = IMAGE_TYPES.get(image_ext)
        if not image_type:
            return _err(400, "Bilden måste vara JPG, PNG, WEBP eller HEIC.")
        image_bytes = image.read()
        if len(image_bytes) > MAX_IMAGE_BYTES:
            return _err(413, "Bilden är för stor (max 8 MB).")

    now = datetime.now(timezone.utc)
    stamp = now.strftime("%Y%m%dT%H%M%SZ")
    ticket_id = "{0}-{1}".format(stamp, uuid.uuid4().hex[:8])
    pid = u["fastighet"]

    # The user's own file name is never used in the blob path.
    image_name = "{0}/{1}/bild{2}".format(pid, ticket_id, image_ext) if image_bytes else ""

    # 1) Photo.
    if image_bytes:
        c.blob_service.get_container_client(c.IMAGES_CONTAINER).upload_blob(
            name=image_name, data=image_bytes, overwrite=False,
            content_settings=ContentSettings(content_type=image_type),
        )

    # 2) Ticket row (this is the "list" tenants and managers read from).
    entity = {
        "PartitionKey": pid, "RowKey": ticket_id,
        "hyresgastId": u["id"], "hyresgastNamn": u["namn"], "hyresgastMail": u["mail"],
        "enhet": u["enhet"],
        "kategori": cat["id"], "kategoriNamn": cat["namn"], "akut": cat["akut"],
        "rubrik": rubrik, "beskrivning": beskrivning,
        "bild": image_name, "bildTyp": image_type,
        "status": "ny", "skapad": now.isoformat(), "uppdaterad": now.isoformat(),
        "notis": "vantar",
    }
    c.table(c.TICKETS_TABLE).create_entity(entity)

    # 3) Hand over to the notification job. The ticket is already saved, so a
    #    queue problem must not fail the request from the tenant's point of view.
    try:
        c.queue(c.QUEUE_NAME).send_message(json.dumps({"fastighet": pid, "id": ticket_id}))
        app.logger.info("Queued notification for ticket %s", ticket_id)
    except Exception:
        app.logger.exception("Could not queue notification for ticket %s", ticket_id)

    return jsonify({"id": ticket_id, "akut": cat["akut"]}), 201


@app.get("/api/arenden")
@needs_roles("hyresgast", "forvaltare")
def list_tickets():
    u = g.user
    status = request.args.get("status", "")
    rows = []
    tbl = c.table(c.TICKETS_TABLE)
    if u["roll"] == "hyresgast":
        rows = tbl.query_entities(
            "PartitionKey eq @p and hyresgastId eq @u",
            parameters={"p": u["fastighet"], "u": u["id"]},
        )
    else:
        wanted = request.args.get("fastighet", "")
        for pid in u["fastigheter"]:
            if wanted and wanted != pid:
                continue
            rows = list(rows) + list(tbl.query_entities(
                "PartitionKey eq @p", parameters={"p": pid}
            ))
    items = [_public_ticket(e, u["roll"]) for e in rows]
    if status in c.STATUSES:
        items = [i for i in items if i["status"] == status]
    items.sort(key=lambda i: i["id"], reverse=True)
    return jsonify(items[:300])


@app.get("/api/arenden/<ticket_id>")
@needs_roles("hyresgast", "forvaltare")
def get_ticket(ticket_id):
    e = _get_ticket(g.user, ticket_id)
    if e is None:
        return _err(404, "Ärendet finns inte.")
    return jsonify(_public_ticket(e, g.user["roll"]))


@app.get("/api/arenden/<ticket_id>/bild")
@needs_roles("hyresgast", "forvaltare")
def ticket_image(ticket_id):
    e = _get_ticket(g.user, ticket_id)
    if e is None or not e.get("bild"):
        return _err(404, "Bilden finns inte.")
    data = c.blob_service.get_blob_client(c.IMAGES_CONTAINER, e["bild"]).download_blob().readall()
    resp = Response(data, mimetype=e.get("bildTyp") or "application/octet-stream")
    resp.headers["Cache-Control"] = "private, max-age=3600"
    return resp


@app.post("/api/arenden/<ticket_id>/status")
@needs_roles("forvaltare")
def set_status(ticket_id):
    # Body: {"status": "ny|pagar|klar", "losning": "text"}. "losning" is optional:
    # if it is left out, the saved solution is not touched.
    body = request.get_json(silent=True) or {}
    status = body.get("status", "")
    if status not in c.STATUSES:
        return _err(400, "Ogiltig status.")
    e = _get_ticket(g.user, ticket_id)
    if e is None:
        return _err(404, "Ärendet finns inte.")
    now = datetime.now(timezone.utc).isoformat()
    update = {"PartitionKey": e["PartitionKey"], "RowKey": e["RowKey"], "status": status, "uppdaterad": now}
    losning = e.get("losning", "")
    if "losning" in body:
        new = str(body.get("losning") or "").strip()[:4000]
        if new != losning:
            losning = new
            update["losning"] = new
            update["losningAv"] = g.user["namn"] if new else ""
            update["losningTid"] = now if new else ""
    c.table(c.TICKETS_TABLE).update_entity(update, mode=UpdateMode.MERGE)
    return jsonify({"id": ticket_id, "status": status, "losning": losning})


# ---- Documents (contracts, inspection protocols) -------------------------
def _doc_prefix(user):
    """Returns the list of blob prefixes this user may read."""
    if user["roll"] == "hyresgast":
        return ["{0}/{1}/".format(user["fastighet"], user["enhet"])]
    if user["roll"] == "forvaltare":
        return ["{0}/".format(p) for p in user["fastigheter"]]
    return []


def _doc_allowed(user, blob_name):
    if ".." in blob_name or blob_name.startswith("/"):
        return False
    return any(blob_name.startswith(p) for p in _doc_prefix(user))


@app.get("/api/dokument")
@needs_roles("hyresgast", "forvaltare")
def list_documents():
    u = g.user
    prefixes = _doc_prefix(u)
    wanted = request.args.get("fastighet", "")
    unit = request.args.get("enhet", "")
    if u["roll"] == "forvaltare":
        if wanted:
            prefixes = [p for p in prefixes if p == wanted + "/"]
            if prefixes and unit:
                prefixes = [prefixes[0] + unit + "/"]
    cont = c.blob_service.get_container_client(c.DOCS_CONTAINER)
    docs = []
    for p in prefixes:
        for b in cont.list_blobs(name_starts_with=p):
            docs.append({
                "namn": b.name, "visa": b.name[len(p):] if u["roll"] == "hyresgast" else b.name,
                "storlek": b.size,
                "andrad": b.last_modified.isoformat() if b.last_modified else "",
            })
            if len(docs) >= 500:
                break
    docs.sort(key=lambda d: d["andrad"], reverse=True)
    return jsonify(docs)


@app.get("/api/dokument/hamta")
@needs_roles("hyresgast", "forvaltare")
def download_document():
    name = request.args.get("namn", "")
    if not _doc_allowed(g.user, name):
        return _err(404, "Dokumentet finns inte.")
    try:
        blob = c.blob_service.get_blob_client(c.DOCS_CONTAINER, name).download_blob()
    except ResourceNotFoundError:
        return _err(404, "Dokumentet finns inte.")
    resp = Response(blob.readall(), mimetype="application/octet-stream")
    safe = name.rsplit("/", 1)[-1].replace('"', "")
    resp.headers["Content-Disposition"] = "attachment; filename=\"{0}\"".format(safe)
    return resp


# ---- Statistics (no personal data; used by managers and finance) ---------
_stats_cache = {}


@app.get("/api/statistik")
@needs_roles("forvaltare", "ekonomi")
def statistics():
    u = g.user
    props = c.list_properties()
    scope = u["fastigheter"] if u["roll"] == "forvaltare" else list(props.keys())
    key = (u["roll"], tuple(sorted(scope)))
    hit = _stats_cache.get(key)
    if hit and time.time() - hit[0] < 300:
        return jsonify(hit[1])

    since = (datetime.now(timezone.utc) - timedelta(days=365)).strftime("%Y%m%dT000000Z")
    tbl = c.table(c.TICKETS_TABLE)
    per_prop, per_month, per_cat = {}, {}, {}
    for pid in scope:
        rows = tbl.query_entities(
            "PartitionKey eq @p and RowKey ge @s",
            parameters={"p": pid, "s": since},
            select=["PartitionKey", "RowKey", "kategoriNamn", "akut", "status"],
        )
        for e in rows:
            p = per_prop.setdefault(pid, {"fastighet": pid, "namn": props.get(pid, {}).get("namn", pid),
                                          "antal": 0, "akuta": 0, "oppna": 0})
            p["antal"] += 1
            p["akuta"] += 1 if e.get("akut") else 0
            p["oppna"] += 0 if e.get("status") == "klar" else 1
            month = e["RowKey"][:6]
            per_month[month] = per_month.get(month, 0) + 1
            cat = e.get("kategoriNamn", "Övrigt")
            per_cat[cat] = per_cat.get(cat, 0) + 1
    result = {
        "perFastighet": sorted(per_prop.values(), key=lambda x: -x["antal"]),
        "perManad": [{"manad": m, "antal": n} for m, n in sorted(per_month.items())],
        "perKategori": [{"kategori": k, "antal": n} for k, n in sorted(per_cat.items(), key=lambda x: -x[1])],
    }
    _stats_cache[key] = (time.time(), result)
    return jsonify(result)


@app.get("/health")
def health():
    # Used by the Container Apps liveness/readiness probes. Deliberately does not
    # touch storage, so a storage hiccup does not restart healthy replicas.
    return {"status": "ok", "auth_mode": c.AUTH_MODE, "flow_configured": bool(c.FLOW_URL)}
