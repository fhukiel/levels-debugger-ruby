CallStackEntry = require './call-stack-entry'
MessageUtils   = require '../messaging/message-utils'

module.exports =
class CallStackFactory
  @fromString: (string) ->
    callStack = []

    if string? && string.length != 0
      splitted = string.split MessageUtils.DELIMITER

      for elem in splitted
        innerSplitted = elem.split MessageUtils.ASSIGN_SYMBOL
        entry = new CallStackEntry innerSplitted[0], innerSplitted[1]
        callStack.push entry

    return callStack