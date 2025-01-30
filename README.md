# Development Stockpile 🛠️

<div align="center">

[![Project Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)](https://github.com/pondersource/dev-stock)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![OCM Standard](https://img.shields.io/badge/OCM-W3C_Community_Group-orange?style=for-the-badge)](https://www.w3.org/community/ocm/)

Your complete toolkit for Enterprise File Sync & Share (EFSS) development and testing 🚀

[Getting Started](docs/guides/getting-started.md) •
[Documentation](#documentation) •
[Contributing](CONTRIBUTING.md)

</div>

## 🌟 Overview

Development Stockpile is a comprehensive collection of Docker images and testing tools designed to streamline the development and testing of Enterprise File Sync & Share (EFSS) applications. Our primary focus is on enabling seamless interoperability testing between different EFSS platforms through the Open Cloud Mesh (OCM) standard.

### Why Development Stockpile?

- 🔄 **Complete Testing Environment**: Pre-configured Docker images for major EFSS platforms including Nextcloud, ownCloud, and OCM Stub
- 🤝 **Interoperability Focus**: Built-in support for OCM testing between different platforms and versions
- 🧪 **Comprehensive Test Suite**: Automated testing for login, sharing, and invitation workflows
- 🛠️ **Developer Friendly**: Easy-to-use scripts and containerized development environment
- 🔍 **Extensive Platform Support**: Support for multiple EFSS versions and configurations

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/pondersource/dev-stock.git
cd dev-stock

# Pull required Docker images
./docker/pull/all.sh

# Run your first test (example with Nextcloud)
./dev/ocm-test-suite.sh login nextcloud v30.0.2 dev chrome
```

For detailed setup instructions, see our [Getting Started Guide](docs/guides/getting-started.md).

## 📚 Documentation

### Core Documentation
- [Getting Started Guide](docs/guides/getting-started.md)
- [Docker Images](docs/docker-images.md)
- [OCM Test Suite](docs/testing/test-suite.md)
- [Platform Compatibility Matrix](docs/compatibility-matrix.md)

### Platform Integration
- [Nextcloud Integration](docs/guides/nextcloud.md)
- [ownCloud Integration](docs/guides/owncloud.md)
- [OCM Stub Usage](docs/guides/ocmstub.md)

### Other Topics
- [ScienceMesh Integration](docs/scienecemesh.md)
- [SOLID RemoteStorage](docs/solid-remotestorage.md)
- [Debugging with Xdebug](docs/xdebug.md)
- [GitHub Actions Integration](docs/guides/act.md)

## 🔧 Supported Platforms

- **Nextcloud**: v27.x, v28.x, v30.x
- **ownCloud**: v10.x
- **OCM Stub**: v1.x
- **Seafile**: v11.x
- **OCIS**: v5.x

## 🤝 Contributing

We welcome contributions! Whether it's adding support for new platforms, improving documentation, or fixing bugs, please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ by PonderSource
</div>
