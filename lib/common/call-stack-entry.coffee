module.exports =
class CallStackEntry
  constructor: (@methodAndArgs, @callId) ->

  getMethodAndArgs: ->
    return @methodAndArgs

  getCallId: ->
    return @callId