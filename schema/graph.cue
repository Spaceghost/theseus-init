package schema

import "strings"

#TargetName: #ServiceName

#GraphService: {
  service: #Service
  let listSeparator = ","
  let configuration = service
  _runtime: #CompiledService & {service: configuration}
  let graphFields = "\(strings.Join(service.requires, listSeparator))\t\(strings.Join(service.wants, listSeparator))\t\(strings.Join(service.after, listSeparator))\t\(strings.Join(service.before, listSeparator))"
  let magic = strings.SplitN(_runtime.compiled, "\t", 2)[0]
  if magic == "TSC2" {
    compiled: "\(strings.Replace(_runtime.compiled, "TSC2", "TSC3", 1))\t\(graphFields)"
  }
  if magic == "TSC4" {
    compiled: "\(strings.Replace(_runtime.compiled, "TSC4", "TSC5", 1))\t\(graphFields)"
  }
  if magic == "TSC6" {
    compiled: "\(strings.Replace(_runtime.compiled, "TSC6", "TSC7", 1))\t\(graphFields)"
  }
}

#Target: {
  name: #TargetName
  members: [...#ServiceName] & [_, ...]
  let listSeparator = ","
  compiled: "TGT1\t\(name)\t\(strings.Join(members, listSeparator))"
}
