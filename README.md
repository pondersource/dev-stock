# Development Stockpile 🛠️

<div align="center">

[![Project Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)](https://github.com/pondersource/dev-stock)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![OCM Standard](https://img.shields.io/badge/OCM-W3C_Community_Group-orange?style=for-the-badge)](https://www.w3.org/community/ocm/)

Your complete toolkit for Enterprise File Sync & Share (EFSS) development and testing 🚀

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
./dev/ocm-test-suite.sh login nextcloud v30.0.11 dev chrome
```

For detailed setup instructions, see our [Development Guide](./docs/5-development-guide.md).

## 📚 Documentation

### Core Documentation
1. [Overview](./docs/1-overview.md)
2. [OCM Test Suite Architecture](./docs/2-architecture.md)
    - [Test Categories](./docs/2.2-test-categories.md)
    - [Platform Compatibility](./docs/2.3-platform-compatibility.md)
        - [OCM Test Suite Documentation](./docs/2.3.2-test-suite.md)
3. [Docker Management](./docs/3-docker-management.md)
    - [Docker Images](./docs/3.2-docker-images.md)
        - [Detailed Docker Images Documentation](./docs/3.2.2-detailed-docker-images.md)
    - [Environment Management](./docs/3.3-environment-management.md)
4. [Result Visualization](./docs/4-result-visualization.md)
    - [OCM Compatibility Matrix](./docs/4.2-compatibility-matrix.md)
5. [Development Guide](./docs/5-development-guide.md)
    - [Local Setup](./docs/5.2-local-setup.md)
    - [Debugging PHP with Xdebug v3 inside Docker using VSCode](./docs/5.3-xdebug.md)
    - [Local GitHub Actions with Act](./docs/5.4-act.md)

### Other Topics
- [SOLID RemoteStorage](./docs/99-appendix-solid-remotestorage.md)

## 🔧 Supported Platforms

- **Nextcloud**: v27.x, v28.x, v30.x, v31.x, v32.x
- **ownCloud**: v10.x
- **OCM Stub**: v1.x
- **Seafile**: v11.x
- **OCIS**: v5.x v7.x

## 🤝 Contributing

We welcome contributions! Whether it's adding support for new platforms, improving documentation, or fixing bugs, please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ by PonderSource
</div>
