#!/bin/bash

# Configuration
CONTAINER_NAME="LibreChat"
TITLE="Innovative Hype"
FOOTER_TITLE="Innovative Hype Chat"

# Use $HOME instead of ~ for proper expansion
BASE_PATH="$HOME/InnovativeHypeChat"
ASSETS_SRC="$BASE_PATH/client/public/assets"

# Target paths in the container
PUBLIC_DIR="/app/client/public"
DIST_DIR="/app/client/dist"
FOOTER_PATH="/app/client/src/components/Chat/Footer.tsx"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "❌ Container ${CONTAINER_NAME} is not running!"
  echo "Please start the container first with 'docker-compose up -d'"
  exit 1
fi

# Verify directories exist in container
echo "🔍 Verifying container directories..."
if ! docker exec $CONTAINER_NAME ls $PUBLIC_DIR > /dev/null 2>&1; then
  echo "❌ Directory $PUBLIC_DIR does not exist in the container!"
  exit 1
fi

# Create assets directories if they don't exist
docker exec $CONTAINER_NAME mkdir -p $PUBLIC_DIR/assets
docker exec $CONTAINER_NAME mkdir -p $DIST_DIR/assets

echo "📂 Copying all branding assets to container..."

# Debug: Show actual path being used
echo "Looking for assets in: $ASSETS_SRC"

# List of assets to copy
ASSETS=(
  "logo.svg"
  "apple-touch-icon-180x180.png"
  "favicon-32x32.png"
  "favicon-16x16.png"
  "maskable-icon.png"
  "icon-192x192.png"
)

# Track successful and failed copies
SUCCESS_COUNT=0
FAILED_COUNT=0

# Copy each asset to both public and dist directories
for asset in "${ASSETS[@]}"; do
  if [ -f "$ASSETS_SRC/$asset" ]; then
    echo "Copying $asset..."
    
    # Copy to public dir
    if docker cp "$ASSETS_SRC/$asset" "$CONTAINER_NAME:$PUBLIC_DIR/assets/$asset"; then
      echo "- ✅ Copied to public directory"
      SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    else
      echo "- ❌ Failed to copy to public directory"
      FAILED_COUNT=$((FAILED_COUNT+1))
    fi
    
    # Copy to dist dir
    if docker cp "$ASSETS_SRC/$asset" "$CONTAINER_NAME:$DIST_DIR/assets/$asset"; then
      echo "- ✅ Copied to dist directory"
      SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    else
      echo "- ❌ Failed to copy to dist directory" 
      FAILED_COUNT=$((FAILED_COUNT+1))
    fi
  else
    echo "⚠️ Warning: $ASSETS_SRC/$asset not found, skipping."
    FAILED_COUNT=$((FAILED_COUNT+1))
  fi
done

# Update title in index.html (both in public and dist directories)
echo "✏️ Updating title in index.html..."
TITLE_UPDATED=false

if docker exec $CONTAINER_NAME test -f $PUBLIC_DIR/index.html; then
  docker exec $CONTAINER_NAME sed -i "s/<title>.*<\/title>/<title>$TITLE<\/title>/g" $PUBLIC_DIR/index.html
  echo "- ✅ Updated title in public/index.html"
  TITLE_UPDATED=true
fi

if docker exec $CONTAINER_NAME test -f $DIST_DIR/index.html; then
  docker exec $CONTAINER_NAME sed -i "s/<title>.*<\/title>/<title>$TITLE<\/title>/g" $DIST_DIR/index.html
  echo "- ✅ Updated title in dist/index.html"
  TITLE_UPDATED=true
fi

if [ "$TITLE_UPDATED" = false ]; then
  echo "- ⚠️ No index.html files found to update title"
fi

# Update Footer.tsx to replace LibreChat with Innovative Hype Chat
echo "✏️ Updating Footer.tsx..."
if docker exec $CONTAINER_NAME test -f $FOOTER_PATH; then
  # Using sh instead of bash for compatibility with minimal containers
  docker exec $CONTAINER_NAME sh -c "perl -i -pe 's/\[LibreChat (\+\s+Constants\.VERSION \+)/\[$FOOTER_TITLE \1/g' $FOOTER_PATH"
  
  # Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "- ✅ Updated LibreChat reference in Footer.tsx"
  else
    echo "- ❌ Failed to update Footer.tsx"
    FAILED_COUNT=$((FAILED_COUNT+1))
  fi
else
  echo "- ⚠️ Footer.tsx not found at $FOOTER_PATH"
  FAILED_COUNT=$((FAILED_COUNT+1))
fi

# Summary
echo ""
echo "📋 Summary:"
echo "- $SUCCESS_COUNT files successfully copied"
echo "- $FAILED_COUNT files failed or skipped"
echo ""
echo "✨ Branding update for Innovative Hype Chat is complete."
echo "🔄 You may need to refresh or clear your browser cache to see the changes."
echo "⚠️ You might need to rebuild the application for Footer.tsx changes to take effect."