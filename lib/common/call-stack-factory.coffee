CallStackEntry             = require './call-stack-entry'
{DELIMITER, ASSIGN_SYMBOL} = require '../messaging/message-utils'

module.exports =
class CallStackFactory
  @fromString: (string) ->
    callStack = []

    if string
      splitted = string.split DELIMITER

      for elem in splitted
        innerSplitted = elem.split ASSIGN_SYMBOL
        entry = new CallStackEntry innerSplitted[0], innerSplitted[1]
        callStack.push entry

    return callStack