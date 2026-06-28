# Use Fedora as base
FROM fedora

# Set timezone
ARG TZ=Europe/Berlin
ENV TZ=${TZ}

# Install basic development tools (nodejs/npm required for Codex CLI)
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
  nodejs \
  npm \
  && dnf clean all

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
RUN curl -fsSL https://claude.ai/install.sh | bash 
# Install Codex
RUN npm install -g @openai/codex
# Install Antigravity CLI
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash 
# Install Mistral Vibe CLI
RUN curl -LsSf https://mistral.ai/vibe/install.sh | bash

# Install personal agent config (AGENTS.md/CLAUDE.md, skills, Claude Code statusline).
# Public repo -> HTTPS clone needs no credentials. Cloned (not copied) so it stays
# updatable in-container via `git -C ~/.agent-config pull`. Lives outside the mounted
# workspace, which would otherwise shadow build-time files at runtime.
ARG AGENT_CONFIG_REPO=https://github.com/spieseba/agent-config.git
RUN git clone --depth 1 "${AGENT_CONFIG_REPO}" /home/agent/.agent-config \
 && mkdir -p /home/agent/.claude /home/agent/.codex /home/agent/.gemini /home/agent/.vibe \
 && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.claude/CLAUDE.md \
 && ln -sf /home/agent/.agent-config/skills /home/agent/.claude/skills \
 && ln -sf /home/agent/.agent-config/claude/statusline-command.sh /home/agent/.claude/statusline-command.sh \
 && printf '%s\n' \
      '{' \
      '  "statusLine": { "type": "command", "command": "~/.claude/statusline-command.sh" }' \
      '}' > /home/agent/.claude/settings.json \
 && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.codex/AGENTS.md \
 && ln -sf /home/agent/.agent-config/skills /home/agent/.codex/skills \
 && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.gemini/GEMINI.md \
 && ln -sf /home/agent/.agent-config/skills /home/agent/.gemini/skills \
 && ln -sf /home/agent/.agent-config/AGENTS.md /home/agent/.vibe/AGENTS.md \
 && ln -sf /home/agent/.agent-config/skills /home/agent/.vibe/skills


# Default command
CMD ["/bin/bash"]
