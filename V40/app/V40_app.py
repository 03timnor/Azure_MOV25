# Novatrix ticket app (container version).
# Serves the ticket form and handles POST /submit. Each ticket is stored in
# Blob Storage using a managed identity. No account key is used.
#
# Configuration comes from environment variables (set by Bicep):
#   STORAGE_ACCOUNT  Name of the storage account (required)
#   CONTAINER        Blob container name (default: arenden)
#   BLOB_LAYOUT      "root" or "folder" (default: root)
#   FLOW_URL         Optional Power Automate HTTP trigger URL (stored as a secret)
#   AZURE_CLIENT_ID  Client ID of the user-assigned managed identity

import base64
import json
import mimetypes
import os
import urllib.request
import uuid
from datetime import datetime, timezone

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, ContentSettings
from flask import Flask, Response, request, send_from_directory

STORAGE_ACCOUNT = os.environ["STORAGE_ACCOUNT"]
CONTAINER = os.environ.get("CONTAINER", "arenden")
BLOB_LAYOUT = os.environ.get("BLOB_LAYOUT", "root")
FLOW_URL = os.environ.get("FLOW_URL", "")

ACCOUNT_URL = "https://{0}.blob.core.windows.net".format(STORAGE_ACCOUNT)
STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")

app = Flask(__name__, static_folder=None)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024  # same limit nginx had (10 MB)

# One credential and one client for the whole app. DefaultAzureCredential finds
# the container's managed identity automatically (AZURE_CLIENT_ID selects which).
_credential = DefaultAzureCredential(
    managed_identity_client_id=os.environ.get("AZURE_CLIENT_ID")
)
_blob_service = BlobServiceClient(account_url=ACCOUNT_URL, credential=_credential)


def _container():
    return _blob_service.get_container_client(CONTAINER)


def _blob_names(ticket_id, image_filename):
    # Returns (ticket_blob_name, image_blob_name) for the chosen layout.
    # image_blob_name is None when no image was attached.
    if BLOB_LAYOUT == "folder":
        ticket_name = "{0}/arende.json".format(ticket_id)
        image_name = "{0}/{1}".format(ticket_id, image_filename) if image_filename else None
    else:
        ticket_name = "arende-{0}.json".format(ticket_id)
        image_name = "{0}-{1}".format(ticket_id, image_filename) if image_filename else None
    return ticket_name, image_name


def _notify_flow(payload):
    # POSTs the payload to Power Automate if a URL is configured. Errors are
    # deliberately swallowed (but logged): the form must keep working even if
    # the flow is down.
    if not FLOW_URL:
        return
    try:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        req = urllib.request.Request(
            FLOW_URL,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        app.logger.exception("Could not send the ticket to Power Automate")


@app.get("/")
def index():
    return send_from_directory(STATIC_DIR, "V40_index.html")


@app.post("/submit")
def submit():
    # Field names must match the form in static/V40_index.html.
    name = request.form.get("name", "").strip()
    mail = request.form.get("mail", "").strip()
    msg = request.form.get("msg", "").strip()
    image = request.files.get("bild")

    # Unique ticket id: UTC timestamp plus a short random suffix.
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    ticket_id = "{0}-{1}".format(stamp, uuid.uuid4().hex[:8])

    ticket = {
        "id": ticket_id,
        "name": name,
        "mail": mail,
        "message": msg,
        "created": stamp,
    }

    container = _container()
    image_filename = image.filename if (image is not None and image.filename) else None
    ticket_name, image_name = _blob_names(ticket_id, image_filename)
    ticket["image"] = image_name or ""

    # Read the image once: it is uploaded to blob storage and also embedded
    # (base64) in the flow payload below. The stream can only be consumed once.
    image_bytes = image.read() if image_filename else None
    image_content_type = None
    if image_bytes is not None:
        image_content_type = mimetypes.guess_type(image_filename)[0] or "application/octet-stream"

    # 1) Store the ticket itself as a JSON blob.
    container.upload_blob(
        name=ticket_name,
        data=json.dumps(ticket, ensure_ascii=False).encode("utf-8"),
        overwrite=True,
        content_settings=ContentSettings(content_type="application/json"),
    )

    # 2) Store the attached image next to it, if one was sent.
    if image_name is not None:
        container.upload_blob(
            name=image_name,
            data=image_bytes,
            overwrite=True,
            content_settings=ContentSettings(content_type=image_content_type),
        )

    # 3) Optionally notify Power Automate. The image is embedded as base64
    #    because the flow cannot reach the locked-down storage account.
    flow_payload = dict(ticket)
    if image_bytes is not None:
        flow_payload["image_content_type"] = image_content_type
        flow_payload["image_base64"] = base64.b64encode(image_bytes).decode("ascii")
    else:
        flow_payload["image_content_type"] = ""
        flow_payload["image_base64"] = ""
    _notify_flow(flow_payload)

    # Confirmation page (Swedish, part of the customer-facing website).
    body = (
        "<!DOCTYPE html><html lang='sv'><head><meta charset='UTF-8'>"
        "<title>Tack</title></head>"
        "<body style='font-family:Arial;max-width:640px;margin:40px auto'>"
        "<h1>Tack!</h1>"
        "<p>Ditt ärende är sparat med id <code>{0}</code>.</p>"
        "<p><a href='/'>Skicka in ett till</a></p>"
        "</body></html>"
    ).format(ticket_id)
    return Response(body, mimetype="text/html")


@app.get("/health")
def health():
    # Used by the Container Apps liveness/readiness probes.
    return {
        "status": "ok",
        "account": STORAGE_ACCOUNT,
        "container": CONTAINER,
        "blob_layout": BLOB_LAYOUT,
        "flow_configured": bool(FLOW_URL),
    }
