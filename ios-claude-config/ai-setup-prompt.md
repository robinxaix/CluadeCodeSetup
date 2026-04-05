# AI Setup Prompt — iOS Claude Code Configuration

Paste this entire file content into a Claude Code session opened at your iOS project root.  
Claude will execute all steps to recreate the full configuration.

---

Please set up the Claude Code configuration for this iOS project by performing the following steps exactly. Create all files with the exact content specified. Do not skip any step.

## Step 1 — Add Build Commands to CLAUDE.md

Append the following section to the project's `CLAUDE.md`:

```
---

## Build Commands

- **Build**: Use `mcp__xcodebuildmcp__build_sim_name_proj` for simulator builds
- **Test**: Use `mcp__xcodebuildmcp__test_sim_name_proj` for running tests
- **Clean**: Use `mcp__xcodebuildmcp__clean` before major rebuilds
- **Logs**: Use `mcp__xcodebuildmcp__capture_logs` to debug runtime issues
```

## Step 2 — Create Project Slash Commands

Create `.claude/commands/` directory and the following files:

### `.claude/commands/build.md`
```
---
description: Build the iOS project intelligently
allowed-tools: mcp__xcodebuildmcp__*
---

# Build Project

Detect the project type and build appropriately:
1. Check for .xcworkspace or .xcodeproj
2. Use XcodeBuildMCP to build for iOS Simulator
3. Report any build errors with suggested fixes
```

### `.claude/commands/test.md`
```
---
description: Run all relevant tests
allowed-tools: mcp__xcodebuildmcp__*, Bash(swift *)
---

# Run Tests

Based on current context:
- For main app: `mcp__xcodebuildmcp__test_sim_name_proj`
- For Swift packages: `mcp__xcodebuildmcp__swift_package_test`
- Report test results and any failures
```

### `.claude/commands/run-app.md`
```
---
description: Build and launch app on simulator
allowed-tools: mcp__xcodebuildmcp__*
---

# Build and Run

1. List available simulators
2. Build the app for the default simulator (iPhone 15)
3. Boot the simulator if needed
4. Install and launch the app
5. Start capturing logs
```

### `.claude/commands/create-view.md`
```
---
description: Create a new SwiftUI view with ViewModel
argument-hint: <ViewName>
allowed-tools: Read, Write
---

# Create SwiftUI View: $ARGUMENTS

Create a new SwiftUI view following project patterns:

1. Read existing views for style reference
2. Create `$ARGUMENTS.swift` in appropriate Features directory
3. Create `${ARGUMENTS}ViewModel.swift` as @Observable class
4. Add preview provider
5. Follow project's navigation and styling patterns
```

### `.claude/commands/refactor-view.md`
```
---
description: Extract and refactor a SwiftUI view
argument-hint: <source-file>
allowed-tools: Read, Write, Edit
---

# Refactor View: $ARGUMENTS

Analyze the view and:
1. Identify extractable subviews (>50 lines or reusable)
2. Extract to separate files
3. Create appropriate ViewModels if needed
4. Ensure proper data flow with bindings
5. Add documentation comments
```

### `.claude/commands/fix-build.md`
```
---
description: Diagnose and fix build errors
allowed-tools: mcp__xcodebuildmcp__*, Read, Write, Edit, Bash(swift *)
---

# Fix Build Errors

ultrathink about the build errors:

1. Run a clean build to get fresh errors
2. Analyze each error
3. Propose fixes
4. Implement fixes one at a time
5. Verify build succeeds
```

### `.claude/commands/implement-feature.md`
```
---
description: Implement a feature from spec
argument-hint: <feature-name>
allowed-tools: Read, Write, Edit, mcp__xcodebuildmcp__*
---

# Implement Feature: $ARGUMENTS

Follow the PRD workflow:

1. Read `docs/specs/$ARGUMENTS.md` for requirements
2. Read `docs/tasks/$ARGUMENTS-tasks.md` for task breakdown
3. Implement the current uncompleted task
4. Write tests for the implementation
5. Update task progress in the tasks file
6. Build and test

Stop after completing each task and wait for approval.
```

## Step 3 — Create Personal Slash Command

