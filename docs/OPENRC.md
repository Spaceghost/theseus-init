# OpenRC compatibility

```text
theseus openrc postgresql start
theseus openrc postgresql reload
the status of openrc postgresql
theseus openrc postgresql stop
```

The adapter executes the installed `/sbin/rc-service` directly with the
selected service and action. OpenRC handles script lookup, dependencies,
configuration, state, and daemon management. Output and exit status are
preserved. The command accepts one action, including package-defined
actions such as `postgresql setup`. Package command arguments and general
`rc-service` options are outside this interface. Both the one-shot and live
clients expose the same OpenRC forms.

## Alpine package evidence

The lifecycle comparison exercises Alpine 3.23.5 with OpenRC 0.63-r1.
It runs each script first directly and then through the Theseus adapter,
checking status before start, after start and restart, and after stop.
It also compares exit status for a missing service.

| Service | APK containing the script | Workload check |
| --- | --- | --- |
| cronie | `cronie-openrc-1.7.2-r0` | crond present while started and gone after stop |
| lighttpd | `lighttpd-openrc-1.4.85-r0` | HTTP response over loopback |
| postgresql | `postgresql-common-openrc-1.2-r2` | PostgreSQL 17.12 executes SQL after start, restart, and reload |

## Reproduce the comparison

1. Build `src/theseus.nelua` as `theseus` and
   `tests/alpine_openrc.nelua` as `alpine-openrc-test` with Nelua targeting
   Alpine. Create a `the` symlink to `theseus`.
2. Install `openrc`, `busybox-suid`, `cronie`, `lighttpd`, `postgresql17`,
   `postgresql17-client`, and their OpenRC subpackages in a disposable
   Alpine guest. Use a PID 1 that reaps orphaned processes. Bring up
   loopback and initialize OpenRC state before the comparison.
3. Configure lighttpd to bind `127.0.0.1:8080` and give its document root
   an index page. Configure PostgreSQL to listen on loopback and keep its
   Unix socket under `/run/postgresql`. Initialize its test cluster using
   `theseus openrc postgresql setup`.
4. Run the comparison with the binaries in the current directory.

   ```sh
   ./alpine-openrc-test ./theseus ./the cronie lighttpd postgresql
   ```

Repeat with the binary built from `src/live_client.nelua` and its own
`the` symlink to exercise the live client's entry point. This corpus
covers service commands in userspace. Runlevel and boot behavior remain
unqualified.
