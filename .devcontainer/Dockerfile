ARG RUBY_VERSION=3.4.5
FROM ghcr.io/rails/devcontainer/images/ruby:${RUBY_VERSION}

# Switch to root for system package installation
USER root

# Install Node.js 24.x and system dependencies
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libvips nodejs tmux ripgrep && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Playwright system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
      libdbus-1-3 libxkbcommon0 libatspi2.0-0 libxcomposite1 libxdamage1 \
      libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Switch back to vscode user for tool installations
USER vscode

# Install uv, bun, and Claude Code CLI
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV BUN_INSTALL="/home/vscode/.bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
RUN curl -fsSL https://claude.ai/install.sh | bash

# Pre-cache Playwright browsers
COPY --chown=vscode package.json bun.lock* /tmp/playwright-setup/
RUN cd /tmp/playwright-setup && \
    bun install 2>/dev/null && \
    bunx playwright install chromium || true && \
    rm -rf /tmp/playwright-setup
