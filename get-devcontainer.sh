#!/usr/bin/env bash

set -euo pipefail

# set template name (subdirectory in the repo)
TEMPLATE=hackathon

URL=https://github.com/Lingaro/devcontainers-templates.git
BRANCH=main
REMOTE=devcontainers-templates
DEST=.

# initialize git repo if not initialized already (needed for git remote commands)
git init 2>/dev/null || :

# install VSCode Dev Containers extension if not installed
if CODE="$(command -v code-insiders 2>/dev/null)"; then
  :
elif CODE="$(command -v code 2>/dev/null)"; then
  :
else
  echo "❌ VSCode command line tool (code or code-insiders) not found in PATH"
  exit 1
fi
EXTENSION="ms-vscode-remote.remote-containers"
if ! "$CODE" --list-extensions | grep -qi "^${EXTENSION}$"; then
  "$CODE" --install-extension "$EXTENSION" --force
fi

# add or update devcontainers-templates repo
if git remote get-url "$REMOTE" >/dev/null 2>&1; then
  git remote set-url "$REMOTE" "$URL"
else
  git remote add "$REMOTE" "$URL"
fi

git fetch "$REMOTE" "$BRANCH"

# check if path exists in the given branch
git cat-file -e "$REMOTE/$BRANCH:$TEMPLATE" || {
  echo "❌ No '$TEMPLATE' on $REMOTE/$BRANCH"; exit 1;
}

# import files
git archive "$REMOTE/$BRANCH:$TEMPLATE" | tar -x -C "$DEST"

# convert line endings to LF in all .sh files
# fallback for macOS sed which requires an argument for -i
find . -type f -name '*.sh' -print0 | xargs -0 sed -i 's|\r$||' \
|| find . -type f -name '*.sh' -print0 | xargs -0 sed -i '' 's|\r$||'

# make all .sh files executable
find . -type f -name '*.sh' -print0 | xargs -0 chmod +x

# update .env.example with absolute path
if grep -q '^HOST_ABSOLUTE_PATH=' .devcontainer/.env.example 2>/dev/null; then
  WINDOWS_HOST_ABSOLUTE_PATH="$( (pwd -W 2>/dev/null) || true )"
  if [ -n "$WINDOWS_HOST_ABSOLUTE_PATH" ]; then
    # Windows
    HOST_ABSOLUTE_PATH="$(printf '%s' "$WINDOWS_HOST_ABSOLUTE_PATH" | sed -E 's|\\|/|g; s|^([A-Za-z]):/|/run/desktop/mnt/host/\L\1/|')"
  else
    # mac/Linux
    HOST_ABSOLUTE_PATH="$(pwd -P)"
  fi
  # escape & for sed replacement
  HOST_ABSOLUTE_PATH="$(printf '%s' "$HOST_ABSOLUTE_PATH" | sed 's|[&]|\\&|g')"
  # fallback for macOS sed which requires an argument for -i
  sed -i -E "s|^HOST_ABSOLUTE_PATH=.*|HOST_ABSOLUTE_PATH=${HOST_ABSOLUTE_PATH}|" .devcontainer/.env.example \
  || sed -i '' -E "s|^HOST_ABSOLUTE_PATH=.*|HOST_ABSOLUTE_PATH=${HOST_ABSOLUTE_PATH}|" .devcontainer/.env.example
fi

echo "✅ Imported: $REMOTE/$BRANCH:$TEMPLATE → $DEST"
printf "❗ Please:\n\t1. Copy .devcontainer/.env.example to .devcontainer/.env.\n\t2. Set the variables as needed.\n\t3. Reopen the folder in the container (F1 → Dev Containers: Reopen in Container)"
