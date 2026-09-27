#!/usr/bin/env bash
set -euo pipefail

KERNEL_VERSION="7.1.9"
BASE_LOCALVERSION="kirkwood-tld-1"
LOCAL_REVISION="${1:-raffe-1}"
JOBS="${JOBS:-$(nproc)}"

case "$LOCAL_REVISION" in
  ""|*[!a-zA-Z0-9._-]*)
    echo "ERROR: local revision may contain only letters, digits, dot, underscore and hyphen." >&2
    exit 2
    ;;
esac

: "${DEBFULLNAME:?Set DEBFULLNAME to your own package maintainer name}"
: "${DEBEMAIL:?Set DEBEMAIL to your own package maintainer email}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/configs/kirkwood/config-${KERNEL_VERSION}-${BASE_LOCALVERSION}"
PATCH_FILE="$REPO_ROOT/patches/kirkwood/linux-${KERNEL_VERSION}-${BASE_LOCALVERSION}.patch"
UPSTREAM_SHA_FILE="$REPO_ROOT/checksums/linux-${KERNEL_VERSION}.tar.xz.sha256"
REFERENCE_FILE="$REPO_ROOT/checksums/kirkwood-${KERNEL_VERSION}-reference.env"

for required in "$CONFIG_FILE" "$PATCH_FILE" "$UPSTREAM_SHA_FILE" "$REFERENCE_FILE"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required file: $required" >&2
    exit 3
  fi
done

# shellcheck disable=SC1090
source "$REFERENCE_FILE"

KERNEL_RELEASE="${KERNEL_VERSION}-${BASE_LOCALVERSION}-${LOCAL_REVISION}"
WORK_ROOT="$REPO_ROOT/.work/kirkwood-${KERNEL_VERSION}-${LOCAL_REVISION}"
SRC_ARCHIVE="$WORK_ROOT/linux-${KERNEL_VERSION}.tar.xz"
SRC_DIR="$WORK_ROOT/linux-${KERNEL_VERSION}"
STAGE_DIR="$WORK_ROOT/release-${KERNEL_RELEASE}"
OUTPUT_DIR="$REPO_ROOT/dist/kirkwood/${KERNEL_VERSION}-${LOCAL_REVISION}"
DTB_STAGE="$WORK_ROOT/dtb-stage"

mkdir -p "$WORK_ROOT"
rm -rf "$SRC_DIR" "$STAGE_DIR" "$DTB_STAGE" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$SRC_ARCHIVE" ]]; then
  echo "==> Downloading vanilla Linux ${KERNEL_VERSION}"
  wget -O "$SRC_ARCHIVE" "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${KERNEL_VERSION}.tar.xz"
fi

# sha256sum file contains only the archive basename, so verify from WORK_ROOT.
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
export CROSS_COMPILE=arm-linux-gnueabi-
export KBUILD_DEBARCH=armel
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
N1T1_DTB="$SRC_DIR/arch/arm/boot/dts/marvell/kirkwood-n1t1.dtb"
[[ -s "$ZIMAGE" ]] || { echo "ERROR: zImage missing" >&2; exit 6; }
[[ -s "$N1T1_DTB" ]] || { echo "ERROR: kirkwood-n1t1.dtb missing" >&2; exit 6; }

mapfile -t DTBS < <(find "$SRC_DIR/arch/arm/boot/dts/marvell" -maxdepth 1 -type f -name 'kirkwood-*.dtb' -print | sort)
if [[ "${#DTBS[@]}" -ne "$KIRKWOOD_DTB_COUNT" ]]; then
  echo "ERROR: built ${#DTBS[@]} Kirkwood DTBs, expected $KIRKWOOD_DTB_COUNT" >&2
  exit 7
fi

actual_n1t1_sha="$(sha256sum "$N1T1_DTB" | awk '{print $1}')"
if [[ "$actual_n1t1_sha" != "$N1T1_DTB_SHA256" ]]; then
  echo "ERROR: N1T1 DTB SHA256 mismatch" >&2
  echo "  actual:   $actual_n1t1_sha" >&2
  echo "  expected: $N1T1_DTB_SHA256" >&2
  exit 8
fi

echo "==> Building Debian packages"
make -j"$JOBS" -C "$SRC_DIR" bindeb-pkg

IMAGE_DEB="$WORK_ROOT/linux-image-${KERNEL_RELEASE}_1_armel.deb"
HEADERS_DEB="$WORK_ROOT/linux-headers-${KERNEL_RELEASE}_1_armel.deb"
LIBC_DEB="$WORK_ROOT/linux-libc-dev_1_armel.deb"

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

PATCH_SHA="$(sha256sum "$PATCH_FILE" | awk '{print $1}')"
CONFIG_SHA="$(sha256sum "$CONFIG_FILE" | awk '{print $1}')"
UPSTREAM_SHA="$(awk '{print $1}' "$UPSTREAM_SHA_FILE")"
GIT_SHA="${GITHUB_SHA:-$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || printf 'not-a-git-checkout')}"
COMPILER_VERSION="$(arm-linux-gnueabi-gcc --version | head -n 1)"
BUILD_TIME_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

cat > "$OUTPUT_DIR/BUILD-METADATA.txt" <<META
kernel_version=$KERNEL_VERSION
kernel_release=$KERNEL_RELEASE
platform=kirkwood
architecture=armel
cross_compile=arm-linux-gnueabi-
kdeb_pkgversion=$KDEB_PKGVERSION
local_revision=$LOCAL_REVISION
upstream_sha256=$UPSTREAM_SHA
patch_sha256=$PATCH_SHA
source_config_sha256=$CONFIG_SHA
n1t1_dtb_sha256=$actual_n1t1_sha
kirkwood_dtb_count=${#DTBS[@]}
compiler=$COMPILER_VERSION
build_time_utc=$BUILD_TIME_UTC
git_commit=$GIT_SHA
maintainer_name=$DEBFULLNAME
maintainer_email=$DEBEMAIL
META

(
  cd "$OUTPUT_DIR"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\n' | sort | xargs -r sha256sum > SHA256SUMS
)

echo
echo "Build complete:"
echo "  $OUTPUT_DIR"
echo "  kernel release: $KERNEL_RELEASE"
echo "  DTBs verified: ${#DTBS[@]}"
echo "  N1T1 SHA256: $actual_n1t1_sha"
