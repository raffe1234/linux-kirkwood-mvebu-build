# Rootfs reference and validation

## Scope

The repository builds and verifies custom Linux kernels and now has a separate
Debian 13 base-rootfs generator. It does not yet produce a complete boot-ready
rootfs or boot-media image.

Rootfs work is intentionally separated from the verified kernel build pipeline.
The first stable rootfs step was read-only reference validation; the current
development step builds and validates Debian userland without writing media.

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

## Debian 13 base-rootfs generator

The next phase is implemented by `scripts/build-rootfs.sh`. It creates a Debian
13 base userland for Kirkwood (`armel`) or MVEBU (`armhf`) and validates the
result with `scripts/validate-generated-rootfs.sh`.

This first generator intentionally does **not** install the project's custom
kernel. Kernel integration remains the next independent step so userland and
kernel failures can be isolated. The Kirkwood (`armel`) GitHub Actions build has
passed; MVEBU (`armhf`) validation is still pending before the rootfs-builder
baseline is tagged `v1.2`. See `docs/ROOTFS_BUILD.md`.

Media creation remains separate from rootfs generation. Any future command that
partitions or formats removable media must require an explicit device and strong
safety checks.
