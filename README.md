# FyreKit

A description of this package.

## Installation
- Copy FyreKitConfig & Info.plist configuration files
- Go to `Project → Targets → Build Settings → Info.plist File` and add the path to the Info.plist file
- Set `Generate Info.plist File` to “No”:
- Go to `Project → Targets → Build Phases → Copy Bundle Resources`
  - And remove Info.plist. This is to prevent a “Multiple commands produce” error.
