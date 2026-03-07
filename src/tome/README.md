# Tome

Tome is a simple text-based format for data interchange. It is designed to be a lightweight alternative to JSON and TOML.

Tome looks similar to TOML but it's more like JSON with some tweaks here and there. All Tome files are objects or arrays without exception.

## Current Status

**⚠️ Work In Progress (WIP) / Under Development**
This project is currently under heavy development. Features and syntax may change.

## Features & Syntax

- **Line Comments**: Only supports line comments using the `#` symbol.
- **Key-Value Pairs**: Just like JSON, there are key-value pairs (spaces between equal signs are optional).
- **Unquoted Keys**: Unlike JSON, there are no quotes around keys.
- **Strings**: Enclosed in double quotes. They are multi-line by default. Escaping works just like JSON.
- **Literals**: Supports literal values for numbers and booleans.
- **Arrays**: Supports arrays, which can be nested and multi-line.
- **Objects**: Supports nested objects.

### Example

```tome
# Tome is a simple text-based format for data interchange.
# It only supports line comments by using the `#` symbol. Like this one

# Tome looks similar to TOML but it's more like JSON with some tweaks here and there
# All tome files are objects or arrays without exception

# Just like JSON, there are key-value pairs (spaces between equal signs are optional)
# But unlike JSON, there are no quotes around keys
# Strings are enclosed in double quotes
title = "Example file", # comments are supported at the end of the line too

# strings are multi-line by default
multi_line_string = "This is a multi-line string.
It can span multiple lines.",

escaped = "This is an escaped string with a backslash: \\", # just like JSON

# Support literal values for numbers and booleans
enabled = true,
port = 8080,

# Support arrays, which can be nested
array = [1, 2, 3],

# Unlike TOML arrays can be multi-line
array = [
    1,
    2,
    3,
],

# Support objects
object = {key = "value"},

# And a combination of arrays and objects
combination = {
	values: [1, 2, 3]
},
```

## Installation

Since Tome is an Odin library, the best way to use it is to add it to your existing Odin project. You can do this by either:

1. Adding it as a git submodule:
    ```bash
    git submodule add <repository-url> tome
    ```
2. Downloading the source directly and placing it in your project's directory.

Then, you can import it in your Odin code (assuming you placed it in a directory named `tome`):

```odin
import "tome"
```

## Running Tests

To run the test suite for the parser and tokenizer:

```bash
odin test tests
```
