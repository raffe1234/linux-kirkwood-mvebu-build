#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:-}"
KERNEL_VERSION="${2:-7.1.9}"
LOCAL_REVISION="${3:-raffe-1}"
JOBS="${JOBS:-$(nproc)}"

usage() {
  echo "Usage: $0 <kirkwood|mvebu> [kernel-version] [local-revision]" >&2
  exit 2
}

[[ -n "$PLATFORM" ]] || usage

case "$LOCAL_REVISION" in
  ""|*[!a-zA-Z0-9._-]*)
    echo "ERROR: local revision may contain only letters, digits, dot, underscore and hyphen." >&2
    exit 2
    ;;
esac

case "$KERNEL_VERSION" in
  ""|*[!0-9A-Za-z._-]*)
    echo "ERROR: kernel version contains unsupported characters." >&2
    exit 2
    ;;
esac

case "$PLATFORM" in
  kirkwood)
    BASE_LOCALVERSION="kirkwood-tld-1"
    CROSS_COMPILE="arm-linux-gnueabi-"
    KBUILD_DEBARCH="armel"
    DTB_PATTERN="kirkwood-*.dtb"
    REFERENCE_DTB_NAME="kirkwood-n1t1.dtb"
    REFERENCE_COUNT_VAR="KIRKWOOD_DTB_COUNT"
    REFERENCE_SHA_VAR="N1T1_DTB_SHA256"
    REFERENCE_LABEL="N1T1"
    ;;
  mvebu)
    BASE_LOCALVERSION="mvebu-tld-1"
    CROSS_COMPILE="arm-linux-gnueabihf-"
    KBUILD_DEBARCH="armhf"
    DTB_PATTERN="*.dtb"
    REFERENCE_DTB_NAME="armada-380-zyxel-nas326.dtb"
    REFERENCE_COUNT_VAR="MVEBU_DTB_COUNT"
    REFERENCE_SHA_VAR="NAS326_DTB_SHA256"
    REFERENCE_LABEL="NAS326"
    ;;
  *)
    echo "ERROR: unsupported platform: $PLATFORM" >&2
    usage
    ;;
esac

: "${DEBFULLNAME:?Set DEBFULLNAME to your own package maintainer name}"
: "${DEBEMAIL:?Set DEBEMAIL to your own package maintainer email}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/configs/$PLATFORM/config-${KERNEL_VERSION}-${BASE_LOCALVERSION}"
PATCH_FILE="$REPO_ROOT/patches/$PLATFORM/linux-${KERNEL_VERSION}-${BASE_LOCALVERSION}.patch"
UPSTREAM_SHA_FILE="$REPO_ROOT/checksums/linux-${KERNEL_VERSION}.tar.xz.sha256"
REFERENCE_FILE="$REPO_ROOT/checksums/${PLATFORM}-${KERNEL_VERSION}-reference.env"

for required in "$CONFIG_FILE" "$PATCH_FILE" "$UPSTREAM_SHA_FILE" "$REFERENCE_FILE"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required file: $required" >&2
    exit 3
  fi
done

# shellcheck disable=SC1090
source "$REFERENCE_FILE"

EXPECTED_DTB_COUNT="${!REFERENCE_COUNT_VAR:-}"
EXPECTED_DTB_SHA="${!REFERENCE_SHA_VAR:-}"

[[ -n "$EXPECTED_DTB_COUNT" ]] || {
  echo "ERROR: $REFERENCE_COUNT_VAR missing from $REFERENCE_FILE" >&2
  exit 3
}
[[ -n "$EXPECTED_DTB_SHA" ]] || {
  echo "ERROR: $REFERENCE_SHA_VAR missing from $REFERENCE_FILE" >&2
  exit 3
}

PATCH_SHA="$(sha256sum "$PATCH_FILE" | awk '{print $1}')"
CONFIG_SHA="$(sha256sum "$CONFIG_FILE" | awk '{print $1}')"

if [[ -n "${BODHI_CONFIG_SHA256:-}" && "$CONFIG_SHA" != "$BODHI_CONFIG_SHA256" ]]; then
  echo "ERROR: bodhi config SHA256 mismatch" >&2
  echo "  actual:   $CONFIG_SHA" >&2
  echo "  expected: $BODHI_CONFIG_SHA256" >&2
  exit 3
fi

if [[ -n "${BODHI_PATCH_SHA256:-}" && "$PATCH_SHA" != "$BODHI_PATCH_SHA256" ]]; then
  echo "ERROR: bodhi patch SHA256 mismatch" >&2
  echo "  actual:   $PATCH_SHA" >&2
  echo "  expected: $BODHI_PATCH_SHA256" >&2
  exit 3
