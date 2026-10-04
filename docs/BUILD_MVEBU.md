# Build MVEBU 7.1.9

The MVEBU 7.1.9 path has been successfully built and verified through GitHub Actions.

This guide covers the **kernel build only**. Rootfs reference validation and future rootfs work are documented in `docs/ROOTFS.md`.

## 1. Platform

```text
Debian architecture: armhf
cross compiler:      arm-linux-gnueabihf-
KBUILD_DEBARCH:      armhf
foreign ssl package: libssl-dev:armhf
base localversion:   -mvebu-tld-1
```

## 2. Reference files

```text
configs/mvebu/config-7.1.9-mvebu-tld-1
patches/mvebu/linux-7.1.9-mvebu-tld-1.patch
checksums/mvebu-7.1.9-reference.env
```

The stored reference data verifies:

- 82 DTB files.
- `armada-380-zyxel-nas326.dtb`.
- bodhi config SHA256.
- bodhi patch SHA256.

## 3. Debian 13 amd64 dependencies

```bash
sudo dpkg --add-architecture armhf
sudo apt update
sudo apt install build-essential crossbuild-essential-armhf python3 bc bison flex cpio rsync kmod fakeroot dpkg-dev debhelper libssl-dev libssl-dev:armhf libelf-dev libdw-dev dwarves patch xz-utils wget
```

## 4. Build

```bash
export DEBFULLNAME="your name"
export DEBEMAIL="your email"
./scripts/build-mvebu.sh raffe-1
```

The resulting custom kernel release is:

```text
7.1.9-mvebu-tld-1-raffe-1
```

Output is written below:

```text
dist/mvebu/7.1.9-raffe-1/
```

This remains a custom/test build. Boot-test on the intended hardware before treating it as usable.
