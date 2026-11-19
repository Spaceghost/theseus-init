package tests

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

testDir: *"/run/theseus-tests" | string @tag(testDir)
testProgram: *"/usr/bin/theseus-test" | string @tag(testProgram)

_ready: schema.#CompiledService & {
  service: {
    name: "socket-ready"
    exec: [testProgram, "listen", "\(testDir)/service.sock", "\(testDir)/gate"]
    restart: "never"
    readiness: {
      kind: "unix-socket"
      path: "\(testDir)/service.sock"
      timeoutMs: 5000
    }
  }
}

_timeout: schema.#CompiledService & {
  service: {
    name: "socket-timeout"
    exec: [testProgram, "ignore-term", "\(testDir)/child-started"]
    restart: "on-failure"
    maxRestarts: 1
    readiness: {
      kind: "unix-socket"
      path: "\(testDir)/service.sock"
      timeoutMs: 500
      probe: {exec: [testProgram, "probe-gate", "\(testDir)/unused", "\(testDir)/foreign-probe.pid"]}
    }
  }
}

_earlyExit: schema.#CompiledService & {
  service: {
    name: "socket-early-exit"
    exec: ["/bin/true"]
    restart: "never"
    readiness: {
      kind: "unix-socket"
      path: "\(testDir)/service.sock"
    }
  }
}

readinessRecords: strings.Join([_ready.compiled, _timeout.compiled, _earlyExit.compiled], "\n")

_probeTimeout: schema.#CompiledService & {
  service: {
    name: "probe-timeout"
    exec: [testProgram, "listen", "\(testDir)/slow.sock"]
    restart: "never"
    readiness: {
      kind: "unix-socket"
      path: "\(testDir)/slow.sock"
      timeoutMs: 600
      probe: {
        exec: [testProgram, "probe-wait", "\(testDir)/never", "\(testDir)/slow-probe.pid"]
        intervalMs: 50
        timeoutMs: 100
      }
    }
  }
}

probeTimeoutRecord: _probeTimeout.compiled
