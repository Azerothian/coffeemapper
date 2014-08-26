map = require "../index"
expect = require('chai').expect
util = require "util"
Element = require "./util/element"

debug = require("debug")("coffeemapper:tests:map-test")


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


elementProcessor = {
  newItem: () ->
    return new Element
  setValue: (item, key, value) ->
    item[key] = value
  getValue: (item, key) ->
    return item[key]
}

projectMap = {
  read:
    "name": (src, resolve, reject) ->
      debug "projectMap.read.name", src.properties[0]
      resolve src.properties[0]
    "path": (src, resolve, reject) ->
      debug "projectMap.read.path", src.properties[1]
      resolve src.properties[1]
    "id": (src, resolve, reject) ->
      debug "projectMap.read.id", src.properties[2]
      resolve src.properties[2]
  write:
    "name": (src, resolve, reject) ->
      resolve "Project"
    "properties": (src, resolve, reject) ->
      #debug "projectMap.write.properties", src
      resolve [src.name, src.path, src.id]

}


elementMap = {
  read:
    "VisualStudioVersion": (src, resolve, reject) ->
      value = src.getElement("VisualStudioVersion").properties[0]
      debug "elementMap.read.VisualStudioVersion", value
      return resolve value
    "Projects": (src, resolve, reject) ->
      projects = src.getElementsByName "Project"
      debug "elementMap.read.Projects", projects
      #console.log "projs", util.inspect projects
      #resolve projects
      return map(projects, projectMap.read).then resolve, reject
  write:
    "elements": (src, resolve, reject) ->
      #debug "elementMap.write.elements"
      data = []
      data.push new Element {
        name: "VisualStudioVersion"
        properties: [src.VisualStudioVersion]
      }
      map(src.Projects, projectMap.write, elementProcessor).then (result) ->
        #debug "elementMap.write.elements.map.Projects", result
        for r in result
          data.push r
        return resolve data
      , reject
}



describe 'Object Mapping', () ->
  it 'coffeemapper Test', () ->
    debug "read start"
    map(core, elementMap.read).then (result) ->

      debug "read complete", util.inspect(result)
      expect(result.Projects[0].name).to.equal("WebApplication1")

      debug "write start"
      map(result, elementMap.write, undefined, elementProcessor).then (re) ->
        expect(re.elements[1].name).to.equal("Project")
        debug "write complete"#, re[0].elements[1].name
  it 'context check', ->
    test = {}
    map({hello: "hi"}, {
      "troll": (src, resolve, reject) ->
        resolve(src.hello)
      }, test).then (o) ->
        expect(test.troll).to.equal("hi")
