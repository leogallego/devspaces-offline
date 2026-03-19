# Offline Extensions

Place `.vsix` files in this directory for offline installation in Dev Spaces.

## Required Extensions

Download these from [Open VSX Registry](https://open-vsx.org/) or your internal mirror.

### Core extensions

| Extension | Open VSX ID | Version |
|-----------|-------------|---------|
| YAML | `redhat.vscode-yaml` | 1.21.0 |
| Ansible | `redhat.ansible` | 26.3.0 |
| Python | `ms-python.python` | 2026.4.0 |
| Black Formatter | `ms-python.black-formatter` | 2025.2.0 |

### Dependencies (required by core extensions above)

| Extension | Open VSX ID | Version | Required by |
|-----------|-------------|---------|-------------|
| Python Environments | `ms-python.vscode-python-envs` | 1.10.0 | `redhat.ansible`, `ms-python.python` |

> **Note:** `vscode-python-envs` latest is 1.22.0 but requires VS Code `^1.110.0`.
> Dev Spaces 3.26.1 ships che-code 1.104.3, so we use 1.10.0 (last version compatible
> with `^1.104.0`). See `docs/extension-compatibility-report.md` for details.
| Python Debugger | `ms-python.debugpy` | 2025.18.0 | `ms-python.python` |

### Optional (commented out in download script)

| Extension | Open VSX ID | Version | Notes |
|-----------|-------------|---------|-------|
| OpenShift Toolkit | `redhat.vscode-openshift-connector` | 1.21.1 | 187MB, platform-specific. `oc`/`kubectl` available in terminal instead. |
| Red Hat Account | `redhat.vscode-redhat-account` | 0.2.0 | Dependency of OpenShift Toolkit. |

## Expected Files

```
.vscode/extensions/
  redhat.vscode-yaml-1.21.0.vsix
  redhat.ansible-26.3.0.vsix
  ms-python.python-2026.4.0.vsix
  ms-python.black-formatter-2025.2.0.vsix
  ms-python.vscode-python-envs-1.10.0.vsix
  ms-python.debugpy-2025.18.0@linux-x64.vsix
```

## How to Download

From Open VSX (example):

```bash
curl -L -o .vscode/extensions/redhat.vscode-yaml-1.21.0.vsix \
  "https://open-vsx.org/api/redhat/vscode-yaml/1.21.0/file/redhat.vscode-yaml-1.21.0.vsix"
```

Or use `ovsx` CLI:

```bash
npx ovsx get redhat.vscode-yaml 1.21.0 -o .vscode/extensions/
```

## Install Order

Dependencies must be installed before the extensions that require them.
The devfile `postStart` command handles this automatically in the correct order:

1. `redhat.vscode-yaml` (no deps)
2. `ms-python.vscode-python-envs` (no deps)
3. `ms-python.debugpy` (depends on ms-python.python — circular, but installs fine standalone)
4. `ms-python.python` (bundles pylance, depends on debugpy and python-envs)
5. `redhat.ansible` (depends on vscode-yaml, python-envs)
6. `ms-python.black-formatter` (depends on python)

## Important Notes

- Do NOT include `ms-python.vscode-pylance` — it is proprietary, not available on Open VSX, and not licensed for Code - OSS / Che editors. The Python extension uses Jedi as its language server by default.
- The `sst-dev.opencode` extension is likely pre-installed in the container image (`ansible-devspaces-nested-podman:opencode`). No `.vsix` needed.
