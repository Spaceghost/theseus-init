# `the` query grammar

`the` is the read-oriented interface to the same typed state exposed by `theseus`.

The grammar is intentionally tiny and deterministic. It is not natural-language interpretation.

The installed live client queries the running supervisor. Set
`THESEUS_SOCKET` to its control socket. Under Theseus PID 1,
the socket is `/run/theseus-init/control.sock`. A native query waits
up to five seconds for a complete reply. A timed-out query exits
with status 69 and reports the deadline.

```text
the services
the failed services
the running services
the services of TARGET
the failed services of TARGET
the running services of TARGET
the status of NAME
the state of NAME
the status of target TARGET
the state of target TARGET
the status of openrc SERVICE
the openrc-runlevel
```

The service lists show a snapshot in target plan order with one
tab-separated service name and state per line. A filter with zero
matches succeeds with empty output. Use `theseus services` for the
same full snapshot. OpenRC queries are separate from native service
lists.

A named target list includes its selected services and transitive dependencies.
The daemon reports only the target it is supervising. An inactive target
name, including one declared elsewhere in the same graph, exits with status 3
on an explicit target query. `theseus services TARGET` prints the same list.

`the status of NAME` looks up a supervised service first, then the active
target. Use `the status of target NAME` when both share a name. Target status
shows the current phase and two running counts, one for all selected services
and one for hard requirements. `the state of target NAME` prints only the
phase. Startup reports `STARTING` until the target signals readiness. A
fully running target reports `RUNNING`. After readiness, a failed optional
service or a service awaiting restart readiness produces `DEGRADED`.
During an orderly shutdown the target reports `STOPPING`. If a hard
requirement fails, the target reports `FAILED` and names the service
under `failed-requirement` during rollback. Planned hard dependents
show `FAILED` with PID 0. The control socket closes after service cleanup.

The bootstrap client can inspect compiled configuration and offers
these forms:

```text
the status
the services
the failed services
the running services
the status of SERVICE
the status of openrc SERVICE
the openrc-runlevel
the state of SERVICE
the restart-policy of SERVICE
```

The bootstrap client also accepts these query forms:

```text
theseus status SERVICE
theseus state SERVICE
theseus services
```

OpenRC actions use the explicit `theseus openrc SERVICE ACTION` form.

Later mutating commands such as `theseus start`, `restart`, `stop`, and target transactions must never be inferred from `the` prose.

Design rule:

> `theseus` changes the machine. `the` reports what Theseus believes is true.
