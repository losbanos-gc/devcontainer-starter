# Databricks with AI Tools Container Image (Optimized & Fixed)
FROM python:3.13-slim-bookworm

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to bash with huge pipefail for robust error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Configure environment variables
ENV PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1 \
  UV_INSTALL_DIR=/usr/local/bin \
  # Azure config
  AZURE_CONFIG_DIR=/workspaces/.azure \
  AZURE_EXTENSION_DIR=/workspaces/.azure/extensions \
  # Java
  JAVA_HOME=/usr/lib/jvm/zulu17 \
  PATH=$PATH:/usr/lib/jvm/zulu17/bin \
  # AI Tools
  ANTHROPIC_BASE_URL="" \
  ANTHROPIC_AUTH_TOKEN="" \
  ANTHROPIC_MODEL="" \
  OPENAI_BASE_URL="" \
  OPENAI_API_KEY="" \
  OPENAI_MODEL="" \
  ANTHROPIC_API_KEY=""

# 1. Install base dependencies
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  git curl wget bash jq unzip build-essential libssl-dev sudo vim \
  ca-certificates gnupg lsb-release openssh-client htop dnsutils \
  telnet net-tools elinks \
  && rm -rf /var/lib/apt/lists/*

# 2. Setup Repositories
RUN mkdir -p /etc/apt/keyrings

# Microsoft (Azure CLI)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
  && chmod go+r /etc/apt/keyrings/microsoft.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list

# NodeSource (Node.js)
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Azul (Zulu JDK) - Manual configuration with correct repo URL
RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && gpg --export 0xB1998361219BD9C9 > /etc/apt/keyrings/zulu.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/zulu.gpg] https://repos.azul.com/zulu/deb stable main" > /etc/apt/sources.list.d/zulu.list

# 3. Install Tools
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  azure-cli \
  nodejs \
  zulu17-jdk \
  # Cleanup
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Configure Java (Symlink for backward compatibility)
RUN ln -sf /usr/lib/jvm/zulu17 /usr/lib/jvm/java-17-zulu

# Install AI tools via npm
RUN npm install -g @anthropic-ai/claude-code @qwen-code/qwen-code \
  && npm cache clean --force \
  # Cleanup npm artifacts
  && find /usr/lib/node_modules -name "*.md" -delete \
  && find /usr/lib/node_modules -name "README*" -delete \
  && find /usr/lib/node_modules -name "CHANGELOG*" -delete

# Create qwen-proxy script
RUN echo '#!/bin/bash\nif [ ! -z "$OPENAI_BASE_URL" ]; then\n  exec qwen --openai-base-url "$OPENAI_BASE_URL" "$@"\nelse\n  exec qwen "$@"\nfi' > /usr/local/bin/qwen-proxy \
  && chmod +x /usr/local/bin/qwen-proxy

# Install Python dependencies from requirements.txt
COPY requirements.txt ./
RUN if [ -s requirements.txt ]; then \
  uv pip install --system -r requirements.txt; \
  fi \
  && rm -rf /root/.cache

# Set default shell and working directory
SHELL ["/bin/bash", "-c"]
WORKDIR /workspaces