fi

KERNEL_RELEASE="${KERNEL_VERSION}-${BASE_LOCALVERSION}-${LOCAL_REVISION}"
WORK_ROOT="$REPO_ROOT/.work/${PLATFORM}-${KERNEL_VERSION}-${LOCAL_REVISION}"
SRC_ARCHIVE="$WORK_ROOT/linux-${KERNEL_VERSION}.tar.xz"
SRC_DIR="$WORK_ROOT/linux-${KERNEL_VERSION}"
STAGE_DIR="$WORK_ROOT/release-${KERNEL_RELEASE}"
OUTPUT_DIR="$REPO_ROOT/dist/${PLATFORM}/${KERNEL_VERSION}-${LOCAL_REVISION}"
DTB_STAGE="$WORK_ROOT/dtb-stage"

KERNEL_MAJOR="${KERNEL_VERSION%%.*}"
UPSTREAM_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-${KERNEL_VERSION}.tar.xz"

mkdir -p "$WORK_ROOT"
rm -rf "$SRC_DIR" "$STAGE_DIR" "$DTB_STAGE" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$SRC_ARCHIVE" ]]; then
  echo "==> Downloading vanilla Linux ${KERNEL_VERSION}"
  wget -O "$SRC_ARCHIVE" "$UPSTREAM_URL"
fi

echo "==> Verifying upstream SHA256"
(
  cd "$WORK_ROOT"
  sha256sum -c "$UPSTREAM_SHA_FILE"
)

echo "==> Extracting upstream source"
tar -xf "$SRC_ARCHIVE" -C "$WORK_ROOT"

echo "==> Checking patch"
(
  cd "$SRC_DIR"
  patch --dry-run -p1 < "$PATCH_FILE"
)

echo "==> Applying patch"
(
  cd "$SRC_DIR"
  patch -p1 < "$PATCH_FILE"
)

echo "==> Preparing custom config"
cp "$CONFIG_FILE" "$SRC_DIR/.config"
sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"-${BASE_LOCALVERSION}-${LOCAL_REVISION}\"/" "$SRC_DIR/.config"

if ! grep -qx "CONFIG_LOCALVERSION=\"-${BASE_LOCALVERSION}-${LOCAL_REVISION}\"" "$SRC_DIR/.config"; then
  echo "ERROR: failed to set CONFIG_LOCALVERSION" >&2
  exit 4
fi

export ARCH=arm
export CROSS_COMPILE
export KBUILD_DEBARCH
export KDEB_PKGVERSION=1
export DEBFULLNAME
export DEBEMAIL

echo "==> olddefconfig"
make -C "$SRC_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" olddefconfig

actual_release="$(make -s -C "$SRC_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" kernelrelease)"
if [[ "$actual_release" != "$KERNEL_RELEASE" ]]; then
  echo "ERROR: kernelrelease is '$actual_release', expected '$KERNEL_RELEASE'" >&2
  exit 5
fi
echo "==> kernelrelease: $actual_release"

echo "==> Building zImage and DTBs"
make -j"$JOBS" -C "$SRC_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" zImage dtbs

ZIMAGE="$SRC_DIR/arch/arm/boot/zImage"
REFERENCE_DTB="$SRC_DIR/arch/arm/boot/dts/marvell/$REFERENCE_DTB_NAME"
[[ -s "$ZIMAGE" ]] || { echo "ERROR: zImage missing" >&2; exit 6; }
[[ -s "$REFERENCE_DTB" ]] || { echo "ERROR: $REFERENCE_DTB_NAME missing" >&2; exit 6; }

mapfile -t DTBS < <(find "$SRC_DIR/arch/arm/boot/dts/marvell" -maxdepth 1 -type f -name "$DTB_PATTERN" -print | sort)
if [[ "${#DTBS[@]}" -ne "$EXPECTED_DTB_COUNT" ]]; then
  echo "ERROR: built ${#DTBS[@]} $PLATFORM DTBs, expected $EXPECTED_DTB_COUNT" >&2
  exit 7
fi

actual_reference_sha="$(sha256sum "$REFERENCE_DTB" | awk '{print $1}')"
if [[ "$actual_reference_sha" != "$EXPECTED_DTB_SHA" ]]; then
  echo "ERROR: $REFERENCE_LABEL DTB SHA256 mismatch" >&2
  echo "  actual:   $actual_reference_sha" >&2
  echo "  expected: $EXPECTED_DTB_SHA" >&2
  exit 8
