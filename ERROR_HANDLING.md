# Error Handling Guidelines

This document describes error handling conventions for the narya codebase.

## Error Type Conventions

All custom errors should:
1. Be defined as `enum` types
2. Conform to `Error` and `CustomStringConvertible`
3. Include context-rich associated values
4. Preserve underlying errors when wrapping

### Example: Gold Standard Pattern

```swift
enum MyError: Error, CustomStringConvertible {
    /// Operation failed due to an underlying error.
    case operationFailed(reason: String, underlyingError: Error?)

    /// Validation failed with specific details.
    case validationFailed(details: String)

    var description: String {
        switch self {
        case .operationFailed(let reason, let underlyingError):
            var message = "Operation failed: \(reason)"
            if let error = underlyingError {
                message += " (\(error.localizedDescription))"
            }
            return message
        case .validationFailed(let details):
            return "Validation failed: \(details)"
        }
    }
}
```

## When to Use underlyingError

Include `underlyingError: Error?` when:
- Catching a thrown error and re-throwing a domain-specific error
- Wrapping system errors (file I/O, network, JSON parsing)
- Converting ShellRunnerError to command-specific errors

Do NOT include when:
- The error is a validation failure with no underlying cause
- The error represents a missing resource (not found)

## Throwing vs Herald Reporting

### Throw when:
- The error should stop command execution
- The error is recoverable at a higher level
- You're in a utility/helper function

### Use Herald.declare(asError: true) when:
- Warning the user but continuing execution
- Reporting non-fatal issues mid-command
- The error has already been handled

### Never:
- Silently catch and ignore errors
- Use empty catch blocks without at least logging

```swift
// BAD: Silent failure
do {
    try something()
} catch {
    // Silent - user has no idea what happened
}

// GOOD: Report the error
do {
    try something()
} catch {
    Herald.declare("Could not do something: \(error)", asError: true)
}
```

## Debug Logging

Use `Logger` for debug output that helps troubleshooting:

```swift
Logger.debug("Starting operation with \(args)")
Logger.error("Operation failed", error: error)
```

Debug output:
- Only appears when `--debug` flag is passed
- Goes to stderr (doesn't interfere with normal output)
- Includes file/line for tracing

### Log Levels

- `Logger.debug()` - Detailed trace information for debugging
- `Logger.info()` - General informational messages
- `Logger.warning()` - Potential issues that don't stop execution
- `Logger.error()` - Errors with optional underlying error details

### When to Log

Add debug logging at:
- Entry points of significant operations
- Before and after external process execution (ShellRunner)
- When errors occur (always include the underlying error)
- At decision points that affect behavior

## Testing Errors

Every error case should have tests verifying:
1. Error message contains expected context
2. Underlying errors are preserved
3. Error conforms to required protocols

See `L10nErrorTests.swift` for the pattern:

```swift
@Test("operationFailed includes reason and error details")
func operationFailedMessage() {
    let underlyingError = TestError(message: "Connection refused")
    let error = MyError.operationFailed(
        reason: "Failed to connect",
        underlyingError: underlyingError
    )

    let description = error.description
    #expect(description.contains("Failed to connect"))
    #expect(description.contains("Connection refused"))
}
```

## Error Handling Checklist

When adding new error handling code:

- [ ] Custom error enum conforms to `Error` and `CustomStringConvertible`
- [ ] Cases that wrap errors include `underlyingError: Error?`
- [ ] Description includes underlying error when present
- [ ] No empty catch blocks - always log or report
- [ ] Debug logging added at key decision points
- [ ] Tests cover all error cases

## Examples from the Codebase

### L10nError (Gold Standard)

```swift
case fileReadFailed(path: String, underlyingError: Error)

var description: String {
    case .fileReadFailed(let path, let error):
        return "Failed to read file at '\(path)': \(error.localizedDescription)"
}
```

### SimulatorManagerError

```swift
case simctlFailed(reason: String, underlyingError: Error?)

var description: String {
    case .simctlFailed(let reason, let underlyingError):
        var message = "simctl command failed: \(reason)"
        if let error = underlyingError {
            message += " (\(error.localizedDescription))"
        }
        return message
}
```

### RepoDetectorError

```swift
case invalidMarkerFile(reason: String, underlyingError: Error?)
```
