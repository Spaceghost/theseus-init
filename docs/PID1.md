# Opt-in Linux PID 1

Build src/init.nelua as /sbin/theseus-init and src/supervisor.nelua
as /sbin/theseusd. Prepare a local Linux root with those binaries,
their native loader and libraries if dynamically linked, /bin/sh,
a console, and /etc/theseus/graph.tsc. Compile the graph with CUE
before boot. It must contain a native target called default.

Use theseus-init as the executable handed PID 1 after the root
filesystem is mounted. For a root mounted directly by Linux, use
the kernel option init=/sbin/theseus-init. In an initramfs with
switch_root, select the same executable in the new root. Add
theseus.pid1=1 to enable native service startup.

Theseus init prepares procfs, sysfs, a local /run, and cgroup v2.
It launches the existing userspace daemon with crash recovery
under /run/theseus-init and /sys/fs/cgroup/theseus-init. Clients
can use THESEUS_SOCKET=/run/theseus-init/control.sock to query
the target. Startup has no dependency on a network or CUE evaluator.

## Rescue and shutdown

Omit theseus.pid1=1 or add theseus.rescue=1 for console rescue
without a service target. If the graph fails to load or the
supervisor exits, PID 1 stays alive, reclaims the worker's owned
cgroups and control socket, and starts /bin/sh on /dev/console.
Exiting the rescue shell starts another after a short delay.
Keep the boot console physically or administratively protected.

For an installed system with a separate recovery boot entry, add
`theseus.rescue=off`. This option takes precedence over
`theseus.rescue=1` for console access. Theseus still reports the
failure, cleans up owned resources and accepts reboot, halt and
poweroff signals. It leaves the console without a shell. It also
keeps the shell disabled if it cannot read the kernel command line.

BusyBox halt, poweroff, and reboot request system shutdown.
Their signals are SIGUSR1, SIGUSR2, and SIGTERM respectively.
SIGINT requests reboot for Ctrl+Alt+Del. The daemon first gets
time to stop its services in dependency order. PID 1 gives it
up to 135 seconds, then kills a wedged worker. It cleans up
remaining processes, syncs filesystems, attempts to remount the
root read-only, and requests the kernel action. It returns to
rescue if the syscall fails. A daemon-stop request only stops
the userspace worker and leads to rescue.

A bootloader can add `theseus.trial=1` to a one-boot entry after it
has durably consumed that selection. If startup fails or the
supervisor exits during the trial, PID 1 runs the existing orderly
reboot sequence. Its `trial-reboot` console event includes the
failure reason. A manual shutdown request takes precedence, and
`theseus.rescue=1` still requests rescue. A failed reboot syscall
does not trigger repeated trial reboots.

To bound native startup, add `theseus.trial_timeout=SECONDS` to that
entry. Use a positive whole number from 1 to 3600 and a matching
PID 1 and supervisor from the same release. The clock starts after
the OpenRC boot phases, when PID 1 forks the native supervisor.
The supervisor acknowledges startup only when its required services
have reached their configured readiness and the native target
reports running. If the deadline expires first, PID 1 allows up to
four seconds for native shutdown before killing the supervisor and
continuing the orderly reboot. Set the deadline for the target's
startup and retry policy.

A trial can set `theseus.trial_heartbeat_timeout=SECONDS` from 3 to
3600. Once the target reports running, the supervisor reports
progress from its event loop at one-second intervals. If the
configured interval elapses without progress, PID 1 gives the worker
up to four seconds to stop before forced cleanup and reboot. The
heartbeat checks supervisor responsiveness. Use service readiness
and application-level tests to verify individual workloads. Set the
startup deadline separately and install a matching `theseusd` from
the same release.

A hung PID 1 or kernel requires an independent watchdog or reset.
A one-boot entry can also set `theseus.trial_watchdog=1`. Load the
watchdog driver before PID 1 and configure a reset-capable
`/dev/watchdog0` with a timeout of at least five seconds appropriate
for your system. Opening it arms the timer. PID 1 feeds it from its
event loop, including during OpenRC boot and shutdown. If the device
cannot be opened, PID 1 reports the error and continues with software
trial handling. During a reboot, the watchdog stays armed through
filesystem sync. On halt or poweroff, PID 1 attempts to disable it
and reports failure if the device cannot stop. Qualify the device's
reset and poweroff behavior before enabling it on hardware.