fi

echo "==> Building Debian packages"
make -j"$JOBS" -C "$SRC_DIR" bindeb-pkg

IMAGE_DEB="$WORK_ROOT/linux-image-${KERNEL_RELEASE}_1_${KBUILD_DEBARCH}.deb"
HEADERS_DEB="$WORK_ROOT/linux-headers-${KERNEL_RELEASE}_1_${KBUILD_DEBARCH}.deb"
LIBC_DEB="$WORK_ROOT/linux-libc-dev_1_${KBUILD_DEBARCH}.deb"

[[ -s "$IMAGE_DEB" ]] || { echo "ERROR: expected image package missing: $IMAGE_DEB" >&2; exit 9; }
[[ -s "$HEADERS_DEB" ]] || { echo "ERROR: expected headers package missing: $HEADERS_DEB" >&2; exit 9; }

mkdir -p "$DTB_STAGE/dts" "$STAGE_DIR"
cp "${DTBS[@]}" "$DTB_STAGE/dts/"
tar -C "$DTB_STAGE" -cf "$WORK_ROOT/linux-dtb-${KERNEL_RELEASE}.tar" dts
cp "$SRC_DIR/.config" "$WORK_ROOT/config-${KERNEL_RELEASE}"
cp "$ZIMAGE" "$WORK_ROOT/zImage-${KERNEL_RELEASE}"

cp "$IMAGE_DEB" "$STAGE_DIR/"
cp "$HEADERS_DEB" "$STAGE_DIR/"
cp "$WORK_ROOT/config-${KERNEL_RELEASE}" "$STAGE_DIR/"
cp "$WORK_ROOT/zImage-${KERNEL_RELEASE}" "$STAGE_DIR/"
cp "$WORK_ROOT/linux-dtb-${KERNEL_RELEASE}.tar" "$STAGE_DIR/"
cp "$PATCH_FILE" "$STAGE_DIR/"

FINAL_ARCHIVE="$OUTPUT_DIR/linux-${KERNEL_RELEASE}-custom.tar.bz2"
(
  cd "$STAGE_DIR"
  tar -cjf "$FINAL_ARCHIVE" ./*
)

cp "$STAGE_DIR"/* "$OUTPUT_DIR/"
if [[ -s "$LIBC_DEB" ]]; then
  cp "$LIBC_DEB" "$OUTPUT_DIR/"
fi

UPSTREAM_SHA="$(awk '{print $1}' "$UPSTREAM_SHA_FILE")"
GIT_SHA="${GITHUB_SHA:-$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || printf 'not-a-git-checkout')}"
COMPILER_VERSION="$("${CROSS_COMPILE}gcc" --version | head -n 1)"
BUILD_TIME_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

cat > "$OUTPUT_DIR/BUILD-METADATA.txt" <<META
kernel_version=$KERNEL_VERSION
kernel_release=$KERNEL_RELEASE
platform=$PLATFORM
architecture=$KBUILD_DEBARCH
cross_compile=$CROSS_COMPILE
kdeb_pkgversion=$KDEB_PKGVERSION
local_revision=$LOCAL_REVISION
upstream_sha256=$UPSTREAM_SHA
patch_sha256=$PATCH_SHA
source_config_sha256=$CONFIG_SHA
compiler=$COMPILER_VERSION
build_time_utc=$BUILD_TIME_UTC
git_commit=$GIT_SHA
maintainer_name=$DEBFULLNAME
maintainer_email=$DEBEMAIL
META

if [[ "$PLATFORM" == "kirkwood" ]]; then
  {
    echo "n1t1_dtb_sha256=$actual_reference_sha"
    echo "kirkwood_dtb_count=${#DTBS[@]}"
  } >> "$OUTPUT_DIR/BUILD-METADATA.txt"
else
  {
    echo "nas326_dtb_sha256=$actual_reference_sha"
    echo "mvebu_dtb_count=${#DTBS[@]}"
  } >> "$OUTPUT_DIR/BUILD-METADATA.txt"
fi

(
  cd "$OUTPUT_DIR"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\n' | sort | xargs -r sha256sum > SHA256SUMS
)

echo
echo "Build complete:"
echo "  $OUTPUT_DIR"
echo "  kernel release: $KERNEL_RELEASE"
echo "  DTBs verified: ${#DTBS[@]}"
echo "  $REFERENCE_LABEL SHA256: $actual_reference_sha"
