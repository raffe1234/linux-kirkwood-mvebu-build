# linux-kirkwood-mvebu-build

Personal learning and reproducibility project for building custom Linux kernels
for older Kirkwood and MVEBU devices, with a separate path toward reproducible
Debian rootfs generation.

The project is based on:

- vanilla Linux source from kernel.org;
- bodhi's published Kirkwood/MVEBU patch, config and rootfs material from the
  Doozan forum;
- Debian 13 amd64 cross-build environments;
- reproducible reference checks against known-good bodhi artifacts.

This is **not** an official Doozan/bodhi project or release channel. Custom
builds use their own `CONFIG_LOCALVERSION` suffix and Debian package identity.

## Current baseline

Tag `v1.0` freezes the verified kernel-build baseline. Linux 7.1.9 has been
successfully built through GitHub Actions for both platforms.

| Platform | Debian arch | Cross compiler | DTBs | Reference DTB |
|---|---|---|---:|---|
| Kirkwood | armel | `arm-linux-gnueabi-` | 107 | `kirkwood-n1t1.dtb` |
| MVEBU | armhf | `arm-linux-gnueabihf-` | 82 | `armada-380-zyxel-nas326.dtb` |

Verified custom releases:

```text
7.1.9-kirkwood-tld-1-raffe-1
7.1.9-mvebu-tld-1-raffe-1
```

The next project phase is rootfs work. It starts with read-only validation of
known-good bodhi Debian rootfs archives; automated rootfs generation comes
later. See `docs/ROOTFS.md`.

## Repository layout

```text
.github/workflows/   GitHub Actions kernel builds
checksums/           upstream and kernel-build reference data
configs/             bodhi-derived kernel configs
patches/             bodhi-derived kernel patches
rootfs/              rootfs reference metadata (not the rootfs archives)
scripts/             kernel build and rootfs inspection scripts
docs/                build, status and workflow documentation
```

Large downloaded rootfs archives and generated build output are deliberately
not committed to Git.

## Kernel build design

Common kernel build logic lives in:

```text
scripts/build-platform.sh
```

The platform entry points remain available:

```text
scripts/build-kirkwood.sh
scripts/build-mvebu.sh
```

This keeps the GitHub Actions workflows and manual commands backward-compatible
while avoiding duplicate build logic.

## GitHub Actions

Two manually triggered workflows are available:

```text
Build Kirkwood 7.1.9
Build MVEBU 7.1.9
```

Create these repository variables under **Settings → Secrets and variables →
Actions → Variables**:

- `DEB_FULLNAME` — your package maintainer name;
- `DEB_EMAIL` — your package maintainer email; a GitHub noreply address is fine.

The workflows upload build artifacts but do not create GitHub Releases.

## Local kernel builds

On a Debian 13 amd64 build host, set your package identity and run:

```bash
export DEBFULLNAME="your name"
export DEBEMAIL="your email"
./scripts/build-kirkwood.sh raffe-1
./scripts/build-mvebu.sh raffe-1
```

Output is written below `dist/kirkwood/` and `dist/mvebu/`.

## Built-in kernel verification

The common build script verifies:

- upstream Linux archive SHA256;
- required config, patch and reference files;
- bodhi config/patch SHA256 where those references are stored;
- patch dry-run before applying;
- expected custom kernel release;
- `zImage`;
- expected DTB count;
- known reference DTB SHA256;
- expected image and headers Debian packages;
- release-style six-file package;
- `SHA256SUMS`;
- build metadata including the Git commit.

## Rootfs reference validation

Known-good Kirkwood and MVEBU rootfs archives can be checked without extracting
them to a disk:

```bash
./scripts/inspect-rootfs.sh kirkwood /path/to/Debian-5.6.7-kirkwood-tld-1-rootfs-bodhi.tar.bz2
./scripts/inspect-rootfs.sh mvebu /path/to/Debian-6.6.2-mvebu-tld-1-rootfs-bodhi.tar.bz2
```

The validator is read-only. It verifies the known archive SHA256 and expected
boot/rootfs structure. It never partitions or formats media.

## Adding another kernel version

See `docs/ADDING_KERNEL_VERSION.md`.

A newer kernel version is **not** automatically considered verified merely
because it builds. Its config, patch, DTBs and package output must first be
checked against the appropriate reference.

## Documentation

- `docs/BUILD_KIRKWOOD.md`
- `docs/BUILD_MVEBU.md`
- `docs/ROOTFS.md`
- `docs/ADDING_KERNEL_VERSION.md`
- `docs/NAS_GIT_WORKFLOW.md`
- `docs/PROJECT_STATUS.md`
