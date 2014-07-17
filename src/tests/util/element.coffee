util = require "util"

class Element
  constructor: (data) ->
    @elements = []

    if data?
      for o of data
        @[o] = data[o]

  getElement: (name) ->
    for e in @elements
      if e.name is name
        return e
        
  getElementsByName: (name) ->
    result = []
    for e in @elements
      if e.name is name
        result.push e
    return result


  push: () =>
    @elements.push.apply @elements, arguments




module.exports = Element
