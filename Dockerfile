# --- Stage 1: Build Environment ---
FROM nimlang/nim:latest AS builder

# Install build tools
RUN apt-get update && apt-get install -y xz-utils wget file git
RUN wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz \
    && tar -xf zig-linux-x86_64-0.13.0.tar.xz \
    && mkdir -p /opt/zig \
    && mv zig-linux-x86_64-0.13.0/* /opt/zig/ \
    && ln -s /opt/zig/zig /usr/local/bin/zig \
    && rm -rf zig-linux-x86_64-0.13.0*

WORKDIR /usr/src/app

# Install zigcc and dependencies
COPY gristar.nimble ./
RUN nimble install -y zigcc
RUN nimble install -y --depsOnly

COPY . .

ENV PATH="/root/.nimble/bin:/opt/zig:${PATH}"
RUN mkdir -p dist

# # --- MAC-SPECIFIC SETUP ---
# # We use a repository that provides the necessary macOS headers for Zig
# RUN git clone --depth 1 https://github.com/phish108/apple-native-core-headers.git /opt/apple-sdks

# --- Compilation Targets ---

# 1. Linux AMD64
RUN nim c -d:release --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-linux-gnu.2.28" --passL:"-target x86_64-linux-gnu.2.28" \
    --out:dist/gristar-linux-amd64 src/gristar.nim

# 2. Windows AMD64
RUN nim c -d:release --os:windows --cpu:amd64 --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-windows-gnu" --passL:"-target x86_64-windows-gnu" \
    --out:dist/gristar-windows-amd64.exe src/gristar.nim

## Macos fails. if you need it please fix it.
## https://github.com/phish108/apple-native-core-headers 
# 3. macOS AMD64 (Intel Macs)
# RUN nim c -d:release --os:macosx --cpu:amd64 --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
#     --passC:"-target x86_64-macos" --passL:"-target x86_64-macos" \
#     --out:dist/gristar-macos-amd64 src/gristar.nim
#
# # 4. macOS ARM64 (M1/M2/M3 Apple Silicon)
# RUN nim c -d:release --os:macosx --cpu:arm64 --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
#     --passC:"-target aarch64-macos" --passL:"-target aarch64-macos" \
#     --out:dist/gristar-macos-arm64 src/gristar.nim

# 5. Linux ARM64 (Raspberry Pi)
RUN nim c -d:release --cpu:arm64 --os:linux --cc:clang --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target aarch64-linux-gnu" --passL:"-target aarch64-linux-gnu" \
    --out:dist/gristar-linux-arm64 src/gristar.nim

# Verification
RUN file dist/*

# --- Stage 2: Export ---
FROM debian:bookworm-slim
WORKDIR /output
COPY --from=builder /usr/src/app/dist/ /output/
