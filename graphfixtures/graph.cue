package graphfixtures

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

services: [
  schema.#GraphService & {
    service: {
      name: "localmount"
      exec: ["/bin/sleep", "30"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "pid"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "networking"
      exec: ["/bin/sleep", "30"]
      requires: ["localmount"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "pid"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "app"
      exec: ["/bin/sleep", "30"]
      requires: ["networking"]
      wants: ["optional"]
      after: ["localmount", "clock"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "pid"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "optional"
      exec: ["/bin/false"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "none"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "clock"
      exec: ["/bin/sleep", "30"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "pid"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "cycle-a"
      exec: ["/bin/true"]
      requires: ["cycle-b"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "none"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "cycle-b"
      exec: ["/bin/true"]
      requires: ["cycle-a"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "none"}
    }
  },
  schema.#GraphService & {
    service: {
      name: "broken"
      exec: ["/bin/true"]
      requires: ["missing-hard-dependency"]
      restart: "never"
      maxRestarts: 0
      readiness: {kind: "none"}
    }
  },
]

targets: [
  schema.#Target & {name: "default", members: ["app"]},
  schema.#Target & {name: "cycle", members: ["cycle-a"]},
  schema.#Target & {name: "broken", members: ["broken"]},
]

compiled: strings.Join(
  [for item in services {item.compiled}] + [for target in targets {target.compiled}],
  "\n",
)
