# Mandatory Code Verification & Analysis Rule

After completing any coding task, edit, or refactoring, you MUST always run static analysis and fix all reported errors, warnings, and lints before finishing your response:

1. **Always Run Code Analysis After Every Task**:
   - For Flutter / Dart projects: run `flutter analyze` (or `C:\Users\HOPE\dev\flutter\bin\flutter.bat analyze` on Windows if `flutter` is not in the default sandbox `PATH`) and ensure **0 issues found**.
   - For TypeScript / JavaScript / Python / other projects: run the project's configured linter/typechecker (`tsc --noEmit`, `eslint`, `ruff`, etc.).
2. **Zero Tolerance for Leftover Diagnostics**:
   - Never finish a task while leaving analyzer errors, warnings, or lint issues behind.
   - If `flutter analyze` or the project analyzer reports any issues, resolve every one of them and re-run the analyzer to confirm a clean exit (`No issues found!`) before reporting completion to the user.
3. **Run Relevant Unit Tests**:
   - Run the unit/widget tests covering the modified code (`flutter test <test_paths>`) and verify all tests pass.
