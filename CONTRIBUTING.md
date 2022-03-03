# Contributing to bump-everywhere

First off, thanks for taking the time to contribute! 💓

You can contribute by:

- creating pull requests,
- creating or responding to [issues](https://github.com/undergroundwires/bump-everywhere/issues),
- supporting the development and maintainance by [sponsoring me on GitHub](https://github.com/sponsors/undergroundwires) with a single time donation or reccuring donations, see more options in [undergroundwires.dev/donate](https://undergroundwires.dev/donate/),
- giving the project a star,
- or adding a badge in a project you use bump-everywhere, see [support](./README.md#support).

## Development environment

If you're using visual studio code, [recommended extensions](./.vscode/extensions.json) would install useful linters and extensions.

## Tests

**Automated tests**:

- Test all: `bash ./tests/run.sh`.
- Defined as `.test.sh` files in [`./tests`](./tests/).

- **Manual tests**: See documentation in [docker-entrypoint](./tests/docker-entrypoint)

## Style guide

- Do not introduce any TODO comments, fix them or do not introduce the change.
- Use common sense, simpler is better.

### Shell scripting

- Use [ShellCheck](https://www.shellcheck.net/) to lint your code.
- Always check for return values.
- Declare function-specific variables as `local`.
- Declare variables as readonly whenever possible.
  - E.g. `local -r ..`, `declare -r ..` or `readonly ..`.
- Send all errors messages to stderr.
  - E.g. `>&2 echo 'Error!'`.
- Use always `#!/usr/bin/env bash` shebang.
- Wrap long lines.
- Use `[[ … ]]` over `[ … ]`, `test`.
- Avoid eval at all cost.

#### Naming conventions

**Source file names:**

- Use `kebab-case.sh`.
- For tests, use `.test` suffix such as `<system-under-test>.test.sh`.

**Function names:**

- Use snake_case. E.g. `my_func() { ... }`
- Prefix functions in files that others files source with a scope name and `::`. E.g. `utilities::has_value() { }`.

**Variable names**:

- Use snake_case for local variables.
- Use ALL_CAPS_SEPARATED_WITH_UNDERSCORES for constant and environment variable names.
