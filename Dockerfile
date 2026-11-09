FROM myoung34/github-runner:latest

# ============================================
# 🔧 在这里安装你需要的自定义依赖
# ============================================

# 切换到 root 安装软件
USER root

# Trusted ancestors for workspace and private temporary test data.
RUN install -d -m 0755 /opt/runner-work \
    && install -d -m 0700 /opt/runner-tmp
ENV TMPDIR=/opt/runner-tmp

RUN set -eux; \
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do \
        if [ -f "$f" ]; then \
            sed -i.bak \
                -e 's|http://archive.ubuntu.com/ubuntu|http://mirrors.ivolces.com/ubuntu|g' \
                -e 's|http://security.ubuntu.com/ubuntu|http://mirrors.ivolces.com/ubuntu|g' \
                -e 's|http://ports.ubuntu.com/ubuntu-ports|http://mirrors.ivolces.com/ubuntu-ports|g' \
                "$f"; \
        fi; \
    done
# 系统级依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 构建工具
    make \
    build-essential \
    cmake \
    # 语言运行时
    python3 \
    python3-pip \
    python3-venv \
    # 常用工具
    jq \
    wget \
    unzip \
    zip \
    rsync \
    ssh-client \
    # 数据库客户端（按需）
    # postgresql-client \
    # mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Node.js (通过 NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

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

