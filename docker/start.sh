#!/bin/bash
set -e

# --remote-debugging-address 在 Chrome v149+ 被忽略
# 不加这个 flag 时 Chrome 默认绑定 0.0.0.0:9222 ✓
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
exec chromium "${CHROME_ARGS[@]}"
