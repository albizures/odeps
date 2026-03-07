# Agent Instructions for Odin-Tome

This document provides essential instructions for AI agents operating in the `odin-tome` repository. This repository implements "Tome," a simple text-based data interchange format, written in the [Odin programming language](https://odin-lang.org/).

## 1. Build, Test, and Lint Commands

### Testing
Odin features a built-in testing framework. The tests for this repository are located in the `tests/` directory.

- **Run all tests:**
  ```bash
  odin test tests
  ```
  *Note: Always run tests after making code changes to verify parser and tokenizer behavior.*

- **Run a single test:**
  To isolate and run a specific test by its procedure name (e.g., `test_parse_int`), pass the `ODIN_TEST_NAMES` definition:
  ```bash
  odin test tests -define:ODIN_TEST_NAMES="test_parse_int"
  ```
  *Note: Provide the exact procedure name as the argument.*

### Building and Checking
- **Check for syntax/type errors (Fastest):**
  ```bash
  odin check src
  odin check tests
  ```
- **Build the project:**
  ```bash
  odin build src
  ```
- **Format code:**
  Odin has a built-in code formatter. After writing or modifying code, ensure you format it:
  ```bash
  odin fmt src tests -w
  ```

## 2. Code Style and Architectural Guidelines

### Naming Conventions
- **Procedures and Variables**: Use `snake_case`. (e.g., `parse_object_members`, `advance_token`, `curr_token`).
- **Types, Structs, Unions**: Use `Pascal_Case_With_Underscores`. (e.g., `Parser`, `Tome_Error`, `Value`).
- **Enum Members / Constants**: Use `Pascal_Case_With_Underscores` or `PascalCase`. (e.g., `Invalid_Token`, `Expect_Comma`).

### Formatting & Syntax
- **Indentation**: Use **tabs** for indentation and spaces for alignment. The `odin fmt` tool handles this natively.
- **Braces**: The opening brace `{` goes on the same line as the statement (`struct`, `proc`, `switch`, `if`).
- **Switch Statements**: Utilize `#partial switch` when handling enums if not all cases are explicitly managed. This suppresses compiler warnings regarding unhandled cases.
- **Implicit Returns**: Odin supports named return values (e.g., `proc(p: ^Parser) -> (result: Object)`). Ensure `return` statements are clean and correctly populate named returns.

### Memory Management & Types
- **Allocators**: Never rely exclusively on a global allocator for structures that have variable lifespans. Procedures that perform allocations should accept a `mem.Allocator` as an argument.
- Use `context.temp_allocator` when allocating temporary data that will not persist beyond the current scope or request cycle.
- **Arrays**:
  - `[dynamic]Type` for resizable arrays.
  - Return slices `[]Type` when exposing internal dynamic arrays (e.g., `return parser.errors[:]`).
- **Pointers**: Pass by pointer `^Type` when modifying structs (e.g., `proc(p: ^Parser)`).

### Error Handling
- Do not heavily rely on `panic` for parser errors.
- Accumulate errors in a dynamic array and return them to the caller alongside the parsed structure.
  ```odin
  // Example pattern from src/parser.odin:
  Parser :: struct {
      errors: [dynamic]Tome_Error,
      // ...
  }
  ```
- Always ensure the parser gracefully advances tokens (`advance_token(p)`) even upon encountering an error to prevent infinite loops during error recovery.

### Imports
- Declare `package` at the very top of the file.
- Use multiple `import` lines for clarity. Do not group them in a block unless idiomatic.
- Scope core libraries under `core:` (e.g., `import "core:mem"`, `import "core:strconv"`).

## 3. Tool Usage Constraints (For AI Agents)
- **File modification**: Always use the project's relative `src/` and `tests/` directories.
- **Verification**: Once you modify `.odin` files, run `odin check src && odin test tests` via Bash before reporting completion to the user.
- **Context limit**: Read only the necessary slices of `src/tokenizer.odin` or `src/parser.odin` to understand the state machine before generating parsing logic.
