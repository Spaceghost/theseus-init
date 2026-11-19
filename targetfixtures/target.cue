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
      readiness: {kind: "unix-socket", path: "\(testDir)/gate.sock", timeoutMs: 10000}
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
      exec: ["/bin/sleep", "30"]
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
]

_targets: [
  schema.#Target & {name: "demo", members: ["app"]},
  schema.#Target & {name: "rollback", members: ["unstarted"]},
  schema.#Target & {name: "bad-exec", members: ["exec-dependent"]},
]

compiled: strings.Join(
  [strings.Join([for s in _services {s.compiled}], "\n"), strings.Join([for t in _targets {t.compiled}], "\n")],
  "\n",
)
