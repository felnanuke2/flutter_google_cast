## 2.1.0-dev.1 - Federated Plugin Architecture

### 🏗️ Architecture - Federated Plugin Migration
- **Migrated to federated plugin architecture** following Flutter best practices
  - Split into separate packages: `flutter_chrome_cast_platform_interface`, `flutter_chrome_cast_android`, `flutter_chrome_cast_ios`
  - Pigeon-based type-safe communication between Flutter and native platforms
  - Automatic platform registration via endorsed `default_package`s
  - Dart workspace configuration with shared dependency resolution
  - **Zero breaking changes** - full backward compatibility maintained via re-exports
- All features released in 2.0.0 and earlier (custom Cast message channels, opt-in
  log level filtering, active scan, live iOS device list, canonical metadata keys,
  HLS segment format forwarding, Linux Dart sender) are carried over into the
  federated packages.

