# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Set timezone
ARG TZ=Europe/Berlin
ENV TZ=${TZ}

# Install basic development tools 
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  sudo \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  vim \
  curl \ 
  wget \
  ca-certificates \
  jq \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove the default ubuntu user and create an agent user with UID 1000
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupadd -g 1000 agent \
 && useradd -m -u 1000 -g 1000 -s /bin/zsh agent

# Install Node.js (Required for Claude Code, Codex CLI, and Gemini CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Starship as root
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Ensure user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R agent:agent /usr/local/share

# Grant agent user paswordless sudo for all commands
RUN echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent \
    && chmod 0440 /etc/sudoers.d/agent

# Switch to non-root user
USER agent

# Set working directory
WORKDIR /home/agent/workspace

# Set up environment for user
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/agent/.local/bin
ENV SHELL=/bin/zsh
ENV EDITOR=vim
ENV VISUAL=vim

# Install oh-my-zsh
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -t "" \
  -p git \
  -p https://github.com/zsh-users/zsh-autosuggestions \
  -p https://github.com/zsh-users/zsh-syntax-highlighting \
  -x 

# Initialize and configure Starship
RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc
RUN mkdir -p /home/agent/.config && starship preset pure-preset -o ~/.config/starship.toml

# Install uv 
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN echo '[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"' >> ~/.zshrc

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash 
# Install Codex
RUN npm install -g @openai/codex
# Install Antigravity CLI
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash 
# Install Mistral Vibe CLI
RUN curl -LsSf https://mistral.ai/vibe/install.sh | bash


# Default command
CMD ["/bin/zsh"]
