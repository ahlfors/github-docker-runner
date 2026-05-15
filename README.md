# github-docker-runner

```
github-docker-runners/
├── Dockerfile              # 自定义镜像（安装你需要的依赖）
├── docker-compose.yml      # 多 Runner 编排
├── .env                    # 敏感配置（不入 Git）
└── .gitignore
```


## Deployment

```
# 首次启动（构建镜像 + 启动 4 个 Runner）
docker compose up -d --build

# 查看所有 Runner 状态
docker compose ps

# 查看日志
docker compose logs -f

# 查看单个 Runner 的日志
docker compose logs -f runner-1
```

Used in workflow:
```
name: CI Pipeline
on: [push, pull_request]

jobs:
  build:
    # 通过 labels 匹配你的 Runner
    runs-on: [self-hosted, linux, x64, docker]
    steps:
      - uses: actions/checkout@v4

      - name: Run tests
        run: |
          node --version
          python3 --version
          echo "Running on self-hosted runner!"

  # 多 Job 会被自动分配到不同的空闲 Runner，实现并行
  test:
    runs-on: [self-hosted, linux, x64, docker]
    steps:
      - uses: actions/checkout@v4
      - run: echo "This runs in parallel on another runner!"
```


## Maintance Commands

```
# 扩容到 8 个 Runner
docker compose up -d --scale runner=8

# 缩容到 2 个
docker compose up -d --scale runner=2
```


```
# 修改 Dockerfile 添加新依赖后
docker compose build --no-cache
docker compose up -d
```

```
# 优雅停止（自动从 GitHub 注销）
docker compose down

# 停止并清理所有卷
docker compose down -v
```

