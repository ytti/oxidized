# AGENTS.md

Guidance for AI coding agents working in the Oxidized repository. Human
contributors should read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[docs/](docs/) folder.

## Project overview

Oxidized is a network device configuration backup tool (a RANCID replacement)
written in Ruby. It logs into network devices, runs commands, and stores the
resulting configuration in an output backend (git, file, ...). It supports
150+ device types through "models".

Core concepts:

- **Model** ([lib/oxidized/model/](lib/oxidized/model/)) – describes how to talk
  to one OS type: prompt, commands, comment style, secret removal, etc. Uses a
  Ruby DSL built on `Oxidized::Model`.
- **Input** ([lib/oxidized/input/](lib/oxidized/input/)) – transport such as
  `ssh`, `telnet`, `ftp`, `scp`.
- **Output** ([lib/oxidized/output/](lib/oxidized/output/)) – where configs are
  stored (`git`, `file`, ...).
- **Source** ([lib/oxidized/source/](lib/oxidized/source/)) – where the node
  list comes from (`csv`, `sql`, `http`, ...).
- **Node / Nodes / Job / Worker** ([lib/oxidized/](lib/oxidized/)) – the
  scheduling and execution core.

## Environment & common commands

Dependencies are managed with Bundler into `vendor/bundle`. Prefix commands with
`bundle exec`.

```bash
bundle config set --local path 'vendor/bundle'
bundle install

bundle exec rake              # default task (rubocop + minitest)
bundle exec rake test         # run the whole test suite (minitest)
bundle exec rubocop           # lint / style
bundle exec bin/oxidized      # run Oxidized locally
```

Run a single model test while iterating:

```bash
bundle exec rake test TESTOPTS="--verbose --name=/ios#C9800.*output/"
```

Use `OXIDIZED_HOME` to point at a custom config directory instead of
`~/.config/oxidized/`.

## Communication

- Respond to the user in the language they write in.
- **All code, identifiers, comments, commit messages and documentation must be
  in English.**

## Coding conventions

- Target Ruby `>= 3.0` (see [oxidized.gemspec](oxidized.gemspec)). Do not use
  syntax or stdlib features newer than 3.0.
- Follow RuboCop; the config lives in [.rubocop.yml](.rubocop.yml). Run
  `bundle exec rubocop` before finishing and fix offenses instead of disabling
  cops, unless a disable is clearly justified.
- Strings: prefer `"double quotes"`; use `'single quotes'` to signal that string
  interpolation is intentionally not wanted (not enforced by RuboCop).
- Max line length is 120 (models under `lib/oxidized/model/*.rb` are exempt from
  the RuboCop check, but keep new model lines reasonable — aim for 80 characters
  where possible, without forcing it).
- **Comments should be sparse and concise.** Only comment when the code is not
  self-evident (a non-obvious device quirk, a workaround, a referenced issue).
  Do not add comments, docstrings, or type annotations to code you did not
  change.
- Keep changes focused and minimal. Do not refactor or "clean up" unrelated code
  as part of an unrelated fix.

## Working on models

Read these before touching a model:

- [docs/Creating-Models.md](docs/Creating-Models.md) – model structure, DSL,
  common tasks (`enable`, `clean :escape_codes`, `reject_lines`, ...).
- [docs/Ruby-API.md](docs/Ruby-API.md) – available DSL methods.
- [docs/DeviceSimulation.md](docs/DeviceSimulation.md) – simulation files.
- [docs/ModelUnitTests.md](docs/ModelUnitTests.md) – how models are tested.

Notes:

- A model file is named after the OS type and defines a class of the same name
  inheriting from `Oxidized::Model` (or from another model such as `Defacto`).
- Prefer extending existing behaviour with the DSL (`cmd`, `pre`/`post`,
  `prompt`, `comment`, `cfg`, `macro`) over ad-hoc Ruby.
- When adding a new model, add it to
  [docs/Supported-OS-Types.md](docs/Supported-OS-Types.md).

## Testing conventions

Model unit tests are data-driven from [spec/model/data/](spec/model/data/) and
run automatically by `rake test`. Relevant file suffixes for a given
`<model>#<description>`:

- `#simulation.yaml` – recorded device session (input for the test).
- `#output.txt` – expected rendered configuration.
- `#prompt.yaml`, `#secret.yaml`, `#significant_changes.yaml` – optional focused
  tests.

Generate a missing `#output.txt` from the current model:

```bash
bundle exec ruby spec/model/atoms_generate.rb
```

Custom Ruby tests live in `spec/**/*_spec.rb` (minitest + mocha). Use the
`#custom_simulation.yaml` suffix for custom simulation data so it does not
collide with the automatic tests.

## IMPORTANT: never generate YAML simulation files

An agent must **never** create or hand-write a device simulation YAML file
(`spec/model/data/*#simulation.yaml`). These files must be captured from a real
device so that ANSI escape codes, `\r`, trailing spaces (`\x20`), prompts and
timing are faithful — hand-crafted data produces misleading tests.

Instead, **guide the user** to record one themselves, using one of:

1. **`extra/device2yaml.rb`** – connects over SSH and records the session. See
   [docs/DeviceSimulation.md](docs/DeviceSimulation.md#creating-a-yaml-simulation-file-with-device2yamlrb).
   Example:

   ```bash
   extra/device2yaml.rb oxidized@device \
     -c "terminal length 0
   show version
   show running-config
   exit" \
     -o spec/model/data/ios#C8200L_16.12.1#simulation.yaml
   ```

2. **`input.debug: yaml`** (Oxidized `>= 0.37.0`) – lets a running Oxidized
   instance write the simulation file from a real backup session into
   `~/.config/oxidized/logs/`. See
   [docs/DeviceSimulation.md](docs/DeviceSimulation.md#creating-a-yaml-simulation-file-with-the-debug-option).

   ```yaml
   input:
     default: ssh
     debug: yaml
   ```

Remind the user to redact secrets (passwords, IP addresses, serial numbers)
before committing, and to follow the
`<model>#<hardware>_<software>#simulation.yaml` naming convention. Once the user
provides a real simulation file, the agent may generate/adjust the matching
`#output.txt` and edit the model.

The agent may help redact secrets in a captured simulation file, but must leave
the first and last line of each command output unchanged: they contain the
command echo and the following prompt, which Oxidized relies on for prompt
detection.

## Contribution workflow

- Branch names may be prefixed with the issue number (e.g.
  `1234-short-description`).
- Keep commits small and messages descriptive; they appear in the pull request.
- Before opening a PR: `bundle exec rubocop` and `bundle exec rake test` must
  pass (CI blocks merges otherwise).
