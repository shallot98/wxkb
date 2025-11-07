# GitHub Actions Workflow Configuration

## Overview

This directory contains GitHub Actions workflows for automatically building and packaging the WXKBTweak rootless Jailbreak tweak.

## Build Workflow: `build-deb.yml`

### Purpose

Automatically builds the WXKBTweak tweak and preference bundle for ARM64 and ARM64e architectures as rootless-compatible `.deb` packages.

### Build Environment

- **Runner**: macOS 14 (Apple Silicon)
- **Theos**: Managed by `Randomblock1/theos-action@v1`
- **SDK**: iOS SDK 16.5
- **Compiler**: Clang
- **Architectures**: ARM64 and ARM64e
- **Package Scheme**: Rootless

### Trigger Events

The workflow runs automatically on:

1. **Push to main branches**: `main`, `master`
2. **Tag creation**: Any tag matching `v*` pattern (e.g., `v2.0.1`)
3. **Pull requests**: Against `main`, `master`
4. **Manual trigger**: Via `workflow_dispatch` in GitHub Actions UI

### Build Steps

1. **Checkout**: Fetches the complete repository history
2. **Setup Theos**: Installs Theos environment with iOS SDK 16.5 support
3. **Configure Build**: Sets `THEOS_PACKAGE_SCHEME=rootless` and `ARCHS=arm64 arm64e`
4. **Build Main Tweak**: Compiles the WXKBTweak using `make package FINALPACKAGE=1`
5. **Build Preferences**: Compiles the preference bundle in `wxkbtweakprefs/`
6. **Artifacts Listing**: Lists all generated `.deb` files
7. **Upload Artifacts**: Uploads `.deb` packages (30-day retention)
8. **Create Release**: If a tag triggered the build, automatically creates a GitHub Release
9. **Build Summary**: Displays build information and metadata

### Output Artifacts

- **Primary Location**: Uploaded as GitHub Actions Artifacts under `WXKBTweak-deb-packages`
- **Release Location**: Attached to GitHub Release (when built from tag)
- **Retention**: 30 days for artifacts
- **Packages Included**:
  - `com.laowang.wxkbtweak_*.deb` - Main tweak
  - `com.laowang.wxkbtweakprefs_*.deb` - Preference bundle (if separate)

### Configuration Details

#### Key Environment Variables

Set in Makefile and/or workflow:

```
THEOS_PACKAGE_SCHEME = rootless    # Enables rootless packaging
ARCHS = arm64 arm64e               # Build for both ARM architectures
TARGET = iphone:clang:latest:13.0  # iOS 13+ compatibility
```

#### Build Flags

```
FINALPACKAGE=1    # Production build (enables optimizations)
make clean        # Clean previous build artifacts
```

### Usage

#### Automatic Triggers

1. **Push changes** to `main` branch:
   ```bash
   git push origin main
   ```
   → Workflow runs automatically, artifacts available in Actions tab

2. **Create release**:
   ```bash
   git tag v2.0.2
   git push origin v2.0.2
   ```
   → Workflow runs, creates Release with `.deb` files attached

3. **Manual trigger** in GitHub UI:
   - Go to Actions tab
   - Select "Build Rootless DEB" workflow
   - Click "Run workflow"

#### Downloading Artifacts

**From Actions Tab:**
1. Go to repository Actions page
2. Click the latest successful workflow run
3. Scroll to Artifacts section
4. Download `WXKBTweak-deb-packages`

**From Release:**
1. Go to Releases page
2. Click the release (created from tag)
3. Download `.deb` files directly

### Troubleshooting

#### Build Fails

1. Check workflow logs in Actions tab for error details
2. Common issues:
   - Makefile syntax errors
   - Missing dependencies
   - Code compilation errors
3. Fix code locally, push to trigger rebuild

#### Artifacts Not Found

1. Check if build completed successfully (green checkmark)
2. May be generating .deb to a different location
3. Review "List generated artifacts" step in workflow logs

#### SDK or Theos Issues

- `Randomblock1/theos-action@v1` handles environment setup
- If issues persist, check:
  - Theos installation in action logs
  - SDK path configuration
  - Architecture compatibility

### Maintenance

#### Updating Dependencies

To update action versions:

```yaml
uses: actions/checkout@v4           # Latest v4
uses: actions/upload-artifact@v4    # Latest v4
uses: Randomblock1/theos-action@v1  # Theos action
uses: softprops/action-gh-release@v1 # Release action
```

#### Monitoring Builds

- View build history: Actions tab
- Check specific run: Click run number
- View detailed logs: Expand step names
- Export results: GitHub provides CLI tools

### Best Practices

1. **Tag releases properly**:
   ```bash
   git tag -a v2.0.2 -m "Release version 2.0.2"
   ```

2. **Test locally before pushing**:
   ```bash
   make clean
   make package FINALPACKAGE=1
   cd wxkbtweakprefs && make package FINALPACKAGE=1 && cd ..
   ```

3. **Monitor workflow runs** for failures

4. **Keep main branch stable** - only push tested code

### Related Files

- `Makefile` - Main tweak build configuration
- `wxkbtweakprefs/Makefile` - Preference bundle configuration
- `.gitignore` - Ignores build artifacts but includes `.github/`

### References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Theos Documentation](https://theos.dev)
- [Randomblock1/theos-action](https://github.com/Randomblock1/theos-action)

---

**Author**: WXKBTweak Team  
**Last Updated**: 2024
