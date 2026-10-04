#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:-}"
ARCHIVE="${2:-}"

usage() {
  echo "Usage: $0 <kirkwood|mvebu> /path/to/rootfs.tar.bz2" >&2
  exit 2
}

[[ -n "$PLATFORM" && -n "$ARCHIVE" ]] || usage
[[ -f "$ARCHIVE" ]] || { echo "ERROR: archive not found: $ARCHIVE" >&2; exit 2; }

case "$PLATFORM" in
  kirkwood|mvebu) ;;
  *) echo "ERROR: unsupported platform: $PLATFORM" >&2; usage ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REFERENCE_FILE="$REPO_ROOT/rootfs/$PLATFORM/debian-12-reference.env"

[[ -f "$REFERENCE_FILE" ]] || {
  echo "ERROR: missing rootfs reference: $REFERENCE_FILE" >&2
  exit 3
}

# shellcheck disable=SC1090
source "$REFERENCE_FILE"

for variable in ARCHIVE_SHA256 CANONICAL_FILENAME DEBIAN_ARCH DEBIAN_VERSION \
                DOWNLOADED_FILENAME EXPECTED_DTB_COUNT KERNEL_RELEASE; do
  [[ -n "${!variable:-}" ]] || {
    echo "ERROR: $variable missing from $REFERENCE_FILE" >&2
    exit 3
  }
done

archive_name="$(basename -- "$ARCHIVE")"
case "$archive_name" in
  "$DOWNLOADED_FILENAME"|"$CANONICAL_FILENAME") ;;
  *)
    echo "WARNING: filename is not one of the recorded reference names:" >&2
    echo "  actual:     $archive_name" >&2
    echo "  downloaded: $DOWNLOADED_FILENAME" >&2
    echo "  canonical:  $CANONICAL_FILENAME" >&2
    ;;
esac

actual_sha="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [[ "$actual_sha" != "$ARCHIVE_SHA256" ]]; then
  echo "ERROR: rootfs SHA256 mismatch" >&2
  echo "  actual:   $actual_sha" >&2
  echo "  expected: $ARCHIVE_SHA256" >&2
  exit 4
fi

tmp_manifest="$(mktemp)"
trap 'rm -f "$tmp_manifest"' EXIT

echo "==> SHA256 verified"
echo "==> Reading archive manifest (this can take a while on older NAS hardware)"
tar -tjf "$ARCHIVE" > "$tmp_manifest"

required_paths=(
  "./boot/config-${KERNEL_RELEASE}"
  "./boot/initrd.img-${KERNEL_RELEASE}"
  "./boot/uImage"
  "./boot/uInitrd"
  "./boot/zImage-${KERNEL_RELEASE}"
  "./etc/debian_version"
  "./etc/fstab"
  "./etc/network/interfaces"
  "./usr/lib/modules/${KERNEL_RELEASE}/"
  "./var/lib/dpkg/status"
)

missing=0
for required in "${required_paths[@]}"; do
  if ! grep -Fqx -- "$required" "$tmp_manifest"; then
    echo "ERROR: required archive path missing: $required" >&2
    missing=1
  fi
done
(( missing == 0 )) || exit 5

dtb_count="$(grep -Ec '^\./boot/dts/.*\.dtb$' "$tmp_manifest" || true)"
if [[ "$dtb_count" != "$EXPECTED_DTB_COUNT" ]]; then
  echo "ERROR: /boot/dts contains $dtb_count DTBs; expected $EXPECTED_DTB_COUNT" >&2
  exit 6
fi

cat <<SUMMARY
==> Rootfs reference verified
platform=$PLATFORM
archive=$archive_name
sha256=$actual_sha
reference_debian=$DEBIAN_VERSION
reference_arch=$DEBIAN_ARCH
kernel_release=$KERNEL_RELEASE
boot_dtb_count=$dtb_count
init_system=${EXPECTED_INIT_SYSTEM:-not-recorded}
source=${SOURCE_THREAD_URL:-not-recorded}
SUMMARY

if [[ "$archive_name" != "$CANONICAL_FILENAME" ]]; then
  echo
  echo "NOTE: canonical filename is: $CANONICAL_FILENAME"
fi
