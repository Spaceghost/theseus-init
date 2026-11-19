package qualificationfixtures

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

testDir: *"/run/theseus-qualification" | string @tag(testDir)
testProgram: *"/usr/bin/theseus-test" | string @tag(testProgram)

_services: [
  schema.#GraphService & {
    service: {
      name: "gate"
      exec: [testProgram, "listen", "\(testDir)/gate.sock"]
      restart: "never"
      readiness: {
        kind: "unix-socket"
        path: "\(testDir)/gate.sock"
        timeoutMs: 12000
        probe: {exec: [testProgram, "probe-gate", "\(testDir)/release", "\(testDir)/probe.pid"]}
      }
    }
  },
  schema.#GraphService & {
    service: {
      name: "tree"
      exec: [testProgram, "tree", "\(testDir)"]
      restart: "never"
      requires: ["gate"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "churn"
      exec: [testProgram, "log-churn", "\(testDir)/churn-done"]
      restart: "never"
      requires: ["gate"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "flap"
      exec: ["/bin/false"]
      restart: "on-failure"
      maxRestarts: 8
      after: ["tree", "churn"]
    }
  },
  schema.#GraphService & {
    service: {
      name: "anchor"
      exec: ["/bin/sleep", "120"]
      restart: "never"
      requires: ["gate", "tree", "churn"]
      wants: ["flap"]
    }
  },
]

_target: schema.#Target & {name: "qualification", members: ["anchor"]}

compiled: strings.Join([for service in _services {service.compiled}], "\n") + "\n" + _target.compiled
