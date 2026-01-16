# --- Stage 1: Build Environment ---
FROM nimlang/nim:latest AS builder

# Install Zig and 'file' utility
RUN apt-get update && apt-get install -y xz-utils wget file
RUN wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz \
    && tar -xf zig-linux-x86_64-0.13.0.tar.xz \
    && mkdir -p /opt/zig \
    && mv zig-linux-x86_64-0.13.0/* /opt/zig/ \
    && ln -s /opt/zig/zig /usr/local/bin/zig \
    && rm -rf zig-linux-x86_64-0.13.0*

WORKDIR /usr/src/app

# Install zigcc shim and project dependencies
COPY gristar.nimble ./
RUN nimble install -y zigcc
RUN nimble install -y --depsOnly

COPY . .

ENV PATH="/root/.nimble/bin:/opt/zig:${PATH}"
RUN mkdir -p dist

# --- Compilation Targets ---

# 1. Linux AMD64 (Desktop/Server)
RUN nim c -d:release --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-linux-gnu.2.28" --passL:"-target x86_64-linux-gnu.2.28" \
    --out:dist/gristar-linux-amd64 src/gristar.nim

# 2. Linux ARM64 (Raspberry Pi 4/5 64-bit OS, Apple Silicon Linux)
RUN nim c -d:release --cpu:arm64 --os:linux --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target aarch64-linux-gnu" --passL:"-target aarch64-linux-gnu" \
    --out:dist/gristar-linux-arm64 src/gristar.nim

# 3. Linux ARMv7 (Raspberry Pi 32-bit OS / Older IoT)
RUN nim c -d:release --cpu:arm --os:linux --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target arm-linux-gnueabihf" --passL:"-target arm-linux-gnueabihf" \
    --out:dist/gristar-linux-armv7 src/gristar.nim

# 4. Windows AMD64
RUN nim c -d:release --os:windows --cpu:amd64 --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-windows-gnu" --passL:"-target x86_64-windows-gnu" \
    --out:dist/gristar-windows-amd64.exe src/gristar.nim

# Show file info for verification during build
RUN file dist/*

# --- Stage 2: Export ---
FROM debian:bookworm-slim
WORKDIR /output
COPY --from=builder /usr/src/app/dist/ /output/
