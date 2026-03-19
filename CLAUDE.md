# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository configures an **OpenShift Dev Spaces** (formerly CodeReady Workspaces) workspace for **offline Ansible development**. It provides a cloud-based development environment with nested Podman support, pre-configured tooling, and VS Code workspace settings for Ansible automation.

## Key Files

- **`devfile.yaml`** - Dev Spaces workspace definition (schema 2.2.0). Defines:
  - `dev-tools` - Main development container (`ansible-devspaces-nested-podman:opencode`) with nested container support via `/dev/fuse` and `/dev/net/tun` device mapping, user namespace isolation (`hostUsers: false`), and unmasked `/proc`
  - `prep-workspace` - Init container that copies `oc` and `kubectl` binaries into `/projects/bin` at workspace startup
  - `install-offline-extensions` - postStart command that auto-discovers the code CLI and installs bundled `.vsix` extensions in dependency order
- **`devspaces.code-workspace`** - VS Code workspace config with Ansible-specific settings (ansible-lint with `--profile production --offline`, FQCN enforcement, Podman as container engine). Telemetry and git autofetch are disabled for offline use.
- **`.vscode/extensions/`** - Bundled `.vsix` files for offline extension installation. See `README.md` in that directory for the full list, versions, and download instructions.

## Offline Design

This workspace is designed to operate **without access to online registries**:

- VS Code extensions are bundled as `.vsix` files in `.vscode/extensions/` and installed via the devfile `postStart` event — no Open VSX Registry access needed
- Extension recommendations are commented out in the workspace file (they require registry access)
- Telemetry (`redhat.telemetry.enabled`) and git autofetch are disabled
- Ansible Lint runs with `--offline` flag
- Ansible Lightspeed is disabled
- The `prep-workspace` init container pulls from the internal OpenShift image registry (`image-registry.openshift-image-registry.svc:5000`)

### Updating extensions

1. Download new `.vsix` files from [Open VSX](https://open-vsx.org/) (see `.vscode/extensions/README.md` for URLs)
2. Replace the old `.vsix` files in `.vscode/extensions/`
3. The devfile install command uses glob patterns (`redhat.ansible-*.vsix`) so no devfile changes are needed
4. Update the version table in `.vscode/extensions/README.md`
5. Check for new or changed extension dependencies

## Development Context

- The workspace runs inside OpenShift and uses **Podman** (not Docker) for container operations
- Ansible Lint is configured for **offline** and **production profile** usage: `--profile production --offline`
- All YAML files default to Ansible language mode in the editor
- The workspace mounts sources at `/projects/` with the project at `/projects/devspaces-offline/`
- The code CLI binary path varies across Dev Spaces images — the install command auto-discovers it by checking `/checode/*/bin/remote-cli/code`, then `code`, `code-oss`, `che-code`, `code-server` via `$PATH`

## Ansible Conventions

When adding Ansible content to this repository, follow the rules defined in the global CLAUDE.md (`~/.claude/CLAUDE.md`), which enforces Red Hat CoP automation good practices including:
- FQCN for all modules
- Role name prefixing for all variables
- `snake_case` naming everywhere
- YAML native booleans (`true`/`false`)
- 2-space indentation
