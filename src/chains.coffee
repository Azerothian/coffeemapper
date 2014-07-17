Promise = require 'bluebird'
util = require 'util'
log = () ->

if console?
  if Function?
    if Function.prototype?
      if Function.prototype.bind?
        log = Function.prototype.bind.call(console.log, console)
      else
        log = () ->
          Function.prototype.apply.call(console.log, console, arguments)
  else if console.log?
    if console.log.apply?
      log = () ->
        console.log.apply console, arguments





module.exports = class Chains
  constructor: (@promises=[]) ->
    @length = @promises.length

  add: (promise, context, args) =>
    if !promise?
      throw "Chains - Error: promise being provided is not valid"
    @promises.push { promise: promise, context: context, args: args }
    @length = @promises.length

  push: () =>
    @add.apply @, arguments

  concat: () =>
    for i in arguments
      @promises.concat(i)
  get: () =>
    return @promises

  clear: () =>
    @promises = []
    @length = 0

  run: () =>
    return @chainUtil 0, @promises, arguments

  chainUtil: (i, array, originalArgs, collect, rejected = false) ->
    return new Promise (resolve, reject) =>
      if not array?
        throw "Chains - chainUtil - array is not defined"
      if not collect?
        collect = []
      if array[i]?
        if array[i].args?
          args = array[i].args
        else
          args = originalArgs
        OnComplete = (val) =>
          if val?
            collect.push val
          rs = resolve
          rj = reject

          if @onResolve?
            rs = @onResolve(resolve)
          if @onReject?
            rj = @onReject(reject)

          return @chainUtil(i+1, array, originalArgs, collect, rejected)
            .then(rs, rj)
        OnReject = () =>
          rejected = true
          return OnComplete.apply @, arguments
        try
          if array[i].args?
            return array[i].promise.apply(array[i].context, args)
              .then OnComplete, OnReject
          else if array[i].promise

            return array[i].promise().then OnComplete, OnReject
        catch err
          log "#{err}", util.inspect {current: array[i]}
          throw err

      else
        if rejected
          return reject(collect)
        else
          return resolve(collect)
