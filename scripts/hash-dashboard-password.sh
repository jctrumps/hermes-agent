#!/usr/bin/env bash
set -euo pipefail

# Run in WSL/Linux with Python 3. Prompts on the terminal; never takes a password
# as an argument or writes it to a file. Output matches Hermes's bundled scrypt
# provider: scrypt$16384$8$1$<base64 16-byte salt>$<base64 32-byte derived key>.
python3 - <<'PY'
import base64
import getpass
import hashlib
import secrets
import sys
import warnings

# Refuse getpass's visible-input fallback when no terminal is available.
warnings.simplefilter("error", getpass.GetPassWarning)
try:
    password = getpass.getpass("Dashboard password (16+ characters recommended): ")
    confirmation = getpass.getpass("Confirm dashboard password: ")
except (getpass.GetPassWarning, EOFError, KeyboardInterrupt):
    sys.exit("Cancelled or no secure terminal available. Run interactively in WSL/Linux.")

if password != confirmation:
    sys.exit("Passwords do not match; no hash generated.")
if not password or password != password.strip():
    sys.exit("Use a non-empty password without leading/trailing whitespace; no hash generated.")
if len(password) < 16:
    print("Warning: fewer than 16 characters. Use a longer, unique password for a public dashboard.", file=sys.stderr)

salt = secrets.token_bytes(16)
derived = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=16384, r=8, p=1, dklen=32)
print("scrypt$16384$8$1$" + base64.b64encode(salt).decode() + "$" + base64.b64encode(derived).decode())
PY
