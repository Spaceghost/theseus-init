package services

import (
  "strings"
  "spaceghost.dev/theseus/schema"
)

service: schema.#Service & {
  name: "postgresql"
  exec: ["/usr/bin/postgres", "-D", "/var/lib/postgresql"]
  requires: ["localmount"]
  after: ["networking"]
  restart: "on-failure"
  maxRestarts: 5
  readiness: {
    kind: "unix-socket"
    path: "/run/postgresql/.s.PGSQL.5432"
  }
}

// TSC1 is intentionally tiny and non-JSON. Unit separator preserves argv
// boundaries inside the third tab-delimited field.
compiled: "TSC1\t\(service.name)\t\(strings.Join(service.exec, \"\u001f\"))\t\(service.restart)\t\(service.maxRestarts)"
