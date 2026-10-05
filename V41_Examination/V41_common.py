# Nordvik tenant portal - shared configuration and Azure clients.
# Used by the web app (V41_app.py) and the notification job (V41_worker.py).
#
# Configuration comes from environment variables (set by Bicep):
#   STORAGE_ACCOUNT   Name of the storage account (required)
#   IMAGES_CONTAINER  Blob container for fault-report photos (default: felanmalan)
#   DOCS_CONTAINER    Blob container for contracts / inspection protocols (default: avtal)
#   QUEUE_NAME        Storage queue with notification work (default: notiser)
#   AUTH_MODE         "easyauth" (default, production) or "demo" (test/demo only)
#   AZURE_CLIENT_ID   Client ID of the user-assigned managed identity
#   FLOW_URL          Optional Power Automate HTTP trigger URL (stored as a secret)
#   ACS_ENDPOINT      Azure Communication Services endpoint (e-mail for urgent reports)
#   MAIL_SENDER       Sender address on the ACS e-mail domain
#   AKUT_MAIL_EXTRA   Optional comma-separated extra recipients for urgent reports
#   PORTAL_URL        Public URL of the portal (used in e-mails)

import os

from azure.core.exceptions import ResourceNotFoundError
from azure.data.tables import TableServiceClient
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient

STORAGE_ACCOUNT = os.environ["STORAGE_ACCOUNT"]
IMAGES_CONTAINER = os.environ.get("IMAGES_CONTAINER", "felanmalan")
DOCS_CONTAINER = os.environ.get("DOCS_CONTAINER", "avtal")
QUEUE_NAME = os.environ.get("QUEUE_NAME", "notiser")
AUTH_MODE = os.environ.get("AUTH_MODE", "easyauth")
FLOW_URL = os.environ.get("FLOW_URL", "")
ACS_ENDPOINT = os.environ.get("ACS_ENDPOINT", "")
MAIL_SENDER = os.environ.get("MAIL_SENDER", "")
AKUT_MAIL_EXTRA = [a.strip() for a in os.environ.get("AKUT_MAIL_EXTRA", "").split(",") if a.strip()]
PORTAL_URL = os.environ.get("PORTAL_URL", "")

TICKETS_TABLE = "Arenden"
USERS_TABLE = "Anvandare"
PROPERTIES_TABLE = "Fastigheter"

ROLES = ("hyresgast", "forvaltare", "ekonomi")
STATUSES = ("ny", "pagar", "klar")

credential = DefaultAzureCredential(
    managed_identity_client_id=os.environ.get("AZURE_CLIENT_ID")
)
blob_service = BlobServiceClient(
    account_url="https://{0}.blob.core.windows.net".format(STORAGE_ACCOUNT),
    credential=credential,
)
table_service = TableServiceClient(
    endpoint="https://{0}.table.core.windows.net".format(STORAGE_ACCOUNT),
    credential=credential,
)


def table(name):
    return table_service.get_table_client(name)


def queue(name):
    return QueueClient(
        account_url="https://{0}.queue.core.windows.net".format(STORAGE_ACCOUNT),
        queue_name=name,
        credential=credential,
    )


# Categories. "akut" categories trigger an immediate e-mail to the manager.
CATEGORIES = [
    {"id": "vattenlacka", "namn": "Vattenläcka eller översvämning", "akut": True},
    {"id": "stromavbrott", "namn": "Strömavbrott", "akut": True},
    {"id": "varme", "namn": "Värme eller varmvatten saknas", "akut": True},
    {"id": "hiss", "namn": "Hiss har stannat", "akut": True},
    {"id": "inbrott", "namn": "Inbrott eller trasigt lås", "akut": True},
    {"id": "avlopp", "namn": "Stopp i avlopp eller toalett", "akut": False},
    {"id": "el", "namn": "Elfel (uttag, lampor)", "akut": False},
    {"id": "ventilation", "namn": "Ventilation", "akut": False},
    {"id": "fonster_dorr", "namn": "Fönster eller dörr", "akut": False},
    {"id": "tvattstuga", "namn": "Tvättstuga", "akut": False},
    {"id": "skadedjur", "namn": "Skadedjur", "akut": False},
    {"id": "allmanna_ytor", "namn": "Trapphus, utomhus och gemensamma ytor", "akut": False},
    {"id": "ovrigt", "namn": "Övrigt", "akut": False},
]
CATEGORY_BY_ID = {c["id"]: c for c in CATEGORIES}

# Demo data. Only used when AUTH_MODE=demo (never in production, Bicep enforces it).
DEMO_PROPERTIES = {
    "F001": {"namn": "Kvarteret Älvkanten", "forvaltarMail": "forvaltare.demo@example.com"},
    "F002": {"namn": "Hamnhuset", "forvaltarMail": "forvaltare.demo@example.com"},
}
DEMO_USERS = {
    "hyresgast": {"roll": "hyresgast", "namn": "Elin Demo", "mail": "elin.demo@example.com",
                  "fastighet": "F001", "enhet": "1204", "fastigheter": []},
    "hyresgast2": {"roll": "hyresgast", "namn": "Omar Demo", "mail": "omar.demo@example.com",
                   "fastighet": "F002", "enhet": "0302", "fastigheter": []},
    "forvaltare": {"roll": "forvaltare", "namn": "Frida Förvaltare (demo)", "mail": "forvaltare.demo@example.com",
                   "fastighet": "", "enhet": "", "fastigheter": ["F001", "F002"]},
    "ekonomi": {"roll": "ekonomi", "namn": "Erik Ekonomi (demo)", "mail": "ekonomi.demo@example.com",
                "fastighet": "", "enhet": "", "fastigheter": []},
}


def get_user(user_id):
    """Looks up a portal user (user_id = lower-case UPN). None if not registered."""
    if AUTH_MODE == "demo":
        u = DEMO_USERS.get(user_id)
        return dict(u, id=user_id) if u else None
    try:
        e = table(USERS_TABLE).get_entity("anvandare", user_id)
    except ResourceNotFoundError:
        return None
    return {
        "id": user_id,
        "roll": e.get("roll", ""),
        "namn": e.get("namn", ""),
        "mail": e.get("mail", ""),
        "fastighet": e.get("fastighet", ""),
        "enhet": e.get("enhet", ""),
        "fastigheter": [p.strip() for p in e.get("fastigheter", "").split(",") if p.strip()],
    }


def list_properties():
    """Returns {property_id: {"namn": ..., "forvaltarMail": ...}}."""
    if AUTH_MODE == "demo":
        return DEMO_PROPERTIES
    result = {}
    for e in table(PROPERTIES_TABLE).query_entities("PartitionKey eq 'fastighet'"):
        result[e["RowKey"]] = {"namn": e.get("namn", e["RowKey"]), "forvaltarMail": e.get("forvaltarMail", "")}
    return result
