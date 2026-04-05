# AGENTS

## Branch Naming

- New branches should be prefixed with `feature/` or `fix/`.

## Common Commands

- Run tests with `./scripts/run-tests.sh`.
- Build a release version with `./scripts/build-release.sh`.
- Build a debug version with `./scripts/build-debug.sh`.

## TDD Workflow

- When implementing features, use red/green TDD.
- Start by writing or updating a test that captures the desired behavior and confirm it fails for the expected reason.
- Make the smallest code change needed to get the test passing.
- Run the relevant tests after each change and refactor only while keeping the test suite green.
