#!/bin/bash
# Download pinned VS Code extensions from Open VSX for offline use in Dev Spaces.
# Run this script from a machine with internet access, then commit the .vsix files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Target platform for Dev Spaces (override with: PLATFORM=linux-arm64 ./download-extensions.sh)
PLATFORM="${PLATFORM:-linux-x64}"

# Extension list: "publisher/name version [platform-specific]"
# Extensions marked "platform" use platform-specific download URLs.
EXTENSIONS=(
  "redhat/vscode-yaml 1.21.0"
  "redhat/ansible 26.3.0"
  "ms-python/python 2026.4.0"
  "ms-python/black-formatter 2025.2.0"
  "ms-python/vscode-python-envs 1.10.0"
  # OpenShift Toolkit (187MB) and its dependency — optional, uncomment if you need
  # cluster browsing from the editor. The oc/kubectl CLIs are available in the terminal.
  # "redhat/vscode-redhat-account 0.2.0"
  # "redhat/vscode-openshift-connector 1.21.1 platform"
  "ms-python/debugpy 2025.18.0 platform"
)

FAILED=0

for entry in "${EXTENSIONS[@]}"; do
  read -r ext version platform_flag <<< "$entry"
  publisher="${ext%%/*}"
  name="${ext##*/}"

  if [ "$platform_flag" = "platform" ]; then
    filename="${publisher}.${name}-${version}@${PLATFORM}.vsix"
    url="https://open-vsx.org/api/${publisher}/${name}/${PLATFORM}/${version}/file/${filename}"
  else
    filename="${publisher}.${name}-${version}.vsix"
    url="https://open-vsx.org/api/${publisher}/${name}/${version}/file/${filename}"
  fi

  if [ -f "$filename" ]; then
    echo "SKIP: $filename already exists"
    continue
  fi

  echo "Downloading: $filename"
  if curl -fSL --retry 3 -o "$filename" "$url"; then
    echo "  OK: $filename ($(du -h "$filename" | cut -f1))"
  else
    echo "  FAIL: $filename — check if version $version exists at https://open-vsx.org/extension/${publisher}/${name}" >&2
    rm -f "$filename"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "Download complete."
[ "$FAILED" -gt 0 ] && echo "WARNING: $FAILED extension(s) failed to download." >&2 && exit 1
echo "All extensions downloaded successfully."
ls -lh "$SCRIPT_DIR"/*.vsix 2>/dev/null
