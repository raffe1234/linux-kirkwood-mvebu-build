# Project status

## Verified before this repo scaffold

- Kirkwood Linux 7.1.9 build on Debian 13 amd64.
- `ARCH=arm`, `CROSS_COMPILE=arm-linux-gnueabi-`, `KBUILD_DEBARCH=armel`.
- all 107 Kirkwood DTBs matched the bodhi reference byte-for-byte.
- N1T1 DTB reference SHA256 is stored in `checksums/kirkwood-7.1.9-reference.env`.
- the image package file list matched the bodhi reference.

## Implemented in this scaffold

- one Kirkwood-only shell build script
- one manual GitHub Actions workflow using `debian:13`
- upstream Linux 7.1.9 SHA256 verification
- custom local version suffix
- custom Debian package identity via repository variables
- Actions artifact upload, no automatic GitHub Release
- short QNAP Git workflow

## Still required before the first successful Actions run

- add the saved Kirkwood 7.1.9 config file
- add the saved Kirkwood 7.1.9 patch file
- create `DEB_FULLNAME` and `DEB_EMAIL` repository variables

## Deferred

- MVEBU automation
- matrix/generalized workflow
- GitHub Releases
- newer kernel porting
- rootfs automation
