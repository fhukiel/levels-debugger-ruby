MessageUtils = require './message-utils'

module.exports =
class OutgoingMessageFactory
  @positionToString: (position) ->
    return position.getLine() + MessageUtils.getDelimiter() + position.getColumn()

  @createAddBreakpointMessage: (position) ->
    return MessageUtils.createMessage 'ADDBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString position

  @createRemoveBreakpointMessage: (position) ->
    return MessageUtils.createMessage 'REMOVEBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString position

  @createRunToNextBreakpointMessage: ->
    return MessageUtils.createMessage 'RUNTONEXTBREAKPOINT'

  @createRunToEndOfMethodMessage: ->
    return MessageUtils.createMessage 'RUNTOENDOFMETHOD'

  @createEnableAllBreakpointsMessage: ->
    return MessageUtils.createMessage 'ENABLEALLBREAKPOINTS'

  @createDisableAllBreakpointsMessage: ->
    return MessageUtils.createMessage 'DISABLEALLBREAKPOINTS'

  @createStartReplayMessage: (callID) ->
    return MessageUtils.createMessage 'STARTREPLAY' + MessageUtils.getDelimiter() + callID

  @createStepMessage: ->
    return MessageUtils.createMessage 'STEP'

  @createStepOverMessage: ->
    return MessageUtils.createMessage 'STEPOVER'

  @createStopReplayMessage: ->
    return MessageUtils.createMessage 'STOPREPLAY'

  @createRemoveAllBreakpointsMessage: ->
    return MessageUtils.createMessage 'REMOVEALLBREAKPOINTS'

  @createMessage: (msg) ->
    return msg + MessageUtils.getNewLineSymbol()