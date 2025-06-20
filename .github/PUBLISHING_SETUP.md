# Pub.dev Publishing Setup (OIDC-based)

This document explains how to set up automatic publishing to pub.dev using OpenID Connect (OIDC) tokens when a version tag is created.

## Overview

The publishing workflow now uses the official Dart team's reusable workflow with OIDC authentication, which is much more secure than using long-lived secrets.

## Setup Process

### 1. Enable Automated Publishing on pub.dev

1. Go to [pub.dev](https://pub.dev) and sign in
2. Navigate to your package (`flutter_chrome_cast`)
3. Go to the "Admin" tab
4. Click on "Automated publishing"
5. Configure the following settings:
   - **Repository**: `felnanuke2/flutter_google_cast`
   - **Tag pattern**: `v{{version}}` (this matches tags like `v1.2.3`)
   - **Enable publishing from push events**: ✅ (checked)
   - **Enable publishing from workflow_dispatch events**: ✅ (checked)
   - **Require GitHub Actions environment**: (optional, can leave unchecked for now)

### 2. No Secrets Required! 🎉

Unlike the old method, OIDC authentication doesn't require any GitHub secrets. The authentication happens automatically using temporary tokens.

## How the New Workflow Works

The publishing workflow (`.github/workflows/publish.yml`) is triggered when:

1. **A version tag is pushed** (e.g., `v1.2.3`, `v2.0.0`)
2. The tag pattern matches `v[0-9]+.[0-9]+.[0-9]+`

### Workflow Steps (Handled by Dart Team's Reusable Workflow)

1. **Automatic Setup**: Sets up Dart/Flutter environment
2. **Package Validation**: Runs `dart pub publish --dry-run`
3. **OIDC Authentication**: Automatically authenticates with pub.dev using GitHub's OIDC token
4. **Publishing**: Publishes the package to pub.dev if validation passes

## Release Process

### Automated Tag Creation from pubspec.yaml (Recommended)

The workflow now automatically creates tags based on the version in `pubspec.yaml`:

1. **Update version in `pubspec.yaml`**:
   ```yaml
   version: 1.2.1  # Update this
   ```

2. **Update `CHANGELOG.md`** with your changes

3. **Create a PR and merge to main**:
   ```bash
   git add .
   git commit -m "Bump version to 1.2.1"
   # Create PR, get it reviewed and merged
   ```

4. **Automatic process happens**:
   - ✅ Workflow detects the version change in `pubspec.yaml`
   - ✅ Creates a git tag `v1.2.1` automatically
   - ✅ Triggers the publishing workflow
   - ✅ Publishes to pub.dev using OIDC authentication

### Manual Tag Creation (Alternative)

If you prefer to create tags manually:

### Manual Tag Creation (Alternative)

If you prefer to create tags manually:

1. **Update version in `pubspec.yaml`**:
   ```yaml
   version: 1.2.1  # Update this
   ```

2. **Update `CHANGELOG.md`** with your changes

3. **Commit and push to main**:
   ```bash
   git add .
   git commit -m "Bump version to 1.2.1"
   git push origin main
   ```

4. **Create and push a version tag**:
   ```bash
   git tag v1.2.1
   git push origin v1.2.1
   ```

5. **Automatic publishing happens** when the tag is pushed!

### GitHub Release Creation (Alternative)

1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Create a new tag (e.g., `v1.2.1`) 
4. Fill in release notes
5. Click "Publish release"
6. This automatically creates the tag and triggers publishing

## Version Tag Patterns

The workflow is configured to work with tags like:
- ✅ `v1.2.3` (matches the pattern)
- ✅ `v2.0.0` 
- ✅ `v1.0.0-beta.1`
- ❌ `1.2.3` (no 'v' prefix)
- ❌ `release-1.2.3` (wrong format)

If you want to use a different pattern, update both:
1. The workflow file tag pattern
2. The pub.dev automated publishing tag pattern

## Benefits of OIDC Approach

- 🔒 **More Secure**: No long-lived secrets stored in GitHub
- 🚀 **Simpler Setup**: No credential management needed
- 🛡️ **Official Support**: Uses Dart team's maintained workflow
- 🔄 **Automatic**: Just push a tag and it publishes
- ✅ **Reliable**: Built-in validation and error handling

## Troubleshooting

### Common Issues

1. **Tag pattern mismatch**: Ensure your tags match `v1.2.3` format
2. **pub.dev not configured**: Make sure automated publishing is enabled on pub.dev
3. **Repository mismatch**: Verify the repository name is correct in pub.dev settings

### Testing the Workflow

1. **Create a test tag**:
   ```bash
   git tag v1.2.0-test
   git push origin v1.2.0-test
   ```

2. **Check the Actions tab** in your GitHub repository to see the workflow run

3. **If it fails**, check the workflow logs for specific error messages

## Migration from Old Setup

If you previously had `PUB_DEV_ACCESS_TOKEN` and `PUB_DEV_REFRESH_TOKEN` secrets:
1. You can safely delete them from GitHub repository secrets
2. The new workflow doesn't use them at all
3. OIDC authentication is handled automatically
