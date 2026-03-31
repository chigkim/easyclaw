#!/bin/sh
set -e

apt-get update
apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  git \
  fonts-liberation \
  curl \
  chromium \
  ffmpeg \
  tzdata

export UV_INSTALL_DIR=/usr/local/bin
curl -LsSf https://astral.sh/uv/install.sh | sh

mkdir -p /home/node/.cache/ms-playwright
node /app/node_modules/playwright-core/cli.js install chromium

printf '#!/bin/sh\nexec node /app/node_modules/playwright-core/cli.js "$@"\n' > /usr/local/bin/playwright

ln -sf /usr/bin/chromium /usr/bin/chromium-browser
ln -sf /usr/bin/chromium /usr/bin/google-chrome
ln -sf /usr/bin/chromium /usr/bin/google-chrome-stable

chmod +x /usr/local/bin/playwright
chown -R node:node /home/node

rm -rf /var/lib/apt/lists/*