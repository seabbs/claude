#!/usr/bin/env bash
# claude-dev.sh — Manage the Claude dev container
# Usage:
#   claude-dev          — attach to running container (bash at /workspace)
#   claude-dev start    — start the container
#   claude-dev stop     — stop the container
#   claude-dev restart  — restart the container
#   claude-dev build    — rebuild the container image
#   claude-dev logs     — tail container logs
#   claude-dev status   — show container status
#   claude-dev update   — rebuild image with latest packages and restart

set -euo pipefail

COMPOSE_DIR="${HOME}/.claude/docker"
CONTAINER_NAME="claude-dev"

case "${1:-}" in
  start)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
    echo "Container started. Run 'claude-dev' to attach."
    ;;
  stop)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" down
    ;;
  restart)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" restart
    ;;
  build)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" build --no-cache
    ;;
  update)
    echo "Rebuilding image with latest packages..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" build --no-cache
    echo "Restarting container..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
    echo "Container updated. Named volumes (history, logs) preserved."
    ;;
  logs)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" logs -f
    ;;
  status)
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    ;;
  "")
    # Default: attach to container bash at /workspace
    if ! docker ps --filter "name=$CONTAINER_NAME" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      echo "Container not running. Starting..."
      docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
      sleep 2
    fi
    docker exec -it "$CONTAINER_NAME" bash
    ;;
  *)
    echo "Usage: claude-dev [start|stop|restart|build|update|logs|status]"
    echo "  No argument: attach to container bash at /workspace"
    exit 1
    ;;
esac
