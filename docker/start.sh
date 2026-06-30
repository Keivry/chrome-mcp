#!/bin/bash
set -e

# 清理上一个实例的 Chrome profile 锁文件
rm -f /data/chrome-profile/SingletonLock /data/chrome-profile/SingletonCookie /data/chrome-profile/SingletonSocket

# Chrome v149+ DevTools 默认只监听 127.0.0.1
# socat 与 Chrome 不能共享端口，所以 Chrome 用 9223，socat 在 9222 上监听并转发
CHROME_PORT=9223
SOCAT_PORT=9222

CHROME_ARGS=(
  "--headless=new"
  "--no-sandbox"
  "--disable-gpu"
  "--disable-dev-shm-usage"
  "--remote-debugging-port=${CHROME_PORT}"
  "--user-data-dir=/data/chrome-profile"
  "--window-size=1920,1080"
  "--no-first-run"
  "--disable-background-networking"
  "--disable-default-apps"
  "--disable-sync"
)

echo "Starting Chromium on port ${CHROME_PORT}..."
chromium "${CHROME_ARGS[@]}" &
CHROME_PID=$!

# 等待 Chrome 就绪
for i in $(seq 1 30); do
  if echo > /dev/tcp/127.0.0.1/${CHROME_PORT} 2>/dev/null; then
    echo "Chrome is ready on 127.0.0.1:${CHROME_PORT}"
    break
  fi
  sleep 1
done

# socat 端口转发：0.0.0.0:SOCAT_PORT → 127.0.0.1:CHROME_PORT
# 使用不同端口避免 bind 冲突
echo "Starting socat port forward: 0.0.0.0:${SOCAT_PORT} -> 127.0.0.1:${CHROME_PORT}"
socat TCP-LISTEN:${SOCAT_PORT},fork,reuseaddr TCP:127.0.0.1:${CHROME_PORT} &
SOCAT_PID=$!

# 等待任意子进程退出后终止另一个
wait -n $CHROME_PID $SOCAT_PID 2>/dev/null
kill $SOCAT_PID $CHROME_PID 2>/dev/null
