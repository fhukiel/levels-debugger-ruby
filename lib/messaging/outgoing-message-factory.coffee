{EOL, DELIMITER} = require './message-utils'

module.exports =
class OutgoingMessageFactory
  @positionToString: (position) ->
    return position.getLine() + DELIMITER + position.getColumn()

  @createAddBreakpointMessage: (position) ->
    return OutgoingMessageFactory.createMessage 'ADDBREAKPOINT' + DELIMITER + OutgoingMessageFactory.positionToString position

  @createRemoveBreakpointMessage: (position) ->
    return OutgoingMessageFactory.createMessage 'REMOVEBREAKPOINT' + DELIMITER + OutgoingMessageFactory.positionToString position

  @createRunToNextBreakpointMessage: ->
    return OutgoingMessageFactory.createMessage 'RUNTONEXTBREAKPOINT'

  @createRunToEndOfMethodMessage: ->
    return OutgoingMessageFactory.createMessage 'RUNTOENDOFMETHOD'

  @createEnableAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'ENABLEALLBREAKPOINTS'

  @createDisableAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'DISABLEALLBREAKPOINTS'

  @createStartReplayMessage: (callId) ->
    return OutgoingMessageFactory.createMessage 'STARTREPLAY' + DELIMITER + callId

  @createStepMessage: ->
    return OutgoingMessageFactory.createMessage 'STEP'

  @createStepOverMessage: ->
    return OutgoingMessageFactory.createMessage 'STEPOVER'

  @createStopReplayMessage: ->
    return OutgoingMessageFactory.createMessage 'STOPREPLAY'

  @createRemoveAllBreakpointsMessage: ->
    return OutgoingMessageFactory.createMessage 'REMOVEALLBREAKPOINTS'

  @createMessage: (msg) ->
    return msg + EOL