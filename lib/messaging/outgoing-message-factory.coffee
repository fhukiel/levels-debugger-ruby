messageUtils = require('./message-utils').getInstance()

class OutgoingMessageFactory
  positionToString: (position) ->
    return position.getLine() + messageUtils.getDelimiter() + position.getColumn()

  createAddBreakpointMessage: (position) ->
    return 'ADDBREAKPOINT' + messageUtils.getDelimiter() + @positionToString(position) + messageUtils.getNewLineSymbol()

  createRemoveBreakpointMessage: (position) ->
    return 'REMOVEBREAKPOINT' + messageUtils.getDelimiter() + @positionToString(position) + messageUtils.getNewLineSymbol()

  createRunToNextBreakpointMessage: ->
    return 'RUNTONEXTBREAKPOINT' + messageUtils.getNewLineSymbol()

  createRunToEndOfMethodMessage: ->
    return 'RUNTOENDOFMETHOD' + messageUtils.getNewLineSymbol()

  createEnableAllBreakpointsMessage: ->
    return 'ENABLEALLBREAKPOINTS' + messageUtils.getNewLineSymbol()

  createDisableAllBreakpointsMessage: ->
    return 'DISABLEALLBREAKPOINTS' + messageUtils.getNewLineSymbol()

  createStartReplayMessage: (callID) ->
    return 'STARTREPLAY' + messageUtils.getDelimiter() + callID + messageUtils.getNewLineSymbol()

  createStepMessage: ->
    return 'STEP' + messageUtils.getNewLineSymbol()

  createStepOverMessage: ->
    return 'STEPOVER' + messageUtils.getNewLineSymbol()

  createStopReplayMessage: ->
    return 'STOPREPLAY' + messageUtils.getNewLineSymbol()

  createRemoveAllBreakpointsMessage: ->
    return 'REMOVEALLBREAKPOINTS' + messageUtils.getNewLineSymbol()

module.exports =
class OutgoingMessageFactoryProvider
  instance = null

  @getInstance: ->
    instance ?= new OutgoingMessageFactory