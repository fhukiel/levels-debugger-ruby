MessageUtils = require '../messaging/message-utils'

module.exports =
class CallStackFactory
  @fromString: (string) ->
    callStack = []
    splitted = string?.split MessageUtils.getDelimiter()

    if splitted?
      for i in [1..splitted.length]
        if splitted[i]?
          callStack.push splitted[i]

    return callStack