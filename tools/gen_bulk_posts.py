import requests
import random
from concurrent.futures import ThreadPoolExecutor, as_completed

MM_URL = "http://localhost:8065"
ACCESS_TOKEN = "f8ujzbko5pfgpc5faox4bgscay"
CHANNEL_ID = "oqbeqtskr7f1i8hnfyuh1bgf3r"
NUM_POSTS = 5_000_000
THREADS = 16

HEADERS = {
    "Authorization": f"Bearer {ACCESS_TOKEN}",
    "Content-Type": "application/json",
}


def get_first_channel():
    resp = requests.get(f"{MM_URL}/api/v4/users/me/teams", headers=HEADERS)
    resp.raise_for_status()
    team_id = resp.json()[0]["id"]
    resp = requests.get(
        f"{MM_URL}/api/v4/users/me/teams/{team_id}/channels", headers=HEADERS
    )
    resp.raise_for_status()
    return resp.json()[0]["id"]


def create_post(i):
    data = {
        "channel_id": CHANNEL_ID,
        "message": f"Test post number {i} - {random.randint(1000,9999)}",
    }
    resp = requests.post(f"{MM_URL}/api/v4/posts", headers=HEADERS, json=data)
    if resp.status_code != 201:
        return f"Failed at {i}: {resp.status_code} {resp.text}"
    return None


def main():
    global CHANNEL_ID
    if not CHANNEL_ID:
        CHANNEL_ID = get_first_channel()
        print(f"Using channel: {CHANNEL_ID}")

    with ThreadPoolExecutor(max_workers=THREADS) as executor:
        futures = [executor.submit(create_post, i) for i in range(NUM_POSTS + 1)]
        for i, _ in enumerate(as_completed(futures), start=1):
            if i % 10000 == 0:
                print(f"Created {i} posts...")

    print("\nDone.\n")


if __name__ == "__main__":
    main()
