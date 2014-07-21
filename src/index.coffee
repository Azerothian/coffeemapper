Promise = require "bluebird"
Chains = require "chains"

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
  newItem: () ->
    return {}
  setValue: (item, key, value) ->
    item[key] = value
  getValue: (item, key) ->
    return item[key]
}

setValueHook = (key, data, map, src, proc, refid) ->
  return new Promise (resolve, reject) ->
    debug "#{refid} promiseHook - rule #{key} "
    map[key] src, (value) ->
      debug "#{refid} setValue - #{key}: #{value} "
      proc.setValue data, key, value
      return resolve()
    , reject


singleMap = (src, map, proc, data, refid) ->
  return new Promise (resolve, reject) ->
    inrefid = uuid()

    debug "#{refid}:#{inrefid} singleMap - start "
    proc = baseProcessor if !proc?
    if !data?
      data = proc.newItem()
    p = new Chains

    for key of map
      p.push setValueHook, [key, data, map, src, proc, inrefid]

    debug "#{refid}:#{inrefid} singleMap - starting chains concat "
    p.last(p).then () ->
      debug "#{refid}:#{inrefid} singleMap - finish ", p.length
      resolve data
    , reject


module.exports = (src, map, proc = baseProcessor, data) ->
  return new Promise (resolve, reject) ->
    refid = uuid()
    debug "#{refid} main - start"
    p = new Chains
    if Array.isArray src
      for s in src
        p.push singleMap, [s, map, proc, data, refid]
    else
      p.push singleMap, [src, map, proc, data, refid]

    debug "#{refid} main - processing maps", p.length

    p.collect(p).then (data) ->
      debug "#{refid} main - finish"
      return resolve(data)
    , reject
