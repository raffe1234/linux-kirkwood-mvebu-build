# Rootfs metadata and build definitions

This directory contains both known-good Debian 12 rootfs reference metadata and
Debian 13 base-rootfs build definitions. Rootfs archives themselves are
deliberately not stored in Git.

The files have two separate purposes:

- `*/debian-12-reference.env` describes bodhi rootfs archives used as read-only
  structural references by `scripts/inspect-rootfs.sh`.
- `*/debian-13.env` defines this repository's generated base rootfs parameters
  for `scripts/build-rootfs.sh` and `scripts/validate-generated-rootfs.sh`.
- `checksums/*-reference.env` remains separate and verifies output from the
  kernel build pipeline.

## Debian 12 reference archives

- Kirkwood: Debian 12.2 `armel`, kernel `6.5.7-kirkwood-tld-1`.
- MVEBU: Debian 12.4 `armhf`, kernel `6.6.2-mvebu-tld-1`.

The Kirkwood download was originally published with `5.6.7` in its filename.
Bodhi later confirmed that this was a filename typo; the rootfs contains kernel
6.5.7. Both the downloaded and canonical filenames are therefore recorded in
the reference file.

Inspect local reference archives with:

```bash
./scripts/inspect-rootfs.sh kirkwood /path/to/Debian-5.6.7-kirkwood-tld-1-rootfs-bodhi.tar.bz2
./scripts/inspect-rootfs.sh mvebu /path/to/Debian-6.6.2-mvebu-tld-1-rootfs-bodhi.tar.bz2
```

The inspection command is read-only. It hashes and lists the archive; it does
not extract a rootfs onto a device, repartition media or modify the archive.

## Debian 13 generated base rootfs

The `debian-13.env` files describe the two generator targets:

- `kirkwood`: Debian 13 `armel`;
- `mvebu`: Debian 13 `armhf`.

Build and validation instructions are in `docs/ROOTFS_BUILD.md`. The generator
creates a tarball only. It does not install a kernel, write a block device or
modify U-Boot.
