# Colima Setup

Colima is the **default** container runtime for this dotfiles setup. It's a lightweight alternative to Docker Desktop with significantly lower resource usage.

Docker Desktop is still available as a fallback option if needed, but Colima is recommended for day-to-day development.

## Features

- **Lightweight**: Uses 50-75% less memory than Docker Desktop
- **Fast**: Faster startup times with Apple Virtualization Framework (vz)
- **Compatible**: Works with Docker CLI, docker-compose, and devcontainers
- **Flexible**: Easy to customize CPU, memory, and disk allocation

## Installation

Colima is installed via Homebrew (see `tools/homebrew/Brewfile`):

```bash
brew install colima docker docker-compose
```

## Setup

Run the setup script to start Colima with optimized settings:

```bash
./setup.sh
```

This will:
- Start Colima with 4 CPUs, 8GB RAM, and 60GB disk
- Configure the Docker socket symlink
- Set the Docker context to Colima

## Usage

### Basic Commands

```bash
# Start Colima
colima start

# Stop Colima
colima stop

# Check status
colima status

# Restart Colima
colima restart
```

### Adjusting Resources

To change CPU, memory, or disk allocation:

1. Stop Colima: `colima stop`
2. Delete the VM: `colima delete`
3. Edit `setup.sh` with desired resources
4. Run `./setup.sh` to recreate with new settings

Or use command-line flags:

```bash
colima start --cpu 6 --memory 12 --disk 100
```

### Switching Between Colima and Docker Desktop

If you need to switch back to Docker Desktop temporarily:

```bash
# Stop Colima
colima stop

# Switch Docker context
docker context use desktop-linux

# Start Docker Desktop from menu bar
```

To switch back to Colima:

```bash
# Quit Docker Desktop
# Start Colima
colima start

# Docker context is already set to colima
```

## Devcontainers

Devcontainers work seamlessly with Colima. VS Code and Cursor will automatically detect the Docker socket.

## Troubleshooting

### Devcontainer not connecting

Check the Docker socket:
```bash
ls -la /var/run/docker.sock
```

It should point to `~/.colima/default/docker.sock`. If not, run:
```bash
sudo rm /var/run/docker.sock
sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
```

### Low disk space

Increase disk size (requires recreation):
```bash
colima delete
colima start --disk 100  # 100GB
```

### Performance issues

Try adjusting CPU/memory allocation in `setup.sh`.

## Configuration

Colima's configuration is stored in:
- VM data: `~/.colima/default/`
- Config: `~/.colima/default/colima.yaml`

## Resources

- [Colima GitHub](https://github.com/abiosoft/colima)
- [Docker compatibility](https://github.com/abiosoft/colima/blob/main/docs/DOCKER.md)
