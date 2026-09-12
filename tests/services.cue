package tests

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

services: [
  schema.#CompiledService & {
    service: {
      name: "true-once"
      exec: ["/bin/true"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "none"}
    }
  },
  schema.#CompiledService & {
    service: {
      name: "false-restart"
      exec: ["/bin/false"]
      restart: "on-failure"
      maxRestarts: 2
      readiness: {kind: "pid"}
    }
  },
  schema.#CompiledService & {
    service: {
      name: "sleep-stop"
      exec: ["/bin/sleep", "30"]
      restart: "always"
      maxRestarts: 10
      readiness: {kind: "pid"}
    }
  },
]

compiled: strings.Join([for item in services {item.compiled}], "\n")
