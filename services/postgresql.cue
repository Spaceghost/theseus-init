package services

import "spaceghost.dev/theseus/schema"

runtime: schema.#CompiledService & {
  service: {
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
}

service: runtime.service
compiled: runtime.compiled
