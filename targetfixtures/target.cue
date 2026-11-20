package targetfixtures

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

testDir: *"/run/theseus-target-tests" | string @tag(testDir)
testProgram: *"/usr/bin/theseus-test" | string @tag(testProgram)

_services: [
  schema.#GraphService & {
    service: {
      name: "gate"
      exec: [testProgram, "listen", "\(testDir)/gate.sock", "\(testDir)/release"]
      restart: "never"
      readiness: {
        kind: "unix-socket"
        path: "\(testDir)/gate.sock"
        timeoutMs: 10000
        probe: {exec: [testProgram, "probe-gate", "\(testDir)/probe-release", "\(testDir)/probe-started"]}
      }
    }
  },
  schema.#GraphService & {
    service: {
      name: "optional"
      exec: ["/bin/true"]
      restart: "never"
      readiness: {kind: "unix-socket", path: "\(testDir)/optional.sock"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "skipped"
      exec: ["/bin/sleep", "30"]
      requires: ["optional"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "app"
      exec: ["/bin/sleep", "30"]
      requires: ["gate"]
      wants: ["skipped"]
      restart: "never"
      readiness: {kind: "pid"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "anchor"
      exec: [testProgram, "delay-term", "\(testDir)/anchor", "\(testDir)/release-anchor"]
      stopGraceMs: 10000
      restart: "never"
    }
  },
  schema.#GraphService & {
    service: {
      name: "bad"
      exec: ["/bin/sleep", "30"]
      requires: ["anchor"]
      restart: "never"
      readiness: {kind: "unix-socket", path: "\(testDir)/absent.sock", timeoutMs: 1000}
    }
  },
  schema.#GraphService & {
    service: {
      name: "unstarted"
      exec: ["/bin/sleep", "30"]
      requires: ["bad"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "leaf"
      exec: ["/bin/sleep", "30"]
      requires: ["unstarted"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "exec-failure"
      exec: ["\(testDir)/does-not-exist"]
      restart: "never"
    }
  },
  schema.#GraphService & {
    service: {
      name: "exec-dependent"
      exec: ["/bin/sleep", "30"]
      requires: ["exec-failure"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "shared"
      exec: [testProgram, "listen", "\(testDir)/shared.sock", "\(testDir)/allow-shared"]
      restart: "on-failure"
      maxRestarts: 1
      readiness: {kind: "unix-socket", path: "\(testDir)/shared.sock", timeoutMs: 10000}
    }
  },
]

_targets: [
  schema.#Target & {name: "demo", members: ["app"]},
  schema.#Target & {name: "halt", members: ["anchor"]},
  schema.#Target & {name: "rollback", members: ["leaf"]},
  schema.#Target & {name: "bad-exec", members: ["exec-dependent"]},
  schema.#Target & {name: "shared", members: ["shared"]},
]

compiled: strings.Join(
  [strings.Join([for s in _services {s.compiled}], "\n"), strings.Join([for t in _targets {t.compiled}], "\n")],
  "\n",
)
