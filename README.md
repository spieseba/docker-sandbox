# AI CLI Development Container

A self-contained Docker sandbox for experimenting with AI coding assistants
without giving them access to your host system.

## What this provides

- Pre-installed CLIs: Claude Code, Codex, Mistral Vibe, Antigravity CLI — remove in Dockerfile as desired
- Filesystem isolation: only the mounted workspace is visible to the agent
- Self-contained: no host credentials or config are mounted in; authenticate inside the container
- Baked-in agent config: AGENTS.md/CLAUDE.md, shared skills, and the Claude Code statusline are pulled from [spieseba/agent-config](https://github.com/spieseba/agent-config) at build time and wired into all four CLIs
- Passwordless `sudo` inside the container for convenience (`apt install`, etc.)

The container has full internet access. This is a **convenience sandbox**, not a
hardened environment — use it for playing with agents on your own projects, not
for running untrusted code.

## File layout
```
.
├── Dockerfile           # Container image definition
├── docker-compose.yaml  # Runtime configuration
└── workspace/           # Mounted into the container at ~/workspace
```

## Prerequisites

- Docker and Docker Compose

## Setup

### 1. Clone and build

```bash
git clone https://github.com/spieseba/docker-sandbox
cd docker-sandbox
docker compose build
```

### 2. Start and enter the container

```bash
docker compose up -d sandbox      # Start (detached, persists)
docker compose exec sandbox bash  # Open a shell
```

Exit the shell with `exit` or Ctrl-D. The container keeps running; re-enter
anytime with `docker compose exec sandbox bash`.

To stop and remove the container:

```bash
docker compose down
```

### 3. Authenticate the CLIs

The sandbox is self-contained, so credentials are **not** mounted from the host.
Authenticate inside the container:

```bash
claude   # Follow prompts; likewise: codex, vibe, antigravity
```

> **Note:** Because nothing is mounted into the CLI config directories, logins
> live only inside the container and do **not** survive a rebuild
> (`docker compose build`). If you want auth to persist across rebuilds, mount
> the relevant credential directories yourself in `docker-compose.yaml` (e.g.
> `~/.claude:/home/agent/.claude:rw`) — at the cost of giving the container
> access to those host files.

### 4. Use them

```bash
cd ~/workspace
claude
```

## Configuration

**Timezone** — edit `docker-compose.yaml`:

```yaml
args:
  TZ: Europe/Berlin
```

**Workspace path** — the `./workspace` directory on the host is mounted to
`~/workspace` in the container. Put your projects there, or change the mount in
`docker-compose.yaml`:

```yaml
volumes:
  - /path/to/your/project:/home/agent/workspace:rw
```

**Agent config** — AGENTS.md, skills, and the statusline come from
[spieseba/agent-config](https://github.com/spieseba/agent-config), cloned into
`~/.agent-config` at build time and symlinked into each CLI's config dir. To use
a fork, override the build arg:

```yaml
args:
  AGENT_CONFIG_REPO: https://github.com/you/your-agent-config.git
```

Update it live inside the container with `git -C ~/.agent-config pull`.

## Security notes

- The container has broad sudo and full internet access. Don't run untrusted code in it.
- No host credentials or config are mounted, so the container cannot leak them.
- The container cannot access your host filesystem beyond the mounted workspace.

## Platform support

Tested on macOS Tahoe 26.5 (Apple Silicon) and Fedora 44.

## License

[MIT](https://opensource.org/licenses/MIT)