## Recover the supervisor on an installed system

Add `theseus.supervisor_recovery_timeout=SECONDS` from 3 to 3600 to
a normal boot entry with matching PID 1 and supervisor binaries.
The native target has two minutes to reach readiness. After readiness,
the supervisor reports progress from its event loop once a second.
If it exits or stops reporting, PID 1 allows up to four seconds for
shutdown before sending SIGKILL. It waits for the worker to exit and
reclaims its recorded cgroup and control socket before starting a
replacement. OpenRC stays running.

The first three replacement attempts in a boot wait one, two, then
four seconds. PID 1 enters rescue if it cannot reap the old worker or
reclaim its ownership, or if the budget is exhausted. An operator
poweroff or reboot takes precedence over a pending restart. One-boot
entries use their existing trial failure policy.

## OpenRC-managed services

On Alpine, add theseus.openrc=1 alongside theseus.pid1=1 to boot
the installed OpenRC runlevels. Configure OpenRC's cgroups service
in the boot runlevel with unified cgroup mode. PID 1 runs sysinit,
boot, and default in order. It launches the native target after
OpenRC completes and leaves individual script and dependency
handling to OpenRC. If the runlevel program fails, the init process
enters rescue. A required application can still have its own
readiness requirements after a runlevel completes.

A system shutdown stops the native target first, so its clients
can finish work using servers managed by OpenRC. PID 1 then executes
OpenRC shutdown and finishes kernel shutdown. On reboot, PID 1
invokes OpenRC with its reboot argument so shutdown scripts receive
RC_REBOOT=YES while RC_RUNLEVEL remains shutdown. A failed native
supervisor is cleaned up while already running OpenRC services
remain available in rescue. Use the kernel option theseus.rescue=1
to enter the console before either service manager starts when the
console is enabled.

Each OpenRC invocation has a two-minute deadline. A shutdown
request can interrupt a boot runlevel. PID 1 sends SIGTERM to the
active process group and gives it two seconds before sending
SIGKILL, even if the leader exits during that interval. PID 1
retains the leader's PID until the final group signal. A runlevel
failure or timeout is reported on the console. OpenRC reports the
runlevel program's exit status separately from individual script
results. Check the service's own shutdown result when verifying
that it stopped cleanly. During OpenRC shutdown,
PID 1 forwards script output to the console on a best-effort basis.
If the console stalls, PID 1 discards output that cannot be written
immediately so that the scripts can continue.

## VM checks

Use disposable disk overlays and capture the serial console.
Build the existing tests/live_control.nelua as control-test
and tests/pid1_guest.nelua as pid1-test. Install these binaries,
theseus from src/live_client.nelua, and its the symlink under
/opt/theseus/bin. Compile the guest target before boot.

~~~sh
cue export ./pid1fixtures -e compiled --out text > graph.tsc
~~~

Place graph.tsc at /etc/theseus/graph.tsc in the guest.
The fixture boots a native target with a detached child and
requests poweroff. Set test.action=reboot or test.action=halt
on the kernel command line to exercise the other system actions.
Use test.action=worker-crash to kill the supervisor and inspect
rescue. Use test.action=worker-wedged to stop the supervisor
during the shutdown request and exercise the timeout.

Confirm PID 1 survives malformed or missing graph records and
a missing supervisor binary. Check the native cgroups and
endpoint before leaving rescue after a supervisor crash.
For a disk-backed guest, run a read-only filesystem check
after the kernel action.

For a mixed VM check, install PostgreSQL, Mosquitto, and Cronie
in the OpenRC default runlevel. Set up the PostgreSQL cluster and
configure the test services for loopback. Build
tests/pid1_openrc_guest.nelua as /opt/theseus/bin/pid1-openrc-test
and export openrcCompiled from ./pid1fixtures as the graph.
Boot once with test.action=poweroff, then boot the same disk with
test.action=reboot. To check the action seen by OpenRC, install
tests/openrc_shutdown_action as an executable named
/etc/init.d/theseus-shutdown-action and add it to the shutdown
runlevel with rc-update. Expect the VM_OPENRC_SHUTDOWN_ACTION
line to show level=shutdown on both boots and reboot=YES only
on reboot. The native client writes a PostgreSQL transaction
during its own shutdown and checks for it after the next boot. Boot
a fresh overlay with test.action=worker-crash to check that OpenRC
services remain available while the native scope is reclaimed.
