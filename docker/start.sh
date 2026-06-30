#!/bin/bash
set -e

# Chrome v149+ 默认只监听 127.0.0.1:9222（--remote-debugging-address 被忽略）
# 用 socat 将 0.0.0.0:9222 转发到 127.0.0.1:9222，使 docker-proxy 能正常工作
CHROME_ARGS=(
  "--headless=new"
  "--no-sandbox"
  "--disable-gpu"
  "--disable-dev-shm-usage"
  "--remote-debugging-port=9222"
  "--user-data-dir=/data/chrome-profile"
  "--window-size=1920,1080"
  "--no-first-run"
  "--disable-background-networking"
  "--disable-default-apps"
  "--disable-sync"
)

echo "Starting Chromium..."
chromium "${CHROME_ARGS[@]}" &
CHROME_PID=$!

# 等待 Chrome 就绪
for i in $(seq 1 30); do
  if echo > /dev/tcp/127.0.0.1/9222 2>/dev/null; then
    echo "Chrome is ready on 127.0.0.1:9222"
    break
  fi
  sleep 1
done

# socat 端口转发：0.0.0.0:9222 → 127.0.0.1:9222
echo "Starting socat port forward: 0.0.0.0:9222 -> 127.0.0.1:9222"
socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9222 &
SOCAT_PID=$!

# 等待任意子进程退出后终止另一个
wait $CHROME_PID
kill $SOCAT_PID 2>/dev/null
