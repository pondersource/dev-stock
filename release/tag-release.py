#!/usr/bin/env python3

import os
import sys
import subprocess
import xml.etree.ElementTree as ET
import argparse

def parse_arguments():
    """
    Parses command-line arguments using argparse.

    Returns:
        argparse.Namespace: Parsed command-line arguments.
    """
    parser = argparse.ArgumentParser(description="Version tagging script.")
    parser.add_argument("platform_tag", help="Platform tag")
    parser.add_argument("pre_release_tag", help="Pre-release tag (or 'none')")
    parser.add_argument("directory_name", help="Directory name of the project")
    parser.add_argument("--new-version", help="New version number in X.Y.Z format")
    parser.add_argument("--auto-push", action="store_true", help="Automatically push changes without confirmation")
    return parser.parse_args()

def get_version_info(version_file_path):
    """
    Reads the 'info.xml' file and extracts the version information.

    Args:
        version_file_path (str): Path to the 'info.xml' file.

    Returns:
        tuple: A tuple containing the version string and version tuple.

    Raises:
        FileNotFoundError: If the 'info.xml' file does not exist.
        ValueError: If the version tag is missing or malformed.
    """
    try:
        tree = ET.parse(version_file_path)
        root = tree.getroot()
        version_element = root.find('version')
        if version_element is None or version_element.text is None:
            raise ValueError("Version tag not found or empty in info.xml.")
        version = version_element.text.strip()
        version_info = tuple(map(int, version.split('.')))
        return version, version_info
    except FileNotFoundError:
        raise FileNotFoundError(f"Version file not found: {version_file_path}")
    except ET.ParseError as e:
        raise ValueError("Malformed XML in info.xml.") from e
    except ValueError as e:
        raise ValueError(f"Malformed version in info.xml: {e}") from e

def validate_version_format(version_tuple):
    """
    Validates the format of the version tuple.

    Args:
        version_tuple (tuple): The version tuple to validate.

    Raises:
        ValueError: If the version tuple does not have exactly three integer components.
    """
    if len(version_tuple) != 3 or not all(isinstance(x, int) for x in version_tuple):
        raise ValueError("Version must be in X.Y.Z format (e.g., 1.0.0).")

def validate_new_version(new_version_info, current_version_info):
    """
    Validates that the new version is greater than the current version.

    Args:
        new_version_info (tuple): New version tuple.
        current_version_info (tuple): Current version tuple.

    Raises:
        ValueError: If the new version is not greater than the current version.
    """
    if new_version_info <= current_version_info:
        raise ValueError("New version must be greater than the current version!")

def update_version_file(version_file_path, new_version):
    """
    Updates the 'info.xml' file with the new version.

    Args:
        version_file_path (str): Path to the 'info.xml' file.
        new_version (str): New version string.

    Raises:
        RuntimeError: If the version file cannot be updated.
    """
    try:
        tree = ET.parse(version_file_path)
        root = tree.getroot()
        version_element = root.find('version')
        if version_element is None:
            raise ValueError("Version tag not found in info.xml.")
        version_element.text = new_version
        tree.write(version_file_path, encoding='UTF-8', xml_declaration=True)
    except Exception as e:
        raise RuntimeError("Failed to update version file.") from e

def git_commit_tag(project_path, version_file_path, tag):
    """
    Performs Git commit and tagging operations.

    Args:
        project_path (str): Path to the project directory.
        version_file_path (str): Path to the version file.
        tag (str): Tag name to create.

    Raises:
        RuntimeError: If any Git operation fails.
    """
    try:
        # Stage the version file
        subprocess.check_call(["git", "-C", project_path, "add", version_file_path])
        # Commit the change
        subprocess.check_call(["git", "-C", project_path, "commit", "-m", f"version: {tag}"])
        # Create a new tag
        subprocess.check_call(["git", "-C", project_path, "tag", tag])
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Git operation failed.") from e

def git_revert_tag(project_path, tag):
    """
    Reverts the Git tag and commit if the push is declined.

    Args:
        project_path (str): Path to the project directory.
        tag (str): Tag name to delete.

    Raises:
        RuntimeError: If reverting the Git tag and commit fails.
    """
    try:
        # Delete the tag
        subprocess.check_call(["git", "-C", project_path, "tag", "-d", tag])
        # Undo the last commit
        subprocess.check_call(["git", "-C", project_path, "reset", "--hard", "HEAD~1"])
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Failed to revert Git tag and commit.") from e

def git_push(project_path, tag):
    """
    Pushes the commit and tag to the remote repository.

    Args:
        project_path (str): Path to the project directory.
        tag (str): Tag name to push.

    Raises:
        RuntimeError: If the Git push fails.
    """
    try:
        # Push the commit and the tag
        subprocess.check_call(["git", "-C", project_path, "push", "origin", "HEAD"])
        subprocess.check_call(["git", "-C", project_path, "push", "origin", tag])
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Git push failed.") from e

def main():
    """
    Main function that orchestrates the version tagging process.

    Steps:
    - Parses command-line arguments.
    - Reads the current version from 'info.xml'.
    - Obtains the new version (either via arguments or user input).
    - Validates the new version.
    - Updates 'info.xml' with the new version.
    - Commits the change and creates a Git tag.
    - Optionally pushes the changes to the remote repository.
    """
    try:
        # Parse command-line arguments
        args = parse_arguments()
        platform_tag = args.platform_tag
        pre_release_tag = args.pre_release_tag
        directory_name = args.directory_name
        new_version_arg = args.new_version
        auto_push = args.auto_push

        # Build pre-release suffix
        pre_release_suffix = f"-{pre_release_tag}" if pre_release_tag != "none" else ""

        # Derive paths
        base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        project_path = os.path.join(base_path, directory_name)
        version_file_path = os.path.join(project_path, "appinfo", "info.xml")

        # Read current version
        current_version, current_version_info = get_version_info(version_file_path)
        print(f"Current version: {current_version}")

        # Get new version from the user or arguments
        if new_version_arg:
            new_version = new_version_arg.strip()
            new_version_info = tuple(map(int, new_version.split('.')))
        else:
            print("Enter the new version in X.Y.Z format.")
            new_major = int(input("Enter major version: "))
            new_minor = int(input("Enter minor version: "))
            new_patch = int(input("Enter patch version: "))
            new_version_info = (new_major, new_minor, new_patch)
            new_version = '.'.join(map(str, new_version_info))

        # Validate new version
        validate_version_format(new_version_info)
        validate_new_version(new_version_info, current_version_info)

        # Update version in the file
        update_version_file(version_file_path, new_version)
        print("Version updated successfully.")

        # Create tag and commit
        tag = f"v{new_version}-{platform_tag}{pre_release_suffix}"
        git_commit_tag(project_path, version_file_path, tag)
        print(f"Tag '{tag}' created.")

        # Confirm push
        if auto_push:
            confirm_push = "yes"
        else:
            confirm_push = input("Do you want to push the changes to the repository? (yes/no): ").strip().lower()

        if confirm_push == "yes":
            git_push(project_path, tag)
            print(f"Tag '{tag}' pushed to the repository.")
        else:
            print("Push declined. Reverting tag and commit.")
            git_revert_tag(project_path, tag)
            print("Reverted tag and commit.")

    except ValueError as ve:
        print(f"Error: {ve}")
        sys.exit(1)
    except FileNotFoundError as fe:
        print(f"Error: {fe}")
        sys.exit(1)
    except RuntimeError as re:
        print(f"Error: {re}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
