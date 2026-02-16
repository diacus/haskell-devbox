#!/usr/bin/env bash
set -euo pipefail

function find_compose_root() {
    # First attempt: use git repository root if available
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
	if [ -f "$git_root/docker-compose.yml" ]; then
	    echo "$git_root"
	    return 0
	fi
    fi

    # Fallback: walk up directory tree
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
	if [ -f "$dir/docker-compose.yml" ]; then
	    echo "$dir"
	    return 0
	fi
	dir="$(dirname "$dir")"
    done

    return 1
}

# Determine invoked command name
CMD="$(basename "$0")"

# Find the project root
PROJECT_ROOT="$(find_compose_root)" || {
    echo "docker-compose.yml not found in the current directory or any parent." >/dev/stderr
    exit 1
}

function rewrite_path() {
    local arg="$1"

    if [[ "$arg" == "$HOST_ROOT"* ]]; then
	echo "${arg/$HOST_ROOT/$CONTAINER_ROOT}"
    else
	echo "$arg"
    fi
}

cd "$PROJECT_ROOT"

if [ -z "${SERVICE:-}" ]; then
  echo "SERVICE variable is not set."
  exit 1
fi

if ! docker compose config --services | grep -qx "$SERVICE"; then
  echo "Service '$SERVICE' not found in docker-compose.yml."
  exit 1
fi

# Check if service is running
if ! docker compose ps --services --filter "status=running" | grep -qx "$SERVICE"; then
  echo "▶ Starting service $SERVICE..."
  docker compose up -d "$SERVICE"
fi

HOST_ROOT="$PROJECT_ROOT"
CONTAINER_ROOT="/workspace"

REWRITTEN_ARGS=()

for arg in "$@"; do
    REWRITTEN_ARGS+=("$(rewrite_path "$arg")")
done

if [ -t 1 ]; then
  exec docker compose exec "$SERVICE" "$CMD" "${REWRITTEN_ARGS[@]}"
else
  exec docker compose exec -T "$SERVICE" "$CMD" "${REWRITTEN_ARGS[@]}"
fi
