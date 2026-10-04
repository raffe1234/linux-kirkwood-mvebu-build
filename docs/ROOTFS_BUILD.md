# Building a Debian 13 base rootfs

## Scope

`scripts/build-rootfs.sh` creates a Debian 13 (`trixie`) **base rootfs tarball**
for Kirkwood (`armel`) or MVEBU (`armhf`). It deliberately stops before kernel
installation and before boot-media creation.

The separation is intentional:

1. build and validate Debian userland;
2. install the project's verified custom kernel packages in a later phase;
3. only then create explicitly selected boot media.

The script never partitions, formats or writes to `/dev/sdX`, and it does not
modify U-Boot.

## Debian 13 architecture note

Debian 13 is the last Debian release with the `armel` package architecture.
Debian no longer provides a normal installer/kernel path for new armel systems,
but upgrades and third-party kernels remain possible. This project supplies its
own Kirkwood kernel, so Debian 13 armel remains a valid target for this phase.

MVEBU uses `armhf`, which remains a normal Debian 13 architecture.

References:

- <https://www.debian.org/releases/trixie/>
- <https://www.debian.org/releases/trixie/release-notes.en.html>

## Build with GitHub Actions

The simplest test path is the manual workflow **Build Debian 13 base rootfs**.
Choose `kirkwood` or `mvebu`; the workflow registers ARM QEMU emulation, verifies
the matching Debian 13 container architecture, runs the builder inside a Debian
13 amd64 container, validates the result and uploads the `dist/rootfs/...`
output as an Actions artifact.

The workflow is manual (`workflow_dispatch`); pushing a commit does not start a
rootfs build automatically.

## Local build host

A Debian 13 amd64 machine or VM can run the same builder. Install:

```bash
apt-get update
apt-get install -y \
  arch-test \
  debootstrap \
  qemu-user-static \
  bzip2 \
  ca-certificates
```

Debian 13's old `qemu-debootstrap` wrapper is deprecated. Current Debian QEMU
uses kernel `binfmt_misc` registration, so this project uses regular
`debootstrap --foreign` plus its second stage. Before modifying any rootfs, the
builder runs `arch-test` for the target Debian architecture and aborts if the
kernel cannot execute it.

Check manually if needed:

```bash
arch-test armel
arch-test armhf
```

## Build

Kirkwood:

```bash
sudo ./scripts/build-rootfs.sh kirkwood
```

MVEBU:

```bash
sudo ./scripts/build-rootfs.sh mvebu
```

Output is placed below:

```text
dist/rootfs/<platform>/debian-13/
```

Each build produces:

- the rootfs `.tar.bz2` archive;
- `PACKAGE-MANIFEST.txt` with installed package versions/architectures;
- `ROOTFS-METADATA.txt` with build context;
- `SHA256SUMS`.

The build script runs `validate-generated-rootfs.sh` automatically before it
reports success.

## What the base rootfs contains

The generated rootfs is intentionally conservative and close to the known-good
bodhi layout where practical:

- Debian 13 `trixie`;
- Kirkwood `armel` or MVEBU `armhf`;
- sysvinit as `/sbin/init` provider;
- the `debootstrap --variant=minbase` stage contains only the Debian minimal
  base; optional target packages are deliberately installed afterwards;
- `systemd` and `systemd-sysv` are excluded from the bootstrap package set;
- `systemd-standalone-sysusers` is installed immediately after bootstrap and
  before packages such as `cron` and `udev`, so their sysusers dependency is
  satisfied without pulling in the full systemd package;
- `ifupdown` with DHCP on `eth0`;
- MVEBU `rename /end0=eth0` rule;
- `/etc/fstab` rooted at `LABEL=rootfs`;
- SSH server and common administration/network utilities;
- no reusable SSH host keys in the base archive;
- initramfs and U-Boot tooling for the later kernel phase.

The root account is deliberately **locked**. The base tarball is not intended
to be written to media and booted as-is. A later installation phase must set a
safe authentication method (for example an SSH public key), generate unique SSH
host keys and then enable hardware boot testing.

## Deliberately absent

The first generator does **not** contain:

- the custom Linux 7.1.9 kernel packages;
- `uImage`, `uInitrd` or platform DTBs;
- a default root password;
- partition tables or filesystem images;
- automatic media-writing commands;
- U-Boot environment changes.

## Reproducibility boundary

The build records the package manifest, Git commit and SHA256 output. Because it
currently uses the moving Debian stable mirrors, rebuilding on another date may
select newer Debian 13 point-release package versions and therefore produce a
different archive hash.

A later hardening step can pin a Debian snapshot if byte-for-byte rebuilds are
required. Until then, compare `PACKAGE-MANIFEST.txt`, `ROOTFS-METADATA.txt` and
`SHA256SUMS` rather than expecting identical archive hashes across dates.
