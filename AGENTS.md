# AGENTS.md

Theseus is a reliability-oriented init/supervisor project.

## Non-negotiable language boundary

- Maintained implementation code is Nelua (`.nelua`).
- Native schema/configuration is CUE (`.cue`).
- Do not add maintained implementation in C, C++, Rust, Go, Zig, Odin, Lua, Python, shell, or another language.
- Generated C from the Nelua compiler may exist as disposable build output but must never become an edited source of truth.
- GitHub workflow YAML and prose documentation are build/coordination metadata, not implementation.
- Foreign OpenRC shell scripts may appear only as compatibility fixtures or external package inputs.

## Architectural rules

1. Theseus's internal model is not OpenRC. OpenRC is an adapter.
2. Native service definitions are declarative CUE, never arbitrary runtime code.
3. PID 1 must not require a network, database, D-Bus, dynamic-language runtime, or CUE evaluator to keep the machine alive.
4. State transitions and failure reasons remain explicit and inspectable.
5. Readiness is distinct from process existence.
6. Process identity must eventually use Linux primitives that are robust against PID reuse.
7. `the` stays read-oriented. Mutations require explicit `theseus` commands.
8. PID 1 is the final milestone, not the development environment.

## Evidence

Never claim OpenRC compatibility from a toy service. Compatibility is measured against real Alpine init scripts and package behavior.
Never claim PID 1 readiness from a userspace supervisor test.
Never claim process supervision until real child lifecycle/restart behavior is exercised.
