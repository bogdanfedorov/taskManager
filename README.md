# Task tracker (TASKS.md + Makefile)

A minimal task tracker: one markdown file and a few `make` targets. No dependencies beyond `make`, `awk`, `sed` and `grep`. Designed for both humans and AI agents.

## File format

File: `$(TASKS)` (defaults to `TASKS.md` in the project root). **One task = one line**:

```
- [ ] B1 [todo] Orders table schema
- [ ] B2 [model] Order model
- [x] C5 [done] Users migration
```

Line grammar:

```
- [<mark>] <ID> [<status>] <text>
```

| Field    | Rule |
|----------|------|
| `mark`   | a space unless the status is `done`; `x` when `done`. Managed automatically, do not edit by hand |
| `ID`     | `^[A-Z]+[0-9]+$`, e.g. `B1`, `C5`, `API12`. Must be unique. Case is normalized to uppercase |
| `status` | one of: `todo`, `docs`, `model`, `tests`, `code`, `done` |
| `text`   | free text to the end of the line, no line breaks |

Regex for parsing:

```
^- \[( |x)\] ([A-Z]+[0-9]+) \[(todo|docs|model|tests|code|done)\] (.*)$
```

## Lifecycle (statuses)

```
todo → docs → model → tests → code → done
```

| Status  | Meaning |
|---------|---------|
| `todo`  | task is recorded, work has not started |
| `docs`  | writing or clarifying documentation / specification |
| `model` | designing the data model, types, interfaces |
| `tests` | writing tests (before the implementation) |
| `code`  | writing the implementation until the tests pass |
| `done`  | everything is finished, tests are green, docs are up to date |

Status normally moves forward one step at a time (`task-next`), but `task-st` can set any status, for example to move a task back.

## Commands

| Command | Action |
|---------|--------|
| `make tasks` | list all tasks |
| `make tasks S=tests` | only tasks with status `tests` |
| `make tasks Q=text` | search by ID and text (case-insensitive) |
| `make tasks S=code Q=api` | filters can be combined |
| `make task-find Q=text` | same as `tasks Q=...` |
| `make task-add ID=B1 T="text"` | add a task with status `todo` |
| `make task-st ID=B1 S=docs` | set status |
| `make task-next ID=B1` | advance to the next status |
| `make task-rm ID=B1` | remove a task |

`make tasks` prints columns `ID  STATUS  TEXT`:

```
B1     docs   Orders table schema
C5     done   Users migration
```

If nothing is found, it prints `no tasks` (file is empty) or `no matches` (filters matched nothing).

### Exit codes and errors

All errors return exit code `1` and print a single message:

| Message | Cause |
|---------|-------|
| `usage: ...` | a required parameter is missing |
| `bad ID 'x' (expected like B1, C5)` | ID does not match the format |
| `B1 already exists` | duplicate ID |
| `no task B1` | no task with that ID |
| `status must be one of: ...` | invalid status |
| `B1 is already done` | `task-next` on a finished task |

## Rules for AI agents

1. **Modify the file only through `make`.** Do not edit `TASKS.md` by hand and do not rewrite it wholesale. This keeps the format intact.
2. **Before starting work**, run `make tasks` to see the current state. Use `make tasks Q=...` to find a relevant task.
3. **Do not invent IDs.** If the task does not exist, add it with `task-add`. The ID is chosen by the human or by convention (letter prefix = area, number = sequence). If unsure, ask.
4. **Never reuse IDs** of removed tasks.
5. **Move the status together with the actual work**, right after finishing a stage:
   - finished the specification → `docs`
   - described the model/types → `model`
   - wrote the tests → `tests`
   - implemented it and tests pass → `code`
   - everything verified → `done`
6. **Set `done` only after verification** (tests pass, docs are up to date). Never mark `done` on a guess.
7. **One task = one sentence.** Keep long descriptions in separate files (docs/) and leave only a short title or a link in the task.
8. **Check the exit code.** A non-zero code means the change did not happen. Fix the parameters rather than working around it by editing the file manually.
9. Always quote parameters containing spaces: `T="text with spaces"`.

## Typical agent session

```sh
make tasks                                   # what exists
make task-add ID=B1 T="Orders table schema"
make task-st ID=B1 S=docs                    # started with the spec
# ... wrote the spec ...
make task-next ID=B1                         # docs -> model
# ... described the model ...
make task-next ID=B1                         # model -> tests
# ... wrote the tests ...
make task-next ID=B1                         # tests -> code
# ... implemented, tests green ...
make task-next ID=B1                         # code -> done
make tasks S=done                            # verify
```

## Configuration

```make
TASKS    ?= TASKS.md                         # path to the file; override with: make tasks TASKS=other.md
STATUSES := todo docs model tests code done  # order defines what task-next does
```

To change the stages, edit `STATUSES` in the Makefile. The order of words in the list is the lifecycle order. If you rename statuses, also update the `[a-z]*` pattern in `task-st` when the new names contain digits or hyphens.

## Requirements

- GNU make or compatible
- POSIX `sh`, `awk`, `sed`, `grep`, `tr`, `mv`
- Recipe lines in the Makefile must be indented with **tabs**

## Integrating into an agent workflow

Add to `AGENTS.md` / `CLAUDE.md` / the agent's system instructions:

```md
## Tasks
Tasks are tracked in TASKS.md via the Makefile. Full description: README-tasks.md.
- View state: `make tasks`, search: `make tasks Q=...`
- Add: `make task-add ID=B1 T="text"`
- Status: `make task-next ID=B1` or `make task-st ID=B1 S=<status>`
- Statuses: todo → docs → model → tests → code → done
- Do not edit TASKS.md by hand. Mark `done` only after green tests and updated docs.
```
