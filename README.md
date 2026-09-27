# linux-kirkwood-mvebu-build

Personal learning and reproducibility project for building custom Linux kernels for older Kirkwood and, later, MVEBU devices.

The project is based on:

- vanilla Linux source from kernel.org
- bodhi's published Kirkwood/MVEBU patch and config files from the Doozan forum
- a Debian 13 amd64 cross-build environment

This is **not** an official Doozan/bodhi project or release channel. Custom builds use their own `CONFIG_LOCALVERSION` suffix and their own Debian package identity.

## Current scope

Phase 1 intentionally supports only the locally verified target:

- **Kirkwood**
- Linux **7.1.9**
- Debian **armel**
- cross compiler `arm-linux-gnueabi-`

MVEBU is documented as the next phase, but is not automated until its DTB/package layout has been verified locally against bodhi's 7.1.9 package.

## Required reference files

The repository scaffold does **not** include bodhi's patch or config because they were not part of the project handover archive supplied when this repo was generated.

Before the first build, add these two files from your saved bodhi archive:

```text
configs/kirkwood/config-7.1.9-kirkwood-tld-1
patches/kirkwood/linux-7.1.9-kirkwood-tld-1.patch
```

Do not rename or modify the source copies. The build script copies the config to the temporary build tree and changes `CONFIG_LOCALVERSION` there.

## GitHub Actions setup

Create two repository variables under **Settings → Secrets and variables → Actions → Variables**:

- `DEB_FULLNAME` — your own package maintainer name
- `DEB_EMAIL` — your own chosen package maintainer email

Do not use bodhi's name or email.

Then run **Build Kirkwood 7.1.9** manually from the Actions tab. The default local revision is `raffe-1`, which gives a kernel release like:

```text
7.1.9-kirkwood-tld-1-raffe-1
```

The workflow uploads the build output as a GitHub Actions artifact. It does not create a GitHub Release.

## Local build

On a Debian 13 amd64 build host, install the dependencies in `docs/BUILD_KIRKWOOD.md`, set your own package identity, then run:

```bash
export DEBFULLNAME="your name"
export DEBEMAIL="your email"
./scripts/build-kirkwood.sh raffe-1
```

Output is written under:

```text
dist/kirkwood/7.1.9-raffe-1/
```

## Verification built into the script

For Kirkwood 7.1.9, the build checks:

- upstream Linux tarball SHA256
- patch dry-run before applying it
- expected custom kernel release
- presence of `zImage`
- exactly 107 `kirkwood-*.dtb` files
- the known reference SHA256 for `kirkwood-n1t1.dtb`
- expected image and headers `.deb` files
- final six-file archive plus SHA256SUMS and build metadata

See `docs/BUILD_KIRKWOOD.md` for details and `docs/NAS_GIT_WORKFLOW.md` for the short QNAP Git workflow.
