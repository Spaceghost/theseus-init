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
the status of SERVICE
the state of SERVICE
the status of openrc SERVICE
the openrc-runlevel
```

The service lists show a snapshot in target plan order with one
tab-separated service name and state per line. A filter with zero
matches succeeds with empty output. Use `theseus services` for the
same full snapshot. OpenRC queries are separate from native service
lists.

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
