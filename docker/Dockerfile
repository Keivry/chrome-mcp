FROM node:20-bookworm-slim

# 安装 Chromium 和依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建 Chrome 数据目录
RUN mkdir -p /data/chrome-profile

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD bash -c 'echo >/dev/tcp/127.0.0.1/9222' 2>/dev/null

EXPOSE 9222

CMD ["chromium", \
  "--headless=new", \
  "--no-sandbox", \
  "--disable-gpu", \
  "--disable-dev-shm-usage", \
  "--remote-debugging-port=9222", \
  "--remote-debugging-address=0.0.0.0", \
  "--user-data-dir=/data/chrome-profile", \
  "--window-size=1920,1080", \
  "--no-first-run", \
  "--disable-background-networking", \
  "--disable-default-apps", \
  "--disable-sync"]
