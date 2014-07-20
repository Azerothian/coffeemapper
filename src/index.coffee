Promise = require "bluebird-chains"
debug = require("debug")("mapper:main")

if !Array.isArray
  Array.isArray = (arg) ->
    return Object.prototype.toString.call(arg) is '[object Array]'

isFunction = (functionToCheck) ->
  return functionToCheck && ({}).toString.call(functionToCheck) is '[object Function]'


baseProcessor = {
  newItem: () ->
    return {}
  setValue: (item, key, value) ->
    item[key] = value
  getValue: (item, key) ->
    return item[key]
}

singleMap = (src, map, proc, data) ->
  return new Promise (resolve, reject) ->
    proc = baseProcessor if !proc?
    if !data?
      data = proc.newItem()
    p = []
    for key of map
      p.push new Promise (res, rej) ->
        val = proc.getValue(data, key)
        map[key] src, (value) ->
          proc.setValue data, key, value
          return res()
        , rej
    Promise.chains.concat(p).then () ->
      resolve data
    , reject


module.exports = (src, map, proc = baseProcessor, data) ->
  return new Promise (resolve, reject) ->
    p = []
    if Array.isArray src
      for s in src
        p.push singleMap(s, map, proc, data)
    else
      p.push singleMap(src, map, proc, data)

    Promise.chains.collect(p).then (data) ->
      return resolve(data)
    , reject
