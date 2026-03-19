# Extension Compatibility Report for Dev Spaces 3.26.1

## Environment

- **Red Hat OpenShift Dev Spaces**: 3.26.1
- **Editor**: Microsoft Visual Studio Code - Open Source (che-code)
- **VS Code version**: 1.104.3
- **che-code binary path**: `/checode/checode-linux-libc/ubi9/bin/che-code`
- **Extensions install dir**: `/checode/remote/extensions`

## Issue: Extension Version Incompatibility

### Affected Extension

| Extension | Version | Required VS Code | Installed VS Code | Result |
|-----------|---------|-----------------|-------------------|--------|
| `ms-python.vscode-python-envs` | 1.22.0 | `^1.110.0` | 1.104.3 | **FAILED** |

### Error Message

```
Error: Unable to install extension 'ms-python.vscode-python-envs' as it is not compatible with VS Code '1.104.3'.
```

### Root Cause

The latest version of `ms-python.vscode-python-envs` (1.22.0) on Open VSX Registry requires VS Code `^1.110.0`, which is 6 minor versions ahead of the che-code editor (1.104.3) bundled with Dev Spaces 3.26.1.

### Version Compatibility Analysis

| vscode-python-envs Version | Required VS Code | Compatible with 1.104.3? |
|-----------------------------|-----------------|--------------------------|
| 1.22.0 | `^1.110.0` | No |
| 1.20.1 | `^1.106.0` | No |
| 1.16.0 | `^1.106.0` | No |
| 1.14.0 | `^1.106.0` | No |
| 1.10.0 | `^1.104.0` | Yes |
| 1.8.0 | Not checked | Unknown |

### Impact

`ms-python.vscode-python-envs` is a dependency of:
- `redhat.ansible` (26.3.0) — Ansible language support extension
- `ms-python.python` (2026.4.0) — Python language support extension

Both parent extensions installed successfully without this dependency, but may have degraded functionality:
- The Python extension reports: *"The Python Environments extension requires 'python.useEnvironmentsExtension' to be enabled for full functionality. Enable this setting to use Python environment auto-activation in terminals."*

### Workaround

Downgrade `ms-python.vscode-python-envs` to version **1.10.0** (last version compatible with VS Code `^1.104.0`).

### Recommendation

The Dev Spaces engineering team should consider:
1. **Updating che-code** in Dev Spaces to match the VS Code version that current extension ecosystem targets (1.106.0+ at minimum, ideally 1.110.0+)
2. **Documenting the bundled VS Code version** per Dev Spaces release so extension compatibility can be verified before deployment
3. **Publishing a compatibility matrix** of tested extension versions for each Dev Spaces release

## Additional Findings

### che-code Binary Path

The che-code CLI binary is not at the commonly documented path. Actual vs expected:

| Expected | Actual |
|----------|--------|
| `/checode/checode-linux-libc/bin/remote-cli/code` | Does not exist |
| `/checode/checode-linux-libc/ubi9/bin/che-code` | Correct path |

The `ubi9` subdirectory is specific to the RHEL 9 base image variant. A `ubi8` variant also exists at `/checode/checode-linux-libc/ubi8/bin/che-code`.

### Extensions Directory

The che-code server reads extensions from `/checode/remote/extensions`, not the default CLI install path (`~/.che-code/extensions/`). The `--extensions-dir /checode/remote/extensions` flag must be passed to the CLI for extensions to be visible in the editor.

### postStart Hook Constraints

1. The `/checode/` volume is injected by the Dev Spaces operator as a sidecar — it is not part of the dev container image
2. The volume may not be available immediately when `postStart` fires, requiring a retry/wait mechanism
3. YAML `>-` folded scalars preserve newlines on indented lines, which can cause shell syntax errors in devfile `commandLine` fields — commands must be written as flat single-line scripts

## Successfully Installed Extensions

| Extension | Version | Status |
|-----------|---------|--------|
| `redhat.vscode-yaml` | 1.21.0 | Installed |
| `redhat.ansible` | 26.3.0 | Installed |
| `ms-python.python` | 2026.4.0 | Installed |
| `ms-python.black-formatter` | 2025.2.0 | Installed |
| `ms-python.debugpy` | 2025.18.0 (linux-x64) | Installed |
| `ms-python.vscode-python-envs` | 1.22.0 | **Failed** — incompatible with VS Code 1.104.3 |
