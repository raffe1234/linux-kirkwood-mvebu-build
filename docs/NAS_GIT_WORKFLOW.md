# QNAP NAS Git workflow

Expected repository path:

```text
/share/Public/Temp/work/Github/linux-kirkwood-mvebu-build
```

## Check the repository first

Before applying a supplied patch, the working tree should be clean and `main`
should be up to date:

```bash
cd /share/Public/Temp/work/Github/linux-kirkwood-mvebu-build
git status --short --branch
git switch main
git pull --ff-only origin main
```

If `git status --short` shows local file changes, stop and review them before
applying a patch.

## Apply a patch from ChatGPT

Assuming the patch is stored one directory above the repository:

```bash
git apply --check ../NAME.patch
git apply ../NAME.patch
git diff --check
git diff --stat
git status --short
```

If `git apply --check` reports an error: **stop**. Do not force the patch and do
not create reject files.

Review the diff before committing:

```bash
git diff
```

Then stage, validate and push:

```bash
git add -A
git diff --cached --check
git diff --cached --stat
git commit -m "short message"
git push origin main
```

The kernel workflows are manually triggered with `workflow_dispatch`; a normal
push does not start a kernel build automatically. Run the relevant GitHub
Actions workflow when you want to revalidate a kernel build. Rootfs reference
changes do not write to disks or start a rootfs build unless a future workflow
explicitly adds that behavior.

## Normal manual update

For edits made directly in the repository:

```bash
cd /share/Public/Temp/work/Github/linux-kirkwood-mvebu-build
git status --short --branch
git switch main
git pull --ff-only origin main
git add -A
git diff --cached --check
git diff --cached --stat
git commit -m "short message"
git push origin main
```

No pull request is required for the normal owner workflow, and no Python
commands are needed on the NAS.
