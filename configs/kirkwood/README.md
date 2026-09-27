# Kirkwood configs

Add the verified bodhi config here with this exact filename:

```text
config-7.1.9-kirkwood-tld-1
```

The build script copies it into the temporary source tree and changes only the working copy's `CONFIG_LOCALVERSION` to a custom suffix such as `-kirkwood-tld-1-raffe-1` before `olddefconfig`.
