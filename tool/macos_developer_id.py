#!/usr/bin/env python3
"""Developer ID for the Mac package (#387).

The Mac package used to be signed ad hoc, and an ad hoc signature carries
no application identifier: the data protection keychain refuses every
write with -34018, and the app runs its household unencrypted. A
Developer ID signature alone does not change that either. The keychain
wants `com.apple.application-identifier` and `keychain-access-groups`,
and on a Mac those are only honoured when a provisioning profile in the
bundle allows them -- a Developer ID profile, which needs no devices.

This finds what signing needs on this machine, and asks App Store Connect
for a profile where there is none:

  identity                      SHA-1 of the Developer ID Application
                                identity in the keychain
  profile <bundle id>           path of a valid Developer ID profile for
                                that identifier and that identity
  entitlements <profile> <base> <out>
                                <base> plus the identifier, the team and
                                the keychain group the profile allows
  create-profile <bundle id>... a Developer ID profile from App Store
                                Connect, saved where Xcode keeps its own
  asc-key <directory>           writes the API key there as AuthKey.p8
                                (readable by this user alone) and prints
                                "<key id> <issuer id>"

Nothing of the account is in the repository. The identity is printed as
its hash, never by its name, which is a person's. The API key is the one
`tool/ios_testflight.sh` reads, from the same keychain items.
"""

from __future__ import annotations

import base64
import binascii
import datetime as dt
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

PROFILE_DIRS = [
    Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
    Path.home() / "Library/MobileDevice/Provisioning Profiles",
]
API = "https://api.appstoreconnect.apple.com/v1"


def fail(message: str) -> None:
    print(f"FEHLER: {message}", file=sys.stderr)
    sys.exit(1)


# --- identity -------------------------------------------------------------


