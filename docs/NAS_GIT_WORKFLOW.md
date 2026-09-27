# QNAP NAS Git workflow

Expected repo path:

```text
/share/Public/Temp/work/Github/linux-kirkwood-mvebu-build
```

## Normal update

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

GitHub Actions is the automated build/validation step after the push.

## If ChatGPT gives you a patch

Always check it first:

```bash
cd /share/Public/Temp/work/Github/linux-kirkwood-mvebu-build
git status --short --branch
git switch main
git pull --ff-only origin main
git apply --check ../NAME.patch
```

If `git apply --check` reports an error: **stop**. Do not force it and do not create reject files.

If the check succeeds:

```bash
git apply ../NAME.patch
git diff --check
git diff --stat
git status --short
git add -A
git diff --cached --check
git diff --cached --stat
git commit -m "short message"
git push origin main
```

No pull request is required for the normal owner workflow, and no Python commands are needed on the NAS.
