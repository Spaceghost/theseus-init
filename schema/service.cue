package schema

import "strings"

#ServiceName: string & =~"^[a-zA-Z0-9][a-zA-Z0-9._@:+-]{0,62}$"
#SafeText: string & !~"[\\t\\r\\n\\x1f]"
#RestartPolicy: "never" | "on-failure" | "always"
#ReadinessKind: "none" | "pid" | "unix-socket"

#Service: {
  name: #ServiceName
  exec: [#SafeText, ...#SafeText] & [_, ...]

  requires: *[] | [...#ServiceName]
  wants:    *[] | [...#ServiceName]
  after:    *[] | [...#ServiceName]
  before:   *[] | [...#ServiceName]

  restart: *"on-failure" | #RestartPolicy
  maxRestarts: *5 | int & >=0 & <=1000000

  readiness: *{
    kind: "none"
  } | {
    kind: "pid"
  } | {
    kind: "unix-socket"
    path: #SafeText & =~"^/"
  }
}

// The runtime record stays deliberately narrow. It is compiled by CUE and
// parsed by Nelua before any process effects. argv uses ASCII Unit Separator.
#CompiledService: {
  service: #Service
  let argvSeparator = "\u001f"
  compiled: "TSC2\t\(service.name)\t\(strings.Join(service.exec, argvSeparator))\t\(service.restart)\t\(service.maxRestarts)\t\(service.readiness.kind)"
}
