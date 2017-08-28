StatusUpdateEvent = require './status-update-event'

module.exports =
class StatusUpdateEventFactory
  @createDisabled: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.DISABLED_MESSAGE, StatusUpdateEventFactory.DISABLED_STATUS, true

  @createRunning: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.RUNNING_MESSAGE, StatusUpdateEventFactory.RUNNING_STATUS, true

  @createWaiting: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.WAITING_MESSAGE, StatusUpdateEventFactory.WAITING_STATUS, false

  @createStopped: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.STOPPED_MESSAGE, StatusUpdateEventFactory.STOPPED_STATUS, true

  @createEndOfTape: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.END_OF_TAPE_MESSAGE, StatusUpdateEventFactory.END_OF_TAPE_STATUS, true

  @createGeneric: (isReplay, message, status, isBlocking) ->
    msg = StatusUpdateEventFactory.createMessage isReplay, message
    styleClass = StatusUpdateEventFactory.createStyleClass isReplay, status

    return new StatusUpdateEvent status, msg, isBlocking, styleClass

  @createStyleClass: (isReplay, status) ->
    styleClass = 'status-' + status
    if isReplay
      styleClass += ' status-replay'

    return styleClass

  @createMessage: (isReplay, message) ->
    return if isReplay then '(REPLAY) ' + message else message

  @RUNNING_STATUS: 'running'

  @WAITING_STATUS: 'waiting'

  @STOPPED_STATUS: 'stopped'

  @END_OF_TAPE_STATUS: 'endoftape'

  @DISABLED_STATUS: 'disabled'

  @RUNNING_MESSAGE: 'Debugger Running'

  @WAITING_MESSAGE: 'Debugger Waiting For Step'

  @STOPPED_MESSAGE: 'Debugger Stopped'

  @END_OF_TAPE_MESSAGE: 'End Of Tape'

  @DISABLED_MESSAGE: 'Level Not Debuggable'