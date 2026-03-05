# AGENTS.md

This file contains guidelines and commands for agentic coding agents working in this Odin codebase.

## Build/Test Commands

### Compilation

```bash
# Build the main executable
odin build .

# Build and run directly
odin run .

# Check syntax and type errors without building
odin check .

# Generate documentation
odin doc .
```

### Testing

```bash
# Run all tests in the project
odin test tests/

# Run a specific test file
odin test tests/url.test.odin

# Run tests with verbose output
odin test tests/ -verbose

# Run tests with specific allocator (if needed)
odin test tests/ -allocator=context.temp_allocator
```

## Code Style Guidelines

### Package Structure

- All source files should declare `package odeps_core` (or appropriate package name)
- Test files should declare `package url_tests` (or test-specific package name)
- Keep package names consistent across related files

### Naming Conventions

- **Types**: PascalCase (e.g., `Url_Parser`, `Url_Error`)
- **Procedures**: snake_case (e.g., `parse_url`, `consume_rune`)
- **Variables**: snake_case (e.g., `parser`, `current`, `errors`)
- **Constants/Enums**: PascalCase (e.g., `Url_Step`, `Url_Error`)
- **Private procedures**: Prefix with `@(private)` attribute

### Error Handling

- Use `assert` for critical failures that should never occur
- Use error enums for recoverable errors (e.g., `Url_Error`)
- Return error values as slices when multiple errors possible: `[]Url_Error`
- Use `defer` for cleanup operations

### Memory Management

- Use `context.allocator` for dynamic allocations
- Use `context.temp_allocator` for temporary allocations in tests
- Prefer `context.temp_allocator` or arena allocator over `context.allocator`
- Place the defer statement for freeing as close of the allocation if possible

### Procedure Attributes

- Use `@(test)` for test procedures
- Use `@(private)` for internal procedures

### Code Formatting

- Use 4 spaces for indentation (no tabs)
- Place opening braces on the same line for procedures
- Use blank lines to separate logical sections
- Add comments for complex logic or external API interactions

### Testing Guidelines

- Use `testing.expect_value(t, actual, expected)` for assertions
- Use `testing.expect(t, condition, "message")` for boolean checks
- Always clean up temporary allocations with `defer free_all(allocator)`
- Test files should import the source module with relative paths

### Documentation

- Add brief comments for public APIs
- Document complex parsing logic
- Include usage examples for main procedures

## Development Workflow

1. **Before making changes**: Run `odin check src/` to ensure clean syntax
2. **After changes**: Run `odin test tests/` to verify all tests pass

## Notes

- This is an Odin codebase - Odin is a systems programming language
- The compiler must be installed and available in PATH
- Tests use the built-in testing framework with `@(test)` attribute
- Memory management is explicit and requires careful allocator usage
