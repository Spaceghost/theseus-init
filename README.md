# Theseus

**Theseus is a dependable Linux service supervisor and, eventually, PID 1.**

It is written in **Nelua**. Its native service model is declared in **CUE**. No Lua runtime, no maintained C implementation, no YAML service language, and no database is required to boot.

OpenRC is supported as a compatibility personality rather than as Theseus's internal model. Existing Alpine packages should continue to work while native Theseus services gain stronger supervision, readiness, restart policy, explicit dependency transactions, and structured state.

## Philosophy

> CUE says what should be true. Nelua makes it true.

Theseus is intended to be boring under stress: small, explicit, inspectable, deterministic, and hard to surprise.

The command surfaces are deliberately split:

```text
theseus restart postgresql   # explicit mutation
the status of postgresql     # observation
```

`the` is the short read/query interface to the exact same typed state used by `theseus`.

## Language boundary

Maintained project sources are restricted to:

- `*.nelua` for implementation, tests, tools, compatibility mechanisms, and CLIs;
- `*.cue` for schemas, service declarations, targets, and policy data.

Generated C from Nelua is a build artifact, never maintained source. Shell scripts supplied by existing OpenRC packages are external compatibility inputs, not part of the Theseus implementation.

## Milestones

1. Userspace Nelua supervisor, typed service state machine, dependency graph, and deterministic `the` grammar.
2. CUE service schema and deterministic compilation into a small runtime record format.
3. Process supervision using Linux process identity and event primitives.
4. OpenRC compatibility against the real Alpine init-script corpus.
5. Native targets, readiness, restart/backoff, resource ownership, and structured lifecycle events.
6. PID 1 only after the supervisor and compatibility layers have been abused for long enough to deserve it.

## Current status

Bootstrap implementation in progress. The first executable milestone intentionally runs as an ordinary process rather than PID 1.
