#!/usr/bin/env bash
set -euo pipefail

# Ensure we are in project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

BINARY_DIR="$PROJECT_DIR/.local/bin"
WRAPPER="$PROJECT_DIR/docker-wrapper.sh"

echo "▶ Building and starting container..."
docker compose up --build -d $SERVICE

echo "▶ Ensuring wrapper is executable..."
chmod +x "$WRAPPER"

echo "▶ Creating local bin directory..."
mkdir -p "$BINARY_DIR"

echo "▶ Waiting for container to be ready..."
until docker exec "$CONTAINER" true 2>/dev/null; do
  sleep 1
done

echo "▶ Discovering binaries inside container..."

# List executables inside ghcup bin directory
BINARIES=$(docker exec "$CONTAINER" sh -c \
  'find "$HOME/.ghcup/bin" -maxdepth 1 -executable -printf "%f\n"')

echo "▶ Generating symlinks..."

for BINARY in $BINARIES; do
  ln -sf "$WRAPPER" "$BINARY_DIR/$BINARY"
done

echo "✔ Installation complete."
