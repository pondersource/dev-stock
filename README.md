# Development Stockpile 🛠️📦  
A collection of Docker images and scripts designed to set up a complete development environment for building and testing applications. 🚀

## Our Dockerized EFSS Versions 📂
**EFSS (Enterprise File Sync and Share)** solutions are software platforms designed to enable organizations to securely share and synchronize files, both internally and externally.
These systems are built to ensure data integrity, compliance, and accessibility, making them essential for modern collaboration. 
Some popular EFSS platforms include **Nextcloud** and **ownCloud**, which provide robust, open-source solutions for enterprise file management.

### Nextcloud Versions

| **Repository**                   | **Tag**         | **Branch**                                                                | **Upstream**                                                                 |
|----------------------------------|-----------------|---------------------------------------------------------------------------|------------------------------------------------------------------------------|
| pondersource/dev-stock-nextcloud | latest, v30.0.0 | [v30.0.0](https://github.com/nextcloud/server/releases/tag/v30.0.0)       | [Official Nextcloud Server](https://github.com/nextcloud/server)              |
| pondersource/dev-stock-nextcloud | v29.0.8         | [v29.0.8](https://github.com/nextcloud/server/releases/tag/v29.0.8)       | [Official Nextcloud Server](https://github.com/nextcloud/server)              |
| pondersource/dev-stock-nextcloud | v28.0.12        | [v28.0.12](https://github.com/nextcloud/server/releases/tag/v28.0.12)     | [Official Nextcloud Server](https://github.com/nextcloud/server)              |
| pondersource/dev-stock-nextcloud | v27.1.10        | [v27.1.10](https://github.com/nextcloud/server/releases/tag/v27.1.10)     | [Official Nextcloud Server](https://github.com/nextcloud/server)              |

---

### ownCloud Versions

| **Repository**                   | **Tag**       | **Branch**                                                                 | **Upstream**                                                                 |
|----------------------------------|---------------|----------------------------------------------------------------------------|------------------------------------------------------------------------------|
| pondersource/dev-stock-owncloud  | v10.14.0      | [v10.14.0](https://github.com/owncloud/core/releases/tag/v10.14.0)         | [Official ownCloud Core](https://github.com/owncloud/core)                   |


#### Docker Pull Commands
To pull the Docker images for EFSS, use the following commands:

```bash
# Pull the latest version of Nextcloud
docker pull pondersource/dev-stock-nextcloud:latest

# Pull a specific version of Nextcloud
docker pull pondersource/dev-stock-nextcloud:v30.0.0
docker pull pondersource/dev-stock-nextcloud:v29.0.8

# Pull a specific version of ownCloud
docker pull pondersource/dev-stock-owncloud:v10.14.0
```

# Open Cloud Mesh Test Suite 🌐🧪

## What is the Open Cloud Mesh Test Suite? 🤔

The **Open Cloud Mesh (OCM) Test Suite** is a comprehensive collection of automated tests designed to validate interoperability between different **Enterprise File Sync and Share (EFSS)** platforms that implement the **Open Cloud Mesh** standard. The Open Cloud Mesh API specification is an open source, community-driven project. The project is hosted as a [W3C Community Group](https://www.w3.org/community/ocm/).

---

## Why Open Cloud Mesh? 🤝

**Open Cloud Mesh (OCM)** aims to bridge the gap between different EFSS systems, allowing organizations to collaborate efficiently, regardless of the platform they use. By implementing OCM:
- **Interoperability**: Files can be shared across platforms like **Nextcloud**, **ownCloud**, **Seafile**, and others.
- **Vendor Independence**: Organizations are not locked into a single EFSS solution.
- **Enhanced Collaboration**: Facilitates file sharing between users and organizations in a secure, standard-compliant way.

---

## Features of the OCM Test Suite 🚀

1. **Cross-Platform Validation**:
   - Ensures compatibility between popular EFSS platforms like **Nextcloud**, **ownCloud**, **Seafile**, and **oCIS**.
   
2. **Comprehensive Coverage**:
   - Includes tests for **file sharing**, **link sharing**, **user invitations**.

3. **Version-Aware Testing**:
   - Validates platform behavior across multiple versions, ensuring backward compatibility.

4. **Automated CI Integration**:
   - Runs tests on a **Continuous Integration (CI)** pipeline for every new EFSS version release.

---

## Key Test Categories 📝

1. **Login Tests**:
   - Simple authentication for different EFSS platforms.

2. **Share Link Tests**:
   - Tests the ability to share files and directories via public links across platforms and the ability to add
   a public link share to your own EFSS.

3. **Share With Tests**:
   - Validates sharing files directly with specific users on other EFSS platforms.

4. **Invite Link Tests**:
   - Checks the invitation workflows, enabling users to invite external collaborators seamlessly.

---

## Supported Platforms 📋

The test suite currently supports:
- **Nextcloud** (v27, v28, v29, v30)
- **ownCloud** (v10.14.0)
- **oCIS** (v5.0.6)
- **Seafile** (v11.0.5)
- **OcmStub** (v1.0.0)

---

## How It Works 🔧

1. **Dockerized Test Environment**:
   - The test suite uses Docker containers to simulate various EFSS environments, ensuring isolation and reproducibility.

2. **End-to-End Testing with Headless Cypress**:
   - The test suite uses **Cypress** to run end-to-end (E2E) tests in a headless browser environment.
   - These tests simulate real user interactions across EFSS platforms, ensuring workflows like login, file sharing, and invitations work seamlessly.


3. **CI Integration**:
   - Each test runs as part of a **GitHub Actions CI pipeline**, with real-time feedback via badges.

4. **Status Reporting**:
   - Results are displayed as status badges in a grid format, showing the success or failure of tests for each platform/version combination.

---

## Benefits of the Open Cloud Mesh Test Suite 🌟

- **Interoperability Assurance**: Confirms that users can collaborate across EFSS platforms without issues.

---

### Learn More 🔗

To learn more about the **Open Cloud Mesh** standard, visit: [OCM-API](https://github.com/cs3org/OCM-API)


# OCM Compatibility Results 🚦

## Legend 📖

- **![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square)** Indicates that the test scenario is supported for the specified combination of sender and receiver platforms but the test scripts are not available yet.
- **![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square)** Indicates that the test scenario is not supported for the specified combination of sender and receiver platforms.
- **CI Badge**: Displays the status of the test in the CI pipeline. Click the badge to view the detailed workflow or logs on GitHub Actions.
  - **Green (✅)**: Test passed successfully.
  - **Red (❌)**: Test failed.
  - **Yellow (🕒)**: Test is in progress or has been queued.


## Login Tests
| Test Name | Nextcloud v27.1.10 | Nextcloud v28.0.12 | oCIS v5.0.6 | OcmStub v1.0.0 | ownCloud v10.14.0 | Seafile v11.0.5 |
|-----------|--------------------|--------------------|-------------|----------------|-------------------|-----------------|
| **Login** | [![NC v27.1.10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v27.yml) | [![NC v28.0.12](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v28.yml) | [![oCIS v5.0.6](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocis-v5.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocis-v5.yml) | [![OcmStub v1.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocmstub-v1.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocmstub-v1.yml) | [![ownCloud v10.14.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-owncloud-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-owncloud-v10.yml) | [![Seafile v11.0.5](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-seafile-v11.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-seafile-v11.yml) |

---

## Share Link Tests
| Sender (R) / Receiver (C) | Nextcloud v27.1.10 | Nextcloud v28.0.12 | ownCloud v10.14.0 |
|---------------------------|--------------------|--------------------|-------------------|
| **Nextcloud v27.1.10**    | [![NC v27 ↔ NC v27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-nc-v27.yml) | [![NC v27 ↔ NC v28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-nc-v28.yml) | [![NC v27 ↔ OC v10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v27-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v27-oc-v10.yml) |
| **Nextcloud v28.0.12**    | [![NC v28 ↔ NC v27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-nc-v27.yml) | [![NC v28 ↔ NC v28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-nc-v28.yml) | [![NC v28 ↔ OC v10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-nc-v28-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-nc-v28-oc-v10.yml) |
| **ownCloud v10.14.0**     | [![OC v10 ↔ NC v27](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-nc-v27.yml) | [![OC v10 ↔ NC v28](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-nc-v28.yml) | [![OC v10 ↔ OC v10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-link-oc-v10-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-link-oc-v10-oc-v10.yml) |

---

## Share With Tests
| Sender (R) / Receiver (C) | Nextcloud v27.1.10 | Nextcloud v28.0.12 | OcmStub v1.0.0 | ownCloud v10.14.0 | Seafile v11.0.5 |
|---------------------------|--------------------|--------------------|----------------|-------------------|-----------------|
| **Nextcloud v27.1.10**    | [![NC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v27.yml) | [![NC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v28.yml) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![NC ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-oc-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| **Nextcloud v28.0.12**    | [![NC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v27.yml) | [![NC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v28.yml) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![NC ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-oc-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| **OcmStub v1.0.0**        | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| **ownCloud v10.14.0**     | [![OC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v27.yml) | [![OC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v28.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v28.yml) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![OC ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-oc-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| **Seafile v11.0.5**       | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | [![SF ↔ SF](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-sf-v11-sf-v11.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-sf-v11-sf-v11.yml) |

---

## Invite Link Tests
| Sender (R) / Receiver (C) | Nextcloud v27.1.10 with ScienceMesh | oCIS v5.0.6 | ownCloud v10.14.0 with ScienceMesh |
|---------------------------|-------------------------------------|-------------|-----------------------------------|
| **Nextcloud v27.1.10**    | [![NC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-v27-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-v27-nc-v27.yml) | [![NC ↔ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-v27-ocis-v5.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-v27-ocis-v5.yml) | [![NC ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-nc-v27-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-nc-v27-oc-v10.yml) |
| **oCIS v5.0.6**           | [![oCIS ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-nc-v27.yml) | [![oCIS ↔ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-ocis-v5.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-ocis-v5.yml) | [![oCIS ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-ocis-v5-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-ocis-v5-oc-v10.yml) |
| **ownCloud v10.14.0**     | [![OC ↔ NC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-v10-nc-v27.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-v10-nc-v27.yml) | [![OC ↔ oCIS](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-v10-ocis-v5.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-v10-ocis-v5.yml) | [![OC ↔ OC](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/invite-link-oc-v10-oc-v10.yml?branch=main&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/invite-link-oc-v10-oc-v10.yml) |

# Developer's Guide for the Open Cloud Mesh Test Suite 🛠️

The **Open Cloud Mesh Test Suite** is designed to help developers run and validate specific test scenarios across multiple EFSS platforms. This guide provides instructions on how to execute specific tests using the command-line interface.

---

## Command Syntax 🖥️

To run specific tests, use the following command syntax:

```bash
./dev/ocm-test-suite.sh [test scenario] [platform 1] [platform 1 version] [run mode] [cypress runner] [platform 2] [platform 2 version]
```

### Arguments Breakdown:
1. **Test Scenario:**
    - The type of test you want to run. Supported scenarios:
        1. `login`
        2. `share-with`
        3. `invite-link`
        4. `share-link`


2. **Platform 1:**
    - The first EFSS platform being tested. Supported platforms:
        1. `nextcloud`
        2. `owncloud`
        3. `seafile`
        4. `ocis`

3. **Platform 1 Version:**
    - The specific version of Platform 1. For example: `v27.1.10`.

4. **Run Mode:**
    - Defines the environment for the test execution:
        1. `dev`: Local development mode.
        2. `ci`: Continuous Integration mode.

5. **Cypress Runner:**
    - The browser to be used by the Cypress test runner:
        1. `electron` (default for headless mode)
        2. `chrome`
        3. `firefox`
        4. `edge`

6. **Platform 2 (Optional):**
    - The second EFSS platform involved in cross-platform scenarios. Supported platforms:
        1. `nextcloud`
        2. `owncloud`
        3. `seafile`
        4. `ocis`

7. **Platform 2 Version (Optional):**
    - The specific version of Platform 2. For example: `v28.0.12`.


## Example Usage 📘


### Running a share-with Test:

Run a "share-with" test between two Nextcloud instances using version `v27.1.10`, in CI mode, with the Electron browser:

```bash
./dev/ocm-test-suite.sh share-with nextcloud v27.1.10 ci electron nextcloud v27.1.10
```

### Running a login Test:
Run a "login" test on a Seafile instance using version `v11.0.5`, in development mode, with the Chrome browser:

```bash
./dev/ocm-test-suite.sh login seafile v11.0.5 dev chrome
```

### Running a share-link Test:
Run a "share-link" test between ownCloud and Nextcloud instances, using versions `v10.14.0` and `v29.0.8`, respectively, in CI mode with Firefox:

```bash
./dev/ocm-test-suite.sh share-link owncloud v10.14.0 ci firefox nextcloud v29.0.8
```

## Notes 📝

### Platform Versions:
Ensure the versions provided are supported by the test suite. Refer to the Supported Platforms Section for the latest compatibility list.


### Cypress Runner:
Using `electron` is recommended for headless CI testing.
Other browsers (`chrome`, `firefox`, `edge`) can be used for debugging or local testing.

### Run Mode:
Use dev for iterative local testing with enhanced logging.
Use ci for automated pipelines with concise output.

### Cross-Platform Tests:
For scenarios requiring two platforms (e.g., `share-with`, `invite-link`), specify both Platform 1 and Platform 2 along with their versions.

# Debugging
## RD-SRAM

See https://github.com/SURFnet/rd-sram-integration#testing-environment for up-to-date instructions.

## ScienceMesh

This was moved to https://github.com/cs3org/reva/tree/sciencemesh-testing/examples/sciencemesh .

The scripts for ScienceMesh still exist here but are not guaranteed to work as expected.

### Reva version

upstream: [Reva](https://github.com/cs3org/reva)

branch: [v1.28.0](https://github.com/owncloud/core/releases/tag/v1.28.0)

## Trashbin

See https://github.com/pondersource/surf-trashbin-app

# Using XDebug

See [docs](./docs/xdebug.md)

# SOLID RemoteStorage
for development see [docs](./docs/solid-remotestorage.md)
