# AI CLI Development Container

A self-contained Docker sandbox for experimenting with AI coding assistants
without giving them access to your host system.

## What this provides

- Built on the latest Fedora base image
- Pre-installed CLIs: Claude Code and Mistral Vibe; Codex and Antigravity CLI are opt-in build args (see [Configuration](#configuration))
- Filesystem isolation: only the mounted workspace is visible to the agent
- Self-contained: no host credentials or config are mounted in; authenticate inside the container
- Baked-in agent config: instructions, shared skills, CLI settings, and statuslines are pulled from [spieseba/agent-config](https://github.com/spieseba/agent-config) at build time and wired into each installed CLI
- Two service variants: CPU-only (`sandbox`) and GPU-enabled (`sandbox-gpu`)
- Passwordless `sudo` inside the container for convenience (`dnf install`, etc.)

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
- For `sandbox-gpu` only: an NVIDIA GPU with drivers and the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  installed on the host

## Setup

### 1. Clone and build

```bash
git clone https://github.com/spieseba/docker-sandbox
cd docker-sandbox
docker compose build
```

### 2. Start and enter the container

Two services share the same image:

- `sandbox` — CPU-only
- `sandbox-gpu` — passes an NVIDIA GPU through to the container (see
  [Prerequisites](#prerequisites))

```bash
docker compose up -d sandbox      # Start (detached, persists)
docker compose exec sandbox bash  # Open a shell
```

For the GPU variant, use `sandbox-gpu` instead of `sandbox` in both commands.
Verify GPU access inside the container with `nvidia-smi`.

Exit the shell with `exit` or Ctrl-D. The container keeps running; re-enter
anytime with `docker compose exec sandbox bash`.

To stop and remove the container(s):

```bash
docker compose down
```

### 3. Authenticate the CLIs

The sandbox is self-contained, so credentials are **not** mounted from the host.
Authenticate inside the container:

```bash
claude   # Follow prompts; likewise: vibe (and codex / agy if enabled)
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

**Optional CLIs** — all four CLIs are build args in `docker-compose.yaml`.
Claude Code, Mistral Vibe, Codex, and Antigravity are on by default; comment them out to disable.
Rebuild after changing:

```yaml
args:
  INSTALL_CLAUDE: "true"
  INSTALL_VIBE: "true"
  INSTALL_CODEX: "true"
  INSTALL_ANTIGRAVITY: "true"
```

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

**Agent config** — instructions, skills, CLI settings, and statuslines come from
[spieseba/agent-config](https://github.com/spieseba/agent-config), cloned into
`~/.agent-config` at build time and installed into each CLI's config dir. To use
a fork, override the build arg:

```yaml
args:
  AGENT_CONFIG_REPO: https://github.com/you/your-agent-config.git
```

`git -C ~/.agent-config pull` updates symlinked instructions and skills live.
Rebuild the image to refresh copied CLI settings and scripts.

## Security notes

- The container has broad sudo and full internet access. Don't run untrusted code in it.
- SELinux labeling is disabled for the container (`security_opt: label=disable`
  in `docker-compose.yaml`) so the workspace mount works out of the box on
  SELinux hosts (e.g. Fedora). Filesystem isolation still holds. It relies on
  namespaces, not SELinux. But this removes SELinux as an extra confinement
  layer.
- No host credentials or config are mounted, so the container cannot leak them.
- The container cannot access your host filesystem beyond the mounted workspace.

## Platform support

Tested on macOS Tahoe 26.5 (Apple Silicon) and Fedora 44. The `sandbox-gpu`
service requires an NVIDIA GPU and is therefore Linux-only.

## License

[MIT](https://opensource.org/licenses/MIT)
