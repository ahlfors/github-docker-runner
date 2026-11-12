FROM myoung34/github-runner:latest

# ============================================
# 🔧 在这里安装你需要的自定义依赖
# ============================================

# 切换到 root 安装软件
USER root

# Trusted ancestors for workspace and private temporary test data.
RUN install -d -m 0755 /opt/runner-work \
    && install -d -m 0700 /opt/runner-tmp \
    && chown -R 1001:121 /opt/runner-work /opt/runner-tmp
ENV TMPDIR=/opt/runner-tmp

# Configure the Ubuntu mirror and enable the Universe component.
# Keep package installation in the single system-dependencies layer below.
RUN set -eux; \
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do \
        if [ -f "$f" ]; then \
            sed -i.bak \
                -e 's|https\?://archive.ubuntu.com/ubuntu|http://mirrors.ivolces.com/ubuntu|g' \
                -e 's|https\?://security.ubuntu.com/ubuntu|http://mirrors.ivolces.com/ubuntu|g' \
                -e 's|https\?://ports.ubuntu.com/ubuntu-ports|http://mirrors.ivolces.com/ubuntu-ports|g' \
                "$f"; \
        fi; \
    done; \
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
        sed -i '/^Components:/ { /universe/! s/$/ universe/; }' \
            /etc/apt/sources.list.d/ubuntu.sources; \
    fi; \
    if [ -f /etc/apt/sources.list ]; then \
        sed -i '/^[[:space:]]*deb[[:space:]]/ { /[[:space:]]universe\([[:space:]]\|$\)/! s/$/ universe/; }' \
            /etc/apt/sources.list; \
    fi
    
# 系统级依赖
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        make \
        build-essential \
        cmake \
        python3 \
        python3-pip \
        python3-venv \
        jq \
        wget \
        unzip \
        zip \
        rsync \
        openssh-client \
        pcre2-utils; \
    rm -rf /var/lib/apt/lists/*

# Go (按需)
# ARG GO_VERSION=1.22.3
# RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
#     && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
#     && rm go${GO_VERSION}.linux-amd64.tar.gz
# ENV PATH="/usr/local/go/bin:${PATH}"

# Python 包（按需）
# RUN pip3 install --no-cache-dir \
#     awscli \
#     ansible \
#     pytest
ARG NODE_VERSION=20.11.0

RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "$ARCH" in \
        amd64) NODE_ARCH=x64 ;; \
        arm64) NODE_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac; \
    wget -q "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -O /tmp/node.tar.xz; \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1; \
    rm -f /tmp/node.tar.xz; \
    node -v; \
    npm -v

RUN npm install -g pnpm yarn

ARG IMAGE_SYNCER_VERSION=v1.5.2
ARG IMAGE_SYNCER_BASE_URL=https://github.com/AliyunContainerService/image-syncer/releases/download

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  pkg_arch=amd64 ;; \
      aarch64) pkg_arch=arm64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    url="${IMAGE_SYNCER_BASE_URL}/${IMAGE_SYNCER_VERSION}/image-syncer-${IMAGE_SYNCER_VERSION}-linux-${pkg_arch}.tar.gz"; \
    curl -fL --retry 5 --retry-all-errors --connect-timeout 10 --max-time 120 \
      -o /tmp/image-syncer.tgz "$url"; \
    tar -tzf /tmp/image-syncer.tgz; \
    tar -xzf /tmp/image-syncer.tgz -C /usr/local/bin; \
    chmod +x /usr/local/bin/image-syncer; \
    rm -f /tmp/image-syncer.tgz; \
    image-syncer --help >/dev/null

