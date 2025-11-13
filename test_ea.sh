#!/usr/bin/env bash
set -euo pipefail

# Figure out repo root based on script location (robust even if you run from elsewhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

EA_CONFIG="${EA_CONFIG:-$REPO_ROOT/ea_endpoints}"
EXTERNAL_DIR="${EXTERNAL_DIR:-$REPO_ROOT/externalAdapters}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") --ea <ea-name> [--file payload.json]
  $(basename "$0") --url <EA_URL>  [--file payload.json]

If --file is not provided, JSON is read from stdin (paste and Ctrl-D).

Options:
  -e, --ea    EA name (looked up via comments in externalAdapters and cached in $(basename "$EA_CONFIG"))
  -u, --url   Full EA URL (bypass config / parsing)
  -f, --file  JSON payload file
  -h, --help  Show this help

Examples:
  $(basename "$0") --ea coinpaprika-state
  $(basename "$0") --ea allium-state --file req.json
  $(basename "$0") --url http://localhost:8010 --file req.json
EOF
}

ea_name=""
ea_url=""
payload_file=""

########################################################
# regenerate ea_endpoints from externalAdapters comments
########################################################
sync_ea_config_from_external() {
  # If externalAdapters doesn't exist, just create an empty config and bail
  if [[ ! -d "$EXTERNAL_DIR" ]]; then
    {
      echo "# Auto-generated EA endpoints config"
      echo "# externalAdapters directory not found: $EXTERNAL_DIR"
      echo "# This file will be rebuilt whenever externalAdapters exists."
      echo
    } > "$EA_CONFIG"
    return 0
  fi

  # Rebuild ea_endpoints from scratch each time
  {
    echo "# Auto-generated EA endpoints config"
    echo "# Source of truth: comment headers in scripts under externalAdapters/"
    echo "# Format: <ea-name> <url>"
    echo
  } > "$EA_CONFIG"

  local f ea_name_found endpoint_found
  for f in "$EXTERNAL_DIR"/*; do
    [[ -f "$f" ]] || continue

    ea_name_found="$(
      grep -E '^# *ea-name:' "$f" 2>/dev/null \
        | head -n1 \
        | sed -E 's/^# *ea-name:[[:space:]]*//'
    )" || true

    endpoint_found="$(
      grep -E '^# *endpoint:' "$f" 2>/dev/null \
        | head -n1 \
        | sed -E 's/^# *endpoint:[[:space:]]*//'
    )" || true

    if [[ -n "$ea_name_found" && -n "$endpoint_found" ]]; then
      echo "$ea_name_found $endpoint_found" >> "$EA_CONFIG"
    fi
  done
}

########################################################
# Look up EA URL (with -redis fallback)
########################################################
resolve_ea_url_from_config() {
  local name="$1"

  sync_ea_config_from_external

  local url=""
  if [[ -f "$EA_CONFIG" ]]; then
    # 1) exact match
    url="$(
      awk -v n="$name" '
        NF && $1 !~ /^#/ && $1==n {print $2}
      ' "$EA_CONFIG" | head -n1
    )" || true

    # 2) if not found, try "<name>-redis" (to handle coinpaprika-state vs coinpaprika-state-redis)
    if [[ -z "$url" ]]; then
      local alt="${name}-redis"
      url="$(
        awk -v n="$alt" '
          NF && $1 !~ /^#/ && $1==n {print $2}
        ' "$EA_CONFIG" | head -n1
      )" || true
    fi
  fi

  if [[ -n "$url" ]]; then
    printf '%s\n' "$url"
    return 0
  fi

  # Still not found: fall back to interactive one-off URL
  echo "Warning: EA '$name' not found in externalAdapters comments / $(basename "$EA_CONFIG")." >&2
  echo "Add lines like these to the appropriate script under externalAdapters/:" >&2
  echo "  # ea-name: $name" >&2
  echo "  # endpoint: http://HOST:PORT" >&2
  echo >&2
  echo "For now, enter a URL to use just for this run (or leave blank to abort):" >&2

  local input_url=""
  if ! read -r input_url </dev/tty; then
    echo "Error: unable to read from /dev/tty." >&2
    exit 1
  fi

  if [[ -z "$input_url" ]]; then
    echo "No URL entered. Cannot continue for '$name'." >&2
    exit 1
  fi

  printf '%s\n' "$input_url"
}

########################################################
# main test logic
########################################################
# arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--ea)
      ea_name="$2"
      shift 2
      ;;
    -u|--url)
      ea_url="$2"
      shift 2
      ;;
    -f|--file)
      payload_file="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# resolve URL
if [[ -z "${ea_url:-}" ]]; then
  if [[ -z "${ea_name:-}" ]]; then
    echo "Error: you must provide either --ea <name> or --url <URL>" >&2
    usage >&2
    exit 1
  fi

  ea_url="$(resolve_ea_url_from_config "$ea_name")"
fi

# read payload
payload=""

if [[ -n "${payload_file:-}" ]]; then
  if [[ ! -f "$payload_file" ]]; then
    echo "Error: payload file '$payload_file' not found." >&2
    exit 1
  fi
  payload="$(<"$payload_file")"
else
  echo "Paste JSON payload, then press Ctrl-D:" >&2
  payload="$(cat)"
fi

if [[ -z "$payload" ]]; then
  echo "Error: empty payload." >&2
  exit 1
fi

# validate JSON if jq exists
if command -v jq >/dev/null 2>&1; then
  if ! echo "$payload" | jq empty >/dev/null 2>&1; then
    echo "Error: payload is not valid JSON (jq failed)." >&2
    exit 1
  fi
fi

# fire request
echo "⇒ POST $ea_url" >&2

if command -v jq >/dev/null 2>&1; then
  curl -sS -X POST "$ea_url" \
    -H "Content-Type: application/json" \
    -d "$payload" | jq .
else
  curl -sS -X POST "$ea_url" \
    -H "Content-Type: application/json" \
    -d "$payload"
fi

echo "⇐ Done" >&2
