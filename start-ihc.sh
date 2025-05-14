#!/bin/bash

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH" >&2
    exit 1
fi

if [ ! -f "./rebrand.sh" ]; then
    echo "Error: rebrand.sh script not found" >&2
    exit 1
fi

# Start containers in detached mode
echo "Starting LibreChat containers..."
if ! docker compose up -d; then
    echo "Failed to start containers" >&2
    exit 1
fi

# Wait for container readiness using healthcheck
echo "Waiting for LibreChat container to be ready..."
MAX_RETRIES=30
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    if docker compose exec -T libre-chat curl -s http://localhost:3080/api/health >/dev/null 2>&1; then
        echo "Container is ready!"
        break
    fi
    echo "Waiting for container to be ready... ($COUNT/$MAX_RETRIES)"
    COUNT=$((COUNT+1))
    sleep 2
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "Timed out waiting for container to be ready" >&2
    echo "Continuing anyway - rebrand might fail if container isn't fully initialized"
fi

# Run rebrand script
echo "Running rebrand script..."
if ! ./rebrand.sh; then
    echo "Warning: Rebrand script failed or completed with errors" >&2
fi

echo "Container is up and rebranded."
echo "To view logs, run: docker compose logs -f"