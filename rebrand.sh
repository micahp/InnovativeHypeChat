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
echo "✏️ Updating Footer content in all locations..."

# 1. Update the TypeScript source file
if docker exec $CONTAINER_NAME test -f $FOOTER_PATH; then
  # Extract the file from container to host for processing
  TMP_FOOTER="$BASE_PATH/tmp_footer.tsx"
  
  # Copy the file from container to host
  docker cp "$CONTAINER_NAME:$FOOTER_PATH" "$TMP_FOOTER"
  
  if [ -f "$TMP_FOOTER" ]; then
    # Target the correct markdown pattern in the source code
    # The original pattern is: '[LibreChat ' + Constants.VERSION + '](https://librechat.ai)'
    sed -i "s|\[LibreChat \' +|\[$FOOTER_TITLE \' +|g" "$TMP_FOOTER"
    sed -i "s|https://librechat.ai|#|g" "$TMP_FOOTER"
    
    # Copy the modified file back to the container
    if docker cp "$TMP_FOOTER" "$CONTAINER_NAME:$FOOTER_PATH"; then
      echo "- ✅ Updated source Footer.tsx successfully"
    else
      echo "- ❌ Failed to copy modified source file back to container"
      FAILED_COUNT=$((FAILED_COUNT+1))
    fi
    rm "$TMP_FOOTER"
  else
    echo "- ❌ Failed to copy Footer.tsx from container"
    FAILED_COUNT=$((FAILED_COUNT+1))
  fi
else
  echo "- ⚠️ Footer.tsx source file not found at $FOOTER_PATH"
  FAILED_COUNT=$((FAILED_COUNT+1))
fi

# 2. Find and update the compiled JS files that might contain the footer content
echo "- 🔍 Searching for compiled JS files containing LibreChat footer content..."

# First look for files with LibreChat in direct string references
COMPILED_FILES=$(docker exec $CONTAINER_NAME find /app/client/dist -type f -name "*.js" -exec grep -l "LibreChat" {} \; 2>/dev/null)

# Also look for files with librechat.ai domain
DOMAIN_FILES=$(docker exec $CONTAINER_NAME find /app/client/dist -type f -name "*.js" -exec grep -l "librechat.ai" {} \; 2>/dev/null)

# Combine unique results
ALL_FILES=$(echo "$COMPILED_FILES"$'\n'"$DOMAIN_FILES" | sort | uniq)

if [ -n "$ALL_FILES" ]; then
  echo "- 📄 Found these files with LibreChat references:"
  echo "$ALL_FILES"
  
  # Create a temporary directory for processing compiled files
  TEMP_DIR="$BASE_PATH/tmp_compiled"
  mkdir -p "$TEMP_DIR"
  
  # Process each file that might contain the footer content
  for COMPILED_FILE in $ALL_FILES; do
    echo "- ✏️ Processing $COMPILED_FILE"
    FILE_NAME=$(basename "$COMPILED_FILE")
    LOCAL_PATH="$TEMP_DIR/$FILE_NAME"
    
    # Copy from container to host
    docker cp "$CONTAINER_NAME:$COMPILED_FILE" "$LOCAL_PATH"
    
    if [ -f "$LOCAL_PATH" ]; then
      # More aggressive replacements for compiled/minified JS files
      # 1. Replace standard text
      sed -i "s|LibreChat|$FOOTER_TITLE|g" "$LOCAL_PATH"
      
      # 2. Replace URL references - both with and without quotes/escapes
      sed -i "s|https://librechat.ai|#|g" "$LOCAL_PATH"
      sed -i "s|\"https://librechat.ai\"|\"#\"|g" "$LOCAL_PATH"
      sed -i "s|'https://librechat.ai'|'#'|g" "$LOCAL_PATH"
      sed -i "s|\\\\\"https://librechat.ai\\\\\"|\\\\\"#\\\\\"|g" "$LOCAL_PATH"
      
      # 3. Handle potential minified versions (no spaces)
      sed -i "s|\[LibreChat\"|\[$FOOTER_TITLE\"|g" "$LOCAL_PATH"
      sed -i "s|\[LibreChat'|\[$FOOTER_TITLE'|g" "$LOCAL_PATH"
      sed -i "s|\[LibreChat+|\[$FOOTER_TITLE+|g" "$LOCAL_PATH"
      
      # Copy back to container
      if docker cp "$LOCAL_PATH" "$CONTAINER_NAME:$COMPILED_FILE"; then
        echo "  ✅ Updated $COMPILED_FILE"
      else
        echo "  ❌ Failed to update $COMPILED_FILE"
        FAILED_COUNT=$((FAILED_COUNT+1))
      fi
    fi
  done
  
  # Clean up
  rm -rf "$TEMP_DIR"
  echo "- ✅ Compiled file updates complete"
