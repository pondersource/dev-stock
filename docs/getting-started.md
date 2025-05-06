# Getting Started Guide

This guide will help you get started with Development Stockpile for EFSS development and testing.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Development Environment](#development-environment)
- [Next Steps](#next-steps)

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
- Docker Engine (20.10.0 or higher)
- Docker Compose (2.0.0 or higher)
- Git

### System Requirements
- At least 4GB of RAM
- 20GB of free disk space
- Internet connection for pulling Docker images

### Optional Tools
- Visual Studio Code with Docker extension
- Act for local GitHub Actions testing
- Xdebug for PHP debugging

## Installation

1. Clone the repository:
```bash
git clone https://github.com/pondersource/dev-stock.git
cd dev-stock
```

2. Pull required Docker images:
```bash
./docker/pull/all.sh
```

3. Install Node.js dependencies:
```bash
npm install
```

4. Copy and configure environment variables:
```bash
cp .env.example .env
# Edit .env with your preferred settings
```

## Basic Usage

### Running Tests

The OCM Test Suite supports various test scenarios. Before running any tests, please check our [Platform Compatibility Matrix](../compatibility-matrix.md) to ensure your target platforms and versions are compatible with the feature you want to test.

1. Login Tests:
```bash
./dev/ocm-test-suite.sh login nextcloud v30.0.2 dev chrome
```

2. Share Link Tests:
```bash
./dev/ocm-test-suite.sh share-link nextcloud v30.0.2 dev chrome owncloud v10.15.0
```

3. Share With Tests:
```bash
./dev/ocm-test-suite.sh share-with nextcloud v30.0.2 dev chrome nextcloud v30.0.2
```

4. Invite Link Tests:
```bash
./dev/ocm-test-suite.sh invite-link nextcloud-sm v27.1.11-sm ci chrome owncloud-sm v10.15.0-sm
```

### Test Command Structure
```bash
./dev/ocm-test-suite.sh <category> <platform1> <version1> <mode> <browser> [platform2] [version2]
```

- `category`: login, share-link, share-with, or invite-link
- `platform1`: nextcloud, owncloud, ocmstub, seafile, or ocis
- `version1`: platform version (e.g., v30.0.2)
- `mode`: dev or ci
- `browser`: chrome or firefox
- `platform2`: (optional) second platform for cross-platform tests
- `version2`: (optional) version of the second platform

## Development Environment

### Directory Structure
```
dev-stock/
├── cypress/          # Test suites and configurations
├── docker/           # Docker configurations and images
│   ├── build/       # Image build scripts
│   ├── configs/     # Platform configurations
│   ├── pull/        # Image pull scripts
│   └── scripts/     # Utility scripts
├── docs/            # Documentation
├── .github/         # GitHub Actions workflows
└── dev/             # Development scripts
```

### Common Development Tasks

1. Building custom images:
```bash
./docker/build/all.sh
```

2. Cleaning previous test data and docker containers:
```bash
./scripts/clean.sh
```

## Next Steps

After getting started, you might want to:

1. Learn about [Docker Images](../docker-images.md)
2. Explore the [OCM Test Suite](../testing/test-suite.md)
3. Set up [Xdebug](../xdebug.md) for debugging
4. Configure [GitHub Actions](./act.md) for CI/CD

## Support

If you encounter any issues:
1. Check the logs using `docker logs <container_name>`
2. Review test screenshots in `cypress/screenshots`
3. Search existing GitHub issues
4. Create a new issue with detailed reproduction steps

## Contributing

We welcome contributions! Please see our [Contributing Guide](../../CONTRIBUTING.md) for details.
