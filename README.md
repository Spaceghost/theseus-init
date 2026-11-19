# Theseus

**Theseus is a dependable Linux service supervisor and, eventually, PID 1.**

It is written in **Nelua**. Its native service model is declared in **CUE**. No Lua runtime, no maintained C implementation, no YAML service language, and no database is required to boot.

The OpenRC adapter runs installed Alpine service scripts through the
system OpenRC runtime. Native Theseus services have their own lifecycle
and dependency model. See [OpenRC compatibility](docs/OPENRC.md) for the
command surface and package evidence.

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

The userspace daemon supervises an individual foreground service or a
native target. It tracks direct children with Linux pidfds, applies
bounded restart policy, and serves status and shutdown requests over
a local Unix socket. It reaps adopted descendants while running. A target uses the validated dependency order and
waits for the configured service readiness before admitting subsequent
services. Run it with `theseusd --target TARGET`.

Set `THESEUS_CGROUP_ROOT` to a delegated cgroup v2 directory to track
and clean up each service's descendants. See
[resource ownership](docs/ARCHITECTURE.md#resource-ownership).
A [private runtime directory](docs/ARCHITECTURE.md#recovery-after-an-unclean-daemon-exit)
enables automatic cleanup on restart after a daemon crash.

Unix socket readiness can also require a successful application probe.
The PostgreSQL example uses `pg_isready` to wait until the database
accepts connections. The [Alpine soak procedure](docs/OPENRC.md#soak-native-targets-alongside-openrc) exercises native targets and live OpenRC packages together. The [full guest check](docs/OPENRC.md#qualify-complete-alpine-boots-and-shutdowns) covers boot and shutdown under Alpine init. Broader Alpine package qualification remains open. The rescue entry point below is separate from the service
supervisor.

## Opt-in PID 1

The [native PID 1 entry point](docs/PID1.md) is available for isolated
Linux VM qualification. It supervises the native daemon and enters
console rescue on boot failure.

## Early boot in nebox

The opt-in nebox build uses `src/theseus/earlyboot.nelua` as the initramfs
entry point. It mounts procfs and sysfs, starts an interactive nebox shell
on the boot console, reaps children, and restarts the shell after exit.
The module uses the Spaceghost Nelua fork's control flow, compound
assignment, conditional expressions, and string interpolation extensions.

This entry point is for bring-up and rescue. The CUE service model and
long-lived userspace supervisor are separate from this boot path.
See the nebox README for the build and QEMU smoke commands.
