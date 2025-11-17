# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Set timezone
ARG TZ=Europe/Berlin
ENV TZ=${TZ}

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  vim \
  curl \ 
  wget \
  ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js (Required for Claude Code, Codex CLI, and Gemini CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Starship as root
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Create non-root user 
ARG USERNAME=developer
RUN useradd -m -s /bin/zsh ${USERNAME}

# Only on Linux, when there are file permission issues
#ARG USER_GID=1000
#ARG USER_UID=1000
#RUN groupadd --gid ${USER_GID} ${USERNAME} \
#    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

# Ensure user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R ${USERNAME}:${USERNAME} /usr/local/share

# Create workspace and set permissions
RUN mkdir -p /workspace && chown -R ${USERNAME}:${USERNAME} /workspace

# Copy and configure firewall script 
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh \
    && echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/${USERNAME}-firewall \
    && chmod 0440 /etc/sudoers.d/${USERNAME}-firewall

# Switch to non-root user
USER ${USERNAME}

# Set working directory
WORKDIR /workspace

# Set up environment for user
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
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
RUN mkdir -p /home/${USERNAME}/.config && starship preset jetpack -o ~/.config/starship.toml

# Install Claude Code, Codex, Gemini
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG GEMINI_VERSION=latest

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && npm install -g @openai/codex@${CODEX_VERSION} \
    && npm install -g @google/gemini-cli@${GEMINI_VERSION}

# Default command
CMD ["/bin/zsh"]
