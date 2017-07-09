messageUtils = require('../messaging/message-utils').getInstance()

class CallStackFactory
  fromString: (string) ->
    callStack = new Array
    splitted = string?.split messageUtils.getDelimiter()

    if splitted?
      for i in [1..splitted.length]
        if splitted[i]?
          callStack.push splitted[i]

    return callStack

module.exports =
class CallStackFactoryProvider
  instance = null

  @getInstance: ->
    instance ?= new CallStackFactory