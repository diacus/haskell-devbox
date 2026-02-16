#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/diacus/haskell-devbox"
TARBALL_URL="$REPO_URL/archive/refs/heads/main.tar.gz"
SUBDIR="haskell-devbox-main"

USER_ID=$(id -u)
GROUP_ID=$(id -g)
CONTAINER=devbox
SERVICE=devbox

echo "▶ Bootstrapping haskell-devbox..."

TMP_DIR="$(mktemp -d)"

curl -L "$TARBALL_URL" -o "$TMP_DIR/repo.tar.gz"
tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR"

mv "$TMP_DIR/$SUBDIR/"* .
rm -rf "$TMP_DIR"

echo "✔ Project files downloaded."

PROJECT_DIR="$(pwd)"
BINARY_DIR="$PROJECT_DIR/.local/bin"
WRAPPER="$PROJECT_DIR/docker-wrapper.sh"

echo "▶ Building and starting container..."
USER_ID=$(id -u) GROUP_ID=$(id -g) CONTAINER=devbox SERVICE=devbox \
       docker compose up --build -d 

echo "▶ Ensuring wrapper is executable..."
chmod +x "$WRAPPER"

echo "▶ Creating local bin directory..."
mkdir -p "$BINARY_DIR"

echo "▶ Waiting for container to be ready..."
until docker exec "$CONTAINER" true 2>/dev/null; do
  sleep 1
done

echo "▶ Discovering binaries inside container..."

BINARIES=$(docker exec "$CONTAINER" sh -c \
  'find "$HOME/.ghcup/bin" -maxdepth 1 -executable -printf "%f\n"')

echo "▶ Generating symlinks..."

for BINARY in $BINARIES; do
  ln -sf "$WRAPPER" "$BINARY_DIR/$BINARY"
done

echo "▶ Saving environment variables to .envrc..."

cat > .envrc <<EOF
export USER_ID=$USER_ID
export GROUP_ID=$GROUP_ID
export CONTAINER=$CONTAINER
export SERVICE=$SERVICE
EOF

echo "▶ Enable the environment with `direnv allow`"

echo "✔ Installation complete."
