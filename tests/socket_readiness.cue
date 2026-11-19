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
