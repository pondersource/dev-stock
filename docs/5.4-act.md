# Local GitHub Actions with Act 🚀

[Act](https://github.com/nektos/act) allows you to run your GitHub Actions locally. This is incredibly useful for testing and debugging your workflows before pushing them to GitHub.

## Table of Contents
- [Basic Usage](#basic-usage)
- [Common Commands](#common-commands)
- [Advanced Usage](#advanced-usage)
- [Environment Configuration](#environment-configuration)
- [Troubleshooting](#troubleshooting)

## Basic Usage

Act runs your GitHub Actions workflows locally by spinning up Docker containers that match GitHub's runner environments.

### Command Structure
```bash
act [<event>] [options]
```
- If no event is specified, defaults to "on: push"
- If the workflow only handles one event, that event becomes the default

### Quick Start Examples
```bash
# List all available actions
act -l

# Run the default push event
act

# Run with verbose output
act -v

# Dry run (prints the actions without executing)
act -n
```

## Common Commands

### Event-Based Execution
```bash
# Run pull request event
act pull_request

# Run workflow dispatch event
act workflow_dispatch

# Run release event
act release
```

### Job-Specific Execution
```bash
# Run a specific job by name
act -j build

# Run a job from a specific workflow file
act -j test -W .github/workflows/test.yml

# List jobs for a specific event
act pull_request -l
```

### Artifact Management
```bash
# Collect artifacts to a specific directory
act --artifact-server-path /tmp/artifacts

# Use a custom artifacts directory with a specific job
act -j build --artifact-server-path ./my-artifacts
```

## Advanced Usage

### Platform Selection
```bash
# Use Ubuntu latest
act -P ubuntu-latest=node:16-buster

# Use custom platform image
act -P custom=myorg/myimage:latest
```

### Secret Management
```bash
# Run with secrets file
act --secret-file my.secrets

# Pass individual secrets
act -s MY_SECRET=value

# Use .env file
act --env-file .env
```

### Working Directory
```bash
# Run from a specific directory
act -C /path/to/repo

# Use custom event payload
act pull_request -e event.json
```

## Environment Configuration

### Runner Images
Act supports different runner images to match GitHub's environments:

- **Micro**: ~300MB, sufficient for basic actions
- **Medium**: ~1.2GB, includes more tools
- **Large**: ~3.5GB, closest to GitHub-hosted runners

```bash
# Use micro runner
act -P micro

# Use large runner
act -P large
```

### Configuration File
Create `.actrc` in your home or project directory:
```bash
# Example .actrc
-P ubuntu-latest=node:16-buster
-P ubuntu-18.04=node:16-buster
--secret-file my.secrets
```

## Troubleshooting

### Common Issues

1. **Docker Not Running**
   ```bash
   # Check Docker status
   docker info
   ```

2. **Permission Issues**
   ```bash
   # Run with sudo if needed
   sudo act
   ```

3. **Resource Limits**
   ```bash
   # Increase container memory
   act --container-options "-m 4G"
   ```

### Debug Mode
```bash
# Enable debug logging
act -v

# Maximum verbosity
act -v -v
```

### Cleanup
```bash
# Remove act containers
docker rm $(docker ps -a -q --filter "name=act-*")

# Remove act images
docker rmi $(docker images -q --filter "reference=node:*-buster")
```

For more information and updates, visit the [official Act repository](https://github.com/nektos/act).
