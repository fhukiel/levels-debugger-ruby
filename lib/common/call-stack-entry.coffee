module.exports =
class CallStackEntry
  constructor: (@methodAndArgs, @callID) ->

  getMethodAndArgs: ->
    return @methodAndArgs

  getCallID: ->
    return @callID