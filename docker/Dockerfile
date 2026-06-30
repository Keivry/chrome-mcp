FROM node:22-bookworm-slim

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

EXPOSE 9222

# Chrome 只绑定 127.0.0.1（--remote-debugging-address=0.0.0.0 在 v149 被忽略）
# 所以用 Node.js TCP proxy 把流量从 0.0.0.0:9222 转发到 127.0.0.1:9222
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD bash -c 'echo >/dev/tcp/127.0.0.1/9222' 2>/dev/null

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
