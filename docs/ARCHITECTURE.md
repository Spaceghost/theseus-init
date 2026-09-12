# Theseus architecture

Theseus is a native Linux supervisor first and PID 1 only after the supervisor has earned that responsibility.

## Language contract

- Maintained implementation: Nelua.
- Native configuration and service schema: CUE.
- Generated C is disposable compiler output, never hand-maintained source.
- Existing OpenRC shell scripts are foreign compatibility inputs. They do not define Theseus internals.
- There is no Lua runtime or runtime scripting engine.

## Layering

```text
CUE service declarations
        |
        | validate + compile
        v
TSC1 deterministic records
        |
        v
Nelua Theseus core
  - service state machines
  - dependency graph
  - process supervision
  - readiness / restart policy
  - event stream
        |
        +--> theseus  (explicit mutations)
        +--> the      (read/query grammar)
        +--> OpenRC compatibility adapter
        |
        v
Linux process/event primitives
```

The CUE compiler is a configuration/build-time dependency. The running supervisor does not embed CUE and does not need CUE to keep already-compiled services alive.

## State model

A service is always in one explicit state:

```text
ABSENT -> PLANNED -> STARTING -> READY -> RUNNING
                         |          |         |
                         v          v         v
                       FAILED <--- DEGRADED   STOPPING -> STOPPED
                         |
                         v
                       BACKOFF -> STARTING
```

Illegal transitions are rejected rather than silently coerced.

## TSC1

The bootstrap runtime record is deliberately narrow:

```text
TSC1<TAB>name<TAB>argv-with-US-separators<TAB>restart-policy<TAB>max-restarts
```

TSC1 is not intended to become a kitchen-sink wire format. It exists to prove the CUE-to-Nelua boundary without adding JSON or a runtime CUE evaluator. A later binary format may replace it once process supervision and compatibility requirements settle.

## PID 1 boundary

The userspace supervisor must prove, in order:

1. deterministic service graph handling;
2. real process identity and child lifecycle;
3. restart/backoff and readiness;
4. shutdown and failure propagation;
5. OpenRC compatibility on Alpine package scripts;
6. only then PID 1 signal/reaping/reboot responsibilities.

The machine should not become unbootable merely because we became enthusiastic.
