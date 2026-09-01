# Use Fedora as base
FROM fedora

# Set timezone
ARG TZ=Europe/Berlin
ENV TZ=${TZ}

# Optional CLIs — toggled at build time (see docker-compose.yaml args).
# Claude Code and Mistral Vibe are on by default; Codex and Antigravity opt-in.
ARG INSTALL_CLAUDE=true
ARG INSTALL_VIBE=true
ARG INSTALL_CODEX=false
ARG INSTALL_ANTIGRAVITY=false

# Install basic development tools
RUN dnf install -y --setopt=install_weak_deps=False --allowerasing \
  less \
  git \
  sudo \
  man-db \
  unzip \
  gnupg2 \
  vim \
  curl \
  wget \
  ca-certificates \
  jq \
  bubblewrap \
  hostname \
  && dnf clean all

# nodejs/npm are only needed for the Codex CLI
RUN if [ "$INSTALL_CODEX" = "true" ]; then \
      dnf install -y --setopt=install_weak_deps=False nodejs npm && dnf clean all; \
    fi

# Create an agent user with UID 1000 (Fedora base has no default non-root user)
RUN groupadd -g 1000 agent \
 && useradd -m -u 1000 -g 1000 -s /bin/bash agent

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
ENV EDITOR=vim
ENV VISUAL=vim

# Install uv 
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN echo '[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"' >> ~/.bashrc

# Install Claude Code
RUN if [ "$INSTALL_CLAUDE" = "true" ]; then curl -fsSL https://claude.ai/install.sh | bash; fi
# Install Mistral Vibe CLI
RUN if [ "$INSTALL_VIBE" = "true" ]; then curl -LsSf https://mistral.ai/vibe/install.sh | bash; fi
# Install Codex
RUN if [ "$INSTALL_CODEX" = "true" ]; then npm install -g @openai/codex; fi
# Install Antigravity CLI
RUN if [ "$INSTALL_ANTIGRAVITY" = "true" ]; then curl -fsSL https://antigravity.google/cli/install.sh | bash; fi

# Install personal agent config (AGENTS.md/CLAUDE.md, skills, statuslines).
ARG AGENT_CONFIG_REPO=https://github.com/spieseba/agent-config.git
RUN git clone --depth 1 "${AGENT_CONFIG_REPO}" /home/agent/.agent-config \
 && if [ "$INSTALL_CLAUDE" = "true" ]; then \
      mkdir -p /home/agent/.claude \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.claude/CLAUDE.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.claude/skills \
      && ln -sf /home/agent/.agent-config/claude/statusline-command.sh /home/agent/.claude/statusline-command.sh \
      && chmod +x /home/agent/.agent-config/claude/statusline-command.sh \
      && ln -sf /home/agent/.agent-config/claude/settings.json /home/agent/.claude/settings.json; \
    fi \
 && if [ "$INSTALL_VIBE" = "true" ]; then \
      mkdir -p /home/agent/.vibe \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.vibe/AGENTS.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.vibe/skills; \
    fi \
 && if [ "$INSTALL_CODEX" = "true" ]; then \
      mkdir -p /home/agent/.codex \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.codex/AGENTS.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.codex/skills; \
    fi \
 && if [ "$INSTALL_ANTIGRAVITY" = "true" ]; then \
      mkdir -p /home/agent/.gemini \
      && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.gemini/GEMINI.md \
      && ln -sf /home/agent/.agent-config/skills /home/agent/.gemini/skills; \
    fi


# Default command
CMD ["/bin/bash"]
