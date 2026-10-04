# Rootfs references

This directory contains metadata for known-good bodhi rootfs archives. The
archives themselves are deliberately not stored in Git.

These references serve a different purpose from `checksums/*-reference.env`:

- `checksums/` verifies output from this repository's kernel build pipeline.
- `rootfs/` describes older, known-good Debian rootfs archives that can be used
  as structural references while rootfs automation is developed.

The reference archives currently used are:

- Kirkwood: Debian 12.2 with kernel `6.5.7-kirkwood-tld-1`.
- MVEBU: Debian 12.4 with kernel `6.6.2-mvebu-tld-1`.

The Kirkwood download was originally published with `5.6.7` in its filename.
Bodhi later confirmed that this was a filename typo; the rootfs contains kernel
6.5.7. Both the downloaded and canonical filenames are therefore recorded in
the reference file.

Inspect a local archive with:

```bash
./scripts/inspect-rootfs.sh kirkwood /path/to/Debian-5.6.7-kirkwood-tld-1-rootfs-bodhi.tar.bz2
./scripts/inspect-rootfs.sh mvebu /path/to/Debian-6.6.2-mvebu-tld-1-rootfs-bodhi.tar.bz2
```

The inspection command is read-only. It hashes and lists the archive; it does
not extract a rootfs onto a device, repartition media or modify the archive.
