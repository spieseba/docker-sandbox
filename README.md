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
   - Claude Code API and authentication services
   - OpenAI API and authentication services
   - Gemini API and authentication services
   - GitHub
3. **Blocked**: Everything else

The whitelisted domains can be adjusted in the `init-firewall.sh` script.

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

### 1. Create credential files and folders on host (Linux/macOS)

Claude Code, Codex, and Gemini can all be authenticated in headless mode from within the container. Credentials are stored in:

| Tool        | Credential location(s)              |
|-------------|-------------------------------------|
| Claude Code | `~/.claude/` and `~/.claude.json`   |
| Codex       | `~/.codex/`                         |
| Gemini      | `~/.gemini/`                        |

To persist credentials on your host, these paths are mounted into the container. They must exist on the host before starting the container, otherwise Docker will create them as root-owned empty directories which may cause permission errors inside the container.

```bash
mkdir -p ~/.claude ~/.codex ~/.gemini
touch ~/.claude.json
```

### 2. Clone and setup

```bash
git clone https://github.com/spieseba/docker-sandbox
cd docker-sandbox
```

### 3. Build and run

```bash
# Build the container
docker compose build

# Start the container (choose one)
docker compose up -d sandbox-open    # Without firewall
docker compose up -d sandbox-closed  # With firewall

# Enter the container
docker compose exec sandbox-open zsh    # Without firewall
docker compose exec sandbox-closed zsh  # With firewall
```

### 4. Authenticate CLI tools

Inside the container, run each tool and follow the authentication prompts:

```bash
claude   # Follow prompts to authenticate
codex    # Follow prompts to authenticate  
gemini   # Follow prompts to authenticate
```

### 5. Use the AI CLIs

Once authenticated, you can use the tools:

```bash
claude -p "review this code"
codex "explain this codebase"
gemini -p "what does this code do?"
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
