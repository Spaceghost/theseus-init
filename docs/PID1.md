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
