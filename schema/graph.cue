package schema

import "strings"

#TargetName: #ServiceName

#GraphService: {
  service: #Service
  let listSeparator = ","
  let argvSeparator = "\u001f"
  let serviceFields = "\(service.name)\t\(strings.Join(service.exec, argvSeparator))\t\(service.restart)\t\(service.maxRestarts)\t\(service.readiness.kind)"
  let graphFields = "\(strings.Join(service.requires, listSeparator))\t\(strings.Join(service.wants, listSeparator))\t\(strings.Join(service.after, listSeparator))\t\(strings.Join(service.before, listSeparator))"
  if service.readiness.kind == "unix-socket" {
    compiled: "TSC5\t\(serviceFields)\t\(service.readiness.path)\t\(service.readiness.timeoutMs)\t\(graphFields)"
  }
  if service.readiness.kind != "unix-socket" {
    compiled: "TSC3\t\(serviceFields)\t\(graphFields)"
  }
}

#Target: {
  name: #TargetName
  members: [...#ServiceName] & [_, ...]
  let listSeparator = ","
  compiled: "TGT1\t\(name)\t\(strings.Join(members, listSeparator))"
}
