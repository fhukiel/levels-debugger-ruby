StatusUpdateEvent = require('./status-update-event')

class StatusUpdateEventFactory
  createDisabled: (isReplay) ->
    return @createGeneric(isReplay, @getDisabledMessage(), @getDisabledStatus(), true)

  createRunning: (isReplay) ->
    return @createGeneric(isReplay, @getRunningMessage(), @getRunningStatus(), true)

  createWaiting: (isReplay) ->
    return @createGeneric(isReplay, @getWaitingMessage(), @getWaitingStatus(), false)

  createStopped: (isReplay) ->
    return @createGeneric(isReplay, @getStoppedMessage(), @getStoppedStatus(), true)

  createEndOfTape: (isReplay) ->
    return @createGeneric(isReplay, @getEndOfTapeMessage(), @getEndOfTapeStatus(), true)

  createGeneric: (isReplay, message, status, isBlocking) ->
    message = @createMessage(isReplay, message)
    styleClass = @createStyleClass(isReplay, status)
    return new StatusUpdateEvent(status, message, isBlocking, styleClass)

  createStyleClass: (isReplay, status) ->
    styleClass = 'status ' + status
    if isReplay
      styleClass += ' replay'

    return styleClass

  createMessage: (isReplay, message) ->
    return if isReplay then '(REPLAY) ' + message else message

  getRunningStatus: ->
    return 'running'

  getWaitingStatus: ->
    return 'waiting'

  getStoppedStatus: ->
    return 'stopped'

  getEndOfTapeStatus: ->
    return 'endoftape'

  getDisabledStatus: ->
    return 'disabled'

  getRunningMessage: ->
    return 'Debugger Running'

  getWaitingMessage: ->
    return 'Debugger Waiting For Step'

  getStoppedMessage: ->
    return 'Debugger Stopped'

  getEndOfTapeMessage: ->
    return 'End Of Tape'

  getDisabledMessage: ->
    return 'Level Not Debuggable'

module.exports =
class StatusUpdateEventFactoryProvider
  instance = null

  @getInstance: ->
    instance ?= new StatusUpdateEventFactory()