#!/usr/bin/env python3
"""Check whether the App Store Connect app record exists.

This script intentionally performs a read-only lookup. Apple's current public
OpenAPI spec exposes GET /v1/apps with bundle-id filtering, but not a create-app
operation for the initial App Store Connect record.
"""

from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
import time
import urllib.parse
import urllib.request


DEFAULT_BUNDLE_ID = "com.chrisdimarco.ParkRidgeConnect"
DEFAULT_NAME = "Park Ridge Connect"
DEFAULT_SKU = "park-ridge-connect-ios"
API_BASE_URL = "https://api.appstoreconnect.apple.com"


def base64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def der_length(data: bytes, offset: int) -> tuple[int, int]:
    if offset >= len(data):
        raise ValueError("Truncated DER signature")
    first = data[offset]
    offset += 1
    if first < 0x80:
        return first, offset

    length_bytes = first & 0x7F
    if length_bytes == 0 or length_bytes > 2 or offset + length_bytes > len(data):
        raise ValueError("Unsupported DER length encoding")
    value = int.from_bytes(data[offset : offset + length_bytes], "big")
    return value, offset + length_bytes


def der_integer(data: bytes, offset: int) -> tuple[int, int]:
    if offset >= len(data) or data[offset] != 0x02:
        raise ValueError("Expected DER integer")
    length, offset = der_length(data, offset + 1)
    end = offset + length
    if end > len(data):
        raise ValueError("Truncated DER integer")
    return int.from_bytes(data[offset:end], "big"), end


def der_ecdsa_to_raw_signature(der_signature: bytes) -> bytes:
    if not der_signature or der_signature[0] != 0x30:
        raise ValueError("Expected DER sequence")
    sequence_length, offset = der_length(der_signature, 1)
    sequence_end = offset + sequence_length
    if sequence_end != len(der_signature):
        raise ValueError("Unexpected DER sequence length")

    r, offset = der_integer(der_signature, offset)
    s, offset = der_integer(der_signature, offset)
    if offset != sequence_end:
        raise ValueError("Unexpected trailing bytes in DER signature")
    return r.to_bytes(32, "big") + s.to_bytes(32, "big")


def sign_es256(signing_input: str, private_key_path: str) -> bytes:
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", private_key_path],
        input=signing_input.encode("ascii"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.decode("utf-8", "replace").strip())
    return der_ecdsa_to_raw_signature(result.stdout)


def make_token(key_id: str, issuer_id: str, private_key_path: str) -> str:
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    signing_input = ".".join(
        [
            base64url(json.dumps(header, separators=(",", ":")).encode("utf-8")),
            base64url(json.dumps(payload, separators=(",", ":")).encode("utf-8")),
        ]
    )
    signature = sign_es256(signing_input, private_key_path)
    return f"{signing_input}.{base64url(signature)}"


def get_app_record(token: str, bundle_id: str) -> dict:
    query = urllib.parse.urlencode(
        {
            "filter[bundleId]": bundle_id,
            "fields[apps]": "name,bundleId,sku,primaryLocale",
            "limit": "1",
        }
    )
    request = urllib.request.Request(
        f"{API_BASE_URL}/v1/apps?{query}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check for the Park Ridge Connect App Store Connect app record."
    )
    parser.add_argument("--key-id", required=True, help="App Store Connect API key ID.")
    parser.add_argument("--issuer-id", required=True, help="App Store Connect API issuer ID.")
    parser.add_argument(
        "--private-key-path",
        required=True,
        help="Path to the downloaded AuthKey_*.p8 private key.",
    )
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--expected-name", default=DEFAULT_NAME)
    parser.add_argument("--expected-sku", default=DEFAULT_SKU)
    args = parser.parse_args()

    token = make_token(args.key_id, args.issuer_id, args.private_key_path)
    payload = get_app_record(token, args.bundle_id)
    apps = payload.get("data", [])
    if not apps:
        print(f"Missing App Store Connect app record for {args.bundle_id}.")
        return 2

    app = apps[0]
    attributes = app.get("attributes", {})
    print(f"Found App Store Connect app record: {app.get('id')}")
    print(f"Name: {attributes.get('name')}")
    print(f"Bundle ID: {attributes.get('bundleId')}")
    print(f"SKU: {attributes.get('sku')}")
    print(f"Primary locale: {attributes.get('primaryLocale')}")

    warnings = []
    if attributes.get("name") != args.expected_name:
        warnings.append(f"Expected name {args.expected_name!r}.")
    if attributes.get("sku") != args.expected_sku:
        warnings.append(f"Expected SKU {args.expected_sku!r}.")

    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
