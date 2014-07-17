map = require "../index"
expect = require('chai').expect
util = require "util"

Element = require "./util/element"


core = new Element
core.push new Element {
  name: "VisualStudioVersion"
  properties: ["12.0.30501.0"]
}
core.push new Element {
  name: "MinimumVisualStudioVersion"
  properties: ["10"]
}
core.push new Element {
  name: "Project"
  properties: [
    "WebApplication1",
    "WebApplication1\\WebApplication1.csproj",
    "{DAA7C8D8-63E8-4587-842D-B39F01718BF8}"
  ]
}
core.push new Element {
  name: "Project"
  properties: [
    "ConsoleApplication1",
    "ConsoleApplication1\\ConsoleApplication1.csproj",
    "{B68291DE-FCED-46E0-85EE-F273AA73448F}"
  ]
}


projectMap = {
  read:
    "name": (src, resolve, reject) ->
      #console.log "src:", src
      resolve src.properties[0]
    "path": (src, resolve, reject) ->
      resolve src.properties[1]
    "id": (src, resolve, reject) ->
      resolve src.properties[2]
  write:
    "name": (src, resolve, reject) ->
      resolve "Project"
    "properties": (src, resolve, reject) ->
      resolve [src.name, src.path, src.id]

}
elementProcessor = {
  newItem: () ->
    console.log "exec"
    return new Element
  setValue: (item, key, value) ->
    item[key] = value
}


elementMap = {
  read:
    "VisualStudioVersion": (src, resolve, reject) ->
      value = src.getElement("VisualStudioVersion").properties[0]
      return resolve value
    "Projects": (src, resolve, reject) ->
      projects = src.getElementsByName "Project"
      #console.log "projs", util.inspect projects
      return map(projects, projectMap.read).then resolve, reject
  write:
    "elements": (src, resolve, reject) ->
      data = []
      data.push new Element {
        name: "VisualStudioVersion"
        properties: [src.VisualStudioVersion]
      }
      map(src.Projects, projectMap.write, elementProcessor).then (result) ->
        for r in result
          data.push r
        return resolve data
      , reject
}



describe 'Object Mapping', () ->
  it 'Mapper Test', () ->
    map(core, elementMap.read).then (result) ->
      console.log "res: ", result.Projects[0].name
      expect(result.Projects[0].name).to.equal("WebApplication1")
      return map(result, elementMap.write, elementProcessor).then (re) ->
        console.log "write", util.inspect re


###
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "WebApplication1", "WebApplication1\WebApplication1.csproj", "{DAA7C8D8-63E8-4587-842D-B39F01718BF8}"
  ProjectSection(ProjectDependencies) = postProject
    {B68291DE-FCED-46E0-85EE-F273AA73448F} = {B68291DE-FCED-46E0-85EE-F273AA73448F}
  EndProjectSection
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "ConsoleApplication1", "ConsoleApplication1\ConsoleApplication1.csproj", "{B68291DE-FCED-46E0-85EE-F273AA73448F}"
EndProject
###
