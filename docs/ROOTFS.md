# Rootfs reference and validation

## Scope

The repository currently builds and verifies custom Linux kernels. It does not
yet build a complete Debian rootfs.

Rootfs work is intentionally a separate phase so that the verified kernel build
pipeline remains stable. The first rootfs step is therefore reference and
validation, not automated disk creation.

## Known-good reference archives

Two bodhi rootfs archives are used as structural references:

| Platform | Debian | Architecture | Included kernel | `/boot/dts` |
|---|---|---|---|---:|
| Kirkwood | 12.2 | armel | `6.5.7-kirkwood-tld-1` | 105 |
| MVEBU | 12.4 | armhf | `6.6.2-mvebu-tld-1` | 82 |

Their SHA256 values and filenames are stored under `rootfs/`. The archives are
not committed to Git.

The Kirkwood archive may exist locally as
`Debian-5.6.7-kirkwood-tld-1-rootfs-bodhi.tar.bz2`. Bodhi confirmed that `5.6.7`
was a filename typo; the archive is the 6.5.7 rootfs. The validator therefore
accepts both the downloaded filename and the corrected canonical filename, but
always verifies the SHA256 and the internal 6.5.7 kernel paths.

Sources:

- Kirkwood release thread: <https://forum.doozan.com/read.php?2,12096>
- MVEBU release thread: <https://forum.doozan.com/read.php?2,32146>

## Inspect a downloaded rootfs

```bash
./scripts/inspect-rootfs.sh kirkwood /path/to/Debian-5.6.7-kirkwood-tld-1-rootfs-bodhi.tar.bz2
./scripts/inspect-rootfs.sh mvebu /path/to/Debian-6.6.2-mvebu-tld-1-rootfs-bodhi.tar.bz2
```

The script verifies the archive SHA256 and checks the archive manifest for:

- the expected kernel module directory;
- versioned config, zImage and initramfs files;
- `uImage` and `uInitrd`;
- expected `/boot/dts` count;
- basic Debian/network/rootfs metadata paths.

It reports Debian version and architecture from the recorded reference metadata.
Because the SHA256 must match the known archive, those values describe the exact
archive being inspected rather than an arbitrary tarball.

The script is read-only. It does not extract the rootfs to a target disk, write
to `/dev/sdX`, change partitions or modify U-Boot.

## Relationship to the 7.1.9 kernel builds

The rootfs references intentionally contain older kernels than the repository's
current verified 7.1.9 builds. A rootfs and a kernel release are separate
artifacts.

For example, the Kirkwood 6.5.7 rootfs contains 105 DTBs in `/boot/dts`, while
the verified 7.1.9 Kirkwood kernel build currently produces 107 DTBs. Those
counts should not be compared as if they describe the same release.

## Next rootfs phase

After the reference validator is stable, the next implementation step should be
a Debian 13 rootfs generator, probably as a separate `scripts/build-rootfs.sh`.
It should consume the already verified kernel artifacts instead of duplicating
kernel build logic.

Keep media creation separate from rootfs generation. Any future command that
partitions or formats removable media should require an explicit device and
strong safety checks; it should not be part of the reference validator.
