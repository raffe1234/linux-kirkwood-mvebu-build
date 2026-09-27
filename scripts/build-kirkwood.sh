#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_REVISION="${1:-raffe-1}"
KERNEL_VERSION="${2:-7.1.9}"

exec "$SCRIPT_DIR/build-platform.sh" kirkwood "$KERNEL_VERSION" "$LOCAL_REVISION"
