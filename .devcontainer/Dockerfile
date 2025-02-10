FROM debian:12

RUN \
    apt update && apt install -y \
        build-essential \
        curl \
        git \
        jq


# Rust

ARG RUST_TOOLCHAIN='1.84.0'

RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        -y \
        --default-toolchain ${RUST_TOOLCHAIN}

RUN \
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | sh

# miniserve

ARG MINISERVE_VERSION='0.28.0'

RUN \
    /root/.cargo/bin/cargo binstall \
        --locked \
        --version ${MINISERVE_VERSION} \
        miniserve


# Dfx

ARG DFX_VERSION='0.24.3'

RUN \
    curl -fsSL https://internetcomputer.org/install.sh | \
        DFXVM_INIT_YES='1' \
        DFX_VERSION=${DFX_VERSION} \
            sh -s
