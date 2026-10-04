#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:-}"
ARCHIVE="${2:-}"

usage() {
  echo "Usage: $0 <kirkwood|mvebu> /path/to/generated-rootfs.tar.bz2" >&2
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
CONFIG_FILE="$REPO_ROOT/rootfs/$PLATFORM/debian-13.env"

[[ -f "$CONFIG_FILE" ]] || {
  echo "ERROR: missing rootfs build definition: $CONFIG_FILE" >&2
  exit 3
}

# shellcheck disable=SC1090
source "$CONFIG_FILE"

for variable in DEBIAN_ARCH DEBIAN_MAJOR DEBIAN_SUITE FSTAB_ROOT_TYPE ROOTFS_HOSTNAME; do
  [[ -n "${!variable:-}" ]] || {
    echo "ERROR: $variable missing from $CONFIG_FILE" >&2
    exit 3
  }
done

tmp_manifest="$(mktemp)"
trap 'rm -f "$tmp_manifest"' EXIT

tar -tjf "$ARCHIVE" > "$tmp_manifest"

required_paths=(
  "./etc/apt/sources.list"
  "./etc/debian_version"
  "./etc/fstab"
  "./etc/hostname"
  "./etc/hosts"
  "./etc/linux-kirkwood-mvebu-build-rootfs"
  "./etc/network/interfaces"
  "./etc/passwd"
  "./etc/shadow"
  "./root/ROOTFS-BUILD-METADATA.txt"
  "./root/ROOTFS-PACKAGE-MANIFEST.txt"
  "./usr/sbin/init"
  "./var/lib/dpkg/status"
)

missing=0
for required in "${required_paths[@]}"; do
  if ! grep -Fqx -- "$required" "$tmp_manifest"; then
    echo "ERROR: required archive path missing: $required" >&2
    missing=1
  fi
done
(( missing == 0 )) || exit 4

marker="$(tar -xOjf "$ARCHIVE" ./etc/linux-kirkwood-mvebu-build-rootfs)"
fstab="$(tar -xOjf "$ARCHIVE" ./etc/fstab)"
interfaces="$(tar -xOjf "$ARCHIVE" ./etc/network/interfaces)"
hostname="$(tar -xOjf "$ARCHIVE" ./etc/hostname | tr -d '\r\n')"
status="$(tar -xOjf "$ARCHIVE" ./var/lib/dpkg/status)"
debian_version="$(tar -xOjf "$ARCHIVE" ./etc/debian_version | tr -d '\r\n')"
shadow_root="$(tar -xOjf "$ARCHIVE" ./etc/shadow | grep '^root:' | head -n 1 || true)"

check_marker() {
  local key="$1" expected="$2"
  if ! grep -Fqx "$key=$expected" <<<"$marker"; then
    echo "ERROR: marker does not contain $key=$expected" >&2
    exit 5
  fi
}

check_marker platform "$PLATFORM"
check_marker debian_suite "$DEBIAN_SUITE"
check_marker debian_major "$DEBIAN_MAJOR"
check_marker debian_arch "$DEBIAN_ARCH"
check_marker kernel_installed no
check_marker media_installed no

case "$debian_version" in
  "$DEBIAN_MAJOR".*|"$DEBIAN_MAJOR") ;;
  *)
    echo "ERROR: /etc/debian_version is '$debian_version', expected Debian $DEBIAN_MAJOR." >&2
    exit 5
    ;;
esac

if ! grep -Eq "^LABEL=rootfs[[:space:]]+/[[:space:]]+$FSTAB_ROOT_TYPE[[:space:]]" <<<"$fstab"; then
  echo "ERROR: fstab does not contain the expected LABEL=rootfs entry." >&2
  exit 6
fi

[[ "$hostname" == "$ROOTFS_HOSTNAME" ]] || {
  echo "ERROR: hostname is '$hostname', expected '$ROOTFS_HOSTNAME'." >&2
  exit 6
}

grep -Fqx 'auto lo eth0' <<<"$interfaces" || {
  echo "ERROR: network interfaces file does not configure lo/eth0." >&2
  exit 6
}
grep -Fqx 'iface eth0 inet dhcp' <<<"$interfaces" || {
  echo "ERROR: network interfaces file does not configure eth0 DHCP." >&2
  exit 6
}

if [[ -n "${NETWORK_RENAME_RULE:-}" ]]; then
  grep -Fqx "$NETWORK_RENAME_RULE" <<<"$interfaces" || {
    echo "ERROR: expected network rename rule is missing: $NETWORK_RENAME_RULE" >&2
    exit 6
  }
fi

sysv_stanza="$(awk 'BEGIN{RS=""} /^Package: sysvinit-core\n/ {print; exit}' <<<"$status")"
systemd_sysv_stanza="$(awk 'BEGIN{RS=""} /^Package: systemd-sysv\n/ {print; exit}' <<<"$status")"
standalone_sysusers_stanza="$(awk 'BEGIN{RS=""} /^Package: systemd-standalone-sysusers\n/ {print; exit}' <<<"$status")"

if ! grep -q '^Status: install ok installed$' <<<"$sysv_stanza"; then
  echo "ERROR: sysvinit-core is not installed in generated rootfs." >&2
  exit 7
fi
if ! grep -q "^Architecture: $DEBIAN_ARCH$" <<<"$sysv_stanza"; then
  echo "ERROR: sysvinit-core architecture does not match $DEBIAN_ARCH." >&2
  exit 7
fi
if grep -q '^Status: install ok installed$' <<<"$systemd_sysv_stanza"; then
  echo "ERROR: systemd-sysv is installed in generated rootfs." >&2
  exit 7
fi
if ! grep -q '^Status: install ok installed$' <<<"$standalone_sysusers_stanza"; then
  echo "ERROR: systemd-standalone-sysusers is not installed." >&2
  exit 7
fi

case "$shadow_root" in
  root:!*) ;;
  *)
    echo "ERROR: root account is not locked in generated rootfs." >&2
    exit 8
    ;;
esac

if grep -Eq '^\./etc/ssh/ssh_host_' "$tmp_manifest"; then
  echo "ERROR: generated base rootfs contains reusable SSH host keys." >&2
  exit 8
fi

if grep -Eq '^\./boot/(uImage|uInitrd|zImage-|vmlinuz-|initrd\.img-)' "$tmp_manifest"; then
  echo "ERROR: generated base rootfs unexpectedly contains kernel/boot images." >&2
  exit 9
fi

cat <<SUMMARY
==> Generated rootfs verified
platform=$PLATFORM
archive=$(basename -- "$ARCHIVE")
debian_suite=$DEBIAN_SUITE
debian_arch=$DEBIAN_ARCH
init_system=sysvinit
hostname=$ROOTFS_HOSTNAME
kernel_installed=no
media_installed=no
SUMMARY
