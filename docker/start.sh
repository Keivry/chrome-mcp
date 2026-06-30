#!/bin/bash
set -e

# Chrome 启动参数（--remote-debugging-address=0.0.0.0 在 v149 被忽略，用 proxy 解决）
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
echo "Waiting for Chrome to listen on 127.0.0.1:9222..."
for i in $(seq 1 30); do
  if bash -c 'echo >/dev/tcp/127.0.0.1/9222' 2>/dev/null; then
    echo "Chrome ready after ${i}s"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "Chrome failed to start"
    kill $CHROME_PID 2>/dev/null
    exit 1
  fi
  sleep 1
done

# Node.js TCP proxy: 0.0.0.0:9222 → 127.0.0.1:9222
# Chrome DevTools 只绑 127.0.0.1，proxy 让外部容器也能访问
echo "Starting TCP proxy..."
node -e "
const net = require('net');
const server = net.createServer((client) => {
  const backend = net.connect(9222, '127.0.0.1', () => {
    client.pipe(backend).pipe(client);
  });
  backend.on('error', (e) => { console.error('backend err:', e.message); client.destroy(); });
  client.on('error', (e) => { /* ignore client disconnect */ });
});
server.listen(9222, '0.0.0.0', () => {
  console.log('Proxy: 0.0.0.0:9222 -> 127.0.0.1:9222');
});
" &
PROXY_PID=$!

# 清理函数
cleanup() {
  echo "Shutting down..."
  kill $CHROME_PID $PROXY_PID 2>/dev/null
  wait
}
trap cleanup SIGTERM SIGINT

# 等待任一进程退出
wait -n $CHROME_PID $PROXY_PID
EXIT_CODE=$?
# 如果 proxy 退出（不应发生），继续等 Chrome
if [ $EXIT_CODE -ne 0 ]; then
  wait $CHROME_PID
  exit $?
fi
