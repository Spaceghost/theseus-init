package schema

import "strings"

#TargetName: #ServiceName

#GraphService: {
  _record: string
  service: #Service
  let listSeparator = ","
  let configuration = service
  _runtime: #CompiledService & {service: configuration}
  let graphFields = "\(strings.Join(service.requires, listSeparator))\t\(strings.Join(service.wants, listSeparator))\t\(strings.Join(service.after, listSeparator))\t\(strings.Join(service.before, listSeparator))"
  let magic = strings.SplitN(_runtime._record, "\t", 2)[0]
  if magic == "TSC2" {
    _record: "\(strings.Replace(_runtime._record, "TSC2", "TSC3", 1))\t\(graphFields)"
  }
  if magic == "TSC4" {
    _record: "\(strings.Replace(_runtime._record, "TSC4", "TSC5", 1))\t\(graphFields)"
  }
  if magic == "TSC6" {
    _record: "\(strings.Replace(_runtime._record, "TSC6", "TSC7", 1))\t\(graphFields)"
  }
  if service.stopGraceMs == 1000 {
    compiled: _record
  }
  if service.stopGraceMs != 1000 {
    compiled: "TSC9\t\(service.stopGraceMs)\t\(_record)"
  }
}

#Target: {
  name: #TargetName
  members: [...#ServiceName] & [_, ...]
  let listSeparator = ","
  compiled: "TGT1\t\(name)\t\(strings.Join(members, listSeparator))"
}
