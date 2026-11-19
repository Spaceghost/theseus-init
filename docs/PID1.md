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

BusyBox halt, poweroff, and reboot request system shutdown.
Their signals are SIGUSR1, SIGUSR2, and SIGTERM respectively.
SIGINT requests reboot for Ctrl+Alt+Del. The daemon first gets
time to stop its services in dependency order. PID 1 gives it
up to 135 seconds, then kills a wedged worker. It cleans up
remaining processes, syncs filesystems, attempts to remount the
root read-only, and requests the kernel action. It returns to
rescue if the syscall fails. A daemon-stop request only stops
the userspace worker and leads to rescue.

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

This entry point currently starts native targets. Alpine's OpenRC
boot and shutdown runlevels have separate userspace qualification.
