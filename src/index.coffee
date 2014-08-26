Promise = require "bluebird"
Chains = require "bluebird-chains"

debug = require("debug")("coffeemapper:index")

uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = if c is 'x' then r else (r & 0x3|0x8)
    v.toString(16)
  )


if !Array.isArray
  Array.isArray = (arg) ->
    return Object.prototype.toString.call(arg) is '[object Array]'

isFunction = (functionToCheck) ->
  return functionToCheck && ({}).toString.call(functionToCheck) is '[object Function]'


baseProcessor = {
  newItem: (src) ->
    return {}
  setValue: (item, key, value) ->
    item[key] = value

  getValue: (item, key) ->
    return item[key]
}

finishedMap = (result, isArray, resolve, reject) ->
  if !isArray
    resolve(result[0])
  else
    resolve(result)

setValueHook = (key, data, map, src, proc, refid) ->
  return new Promise (resolve, reject) ->
    debug "#{refid} promiseHook - rule #{key} "
    setVal = (value) ->
      debug "#{refid} setValue - #{key}: #{value} "
      proc.setValue data, key, value
      return resolve()
    if isFunction(map[key])
      map[key] src, setVal, resolve
    else
      val = proc.getValue(src, key)
      setVal(val)

getNewItem = (data, proc, src) ->
  return new Promise (resolve, reject) ->
    if !data?
      newVar = proc.newItem(src)
      if newVar instanceof Promise
        return newVar.then resolve, reject
      else
        return resolve(newVar)
    else
      resolve()


syncSingleMap = (src, map, proc, data, refid) ->
  return new Promise (resolve, reject) ->
    inrefid = uuid()

    debug "#{refid}:#{inrefid} singleMap - start "
    proc = baseProcessor if !proc?

    getNewItem(data, proc, src).then (result) ->
      if result?
        data = result
      p = new Chains

      for key of map
        p.push setValueHook, [key, data, map, src, proc, inrefid]

      debug "#{refid}:#{inrefid} singleMap - starting chains concat "
      p.last(p).then () ->
        debug "#{refid}:#{inrefid} singleMap - finish ", p.length
        resolve data
      , reject

syncMapper = (src, map, data, proc = baseProcessor) ->
  debug "sync mode"
  return new Promise (resolve, reject) ->
    refid = uuid()
    debug "#{refid} main - start"
    p = new Chains
    if Array.isArray src
      for s in src
        p.push syncSingleMap, [s, map, proc, data, refid]
    else
      p.push syncSingleMap, [src, map, proc, data, refid]

    debug "#{refid} main - processing maps", p.length

    p.collect(p).then (result) ->
      debug "#{refid} main - finish"
      return finishedMap(result, Array.isArray(src), resolve, reject)
    , reject


asyncSingleMap = (src, map, proc, data, refid) ->
  return new Promise (resolve, reject) ->
    inrefid = uuid()

    debug "#{refid}:#{inrefid} singleMap - start "
    proc = baseProcessor if !proc?
    getNewItem(data, proc, src).then (result) ->
      if result?
        data = result
      p = []

      for key of map
        p.push setValueHook(key, data, map, src, proc, inrefid)

      debug "#{refid}:#{inrefid} singleMap - starting chains concat "
      Promise.all(p).then () ->
        debug "#{refid}:#{inrefid} singleMap - finish ", p.length
        resolve data
      , reject


asyncMapper = (src, map, data, proc = baseProcessor) ->
  debug "async mode"
  return new Promise (resolve, reject) ->
    refid = uuid()
    debug "#{refid} main - start"
    p = []
    if Array.isArray src
      for s in src
        p.push asyncSingleMap(s, map, proc, data, refid)
    else
      p.push asyncSingleMap(src, map, proc, data, refid)

    debug "#{refid} main - processing maps", p.length

    Promise.all(p).then (result) ->
      debug "#{refid} main - finish"
      return finishedMap(result, Array.isArray(src), resolve, reject)
    , reject


asyncMapper.sync = syncMapper

module.exports = asyncMapper
