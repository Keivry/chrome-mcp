#!/bin/bash
set -e

# 清理上一个实例的 Chrome profile 锁文件
# 容器重启时 SingletonLock/SingletonCookie/SingletonSocket 会残留
rm -f /data/chrome-profile/SingletonLock /data/chrome-profile/SingletonCookie /data/chrome-profile/SingletonSocket

# Chrome v149+ 默认只监听 127.0.0.1:9222（--remote-debugging-address 被忽略）
# 先启动 socat 绑定 0.0.0.0:9222，Chrome 后绑定 127.0.0.1:9222 不冲突
echo "Starting socat port forward: 0.0.0.0:9222 -> 127.0.0.1:9222"
socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9222 &
SOCAT_PID=$!
sleep 1

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

# 等待任意子进程退出后终止另一个
wait -n $CHROME_PID $SOCAT_PID
kill $SOCAT_PID $CHROME_PID 2>/dev/null
