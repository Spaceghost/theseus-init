# OpenRC compatibility

```text
theseus openrc postgresql start
theseus openrc postgresql reload
the status of openrc postgresql
theseus openrc postgresql stop
theseus openrc-runlevel default
the openrc-runlevel
```

The adapter executes the installed `/sbin/rc-service` directly with the
selected service and action. OpenRC handles script lookup, dependencies,
configuration, state, and daemon management. Output and exit status are
preserved. The command accepts one action, including package-defined
actions such as `postgresql setup`. Package command arguments and general
`rc-service` options are outside this interface. Both the one-shot and live
clients expose the same OpenRC forms.

`theseus openrc-runlevel RUNLEVEL` delegates an ordinary runlevel change
to `/sbin/openrc`. `the openrc-runlevel` reads the current runlevel
through `rc-status --runlevel`. Boot, single-user, and shutdown levels
remain under system init. Native Theseus target selection is separate
from OpenRC's runlevel state.

## Alpine package evidence

The lifecycle comparison exercises Alpine 3.23.5 with OpenRC 0.63-r1.
It runs each script first directly and then through the Theseus adapter,
checking status before start, after start and restart, and after stop.
It compares exact status output and exit codes through both clients,
including the diagnostic for a missing service.

| Service | APK containing the script | Workload check |
| --- | --- | --- |
| cronie | `cronie-openrc-1.7.2-r0` | crond present while started and gone after stop |
| lighttpd | `lighttpd-openrc-1.4.85-r0` | HTTP response over loopback |
| postgresql | `postgresql-common-openrc-1.2-r2` | PostgreSQL 17.12 executes SQL after start, restart, and reload |
| caddy | `caddy-openrc-2.11.4-r0` | HTTP response from a process managed by supervise-daemon |
| valkey | `valkey-openrc-9.0.7-r0` | Valkey responds to PING |
| mosquitto | `mosquitto-openrc-2.0.22-r0` | MQTT QoS 1 publish succeeds |

The runlevel comparison switches from a level containing Valkey to
one containing Mosquitto. Both stack a shared level with Cronie and loopback networking. The test
confirms that Cronie's PID survives the switch, the broker accepts a
publish, and an empty runlevel stops all three services.

## Reproduce the comparison

1. Build `src/theseus.nelua` as `theseus` and
   `tests/alpine_openrc.nelua` as `alpine-openrc-test` with Nelua targeting
   Alpine. Create a `the` symlink to `theseus`.
2. Install `openrc`, `busybox-suid`, `cronie`, `lighttpd`, `postgresql17`,
   `postgresql17-client`, `caddy`, `valkey`, `valkey-cli`, `mosquitto`,
   `mosquitto-clients`,
   and their OpenRC subpackages in a disposable Alpine guest. Use a
   PID 1 that reaps orphaned processes. Bring up loopback and initialize
   OpenRC state. In an offline guest, configure the networking service
   for loopback only.
3. Configure lighttpd and Caddy to answer HTTP on `127.0.0.1:8080` and
   `127.0.0.1:8081`. Use loopback Valkey on port 6379 and a loopback
   Mosquitto listener on port 1883 that accepts the test publisher.
   Configure PostgreSQL on loopback with its Unix socket under
   `/run/postgresql`, then run `theseus openrc postgresql setup`.
4. Run the service comparison from the directory containing the binaries.

   ```sh
   ./alpine-openrc-test ./theseus ./the cronie lighttpd postgresql caddy valkey mosquitto
   ```
5. Create the comparison runlevels and run the switch test.

   ```sh
   mkdir /etc/runlevels/theseus-a /etc/runlevels/theseus-b /etc/runlevels/theseus-shared /etc/runlevels/theseus-idle
   rc-update add cronie theseus-shared
   rc-update add networking theseus-shared
   rc-update add valkey theseus-a
   rc-update add mosquitto theseus-b
   rc-update --stack add theseus-shared theseus-a
   rc-update --stack add theseus-shared theseus-b
   ./alpine-openrc-test ./theseus ./the --runlevels
   ```

Repeat with the binary built from `src/live_client.nelua` and its own
`the` symlink to exercise the live client's entry point. This corpus
covers service commands and ordinary runlevel switches in userspace.
The `--catalog-status` mode compares status output and exit codes
for every service listed by the installed OpenRC. Boot behavior
remains unqualified.
