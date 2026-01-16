# --- Stage 1: Build Environment ---
FROM nimlang/nim:latest AS builder

# 1. Install Zig correctly
# We extract it to /opt/zig and symlink the binary so it can find its 'lib' folder
RUN apt-get update && apt-get install -y xz-utils wget
RUN wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz \
    && tar -xf zig-linux-x86_64-0.13.0.tar.xz \
    && mkdir -p /opt/zig \
    && mv zig-linux-x86_64-0.13.0/* /opt/zig/ \
    && ln -s /opt/zig/zig /usr/local/bin/zig \
    && rm -rf zig-linux-x86_64-0.13.0*

WORKDIR /usr/src/app

# 2. Install zigcc shim and project dependencies
COPY gristar.nimble ./
RUN nimble install -y zigcc
RUN nimble install -y --depsOnly

COPY . .

# Ensure nimble binaries (zigcc) and Zig are in the PATH
ENV PATH="/root/.nimble/bin:/opt/zig:${PATH}"

RUN mkdir -p dist

# 3. Compile for Linux AMD64
RUN nim c -d:release --cc:clang \
    --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-linux-gnu.2.28" \
    --passL:"-target x86_64-linux-gnu.2.28" \
    --out:dist/gristar-linux-amd64 src/gristar.nim

# 4. Compile for Windows AMD64
RUN nim c -d:release --os:windows --cpu:amd64 --cc:clang \
    --clang.exe="zigcc" --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-windows-gnu" \
    --passL:"-target x86_64-windows-gnu" \
    --out:dist/gristar-windows-amd64.exe src/gristar.nim

# --- Stage 2: Export ---
FROM debian:bookworm-slim
WORKDIR /output
COPY --from=builder /usr/src/app/dist/ /output/
