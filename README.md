# Hacker News

A native macOS app for reading Hacker News, built with SwiftUI.

## Features

- Browse top stories from Hacker News
- Pull-to-refresh and toolbar refresh button with animation
- Click stories to open in your default browser
- Clean, native macOS interface

## Requirements

- macOS 14.0+
- Xcode 15.0+

## Building

Build scripts are provided in the `scripts/` directory:

```bash
# Debug build
./scripts/build-debug.sh

# Release build
./scripts/build-release.sh

# Release archive for distribution
./scripts/build-release.sh --archive
```

Build outputs are placed in the `build/` directory.

## Installation

After building a release version, copy the app to your Applications folder:

```bash
cp -R "build/Release/Hacker News.app" /Applications/
```

## License

MIT
