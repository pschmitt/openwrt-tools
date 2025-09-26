# Agent Instructions

These instructions apply to the entire repository for GitHub Copilot, ChatGPT, and any other coding assistants contributing here.

## Shell scripts (bash)
- Bash is the standard shell for this project. Use `#!/usr/bin/env bash` for new scripts and assume Bash semantics when editing existing ones.
- Run `shellcheck` on every modified shell script before submitting changes. Treat all warnings as actionable unless explicitly suppressed with a justification.
- Prefer the Bash `[[ ... ]]` test command for conditionals; reserve `[` for POSIX `sh` scripts only.
- Never place multiple statements on the same line. For conditionals and loops, always use the multi-line form:
  ```bash
  if condition
  then
    ...
  fi
  ```
  The same spacing rule applies to `while`, `until`, and similar constructs.
- Indent block bodies with two spaces. Align `then`, `do`, `elif`, and `else` with their corresponding `if`/`while`/`for` keywords.
- Declare `local` variables immediately before their first use and never inside loops. Avoid redundant initialisation such as `local x=""`; prefer `local x` and assign later.
- When a `local` variable is used as a flag, leave it unset until the condition is met and test it with `[[ -n $flag_var ]]` instead of initialising sentinel values and relying on arithmetic evaluation. Avoid patterns such as:
  ```bash
  local found=0
  if condition
  then
    found=1
  fi
  if (( found ))
  then
    ...
  fi
  ```
  Prefer leaving the variable unset and checking it for non-empty content.
- Avoid subshells unless they are required for correctness. Prefer grouping commands with braces or refactoring into helper functions when possible.
- Keep functions focused and reasonably short. If a function needs many positional parameters, refactor it to parse flags or named arguments internally.
- Precede every function definition with a brief comment explaining its purpose.
- When practical, run modified scripts with representative sample data to catch issues such as infinite loops or unexpected exits.

