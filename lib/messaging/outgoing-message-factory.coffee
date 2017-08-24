MessageUtils = require './message-utils'

module.exports =
class OutgoingMessageFactory
  @positionToString: (position) ->
    return position.getLine() + MessageUtils.getDelimiter() + position.getColumn()

  @createAddBreakpointMessage: (position) ->
    return OutgoingMessageFactory.createMessage 'ADDBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString position

  @createRemoveBreakpointMessage: (position) ->
    return OutgoingMessageFactory.createMessage 'REMOVEBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString position

  @createRunToNextBreakpointMessage: ->
    return OutgoingMessageFactory.createMessage 'RUNTONEXTBREAKPOINT'

  @createRunToEndOfMethodMessage: ->
    return OutgoingMessageFactory.createMessage 'RUNTOENDOFMETHOD'

  @createEnableAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'ENABLEALLBREAKPOINTS'

  @createDisableAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'DISABLEALLBREAKPOINTS'

  @createStartReplayMessage: (callID) ->
    return OutgoingMessageFactory.createMessage 'STARTREPLAY' + MessageUtils.getDelimiter() + callID

  @createStepMessage: ->
    return OutgoingMessageFactory.createMessage 'STEP'

  @createStepOverMessage: ->
    return OutgoingMessageFactory.createMessage 'STEPOVER'

  @createStopReplayMessage: ->
    return OutgoingMessageFactory.createMessage 'STOPREPLAY'

  @createRemoveAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'REMOVEALLBREAKPOINTS'

  @createMessage: (msg) ->
    return msg + MessageUtils.getNewLineSymbol()