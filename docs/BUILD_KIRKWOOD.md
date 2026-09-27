# Build Kirkwood 7.1.9

The Kirkwood 7.1.9 path has been successfully built and verified through GitHub Actions. It uses the common build engine through `scripts/build-kirkwood.sh`.

## 1. Required repo files

Add the two saved bodhi reference files:

```text
configs/kirkwood/config-7.1.9-kirkwood-tld-1
patches/kirkwood/linux-7.1.9-kirkwood-tld-1.patch
```

The script refuses to continue if either is missing.

## 2. Debian 13 amd64 dependencies

```bash
sudo dpkg --add-architecture armel
sudo apt update
sudo apt install build-essential crossbuild-essential-armel python3 bc bison flex cpio rsync kmod fakeroot dpkg-dev debhelper libssl-dev libssl-dev:armel libelf-dev libdw-dev dwarves patch xz-utils wget
```

The `libssl-dev:armel` package is important for this cross-package build.

## 3. Choose your own package identity

```bash
export DEBFULLNAME="your name"
export DEBEMAIL="your email"
```

Do not use bodhi's maintainer identity for your custom build.

## 4. Build

```bash
./scripts/build-kirkwood.sh raffe-1
```

The script changes the build-tree copy of:

```text
CONFIG_LOCALVERSION="-kirkwood-tld-1"
```

to:

```text
CONFIG_LOCALVERSION="-kirkwood-tld-1-raffe-1"
```

The original config stored in `configs/kirkwood/` remains untouched.

## 5. Built-in checks

The script verifies:

1. Linux 7.1.9 upstream archive SHA256.
2. `patch --dry-run -p1` before applying the patch.
3. kernel release exactly matches the requested custom suffix.
4. `zImage` exists.
5. exactly 107 `kirkwood-*.dtb` files were built.
6. `kirkwood-n1t1.dtb` SHA256 equals the verified reference:

```text
54d5f794d91c069c45c8614060e28cdd7b57a692b3b179881b3fb99642a6b04f
```

7. image and headers Debian packages exist.

## 6. Output

For `raffe-1`, output is placed in:

```text
dist/kirkwood/7.1.9-raffe-1/
```

The directory contains the six release-style files, the generated `linux-libc-dev` package when present, the combined custom tarball, `BUILD-METADATA.txt`, and `SHA256SUMS`.

This remains a custom/test build. Boot-test on real hardware before treating it as usable.
