import requests

API_KEY = "DEMO_API_KEY_PLACEHOLDER"


def send_to_analytics(payload):
    headers = {"Authorization": f"Bearer {API_KEY}"}
    r = requests.post(
        "https://analytics.habotconnect.com/ingest",
        json=payload,
        headers=headers,
    )
    return r
