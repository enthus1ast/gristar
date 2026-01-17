#!/bin/bash
set -e

IMAGE_NAME="gristar-all-platforms"
CONTAINER_NAME="gristar-extract"
OUTPUT_DIR="./binaries"

echo "🍎 Building Gristar for Linux, Windows, and macOS..."

# Build image
docker build -t $IMAGE_NAME .

# Extract
mkdir -p $OUTPUT_DIR
docker create --name $CONTAINER_NAME $IMAGE_NAME
docker cp $CONTAINER_NAME:/output/. $OUTPUT_DIR/
docker rm $CONTAINER_NAME

# Checksums
echo "🔐 Hashing binaries..."
cd $OUTPUT_DIR
sha256sum * > checksums.txt
cd ..

echo "✅ Done! All binaries are in $OUTPUT_DIR"