else
  echo "- ⚠️ No compiled files with LibreChat references found"
  
  # Fallback: Try more aggressive search for minified/obfuscated code
  echo "- 🔍 Trying more aggressive search for minified code..."
  CHUNK_FILES=$(docker exec $CONTAINER_NAME find /app/client/dist -type f -name "*.js" -not -size 0 | head -n 20)
  
  if [ -n "$CHUNK_FILES" ]; then
    echo "- 📄 Checking the largest JS chunk files..."
    
    # Create a temporary directory for processing compiled files
    TEMP_DIR="$BASE_PATH/tmp_compiled"
    mkdir -p "$TEMP_DIR"
    
    for CHUNK_FILE in $CHUNK_FILES; do
      echo "- ✏️ Processing $CHUNK_FILE"
      FILE_NAME=$(basename "$CHUNK_FILE")
      LOCAL_PATH="$TEMP_DIR/$FILE_NAME"
      
      # Copy from container to host
      docker cp "$CONTAINER_NAME:$CHUNK_FILE" "$LOCAL_PATH"
      
      if [ -f "$LOCAL_PATH" ]; then
        # Apply all possible replacements to cover minified code
        sed -i "s|LibreChat|$FOOTER_TITLE|g" "$LOCAL_PATH"
        sed -i "s|librechat|innovative-hype|gi" "$LOCAL_PATH"
        sed -i "s|https://librechat.ai|#|g" "$LOCAL_PATH"
        
        # Copy back to container
        if docker cp "$LOCAL_PATH" "$CONTAINER_NAME:$CHUNK_FILE"; then
          echo "  ✅ Updated $CHUNK_FILE"
        else
          echo "  ❌ Failed to update $CHUNK_FILE"
          FAILED_COUNT=$((FAILED_COUNT+1))
        fi
      fi
    done
    
    # Clean up
    rm -rf "$TEMP_DIR"
    echo "- ✅ Fallback chunk updates complete"
  fi
fi

# 3. Try to restart application processes
echo "- 🔄 Attempting to restart application in the container..."

# First try using npm if available
docker exec $CONTAINER_NAME sh -c "cd /app && npm run restart" 2>/dev/null || \
# If specific restart script is unavailable, try touching node files to trigger restart
docker exec $CONTAINER_NAME sh -c "find /app -name '*.js' -exec touch {} \;" 2>/dev/null || \
# Last resort: try to send SIGHUP to PID 1
docker exec $CONTAINER_NAME kill -HUP 1 2>/dev/null || echo "  ⚠️ Could not restart container processes"

echo "✨ Footer update process complete"
echo ""
echo "⚠️ If changes aren't visible after refreshing your browser, try these steps:"
echo "1. Clear your browser cache completely (Ctrl+Shift+Del)"
echo "2. Restart the container with: docker restart $CONTAINER_NAME"
echo "3. If all else fails, you may need to rebuild the application"

# Summary
echo ""
echo "📋 Summary:"
echo "- $SUCCESS_COUNT files successfully copied"
echo "- $FAILED_COUNT files failed or skipped"
echo ""
echo "✨ Branding update for Innovative Hype Chat is complete."
echo "🔄 You may need to refresh or clear your browser cache to see the changes."
echo "⚠️ You might need to rebuild the application for Footer.tsx changes to take effect."

# Add after footer modifications:
echo "🔄 Rebuilding the frontend application..."
docker exec $CONTAINER_NAME sh -c "cd /app && npm run frontend"