package schema

import (
  "list"
  "strings"
)

#ServiceName: string & =~"^[a-zA-Z0-9][a-zA-Z0-9._@:+-]{0,62}$"
#SafeText: string & !~"[\\t\\r\\n\\x00\\x1f]"
#RestartPolicy: "never" | "on-failure" | "always"
#ReadinessKind: "none" | "pid" | "unix-socket"

#Service: {
  name: #ServiceName
  exec: [#SafeText & != "", ...#SafeText] & list.MaxItems(32)

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
    _pathBytes: len(path) & <=107
    timeoutMs: *30000 | int & >=1 & <=600000
  }
}

// The runtime record stays deliberately narrow. It is compiled by CUE and
// parsed by Nelua before any process effects. argv uses ASCII Unit Separator.
#CompiledService: {
  service: #Service
  let argvSeparator = "\u001f"
  let fields = "\(service.name)\t\(strings.Join(service.exec, argvSeparator))\t\(service.restart)\t\(service.maxRestarts)\t\(service.readiness.kind)"
  if service.readiness.kind == "unix-socket" {
    compiled: "TSC4\t\(fields)\t\(service.readiness.path)\t\(service.readiness.timeoutMs)"
  }
  if service.readiness.kind != "unix-socket" {
    compiled: "TSC2\t\(fields)"
  }
}
