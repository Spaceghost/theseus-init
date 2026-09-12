package schema

#ServiceName: string & =~"^[a-zA-Z0-9][a-zA-Z0-9._@:+-]{0,62}$"
#SafeText: string & !~"[\\t\\r\\n\\x1f]"
#RestartPolicy: "never" | "on-failure" | "always"

#Service: {
  name: #ServiceName
  exec: [#SafeText, ...#SafeText]

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
