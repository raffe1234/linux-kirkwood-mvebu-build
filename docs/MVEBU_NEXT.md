# MVEBU — next phase, not yet automated

The expected substitutions are known, but the 7.1.9 MVEBU path has not yet been verified to the same level as Kirkwood.

Expected values:

```text
Debian architecture: armhf
cross compiler:      arm-linux-gnueabihf-
KBUILD_DEBARCH:      armhf
foreign ssl package: libssl-dev:armhf
base localversion:   -mvebu-tld-1
```

Before adding `scripts/build-mvebu.sh` or a GitHub Actions job:

- unpack the saved `linux-7.1.9-mvebu-tld-1-bodhi.tar.bz2`
- confirm its actual config and patch filenames
- dry-run/apply its patch to vanilla 7.1.9
- build zImage and DTBs locally
- build Debian packages locally
- compare package file lists with bodhi's package
- compare all DTBs byte-for-byte
- determine exactly which DTBs belong in bodhi's MVEBU DTB tar and its directory layout

Do not infer the MVEBU DTB selection from Kirkwood.
