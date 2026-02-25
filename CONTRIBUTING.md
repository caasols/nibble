# Contributing

Thanks for contributing to Ethernet Status.

## Development Setup

```bash
swift package resolve
swift build
swift test
```

## CI Lanes

GitHub Actions defines two lanes in `.github/workflows/ci.yml`:

- `stable-build-and-test` (required): uses current package manifest and must pass for merges.
- `builtin-testing-probe` (non-blocking): swaps to `Package.builtin-testing.swift` to track readiness for removing the temporary `swift-testing` dependency.

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
