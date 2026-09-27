# Project status

## Verified

### Kirkwood 7.1.9

- Debian 13 amd64 / GitHub Actions build environment.
- `ARCH=arm`, `CROSS_COMPILE=arm-linux-gnueabi-`, `KBUILD_DEBARCH=armel`.
- custom release `7.1.9-kirkwood-tld-1-raffe-1`.
- 107 Kirkwood DTBs.
- `kirkwood-n1t1.dtb` verified against the stored reference SHA256.
- Debian image and headers packages built successfully.
- release artifact verified.

### MVEBU 7.1.9

- Debian 13 amd64 / GitHub Actions build environment.
- `ARCH=arm`, `CROSS_COMPILE=arm-linux-gnueabihf-`, `KBUILD_DEBARCH=armhf`.
- custom release `7.1.9-mvebu-tld-1-raffe-1`.
- 82 Marvell DTBs.
- `armada-380-zyxel-nas326.dtb` verified against bodhi's reference SHA256.
- Debian image and headers packages built successfully.
- release artifact verified.

## Implemented

- Kirkwood GitHub Actions workflow.
- MVEBU GitHub Actions workflow.
- common platform-aware build engine with backward-compatible wrapper scripts.
- upstream kernel SHA256 verification.
- custom `CONFIG_LOCALVERSION`.
- custom Debian package identity.
- reference DTB checks.
- Git commit recorded in build metadata.
- artifact `SHA256SUMS`.
- short QNAP Git workflow.

## Current reference kernel

```text
Linux 7.1.9
```

## Possible next work

- verify and add a newer kernel version.
- optional GitHub Releases.
- optional Actions matrix workflow.
- rootfs automation.

New kernel versions must be verified independently before being marked known-good.
