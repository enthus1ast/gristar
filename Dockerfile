# --- Stage 1: Build ---
# Using the official Nim image (which is based on Debian)
FROM nimlang/nim:latest AS builder
WORKDIR /usr/src/app

# Copy nimble file first for dependency caching
COPY gristar.nimble ./
RUN nimble install -y --depsOnly

# Copy the source code
COPY . .

# Compile the binary
# We use -d:release for optimization. 
# On Debian, we usually link dynamically against glibc.
RUN nim c -d:release -o:gristar src/gristar.nim

# --- Stage 2: Runtime ---
FROM debian:bookworm-slim
# Install runtime essentials (SSL for networking and SQLite if needed)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/

# Copy the binary from the builder stage
COPY --from=builder /usr/src/app/gristar .

ENTRYPOINT ["./gristar"]
