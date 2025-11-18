# LLM CLI Development Container

A largely secure and isolated Docker environment for experimenting with AI coding assistants including OpenAI Codex, Google Gemini CLI, and Claude Code.

## Purpose
This container provides a sandboxed environment to explore and test LLM-powered coding tools without compromising your host system's security. It combines filesystem isolation, network restrictions, and a comfortable zsh development environment.

## Key Features
- **Multi-AI Support**: Pre-configured for Codex CLI and Gemini CLI. Exentsible to Claude Code.
- **Network Isolation**: Firewall-based whitelist approach (inspired by Anthropic's Claude Code devcontainer)
- **Filesystem Isolation**: Only explicitly mounted directories are accessible
- **Credential Management**: Secure mounting of OAuth tokens from host machine
- **Modern Shell**: zsh shell with oh-my-zsh plugins (autosuggestions, syntax highlighting) and Starship prompt

## Architecture

### Core Files
- **`Dockerfile`**: Defines the container image with Ubuntu 24.04, Node.js 20, and AI CLIs
- **`docker-compose.yml`**: Container runtime configuration with volume mounts and port forwarding
- **`init-firewall.sh`**: Network security rules (adapted from [Anthropic's reference implementation](https://github.com/anthropics/claude-code))

### Security Strategy
The firewall implements a **default-deny policy**:
1. **Allowed by default**: DNS (port 53), SSH (port 22), localhost, Docker host network
2. **Whitelisted domains**: 
   - npm registry 
   - OpenAI API and authentification services
   - Gemini API and authentification services
   - GitHub
3. **Blocked**: Everything else

### File Organization
```
.
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Runtime configuration
├── init-firewall.sh        # Network security (adapted from Anthropic)
└── test-project/           # Test project directory containing Python "Hello World!" script.
```

## Prerequisites

- Docker and Docker Compose
- Authenticated AI CLI accounts on your host machine:
  - Codex: `codex` (ChatGPT login)
  - Gemini: `gemini` (Google account)

## Quick Start

### 1. Authenticate CLIs on Host (Linux/macOS)
```bash
# Install and authenticate on your host machine first
npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex
npm install -g @google/gemini-cli

# Authenticate each
codex
gemini
```

This stores credentials in `~/.codex`, and `~/.gemini`.

### 2. Clone and Setup
```bash
git clone 
cd docker-sandbox
```

### 3. Build and Run
```bash
# Build the container
docker compose build

# Start the container
docker compose up -d

# Enter the container
docker compose exec claude-code-sandbox zsh
```

### 4. Use AI CLIs
Inside the container:
```bash
# Test Codex
codex "explain this codebase"

# Test Gemini
gemini -p "review this code"
```

## Configuration

### Timezone

Edit `docker-compose.yml`:
```yaml
args:
  TZ: Europe/Berlin  # Change to your timezone
```

### Project Directory

Mount your actual project in `docker-compose.yml`:
```yaml
volumes:
  - ./test-project:/workspace:rw  # Change to your project path
```

### Adding Whitelisted Domains
Edit `init-firewall.sh` and add domains to the `REQUIRED_DOMAINS` array:
```bash
REQUIRED_DOMAINS=(
    "registry.npmjs.org"
    "api.openai.com" 
    "chatgpt.com" 
    ...
    "your-domain.com"  # Add here
)
```

## Platform-Specific Notes
This setup is tested on macOS (Apple Silicon) and Linux.

## Security Considerations
- The firewall provides network isolation but is not impenetrable
- Only use with trusted codebases and projects
- Credentials are mounted with read-write access (needed for OAuth token refresh)
- The `ubuntu` user has limited sudo access (only for running the firewall script)

## License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Contributing
Contributions welcome! Please feel free to submit issues or pull requests.
