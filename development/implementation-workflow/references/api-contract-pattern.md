# API Contract Pattern for Multi-Agent Implementation

When dispatching 3+ agents to write code in parallel, API mismatches are **guaranteed** without a contract.

## The Problem

Agent A writes `func process(pixels: [Float], width: Int, height: Int) -> [Float]`
Agent B writes code calling `pipeline.process()` returning `[Float]` (no params)
→ 47 compilation errors, hours of fixing.

## The Solution: API Contract Document

Create a file like `API-CONTRACT.md` before dispatching agents. Each agent reads it.

### Contract Format

```markdown
## ImageIO.swift
```swift
public struct ImageData {
    public let width: Int
    public let height: Int
    public var pixels: [Float]  // flat R,G,B,R,G,B,...
    public init(width: Int, height: Int, pixels: [Float])
}
public enum ExportFormat { case tiff, jpeg, heic }
public enum ImageIO {
    static func load(from url: URL) -> ImageData?
    static func save(_ img: ImageData, to url: URL, format: ExportFormat) -> Bool
}
```

## Pipeline.swift
```swift
public final class Pipeline {
    public var basePixels: [Float]
    public var imageWidth: Int, imageHeight: Int
    public func load(from url: URL) -> Bool
    public func process() -> [Float]
    public func autoAnalyze()
}
```
```

### Key Rules

1. **Exact signatures** — include full parameter labels and return types
2. **Shared types first** — define structs/enums that multiple modules use
3. **Flat arrays always** — specify `[Float]` layout (RGB vs RGBA) explicitly
4. **Pass to all agents** — include the contract in every agent's `context` field
5. **One writer per file** — never let two agents write the same file

## Real-World Example (Sezhao project)

Three agents writing Swift image processing code:

Agent 1 (Core): Package.swift + Logger + ImageIO + Pipeline
Agent 2 (UI): AppViewModel + ContentView + ImageView + CropOverlay
Agent 3 (Metal): MetalRenderer + Shaders + App entry

Each agent received the full API contract. Build succeeded on first try (after Agent 1 completed).
