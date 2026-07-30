"""Checks for the /api/v1/ auth middleware in test17.py.

This service mints OpenAI Realtime keys and runs paid model calls, so "is the door
locked" is the one property worth a regression test. Written as a dependency-free
script because nowli-ai has no test runner:

    cd nowli-ai
    .venv/Scripts/python.exe test_auth_middleware.py     # Windows
    python test_auth_middleware.py                        # elsewhere

Exits non-zero on any failure. Sets NOWLII_JWT_SECRET itself, so it does not need a
configured .env and never touches the real secret.
"""
import datetime as dt
import os
import sys

SECRET = "test-only-secret-never-used-in-production-1f4b7c9e2a"
os.environ["NOWLII_JWT_SECRET"] = SECRET

import jwt  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

import test17  # noqa: E402

NOW = dt.datetime.now(dt.timezone.utc)
# Any authenticated route works; quest-source is the cheapest (no model call, no session).
GUARDED_PATH = "/api/v1/quest-source"


def make_token(key=SECRET, **overrides):
    claims = {
        "token_type": "access",
        "user_id": 7,
        "exp": NOW + dt.timedelta(minutes=5),
        "iat": NOW,
        "jti": "test-jti",
    }
    claims.update(overrides)
    return jwt.encode(claims, key, algorithm="HS256")


def main():
    client = TestClient(test17.app)

    assert test17.AUTH_ENABLED, "AUTH_ENABLED should be True when NOWLII_JWT_SECRET is set"

    cases = [
        # (name, path, Authorization header, expected status)
        ("health stays public", "/health", None, 200),
        ("root stays public", "/", None, 200),
        ("no Authorization header", GUARDED_PATH, None, 401),
        ("malformed token", GUARDED_PATH, "Bearer not-a-jwt", 401),
        ("missing 'Bearer ' scheme", GUARDED_PATH, make_token(), 401),
        ("valid access token", GUARDED_PATH, f"Bearer {make_token()}", 200),
        (
            "expired token",
            GUARDED_PATH,
            f"Bearer {make_token(exp=NOW - dt.timedelta(minutes=1))}",
            401,
        ),
        (
            "token signed with a different secret",
            GUARDED_PATH,
            f"Bearer {make_token(key='some-other-secret')}",
            401,
        ),
        # Refresh tokens carry the same signature but must not buy API access.
        (
            "refresh token rejected",
            GUARDED_PATH,
            f"Bearer {make_token(token_type='refresh')}",
            401,
        ),
    ]

    failures = 0
    for name, path, auth, expected in cases:
        headers = {"Authorization": auth} if auth else {}
        status = client.get(path, headers=headers).status_code
        if status == expected:
            print(f"PASS  {name}")
        else:
            failures += 1
            print(f"FAIL  {name}: got {status}, expected {expected}")

    if client.get("/health").json().get("auth_required") is not True:
        failures += 1
        print("FAIL  /health should report auth_required=true")
    else:
        print("PASS  /health reports auth_required=true")

    print(f"\n{len(cases) + 1 - failures}/{len(cases) + 1} checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
