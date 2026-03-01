# Contributing

Thanks for contributing to Nibble.

## Development Setup

```bash
swift package resolve
swift build
swift test
```

## Code Style

Nibble uses two lint tools that run automatically on pull requests.

| Tool | Job |
|---|---|
| SwiftFormat | Formatting (indentation, spacing, wrapping) |
| SwiftLint | Safety and code quality rules |

Before pushing, run:

```bash
make lint-fix
make lint
```

PRs with lint errors should not be merged.
If a rule produces a false positive, suppress it inline and explain the rationale in the PR description.

## CI Lanes

GitHub Actions defines two lanes in `.github/workflows/ci.yml`:

- `stable-build-and-test` (required): uses current package manifest and must pass for merges.
- `builtin-testing-probe` (non-blocking): swaps to `Package.builtin-testing.swift` to track readiness for removing the temporary `swift-testing` dependency.

For branch protection verification, open a PR to `main` and confirm only `stable-build-and-test` is required.

Linting automation is defined in `.github/workflows/lint.yml` with separate `swiftlint` and `swiftformat` jobs so style/safety failures are diagnosed independently from build/test failures.

## Release Lane

GitHub Actions release automation is defined in `.github/workflows/release.yml`.

- Trigger automatically on tags matching `v*`.
- Supports manual dispatch with a `tag_name` input.
- Builds release app bundle, signs with Developer ID, notarizes with Apple notarytool, runs artifact hygiene checks, uploads release artifacts, and publishes a GitHub Release.

Required repository secrets:

- `APPLE_DEVELOPER_ID_APPLICATION_CERT_BASE64` (base64-encoded `.p12`)
- `APPLE_DEVELOPER_ID_APPLICATION_CERT_PASSWORD`
- `APPLE_SIGNING_IDENTITY` (example: `Developer ID Application: Example, Inc. (TEAMID)`)
- `APPLE_TEAM_ID`
- `APPLE_NOTARY_KEY_ID`
- `APPLE_NOTARY_ISSUER_ID`
- `APPLE_NOTARY_API_KEY_BASE64` (base64-encoded App Store Connect API key `.p8`)

Local verification command for artifact checks:

```bash
make release-hygiene-test
```

## Pull Request Expectations

- Keep PRs focused and small when possible.
- Run `swift build` and `swift test` locally before opening a PR.
- Describe behavioral changes and include verification steps in the PR description.

## Recommended Branch Protection

For `main`, enable:

- Require pull request before merging.
- Require status checks to pass before merging.
- Select `stable-build-and-test` as a required status check.
- Keep `builtin-testing-probe` optional (informational only).

## Dependency Cleanup Plan

Once both local and CI environments pass with `Package.builtin-testing.swift`, remove:

- `swift-testing` from `Package.swift` dependencies.
- `Testing` product dependency from test target.
- `Package.builtin-testing.swift`.
