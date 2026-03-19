# PostStart Extension Installation: Failure Analysis

## Environment

- **Red Hat OpenShift Dev Spaces**: 3.26.1
- **Editor**: che-code (VS Code - Open Source) 1.104.3
- **Container image**: `quay.io/jpullen0/ansible-devspaces-nested-podman:opencode`
- **che-code binary**: `/checode/checode-linux-libc/ubi9/bin/che-code`
- **che-code extensions dir**: `/checode/remote/extensions`
- **che-code IPC socket**: `/tmp/vscode-ipc-*.sock` (created by che-code sidecar)

## Architecture

Dev Spaces 3.26.1 runs the editor (che-code) in a **sidecar container** injected by the operator. The user's dev container (`dev-tools`) shares the `/checode/` volume with the sidecar, but:

- `/tmp/` is **not shared** between containers
- The che-code IPC socket (`VSCODE_IPC_HOOK_CLI`) is only visible inside the che-code sidecar or in terminals spawned by the editor
- The `postStart` devfile event runs in the `dev-tools` container, not the che-code sidecar

## Attempts and Failures

### Attempt 1: Basic `code --install-extension`

**Approach:** Run `code --install-extension` in the postStart command targeting the `dev-tools` component.

**Result:** Exit code 2 — shell syntax error.

**Root cause:** YAML `>-` folded scalar preserves newlines on lines with extra indentation. The `for ... in` list items were on separate indented lines, which produced invalid shell syntax when folded. Shell `for` loops require all items on the same line (or backslash-continued).

**Fix applied:** Flattened the command to keep all `for ... in` items on a single line.

---

### Attempt 2: Correct binary path with retry loop

**Approach:** Added retry loop waiting for the che-code binary to appear at `/checode/checode-linux-libc/bin/remote-cli/code`.

**Result:** Binary never found at that path. Timed out after 60s.

**Root cause:** The actual binary path in Dev Spaces 3.26.1 is `/checode/checode-linux-libc/ubi9/bin/che-code` (or `ubi8`), not the commonly documented `/checode/checode-linux-libc/bin/remote-cli/code`.

**Fix applied:** Updated candidate paths to `ubi9/bin/che-code` and `ubi8/bin/che-code`.

---

### Attempt 3: Install to correct extensions directory

**Approach:** Found the binary, installed extensions without specifying `--extensions-dir`.

**Result:** CLI reported "successfully installed" but extensions not visible in sidebar.

**Root cause:** Without `--extensions-dir`, the CLI installs to `~/.che-code/extensions/` (the user's home directory). The che-code server reads extensions from `/checode/remote/extensions/`.

**Fix applied:** Added `--extensions-dir /checode/remote/extensions` to install commands.

---

### Attempt 4: Wait for che-code HTTP server

**Approach:** Added health check polling `http://127.0.0.1:3100` before installing. Server responded, then ran installs with `--extensions-dir /checode/remote/extensions`.

**Result:** CLI reported "successfully installed" but extensions directory remained empty (only `extensions.json`). All installs silently failed — the `|| echo "WARN: ..."` in the postStart swallowed actual error output, showing only WARN messages.

**Root cause:** The che-code CLI requires the `VSCODE_IPC_HOOK_CLI` environment variable to connect to the running server process. Without it, the CLI runs in **standalone mode** — it reports success but the extensions are not registered with the running server instance. The HTTP health check confirms the server is listening but doesn't establish the IPC channel.

**Evidence:** Running the same install command interactively from a terminal spawned by che-code (which has `VSCODE_IPC_HOOK_CLI` set) succeeds and extensions appear in the sidebar immediately.

---

### Attempt 5: Wait for IPC socket and export `VSCODE_IPC_HOOK_CLI`

**Approach:** Wait for `/tmp/vscode-ipc-*.sock` to appear, then export `VSCODE_IPC_HOOK_CLI` pointing to it before running installs.

**Result:** Socket never appeared. Timed out after 120s (60 attempts x 2s).

**Root cause:** The IPC socket is created in the **che-code sidecar container's** `/tmp/` directory. The `dev-tools` container has its own isolated `/tmp/` — it cannot see the sidecar's socket files. The socket is only visible in terminals spawned by the che-code editor because those terminals run through the sidecar's process space.

---

### Attempt 6 (untested): Extract `.vsix` directly into extensions directory

**Approach:** Since `.vsix` files are ZIP archives, extract them directly into `/checode/remote/extensions/` using Python's `zipfile` module (no `unzip` available in the image).

**Status:** Proof of concept confirmed — extraction works and produces the correct file structure. However, the extension directory layout needs verification (che-code may expect `package.json` at the top level, not inside an `extension/` subdirectory). Not yet tested end-to-end.

## Summary of Issues

| Issue | Category | Impact |
|-------|----------|--------|
| YAML `>-` breaks multiline `for` loops | Devfile syntax | Workspace fails to start |
| Binary path uses `ubi9/` subdirectory | Undocumented | Binary not found |
| Default install dir wrong (`~/.che-code/`) | Undocumented | Extensions invisible |
| CLI needs `VSCODE_IPC_HOOK_CLI` for server | Undocumented | Silent install failure |
| `/tmp/` not shared between containers | K8s architecture | Cannot access IPC socket from postStart |
| `.code-workspace` comments break parser | Strict JSON required | Workspace file ignored |
| `vscode-python-envs` 1.22.0 needs VS Code 1.110+ | Version mismatch | Extension incompatible |
| `which` not a POSIX builtin | Portability | Exit code 2 |

## Recommended Next Steps

1. **Direct extraction approach**: Extract `.vsix` files into `/checode/remote/extensions/` using Python (available in the image), bypassing the CLI entirely. Needs verification of the expected directory layout.

2. **Bake extensions into the container image**: The most reliable approach for offline use — add extensions during image build so they're present before any container starts. Eliminates all timing and IPC issues.

3. **Use a `ConfigMap` or `Volume`**: Pre-populate `/checode/remote/extensions/` via a Kubernetes ConfigMap or PersistentVolume containing the extracted extensions, mounted at workspace creation time.
