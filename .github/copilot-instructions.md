# Copilot Instructions

## Project Focus
This repository is a Flutter plugin that follows a **federated plugin pattern**.
When generating or refactoring code, prioritize long-term maintainability, strict boundaries, and high confidence changes.

## Core Engineering Principles

### 1) SOLID first
- Apply SOLID principles by default.
- Keep classes small and focused on one reason to change.
- Prefer interfaces/abstract contracts over direct concrete dependencies.
- Invert dependencies toward platform-interface/domain contracts.

### 2) Clean Architecture
- Keep clear layers and dependency direction:
  - `domain` (entities, value objects, use-cases, contracts)
  - `application` (orchestrators/services, DTO mappers)
  - `infrastructure/platform` (method channels, native adapters, Pigeon bindings)
  - `presentation` (widgets/UI API)
- Domain must not depend on Flutter UI, method channels, or platform-specific code.
- Platform implementations depend on contracts, never the opposite.

### 3) DDD mindset
- Model behavior around domain concepts (session, discovery, media, cast context).
- Use explicit ubiquitous language in names.
- Prefer value objects for immutable, validated data.
- Keep invariants close to domain models/use-cases.

### 4) Object Calisthenics
- Keep methods short and intention-revealing.
- Avoid deep nesting; extract private helpers/use-cases.
- Prefer encapsulation over data bags.
- Minimize primitive obsession by introducing meaningful types where valuable.

### 5) Separated Concerns (strict)
- Do not mix UI, domain logic, and platform integration in the same class.
- Avoid leaking Android/iOS details into shared/plugin-facing APIs.
- Keep platform channel serialization/deserialization in adapter boundaries.
- Ensure each package has a single clear responsibility:
  - `flutter_chrome_cast_platform_interface`: contracts and platform API surface
  - `flutter_chrome_cast_android` / `flutter_chrome_cast_ios`: platform-specific implementations
  - root plugin package: orchestration/public facade only

## Federated Plugin Rules
- Any new cross-platform API must be introduced in the platform interface first.
- Android/iOS packages must implement the same behavior contract and error semantics.
- Public APIs should remain stable and minimal; avoid breaking changes unless explicitly requested.
- Keep feature flags/capabilities explicit when platform parity is not possible.

## Code Quality Standards
- Prefer explicit types and clear null-safety handling.
- Avoid duplicated logic across platform implementations; share abstractions when feasible.
- Add tests for domain/use-case behavior and contract-level plugin behavior.
- Keep test seams via interfaces and dependency injection.
- Include meaningful errors with actionable context.

## Change Hygiene
- Make minimal, focused diffs.
- Preserve existing architecture and naming conventions unless change is requested.
- Do not introduce unrelated refactors.
- If architecture is violated, propose a small safe incremental path instead of a big-bang rewrite.

## Review Checklist for Generated Code
Before finalizing, verify:
1. Is responsibility split correctly across layers/packages?
2. Are dependencies pointing inward (toward contracts/domain)?
3. Is platform-specific logic isolated from shared abstractions?
4. Are names aligned with domain language?
5. Are tests included/updated for behavior and contracts?
6. Is the API backward compatible (or clearly documented if not)?
// add a section about documentation standards if needed how clear doc should be how it have exmplain goals limitations and usage examples how thing behave in diferent platforms if needed. ect the documentatin should be a project goal
