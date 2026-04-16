# AI CLI Development Container

A Docker sandbox for experimenting with AI coding assistants (Claude Code, OpenAI Codex) without giving them access to your host system.

## What this provides

- Pre-installed CLIs: Claude Code, Codex
- Filesystem isolation: only the mounted workspace is visible to the agent
- Persistent credentials: OAuth tokens mounted from the host so you authenticate once
- Comfortable shell: zsh with oh-my-zsh plugins and Starship prompt
- Passwordless `sudo` inside the container for convenience (`apt install`, etc.)

The container has full internet access. This is a **convenience sandbox**, not a hardened environment — use it for playing with agents on your own projects, not for running untrusted code.

## File layout
```
.
├── Dockerfile           # Container image definition
├── docker-compose.yaml  # Runtime configuration
└── workspace/           # Mounted into the container at ~/workspace
```

## Prerequisites

- Docker and Docker Compose
- Claude Code and Codex logins

## Setup

### 1. Create credential directories on the host

Credentials are mounted from the host so they survive container rebuilds. These paths must exist before the first `docker compose up`, or Docker will create them as root-owned and cause permission errors:

```bash
mkdir -p ~/.claude ~/.codex
touch ~/.claude.json
```

| Tool        | Credential location(s)            |
|-------------|-----------------------------------|
| Claude Code | `~/.claude/` and `~/.claude.json` |
| Codex       | `~/.codex/`                       |

### 2. Clone and build

```bash
git clone https://github.com/spieseba/docker-sandbox
cd docker-sandbox
docker compose build
```

### 3. Start and enter the container

```bash
docker compose up -d sandbox      # Start (detached, persists)
docker compose exec sandbox zsh   # Open a shell
```

Exit the shell with `exit` or Ctrl-D. The container keeps running; re-enter anytime with `docker compose exec sandbox zsh`.

To stop and remove the container:

```bash
docker compose down
```

### 4. Authenticate the CLIs (first run only)

Inside the container:

```bash
claude   # Follow prompts
codex    # Follow prompts
```

Credentials are written to the mounted host directories, so you won't need to re-auth after rebuilds.

### 5. Use them

```bash
cd ~/workspace
claude -p "review this code"
codex "explain this codebase"
```

## Configuration

**Timezone** — edit `docker-compose.yaml`:

```yaml
args:
  TZ: Europe/Berlin
```

**Workspace path** — the `./workspace` directory on the host is mounted to `~/workspace` in the container. Put your projects there, or change the mount in `docker-compose.yaml`:

```yaml
volumes:
  - /path/to/your/project:/home/agent/workspace:rw
```

## Security notes

- The container has broad sudo and full internet access. Don't run untrusted code in it.
- Credentials are mounted read-write (required for OAuth token refresh), so a misbehaving agent can corrupt or potentially leak them.
- The container cannot access your host filesystem beyond the mounted workspace and credential directories.

## Platform support

Tested on macOS (Apple Silicon) and Ubuntu 24.04.

## License

[MIT](https://opensource.org/licenses/MIT)
