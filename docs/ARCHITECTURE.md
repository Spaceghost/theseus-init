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
TSC2 and TSC4 service records / TSC3 and TSC5 graph records
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

## Runtime records

Services with no readiness probe or PID readiness compile to TSC2.

```text
TSC2<TAB>name<TAB>argv-with-US-separators<TAB>restart-policy<TAB>max-restarts<TAB>readiness-kind
```

The argv field holds up to 32 arguments. Empty arguments after the executable
are preserved. Services with Unix socket readiness compile to TSC4,
which uses the same field layout and appends the absolute socket path
and startup timeout in milliseconds. Legacy TSC2 records declaring
Unix socket readiness need recompilation before the daemon starts them.

Graph records append the `requires`, `wants`, `after`, and `before`
lists to the service fields. TSC3 wraps the TSC2 fields. TSC5 wraps the
TSC4 fields and preserves Unix readiness settings. TGT1 records supply
target membership in the same input.

## Userspace daemon

Set `THESEUS_SOCKET` to an absolute path in a directory controlled by the
daemon's user. The socket is created with mode 0600. The daemon handles
up to eight active requests, each with a one-second deadline for sending
the request line. Partial requests and restart backoff share the poll
loop with child exit detection.

`theseus daemon-stop`, SIGTERM, and SIGINT initiate shutdown. The daemon
signals its direct child through the pidfd and gives it one second to
exit. If that expires, it sends SIGKILL and waits up to one more second
for exit. The daemon acknowledges a successful control shutdown after
the child has been reaped and the socket removed.

For CUE readiness kind `unix-socket`, the child starts in `STARTING`
and the daemon attempts nonblocking connections until the configured
deadline. `SO_PEERCRED` and `SO_PEERPIDFD` establish that the listener
belongs to the live foreground child. This probe measures socket
availability at startup. The service owns its socket file.

`timeoutMs` defaults to 30000. On timeout the daemon begins pidfd
shutdown while continuing to answer status queries. A timeout or exit
before readiness counts as a failure for restart policy, even if the
child exits with code zero. The daemon records the outcome in tab-separated
events with fields `TE1`, `readiness`, service name, attempt number, and
one of `ready`, `timeout`, or `exited-before-ready`.

The live daemon implements this probe. The one-shot CLI can inspect
TSC4 service configuration and directs socket-ready services to
`theseusd` for execution.

## Native targets

Set `THESEUS_GRAPH` to the compiled graph file and start
`theseusd --target TARGET` in the foreground. The daemon validates the
complete target graph and selected runtime records before binding the
control socket or creating children. It uses the same order as
`theseus-graph TARGET`. Self-edges and other cycles fail before a plan is
published.

Target members and their transitive `requires` dependencies are
required. The daemon admits foreground services in order, waiting for
the preceding startup verdict and any hard dependencies to be running.
A terminal failure of a wanted service allows the target to continue.
A wanted service whose hard dependency fails is skipped. If a required
service stops or fails and has no remaining restart scheduled, the
daemon shuts down the target and exits 82. A dependency's restart
backoff after startup leaves existing services running.

A close-on-exec handshake keeps newly forked children in `STARTING`
until exec succeeds or reports failure. Services with socket readiness
then wait for their listener. Services configured as `none` or `pid`
need no application probe after exec.

Use the live `the state of SERVICE` against the target's control socket
to inspect any selected service. `theseus daemon-stop` stops and reaps
owned direct children in reverse plan order. Target events report
running, failed, skipped, and stopping outcomes. One daemon manages
one target, and the target contains up to 32 services.

## Resource ownership

Set `THESEUS_CGROUP_ROOT` to an absolute path to an administrator-delegated
cgroup v2 directory. The daemon and its children need permission to
migrate into a new leaf of that delegation. The daemon creates a
private cgroup per selected service and places the child there before
exec, so its descendants enter the same cgroup.

After a leader exits, Theseus uses `cgroup.kill` if the leaf is still
populated. The event loop waits for `populated 0` before allowing a restart.
During explicit shutdown, the daemon first gives the leader its normal
SIGTERM grace period. It then clears any remaining descendants and
removes only the cgroups it created. Active work in sibling cgroups is
outside the cleanup.

The daemon reports assignments, placement failures, and drain progress
as `TE1 ownership` events. The OS's reaper handles orphaned descendants
after they exit. The daemon reaps its own leaders and confirms kernel
cgroup emptiness before declaring cleanup successful.

The delegation is for trusted services operating under the same
process-management account. Use file permissions or credentials to
prevent services from moving themselves into other cgroups if that
matters to their deployment. Leave the variable unset for direct-child
pidfd supervision without a cgroup delegation. The one-shot runner
and the OpenRC adapter keep their own process-management contracts.

## PID 1 boundary

The userspace supervisor must prove, in order:

1. deterministic service graph handling;
2. real process identity and child lifecycle;
3. restart/backoff and readiness;
4. shutdown and failure propagation;
5. OpenRC compatibility on Alpine package scripts;
6. only then PID 1 signal/reaping/reboot responsibilities.

The machine should not become unbootable merely because we became enthusiastic.