Create `~/.claude/commands/swift-style.md` (create the directory if it doesn't exist):

```
---
description: Check Swift style and conventions
allowed-tools: Bash(swiftlint *), Bash(swift-format *)
---

# Swift Style Check

Run linting and formatting checks:
1. Run SwiftLint if configured
2. Run swift-format check
3. Report violations with suggested fixes
```

## Step 4 — Create Agent Skills

Create the following skill directories and files under `.claude/skills/`:

### `.claude/skills/ios-testing/SKILL.md`
```
---
name: ios-testing
description: iOS testing expert for unit tests, UI tests, and test-driven development. Use when working with XCTest, testing SwiftUI views, writing test cases, implementing test strategies, or improving test coverage.
allowed-tools: Read, Grep, Glob, mcp__xcodebuildmcp__test_sim, mcp__xcodebuildmcp__test_device, mcp__xcodebuildmcp__swift_package_test, mcp__xcodebuildmcp__get_coverage_report, mcp__xcodebuildmcp__get_file_coverage
---

# iOS Testing Expert

## Instructions
1. Analyze existing test coverage using coverage tools
2. Identify untested code paths and edge cases
3. Generate comprehensive test cases
4. Use XCTest and Swift Testing frameworks

## Best Practices
- Test behavior, not implementation details
- Use dependency injection for testability (protocols over concrete types)
- Mock external dependencies (gRPC repositories, audio services)
- Target 80%+ code coverage for critical paths (ViewModels, Repositories)
- Use `@MainActor` in tests that call `@MainActor`-isolated code
- Prefer `async/await` test patterns over expectations for streaming tests

## Project-Specific Patterns

### ViewModel Testing
```swift
@MainActor
final class ExampleViewModelTests: XCTestCase {
    var sut: ExampleViewModel!
    var mockRepository: MockLearningRepository!

    override func setUp() {
        mockRepository = MockLearningRepository()
        sut = ExampleViewModel(repository: mockRepository)
    }
}
```

### Streaming / gRPC Testing
- Use `AsyncStream` to mock streaming responses
- Cancel tasks in `tearDown` to prevent test leaks
- Test both success and error paths for every stream

### Coverage Check
After writing tests, run coverage report and report gaps.
```

### `.claude/skills/code-analyzer/SKILL.md`
```
---
name: code-analyzer
description: Read-only code analysis for architecture review and code quality assessment. Use when reviewing PRs, analyzing codebase structure, assessing architecture decisions, or auditing code quality without making changes.
allowed-tools: Read, Grep, Glob
---

# Code Analyzer (Read-Only)

## Review Checklist
1. **Code organization and structure** — follows Features/Core/App layering
2. **Error handling patterns** — no `fatalError`/`preconditionFailure` in production code
3. **Performance considerations** — `@MainActor` isolation, no blocking on main thread
4. **Security concerns** — no hardcoded secrets, safe data handling
5. **Test coverage gaps** — untested ViewModels, uncovered Repository paths

## Project-Specific Checks

### Architecture Compliance
- ViewModels are `@MainActor ObservableObject` with `@Published` properties
- Repositories use protocol + ConnectNIO gRPC implementation
- Views have no business logic (delegate to ViewModel)
- No direct Repository access from Views

### SwiftUI Patterns
- Views avoid `@State` for non-transient UI state
- Navigation handled by `AppCoordinator`, not inline `NavigationLink`
- No `ObservableObject` retained directly in View body

### gRPC / Streaming
- Stream tasks are properly cancelled on deinit / task cancellation
- No force-unwrapping of gRPC response fields

## Output Format
Provide detailed findings organized by severity:
- 🔴 Critical (security, crashes)
- 🟡 Warning (architecture violations, missing tests)
- 🟢 Suggestion (style, readability)

Do not modify any files.
```

### `.claude/skills/swiftui-components/SKILL.md`
```
---
name: swiftui-components
description: SwiftUI component expert for building reusable views, custom modifiers, and view compositions. Use when creating new SwiftUI views, building UI components, refactoring view hierarchies, or implementing custom ViewModifiers in this iOS project.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# SwiftUI Components

## Quick Start
For standard patterns and conventions, see [PATTERNS.md](PATTERNS.md).
For common SwiftUI API reference, see [REFERENCE.md](REFERENCE.md).
For file templates, see the `templates/` directory.

## Instructions
1. Analyze the required component functionality and intended use
2. Check existing components via Glob/Grep for reuse before creating new ones
3. Apply templates from `templates/` directory as starting points
4. Follow project styling conventions (iOS 17+, no UIKit bridging unless necessary)

## Project Conventions
- All ViewModels must be `@MainActor final class` conforming to `ObservableObject`
- Views receive ViewModel via `@StateObject` (owner) or `@ObservedObject` (non-owner)
- No business logic inside View `body` — delegate to ViewModel methods
- Use `@Environment` for navigation actions injected by AppCoordinator
- Preview providers required for every new view
```

### `.claude/skills/swiftui-components/PATTERNS.md`
```
# SwiftUI Patterns

## ViewModel Pattern

```swift
@MainActor
final class ExampleViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .idle

    private let repository: LearningRepositoryProtocol

    init(repository: LearningRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            let data = try await repository.fetchSomething()
            state = .loaded(data)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

## View Pattern

```swift
struct ExampleView: View {
    @StateObject private var viewModel: ExampleViewModel

    init(viewModel: ExampleViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading: ProgressView()
        case .loaded(let data): DataView(data: data)
        case .error(let msg): Text(msg).foregroundStyle(.red)
        }
    }
}
```

## Navigation Pattern (AppCoordinator)

Views receive navigation callbacks via closures — never navigate directly:

```swift
struct ExampleView: View {
    var onNext: () -> Void

    var body: some View {
        Button("Continue", action: onNext)
    }
}
```

## Subview Extraction Rule

Extract to a separate file when:
- Body exceeds ~50 lines
- Component is reused in 2+ places
- Component has its own interaction state
```

### `.claude/skills/swiftui-components/REFERENCE.md`
```
# SwiftUI API Reference

## State Management

| Property Wrapper | When to Use |
|-----------------|-------------|
| `@StateObject` | View owns the ViewModel (init site) |
| `@ObservedObject` | View receives ViewModel from parent |
| `@State` | Transient, local UI state (animation flags, focus) |
| `@Binding` | Two-way data flow from parent to child |
| `@Environment` | Injected values (dismiss, colorScheme, custom actions) |

## Task Lifecycle

```swift
.task { await viewModel.loadData() }           // auto-cancelled on disappear
.task(id: someId) { await viewModel.reload() } // re-runs when id changes
```

## Common Modifiers

```swift
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 16)
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

## iOS 17+ Note

Current project uses `ObservableObject` + `@Published`. Do not migrate to `@Observable` macro until confirmed.
```

### `.claude/skills/swiftui-components/templates/view-template.swift`
```swift
import SwiftUI

struct FeatureNameView: View {
    @StateObject private var viewModel: FeatureNameViewModel

    init(viewModel: FeatureNameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .task { await viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        // TODO: implement view body
        EmptyView()
    }
}

#Preview {
    FeatureNameView(viewModel: FeatureNameViewModel())
}
```

### `.claude/skills/swiftui-components/templates/viewmodel-template.swift`
```swift
import Foundation

@MainActor
final class FeatureNameViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published private(set) var state: ViewState = .idle

    private let repository: LearningRepositoryProtocol

    init(repository: LearningRepositoryProtocol) {
        self.repository = repository
    }

    func onAppear() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            // TODO: implement load logic
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

## Step 5 — Create Subagents

Create the following files under `.claude/agents/`:

### `.claude/agents/ios-architect.md`
```
---
name: ios-architect
description: iOS architecture expert for system design, layer separation, and patterns. Use when designing data layers, planning new features architecturally, evaluating MVVM compliance, or deciding between patterns.
model: claude-opus-4-6
tools: Read, Grep, Glob
---

You are an expert iOS architect specializing in Swift and SwiftUI.

Your expertise includes:
- MVVM, Clean Architecture, Dependency Injection
- Swift Concurrency (actors, async/await, Sendable, `@MainActor`)
- SwiftUI navigation patterns (Coordinator)
- Protocol-oriented design for testability
- Modular feature architecture

When consulted:
1. Read the relevant files to understand current patterns
2. Analyze scalability and maintainability implications
3. Propose patterns consistent with the existing codebase
4. Provide concrete Swift code examples
5. Consider testing implications (protocols over concrete types)

Hard rules:
- No `fatalError()` / `preconditionFailure()` in production code
- All ViewModel logic must be `@MainActor` isolated
- No hardcoded secrets

Focus on practical, production-ready advice.
```

### `.claude/agents/swift-reviewer.md`
```
---
name: swift-reviewer
description: Code reviewer for Swift/SwiftUI code quality, concurrency safety, and architecture compliance. Use when reviewing PRs, auditing code for memory issues, checking Swift 6 concurrency correctness, or validating streaming patterns.
model: claude-sonnet-4-6
tools: Read, Grep, Glob
---

You are an expert Swift code reviewer.

Review code for:
- Swift 6 concurrency safety (`@MainActor`, Sendable, data races)
- Memory management (retain cycles, weak references, Task leaks)
- SwiftUI best practices (state ownership, view/logic separation)
- Architecture compliance (MVVM, no business logic in Views)
- Performance considerations
- Test coverage gaps
- Security issues (no hardcoded secrets, no force-unwrap on external data)

Output format — organize by severity:
- 🔴 Critical (crashes, data races, security)
- 🟡 Warning (architecture violations, missing cancellation)
- 🟢 Suggestion (style, readability)

Provide specific line references and corrected code snippets. Do not modify files.
```

### `.claude/agents/swiftui-specialist.md`
```
---
name: swiftui-specialist
description: SwiftUI expert for complex UI implementation, custom layouts, animations, and view composition. Use when building non-trivial UI components, implementing custom animations, debugging layout issues, or optimizing SwiftUI rendering performance.
model: claude-sonnet-4-6
tools: Read, Write, Edit, Glob, Grep
---

You are a SwiftUI specialist with deep knowledge of:
- Custom `Layout` protocol and `GeometryReader`
- `matchedGeometryEffect` and animation modifiers
- Custom `ViewModifier`, `ButtonStyle`, `LabelStyle`
- `PreferenceKey` for child-to-parent communication
- `@Environment` and `EnvironmentObject` injection
- `NavigationStack` with typed `NavigationPath`
- Performance: `equatable`, `drawingGroup()`, avoiding unnecessary re-renders
- Accessibility: labels, hints, traits

When building UI:
1. Start with the simplest approach
2. Extract reusable components when body exceeds ~50 lines
3. Use proper state management — no `@State` for ViewModel data
4. Ensure accessibility labels on interactive elements
5. Consider small screen (iPhone SE) and iPad layouts

Constraints:
- iOS 17+ APIs allowed
- No UIKit bridging unless absolutely necessary
- No `fatalError()` in View code
```

### `.claude/agents/ios-researcher.md`
```
---
name: ios-researcher
description: Research iOS APIs, Swift Evolution proposals, and best practices. Use when evaluating new Apple APIs, investigating WWDC content, checking iOS version compatibility, or exploring community best practices.
model: claude-opus-4-6
tools: WebSearch, WebFetch, Read
---

You are an iOS research specialist.

When researching:
1. Search Apple Developer Documentation (developer.apple.com/documentation)
2. Find relevant WWDC sessions (developer.apple.com/videos)
3. Check Swift Evolution proposals if language features are involved
4. Look for community best practices (Swift Forums, Swift by Sundell, Donny Wals)
5. Summarize findings with concrete Swift code examples

Output format:
- **Summary**: 2-3 sentence TL;DR
- **iOS Version Requirement**: minimum iOS version
- **Code Example**: minimal working example
- **Caveats / Known Issues**: gotchas, deprecated alternatives
- **Sources**: links to official docs and WWDC sessions

Always note if a feature requires iOS 18+ (may need conditional availability).
```

## Step 6 — Create Output Style

Create `.claude/output-styles/ios-mentor.md`:

```
---
name: iOS Mentor
description: Teaching-focused style for iOS development with explanations and learning opportunities
keep-coding-instructions: true
---

# iOS Mentor Style

You are an iOS development mentor helping developers learn Swift and SwiftUI.

## Behaviors
1. Explain **why** before showing **how**
2. Reference Apple documentation and WWDC sessions
3. Point out common pitfalls and Swift idioms
4. Suggest further learning resources
5. Add `// 💡 Learn: ...` comments explaining key concepts

## Teaching Approach
- Start with the concept, then show implementation
- Compare approaches when multiple valid options exist
- Highlight Swift 6 and iOS 18 modern patterns
```

---

All steps complete. Confirm by listing `.claude/` directory contents.