def identity() -> str:
    """The SHA-1 of the one valid Developer ID Application identity."""
    out = subprocess.run(
        ["security", "find-identity", "-v", "-p", "codesigning"],
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    hashes = [
        m.group(1)
        for m in re.finditer(r'\s\d+\)\s+([0-9A-F]{40})\s+"Developer ID Application:', out)
    ]
    if not hashes:
        fail("kein Zertifikat „Developer ID Application“ im Schlüsselbund")
    if len(set(hashes)) > 1:
        fail("mehr als ein Zertifikat „Developer ID Application“ im Schlüsselbund")
    return hashes[0]


# --- profiles -------------------------------------------------------------


def read_profile(path: Path) -> dict:
    """A provisioning profile's plist. Signed profiles are unwrapped with
    `security cms`; a bare plist (as the tests write) is read as it is."""
    data = path.read_bytes()
    if not data.lstrip().startswith(b"<?xml"):
        data = subprocess.run(
            ["security", "cms", "-D", "-i", str(path)],
            capture_output=True,
            check=True,
        ).stdout
    return plistlib.loads(data)


def application_identifier(profile: dict) -> str:
    entitlements = profile.get("Entitlements", {})
    return entitlements.get("com.apple.application-identifier") or entitlements.get(
        "application-identifier", ""
    )


def profile_fits(profile: dict, bundle_id: str, cert_sha1: str | None, now: dt.datetime) -> bool:
    """Whether [profile] is a Developer ID profile for [bundle_id], still
    valid, and made out for the identity [cert_sha1]."""
    if "OSX" not in profile.get("Platform", []):
        return False
    if not profile.get("ProvisionsAllDevices"):
        return False
    appid = application_identifier(profile)
    if appid.split(".", 1)[-1] != bundle_id:
        return False
    expires = profile.get("ExpirationDate")
    if not isinstance(expires, dt.datetime):
        return False
    if expires.replace(tzinfo=dt.timezone.utc) <= now:
        return False
    if cert_sha1 is None:
        return True
    return any(
        hashlib.sha1(cert).hexdigest().upper() == cert_sha1.upper()
        for cert in profile.get("DeveloperCertificates", [])
    )


def find_profile(bundle_id: str, cert_sha1: str | None, dirs=PROFILE_DIRS) -> Path | None:
    now = dt.datetime.now(dt.timezone.utc)
    found = []
    for directory in dirs:
        if not directory.is_dir():
            continue
        for path in directory.iterdir():
            if path.suffix not in (".provisionprofile", ".mobileprovision"):
                continue
            try:
                profile = read_profile(path)
            except Exception:  # noqa: BLE001 - an unreadable file is not ours
                continue
            if profile_fits(profile, bundle_id, cert_sha1, now):
                found.append((profile["ExpirationDate"], path))
    if not found:
        return None
    return max(found)[1]


def entitlements(profile_path: Path, base_path: Path, out_path: Path) -> None:
    """[base_path] plus what the profile allows for the keychain: the
    application identifier, the team, and the app's own keychain group --
    the group the plugin writes to when it names none."""
    profile = read_profile(profile_path)
    appid = application_identifier(profile)
    allowed = profile.get("Entitlements", {})
    team = allowed.get("com.apple.developer.team-identifier") or appid.split(".", 1)[0]
    groups = allowed.get("keychain-access-groups", [])
    if not appid or not team:
        fail(f"{profile_path.name} nennt keine Anwendungskennung")
    if not any(g == appid or (g.endswith(".*") and appid.startswith(g[:-1])) for g in groups):
        fail(f"{profile_path.name} erlaubt keine Schlüsselbundgruppe {appid}")
    with open(base_path, "rb") as f:
        merged = plistlib.load(f)
    merged["com.apple.application-identifier"] = appid
    merged["com.apple.developer.team-identifier"] = team
    merged["keychain-access-groups"] = [appid]
    with open(out_path, "wb") as f:
        plistlib.dump(merged, f)


# --- App Store Connect ----------------------------------------------------


def keychain(service: str) -> str:
    return subprocess.run(
        ["security", "find-generic-password", "-s", service, "-w"],
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip()


def api_key_text() -> str:
    """The .p8 key from the keychain: stored base64-encoded, or as the
    file's own text, which `security -w` hands back as hex."""
    raw = keychain("de.dasevo.preppsuite.asc-key")
    if not raw:
        fail("API-Schlüssel fehlt (de.dasevo.preppsuite.asc-key, siehe docs/testflight.md)")
    if raw.startswith("-----BEGIN"):
        text = raw
    elif re.fullmatch(r"(?:[0-9a-f]{2})+", raw):
        text = bytes.fromhex(raw).decode()
    else:
        try:
            text = base64.b64decode(raw, validate=False).decode()
        except (binascii.Error, UnicodeDecodeError):
            fail("de.dasevo.preppsuite.asc-key ist weder base64 noch Hex")
    if "-----BEGIN PRIVATE KEY-----" not in text:
        fail("de.dasevo.preppsuite.asc-key ist kein .p8-Schlüssel")
    return text.strip() + "\n"


def asc_ids() -> tuple[str, str]:
    key_id = keychain("de.dasevo.preppsuite.asc-key-id")
    issuer = keychain("de.dasevo.preppsuite.asc-issuer")
    if not key_id or not issuer:
        fail("Schlüssel-ID oder Aussteller-ID fehlt (siehe docs/testflight.md)")
    return key_id, issuer


def write_key(directory: Path) -> Path:
    path = directory / "AuthKey.p8"
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(api_key_text())
    return path


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_signature_to_raw(der: bytes) -> bytes:
    """An ECDSA signature as openssl writes it (DER: SEQUENCE of two
    INTEGERs) in the form a JWT carries it: r and s, 32 bytes each."""
    if len(der) < 8 or der[0] != 0x30:
        raise ValueError("keine DER-Signatur")
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    parts = []
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("keine INTEGER in der Signatur")
        length = der[i + 1]
        value = der[i + 2 : i + 2 + length]
        parts.append(int.from_bytes(value, "big").to_bytes(32, "big"))
        i += 2 + length
    return parts[0] + parts[1]


def token(key_path: Path, key_id: str, issuer: str) -> str:
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    now = int(time.time())
    payload = b64url(
        json.dumps(
            {"iss": issuer, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}
        ).encode()
    )
    message = f"{header}.{payload}".encode()
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", str(key_path)],
        input=message,
        capture_output=True,
        check=True,
    ).stdout
    return f"{header}.{payload}.{b64url(der_signature_to_raw(der))}"


def call(jwt: str, method: str, path: str, body: dict | None = None) -> dict:
    request = urllib.request.Request(
        API + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {jwt}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        try:
            errors = json.loads(detail).get("errors", [])
            detail = "; ".join(e.get("detail") or e.get("title", "") for e in errors)
        except json.JSONDecodeError:
            pass
        fail(f"App Store Connect {method} {path.split('?')[0]}: {error.code} {detail}")


def create_profiles(bundle_ids: list[str]) -> None:
    cert_sha1 = identity()
    key_id, issuer = asc_ids()
    with tempfile.TemporaryDirectory() as work:
        jwt = token(write_key(Path(work)), key_id, issuer)

    # Certificates made since 2021 hang off Apple's G2 intermediate and
    # carry their own type; the account may hold either.
    certificates = call(
        jwt,
        "GET",
        "/certificates?filter[certificateType]="
        "DEVELOPER_ID_APPLICATION,DEVELOPER_ID_APPLICATION_G2&limit=200",
    )["data"]
    certificate = next(
        (
            c
            for c in certificates
            if hashlib.sha1(base64.b64decode(c["attributes"]["certificateContent"]))
            .hexdigest()
            .upper()
            == cert_sha1
        ),
        None,
    )
    if certificate is None:
        fail("das Developer-ID-Zertifikat dieses Macs ist in App Store Connect nicht zu finden")

    target = PROFILE_DIRS[0]
    target.mkdir(parents=True, exist_ok=True)
    for bundle_id in bundle_ids:
        found = call(jwt, "GET", f"/bundleIds?filter[identifier]={bundle_id}&limit=200")["data"]
        bundle = next((b for b in found if b["attributes"]["identifier"] == bundle_id), None)
        if bundle is None:
            bundle = call(
                jwt,
                "POST",
                "/bundleIds",
                {
                    "data": {
                        "type": "bundleIds",
                        "attributes": {
                            "identifier": bundle_id,
                            "name": bundle_id.replace(".", " "),
                            "platform": "MAC_OS",
                        },
                    }
                },
            )["data"]
            print(f"  App-ID angelegt: {bundle_id}")
        stamp = dt.datetime.now().strftime("%Y-%m-%d %H%M")
        profile = call(
            jwt,
            "POST",
            "/profiles",
            {
                "data": {
                    "type": "profiles",
                    "attributes": {
                        "name": f"{bundle_id} Developer ID {stamp}",
                        "profileType": "MAC_APP_DIRECT",
                    },
                    "relationships": {
                        "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                        "certificates": {
                            "data": [{"type": "certificates", "id": certificate["id"]}]
                        },
                    },
                }
            },
        )["data"]["attributes"]
        path = target / f"{profile['uuid']}.provisionprofile"
        path.write_bytes(base64.b64decode(profile["profileContent"]))
        print(f"  Profil für {bundle_id}, gültig bis {profile['expirationDate'][:10]}")


# --- command line ---------------------------------------------------------


def main(argv: list[str]) -> None:
    if not argv:
        print(__doc__)
        sys.exit(2)
    command, args = argv[0], argv[1:]
    if command == "identity" and not args:
        print(identity())
    elif command == "profile" and len(args) == 1:
        path = find_profile(args[0], identity())
        if path is None:
            fail(
                f"kein gültiges Developer-ID-Profil für {args[0]} "
                f"(tool/macos_developer_id.py create-profile {args[0]})"
            )
        print(path)
    elif command == "entitlements" and len(args) == 3:
        entitlements(Path(args[0]), Path(args[1]), Path(args[2]))
    elif command == "create-profile" and args:
        create_profiles(args)
    elif command == "asc-key" and len(args) == 1:
        write_key(Path(args[0]))
        print(" ".join(asc_ids()))
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main(sys.argv[1:])
