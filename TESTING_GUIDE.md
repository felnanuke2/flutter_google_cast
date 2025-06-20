# Testing Guide for Flutter Chrome Cast

This document outlines the testing strategy and enforcement mechanisms for the Flutter Chrome Cast project.

## 📋 Testing Requirements

### Mandatory Testing Rules

1. **Test Directory**: A `test/` directory must exist in the project root
2. **Test Files**: At least one test file (`.dart`) must be present
3. **Test Execution**: All tests must pass before code can be merged
4. **Critical Components**: Core functionality should have corresponding tests

## 🛠️ Analysis Options Configuration

The `analysis_options.yaml` file has been configured with rules that encourage testable code:

### Testing-Related Rules
- **Code Quality**: Rules that make code easier to test
- **Error Handling**: Proper error handling improves test reliability
- **Code Organization**: Clean code is easier to test

### Key Rules for Testability
```yaml
# Makes code more testable
prefer_final_locals: true
avoid_positional_boolean_parameters: true
avoid_catches_without_on_clauses: true

# Improves error handling in tests
avoid_catching_errors: true
avoid_returning_null_for_future: true

# Code organization helps with test structure
directives_ordering: true
sort_constructors_first: true
```

## 🔧 Enforcement Mechanisms

### 1. Analysis Options
- Linter rules encourage testable code patterns
- Strict analysis settings catch potential issues early
- Documentation requirements ensure APIs are well-documented for testing

### 2. CI/CD Pipeline
The GitHub Actions workflow (`.github/workflows/ci.yml`) enforces:
- ✅ Test directory existence
- ✅ Test file presence
- ✅ Test execution
- ✅ Code formatting
- ✅ Static analysis
- 🔄 Optional test coverage checking

### 3. Pre-commit Hooks
The git pre-commit hook (`.git/hooks/pre-commit`) prevents commits without:
- Test directory
- Test files
- Passing tests

### 4. Test Enforcement Script
Run `scripts/test_enforcement.sh` to manually check:
- Test structure
- Test execution
- Coverage reporting
- Critical component coverage

## 📁 Test Structure

```
test/
├── test_runner.dart          # Main test runner
├── unit/                     # Unit tests
│   ├── cast_context_test.dart
│   ├── discovery_test.dart
│   ├── session_test.dart
│   └── media_test.dart
└── widget/                   # Widget tests
    └── cast_widgets_test.dart
```

## 🎯 Testing Strategy

### Unit Tests
Test individual components in isolation:
- `GoogleCastContext` initialization and configuration
- `DiscoveryManager` device discovery logic
- `SessionManager` session lifecycle
- `RemoteMediaClient` media control

### Widget Tests
Test UI components:
- `MiniController` widget rendering
- `ExpandedPlayer` user interactions
- `CastVolume` control behavior

### Integration Tests
Test component interactions:
- End-to-end cast workflows
- Device discovery to session establishment
- Media loading and playback control

## 🚀 Getting Started with Tests

1. **Create your first test:**
   ```bash
   touch test/unit/my_component_test.dart
   ```

2. **Basic test structure:**
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:flutter_chrome_cast/cast_context.dart';

   void main() {
     group('MyComponent Tests', () {
       test('should do something', () {
         // Arrange
         // Act
         // Assert
         expect(actual, expected);
       });
     });
   }
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

4. **Run test enforcement:**
   ```bash
   ./scripts/test_enforcement.sh
   ```

## 📊 Coverage Requirements

While not strictly enforced yet, consider these coverage targets:

- **Unit Tests**: 80%+ coverage for core logic
- **Widget Tests**: 70%+ coverage for UI components
- **Critical Paths**: 100% coverage for essential functionality

To enable coverage enforcement, uncomment the coverage checking sections in:
- `.github/workflows/ci.yml`
- `scripts/test_enforcement.sh`

## 🔍 Best Practices

1. **Test Naming**: Use descriptive test names
   ```dart
   test('should connect to device when valid device is provided')
   ```

2. **Test Organization**: Group related tests
   ```dart
   group('Device Discovery', () {
     group('when network is available', () { ... });
     group('when network is unavailable', () { ... });
   });
   ```

3. **Mocking**: Use mocks for external dependencies
   ```dart
   final mockDevice = MockCastDevice();
   when(mockDevice.connect()).thenAnswer((_) async => true);
   ```

4. **Test Data**: Use factories for test data
   ```dart
   CastDevice createTestDevice({String? name}) {
     return CastDevice(name: name ?? 'Test Device');
   }
   ```

## 🛡️ Bypassing Test Requirements

For emergency situations only:

1. **Temporary bypass of pre-commit hook:**
   ```bash
   git commit --no-verify -m "Emergency fix"
   ```

2. **Disable specific CI checks** by modifying `.github/workflows/ci.yml`

⚠️ **Warning**: Always add proper tests as soon as possible after bypassing requirements.

## 🔧 Troubleshooting

### Common Issues

1. **Tests not found:**
   - Ensure test files end with `_test.dart`
   - Check test files are in the `test/` directory

2. **Import errors in tests:**
   - Make sure `flutter_test` is in `dev_dependencies`
   - Use correct import paths for your project

3. **CI failing:**
   - Run `flutter test` locally first
   - Check GitHub Actions logs for specific errors

### Getting Help

- Run `./scripts/test_enforcement.sh` for detailed checking
- Check analysis options with `flutter analyze`
- Review test structure in existing test files
