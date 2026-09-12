package schema

import "strings"

#TargetName: #ServiceName

#GraphService: {
  service: #Service
  let listSeparator = ","
  let argvSeparator = "\u001f"
  compiled: "TSC3\t\(service.name)\t\(strings.Join(service.exec, argvSeparator))\t\(service.restart)\t\(service.maxRestarts)\t\(service.readiness.kind)\t\(strings.Join(service.requires, listSeparator))\t\(strings.Join(service.wants, listSeparator))\t\(strings.Join(service.after, listSeparator))\t\(strings.Join(service.before, listSeparator))"
}

#Target: {
  name: #TargetName
  members: [...#ServiceName] & [_, ...]
  let listSeparator = ","
  compiled: "TGT1\t\(name)\t\(strings.Join(members, listSeparator))"
}
