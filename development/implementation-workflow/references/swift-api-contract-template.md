# Swift Multi-Module API Contract Template

Use this template when dispatching parallel subagents to build different modules of a Swift project.

## Why This Exists

Without a contract, each subagent invents its own APIs:
- Core writes `func process(pixels: [Float], width: Int, height: Int) -> [Float]`
- UI writes `pipeline.process(&working)` (expects inout)
- Result: 50-100 compilation errors, hours of fixing

## Template

```markdown
# API Contract — All Modules MUST Follow

## Global Functions
\```swift
public func clamp<T: Comparable>(_ x: T, _ lo: T, _ hi: T) -> T
\```

## ModuleA.swift
\```swift
public final class ModuleA: @unchecked Sendable {
    public var property: Type
    public init()
    public func method(param: Type) -> ReturnType
    public func toDict() -> [String: Any]
    public func fromDict(_ d: [String: Any])
}
\```

## ModuleB.swift
\```swift
public enum SomeEnum: String, CaseIterable {
    case case1, case2
}
public struct SomeStruct {
    public let width: Int
    public init(width: Int, height: Int)
}
\```
```

## Rules

1. **Every public type** must be listed with exact signature
2. **Every parameter** must specify label, type, and default value
3. **Return types** must be exact (don't write "returns data" — write `-> [Float]`)
4. **Mutating vs non-mutating** must be explicit (`inout` vs return new value)
5. **Optional vs non-optional** must be explicit (`Type?` vs `Type`)
6. **Enum cases** must be listed exhaustively
7. **Default values** must be specified for all optional parameters

## Common Swift Pitfalls in Multi-Agent Code

| Pitfall | Example | Fix |
|---------|---------|-----|
| inout vs return | Agent A: `func apply(_ pixels: inout [Float])` / Agent B: `let result = apply(to: pixels)` | Pick ONE pattern in contract |
| URL vs String | Agent A: `func load(from: URL)` / Agent B: `pipeline.load(path: myString)` | Specify exact type in contract |
| Optional unwrap | Agent A: `func load() -> ImageData?` / Agent B: `pipeline.load().width` | Specify if optional in contract |
| Static vs instance | Agent A: `static func apply(...)` / Agent B: `instance.apply(...)` | Specify in contract |
| Property naming | Agent A: `.tmP` / Agent B: `.toneMapP` | List ALL property names in contract |
