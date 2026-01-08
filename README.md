# AI CLI Development Container

A Docker container for experimenting with AI coding assistants including Claude Code, OpenAI Codex, and Google Gemini CLI.

## Purpose
This container provides a sandboxed environment to explore and test LLM-powered coding tools without compromising your host system's security. It combines filesystem isolation, optional network restrictions, and a comfortable zsh development environment.

## Key Features
- **Multi-AI Support**: Pre-configured for Claude Code, Codex CLI, Gemini CLI
- **Network Isolation**: Optional firewall whitelist approach (inspired by Anthropic's Claude Code devcontainer)
- **Filesystem Isolation**: Only explicitly mounted directories are accessible
- **Credential Management**: Mounting of OAuth tokens from host machine
- **Modern Shell**: zsh shell with oh-my-zsh plugins (autosuggestions, syntax highlighting) and Starship prompt

## Architecture

### Core Files
- **`Dockerfile`**: Defines the container image with Ubuntu 24.04, Node.js 20, and AI CLIs
- **`docker-compose.yml`**: Container runtime configuration with volume mounts and port forwarding
- **`init-firewall.sh`**: Network security rules (adapted from [Anthropic's reference implementation](https://github.com/anthropics/claude-code))

### Optional Network Security Strategy
To handle untrusted code that might exfiltrate an optional firewall can be activated which implements a **default-deny policy**:
1. **Allowed by default**: DNS (port 53), SSH (port 22), localhost, Docker host network
2. **Whitelisted domains**: 
   - npm registry 
   - Claude Code API and authentification services
   - OpenAI API and authentification services
   - Gemini API and authentification
   - GitHub
3. **Blocked**: Everything else

The whitelisted domains can be adjusted in the `init_firewall.sh` script.

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
- Claude Code, Codex, and Gemini CLI logins

## Quick Start

### 1. Authenticate CLIs on Host (Linux/macOS)
While it is possible to authenticate Claude Code from within the container, Codex and Gemini have to be autheticated from the host.
```bash
# Install and authenticate on your host machine first
npm install -g @google/gemini-cli
npm install -g @openai/codex

# Authenticate
codex
gemini
```

This stores credentials in `~/.codex` and `~/.gemini`.

Claude Code can similarly be authenticated from the host. If you chose not to do so and want to mount the credentials, the file `~/claude.json` should be created before starting the container.

Optional: Uninstall CLIs from Host if desired but keep credentials.

### 2. Clone and Setup
```bash
git clone https://github.com/spieseba/docker-sandbox
cd docker-sandbox
```

### 3. Build and Run
```bash
# Build the container
docker compose build

# To start the container 
docker compose up -d sandbox-open # No firewall
docker compose up -d sandbox-closed # With firewall

# Enter the container
docker compose exec sandbox-open zsh # No firewall
docker compose exec sandbox-closed zsh # With firewall
```

### 4. Authenticate Claude Code
Inside the container run
```bash
claude 
```
and follow instructions to authenticate.

### 5. Use AI CLIs
Inside the container:
```bash
# Test Claude Code
claude -p "review this code"

# Test Codex
codex "explain this codebase"

# Test Gemini CLI
gemini -p "What does this code do?"
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
    # Claude Code
    "api.anthropic.com"
    ...
    "your-domain.com"  # Add here
)
```

## Platform-Specific Notes
This setup is tested on macOS Tahoe (Apple Silicon) and Ubuntu 24.04.

## Security Considerations
- The firewall provides network isolation but is not impenetrable
- Only use with trusted codebases and projects
- Credentials are mounted with read-write access (needed for OAuth token refresh)
- The `ubuntu` user has limited sudo access (only for running the firewall script)

## License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Contributing
Contributions welcome! Please feel free to submit issues or pull requests.
