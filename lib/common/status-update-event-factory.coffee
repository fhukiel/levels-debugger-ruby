StatusUpdateEvent = require './status-update-event'

module.exports =
class StatusUpdateEventFactory
  @createDisabled: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.getDisabledMessage(), StatusUpdateEventFactory.getDisabledStatus(), true

  @createRunning: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.getRunningMessage(), StatusUpdateEventFactory.getRunningStatus(), true

  @createWaiting: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.getWaitingMessage(), StatusUpdateEventFactory.getWaitingStatus(), false

  @createStopped: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.getStoppedMessage(), StatusUpdateEventFactory.getStoppedStatus(), true

  @createEndOfTape: (isReplay) ->
    return StatusUpdateEventFactory.createGeneric isReplay, StatusUpdateEventFactory.getEndOfTapeMessage(), StatusUpdateEventFactory.getEndOfTapeStatus(), true

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

  @getRunningStatus: ->
    return 'running'

  @getWaitingStatus: ->
    return 'waiting'

  @getStoppedStatus: ->
    return 'stopped'

  @getEndOfTapeStatus: ->
    return 'endoftape'

  @getDisabledStatus: ->
    return 'disabled'

  @getRunningMessage: ->
    return 'Debugger Running'

  @getWaitingMessage: ->
    return 'Debugger Waiting For Step'

  @getStoppedMessage: ->
    return 'Debugger Stopped'

  @getEndOfTapeMessage: ->
    return 'End Of Tape'

  @getDisabledMessage: ->
    return 'Level Not Debuggable'