Promise = require "bluebird"
if !Array.isArray
  Array.isArray = (arg) ->
    return Object.prototype.toString.call(arg) is '[object Array]'
isFunction = (functionToCheck) ->
  getType = {}
  return functionToCheck && getType.toString.call(functionToCheck) is '[object Function]'


baseProcessor = {
  newItem: () ->
    return {}
  setValue: (item, key, value) ->
    item[key] = value
}

singleMap = (src, map, proc) ->
  return new Promise (resolve, reject) ->
    console.log "proc", proc, baseProcessor
    proc = baseProcessor if !proc?
    data = proc.newItem()
    p = []
    for key of map
      p.push new Promise (res, rej) ->
        if isFunction(map[key])
          map[key] src, (value) ->
            proc.setValue data, key, value
            return res()
          , rej
        #else
    Promise.all(p).then () ->
      resolve data
    , reject


module.exports = (src, map, proc = baseProcessor) ->
  return new Promise (resolve, reject) ->
    if Array.isArray src
      p = []
      for s in src
        p.push singleMap s, map, proc
      Promise.all(p).then (data) ->
        return resolve(data)
      , reject
    else
      return singleMap(src, map).then resolve, reject
