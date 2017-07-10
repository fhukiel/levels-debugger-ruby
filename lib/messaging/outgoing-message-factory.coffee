MessageUtils = require './message-utils'

module.exports =
class OutgoingMessageFactory
  @positionToString: (position) ->
    return position.getLine() + MessageUtils.getDelimiter() + position.getColumn()

  @createAddBreakpointMessage: (position) ->
    return 'ADDBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString(position) + MessageUtils.getNewLineSymbol()

  @createRemoveBreakpointMessage: (position) ->
    return 'REMOVEBREAKPOINT' + MessageUtils.getDelimiter() + OutgoingMessageFactory.positionToString(position) + MessageUtils.getNewLineSymbol()

  @createRunToNextBreakpointMessage: ->
    return 'RUNTONEXTBREAKPOINT' + MessageUtils.getNewLineSymbol()

  @createRunToEndOfMethodMessage: ->
    return 'RUNTOENDOFMETHOD' + MessageUtils.getNewLineSymbol()

  @createEnableAllBreakpointsMessage: ->
    return 'ENABLEALLBREAKPOINTS' + MessageUtils.getNewLineSymbol()

  @createDisableAllBreakpointsMessage: ->
    return 'DISABLEALLBREAKPOINTS' + MessageUtils.getNewLineSymbol()

  @createStartReplayMessage: (callID) ->
    return 'STARTREPLAY' + MessageUtils.getDelimiter() + callID + MessageUtils.getNewLineSymbol()

  @createStepMessage: ->
    return 'STEP' + MessageUtils.getNewLineSymbol()

  @createStepOverMessage: ->
    return 'STEPOVER' + MessageUtils.getNewLineSymbol()

  @createStopReplayMessage: ->
    return 'STOPREPLAY' + MessageUtils.getNewLineSymbol()

  @createRemoveAllBreakpointsMessage: ->
    return 'REMOVEALLBREAKPOINTS' + MessageUtils.getNewLineSymbol()