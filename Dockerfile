FROM myoung34/github-runner:latest

# ============================================
# 🔧 在这里安装你需要的自定义依赖
# ============================================

# 切换到 root 安装软件
USER root

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