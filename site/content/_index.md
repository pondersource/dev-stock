+++
title = "OCM Test Suite Gallery"
sort_by = "none"
template = "gallery.html"
page_template = "gallery.html"
+++

Welcome to the OCM Test Suite Gallery! This page showcases automated test recordings for various OCM (Open Cloud Mesh) features. Each test demonstrates the interoperability between different cloud storage platforms.

The tests are organized into four main categories:

1. **Authentication Tests** 🔐 - Verify user authentication and session management
2. **Public Link Sharing** 🔗 - Test creation and access of public share links
3. **Direct User Sharing** 🤝 - Validate direct file/folder sharing between users
4. **ScienceMesh Federation** 🌐 - Test federated sharing via ScienceMesh

Each test card shows:
- A video recording of the test execution
- Current test status (passing/failing)
- Test description and details

Click on any video to watch the test execution in detail. The status badge below each video shows the current state of that particular test in our continuous integration pipeline.

## Overview
This matrix displays the current compatibility status of various file sharing and collaboration features across different platforms. Each cell shows the real-time status of automated tests between different platform combinations.

## Status Indicators 📊

- **![Active](https://img.shields.io/badge/Active-2ea44f?style=flat-square)** - Test workflow exists and is actively maintained
- **![Planned](https://img.shields.io/badge/Planned-0969da?style=flat-square)** - Implementation is planned but not yet available
- **![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square)** - Combination is not supported due to technical limitations

## Test Results Legend 🎯

Each test result badge indicates:
- ✅ **Green** - All tests passing
- ❌ **Red** - One or more tests failing
- 🕒 **Yellow** - Tests in progress or pending
- ⚪ **Gray** - Tests not recently run

Click any badge to view detailed test results and logs in GitHub Actions. Hover over the badge to see available test artifacts for download.

## Authentication Tests 🔐

Tests platform authentication mechanisms and user session management.

| Platform | Nextcloud v27.1.11 | Nextcloud v28.0.14 | oCIS v5.0.9 | OcmStub v1.0.0 | ownCloud v10.15.0 | Seafile v11.0.5 |
|----------|-------------------|-------------------|-------------|----------------|------------------|----------------|
| **Status** | [![NC v27.1.11](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v27.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v27.yml) | [![NC v28.0.14](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v28.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v28.yml) | [![oCIS v5.0.9](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocis-v5.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocis-v5.yml) | [![OcmStub v1.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocmstub-v1.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocmstub-v1.yml) | [![OC v10.15.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-owncloud-v10.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-owncloud-v10.yml) | [![Seafile v11.0.5](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-seafile-v11.yml?branch=main&style=flat-square&label=Auth)](https://github.com/pondersource/dev-stock/actions/workflows/login-seafile-v11.yml) |

## Public Link Sharing Tests 🔗

Validates creation, management, and access of public share links across platforms.

| Source Platform ➜ Target Platform | Nextcloud v27.1.11 | Nextcloud v28.0.14 | ownCloud v10.15.0 |
|----------------------------------|-------------------|-------------------|------------------|
| **Nextcloud v27.1.11**           | [![NC27 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-nc-v27.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-nc-v27.yml) | [![NC27 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-nc-v28.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-nc-v28.yml) | [![NC27 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-oc-v10.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-oc-v10.yml) |
| **Nextcloud v28.0.14**           | [![NC28 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-nc-v27.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-nc-v27.yml) | [![NC28 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-nc-v28.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-nc-v28.yml) | [![NC28 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-oc-v10.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-oc-v10.yml) |
| **ownCloud v10.15.0**            | [![OC10 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-nc-v27.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-nc-v27.yml) | [![OC10 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-nc-v28.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-nc-v28.yml) | [![OC10 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-oc-v10.yml?branch=main&style=flat-square&label=Link)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-oc-v10.yml) |

## Direct User Sharing Tests 🤝

Tests direct file and folder sharing capabilities between users across different platforms.

| Source Platform ➜ Target Platform | Nextcloud v27.1.11 | Nextcloud v28.0.14 | OcmStub v1.0.0 | ownCloud v10.15.0 | Seafile v11.0.5 |
|----------------------------------|-------------------|-------------------|----------------|------------------|----------------|
| **Nextcloud v27.1.11**           | [![NC27 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v27.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v27.yml) | [![NC27 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v28.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v28.yml) | [![NC27 ➜ OS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-os-v1.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-os-v1.yml) | [![NC27 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-oc-v10.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-oc-v10.yml) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) |
| **Nextcloud v28.0.14**           | [![NC28 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v27.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v27.yml) | [![NC28 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v28.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v28.yml) | [![NC28 ➜ OS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-os-v1.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-os-v1.yml) | [![NC28 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-oc-v10.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-oc-v10.yml) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) |
| **OcmStub v1.0.0**               | [![OS ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-os-v1-nc-v27.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-os-v1-nc-v27.yml) | [![OS ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-os-v1-nc-v28.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-os-v1-nc-v28.yml) | [![OS ➜ OS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-os-v1-os-v1.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-os-v1-os-v1.yml) | [![OS ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-os-v1-oc-v10.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-os-v1-oc-v10.yml) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) |
| **ownCloud v10.15.0**            | [![OC10 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v27.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v27.yml) | [![OC10 ➜ NC28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v28.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v28.yml) | [![OC10 ➜ OS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-os-v1.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-os-v1.yml) | [![OC10 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-oc-v10.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-oc-v10.yml) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) |
| **Seafile v11.0.5**              | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) | ![Unsupported](https://img.shields.io/badge/Unsupported-red?style=flat-square) | [![SF ➜ SF](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-sf-v11-sf-v11.yml?branch=main&style=flat-square&label=Share)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-sf-v11-sf-v11.yml) |

## ScienceMesh Federation Tests 🌐

Tests federated sharing capabilities between ScienceMesh-enabled platforms.

| Source Platform ➜ Target Platform | Nextcloud v27.1.11 with ScienceMesh | oCIS v5.0.9 | ownCloud v10.15.0 with ScienceMesh |
|----------------------------------|-------------------------------------|-------------|-----------------------------------|
| **Nextcloud v27.1.11 with ScienceMesh** | [![NC27 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-sm-v27-nc-sm-v27.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-sm-v27-nc-sm-v27.yml) | [![NC27 ➜ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-sm-v27-ocis-v5.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-sm-v27-ocis-v5.yml) | [![NC27 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-sm-v27-oc-sm-v10.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-sm-v27-oc-sm-v10.yml) |
| **oCIS v5.0.9** | [![oCIS ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-nc-sm-v27.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-nc-sm-v27.yml) | [![oCIS ➜ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-ocis-v5.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-ocis-v5.yml) | [![oCIS ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-oc-sm-v10.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-oc-sm-v10.yml) |
| **ownCloud v10.15.0 with ScienceMesh** | [![OC10 ➜ NC27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-sm-v10-nc-sm-v27.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-sm-v10-nc-sm-v27.yml) | [![OC10 ➜ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-sm-v10-ocis-v5.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-sm-v10-ocis-v5.yml) | [![OC10 ➜ OC10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-sm-v10-oc-sm-v10.yml?branch=main&style=flat-square&label=ScienceMesh)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-sm-v10-oc-sm-v10.yml) | 