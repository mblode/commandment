# Contributing

Thanks for your interest in Commandment.

## Getting set up

Requires Xcode 16+ and macOS 15.2+ SDK.

```bash
git clone https://github.com/mblode/commandment.git
cd commandment
open Commandment.xcodeproj
npm install
```

Or build from the command line:

```bash
xcodebuild -scheme Commandment -configuration Debug build -derivedDataPath /tmp/commandment-build
```

The macOS source lives in `apps/macos`, its tests in `apps/macos-tests`, and the
Next.js landing page in `apps/web`. Turborepo commands run from the repository
root; use `npm run web:dev` for the site or `npm run build` for both apps.

## Making changes

1. Fork the repo and create a branch
2. Make your changes
3. Test locally — build and run the app from Xcode or the CLI
4. Open a pull request

## Reporting bugs

Open an [issue](https://github.com/mblode/commandment/issues) with steps to reproduce.
