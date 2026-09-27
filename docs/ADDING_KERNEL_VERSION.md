# Adding another kernel version

The build engine accepts a kernel version, but a new version must not be treated as verified until matching reference material has been checked.

For a version `X.Y.Z`:

## 1. Add the upstream checksum

```text
checksums/linux-X.Y.Z.tar.xz.sha256
```

## 2. Add bodhi's config and patch

Kirkwood:

```text
configs/kirkwood/config-X.Y.Z-kirkwood-tld-1
patches/kirkwood/linux-X.Y.Z-kirkwood-tld-1.patch
```

MVEBU:

```text
configs/mvebu/config-X.Y.Z-mvebu-tld-1
patches/mvebu/linux-X.Y.Z-mvebu-tld-1.patch
```

## 3. Add reference data

```text
checksums/kirkwood-X.Y.Z-reference.env
checksums/mvebu-X.Y.Z-reference.env
```

At minimum, store the expected DTB count and the SHA256 of the platform reference DTB. Where available, also store bodhi's config and patch SHA256.

## 4. Build

```bash
./scripts/build-kirkwood.sh raffe-1 X.Y.Z
./scripts/build-mvebu.sh raffe-1 X.Y.Z
```

The common script performs `patch --dry-run` before applying the patch and stops if required reference material is missing.

## 5. Verify before marking the version known-good

Compare, as applicable:

- kernel release.
- Debian architecture.
- image package contents.
- headers package.
- DTB count.
- reference DTB SHA256.
- full DTB set against the reference package.
- release archive layout.
- `SHA256SUMS`.
- build metadata.

A successful compile alone is not sufficient to call a new version verified.
