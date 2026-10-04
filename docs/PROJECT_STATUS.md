# Project status

## Stable baseline: v1.0

Tag `v1.0` marks the verified dual-platform kernel-build baseline.

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

## Implemented kernel infrastructure

- Kirkwood GitHub Actions workflow.
- MVEBU GitHub Actions workflow.
- common platform-aware build engine with backward-compatible wrapper scripts.
- upstream kernel SHA256 verification.
- custom `CONFIG_LOCALVERSION`.
- custom Debian package identity.
- reference DTB checks.
- Git commit recorded in build metadata.
- artifact `SHA256SUMS`.
- QNAP Git/patch workflow.

## Rootfs phase: reference and validation

The first rootfs step is deliberately read-only. The repository records metadata
for two known-good bodhi rootfs archives and provides `scripts/inspect-rootfs.sh`
to verify them.

| Platform | Debian | Architecture | Rootfs kernel | `/boot/dts` |
|---|---|---|---|---:|
| Kirkwood | 12.2 | armel | `6.5.7-kirkwood-tld-1` | 105 |
| MVEBU | 12.4 | armhf | `6.6.2-mvebu-tld-1` | 82 |

These are **rootfs references**, not the current kernel-build version. The
verified project kernel remains Linux 7.1.9.

The Kirkwood rootfs download may have `5.6.7` in its filename because of a
confirmed publication typo; its recorded canonical name and internal kernel are
6.5.7. See `docs/ROOTFS.md`.

## Current reference kernel

```text
Linux 7.1.9
```

## Next work

1. Exercise the rootfs validator against the stored reference archives on the
   NAS/build host.
2. Design a Debian 13 rootfs generator as a separate script that consumes the
   verified kernel artifacts.
3. Only after that, design an explicitly separate and safety-guarded media
   creation/boot-test step.

Possible later work:

- verify and add a newer kernel version;
- optional GitHub Releases;
- optional Actions matrix workflow.

New kernel versions and newly generated rootfs images must each be verified
independently before being marked known-good.
