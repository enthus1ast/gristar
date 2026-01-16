#!/bin/bash
set -e

IMAGE_NAME="gristar-cross-build"
CONTAINER_NAME="gristar-extract"
OUTPUT_DIR="./binaries"

echo "🚀 Building Gristar cross-platform binaries via Docker..."

# 1. Build the Docker image
docker build -t $IMAGE_NAME .

# 2. Create the output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# 3. Create a temporary container instance
echo "📦 Extracting binaries to $OUTPUT_DIR..."
docker create --name $CONTAINER_NAME $IMAGE_NAME

# 4. Copy the files out
docker cp $CONTAINER_NAME:/output/. $OUTPUT_DIR/

# 5. Cleanup
echo "🧹 Cleaning up temporary container..."
docker rm $CONTAINER_NAME

echo "✅ Success! Binaries are available in: $(realpath $OUTPUT_DIR)"
ls -lh $OUTPUT_DIR
