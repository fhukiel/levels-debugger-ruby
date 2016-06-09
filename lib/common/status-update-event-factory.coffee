StatusUpdateEvent    = require('./status-update-event')

class StatusUpdateEventFactory
  constructor: (serializedState) ->

  createDisabled: (isReplay) ->
    return @createGeneric(isReplay, @getDisabledMessage(), @getDisabledStatus(), true);

  createRunning: (isReplay) ->
    return @createGeneric(isReplay, @getRunningMessage(), @getRunningStatus(), true);

  createWaiting: (isReplay) ->
    return @createGeneric(isReplay, @getWaitingMessage(), @getWaitingStatus(), false);

  createStopped: (isReplay) ->
    return @createGeneric(isReplay, @getStoppedMessage(), @getStoppedStatus(), true);

  createEndOfTape: (isReplay) ->
    return @createGeneric(isReplay, @getEndOfTapeMessage(), @getEndOfTapeStatus(), true);

  createGeneric: (isReplay, message, status, isBlocking) ->
    message = @createMessage(isReplay, message);
    styleClass = @createStyleClass(isReplay, status);
    return new StatusUpdateEvent(status, message, isBlocking, styleClass);

  createStyleClass: (isReplay, status) ->
    styleClass = if isReplay then "status " + status + " replay" else "status " + status;
    return styleClass;

  createMessage: (isReplay, msg) ->
    messageText = if isReplay then "(REPLAY) " + msg else msg;
    return messageText;

  getRunningStatus: ->
    return "running";

  getWaitingStatus: ->
    return "waiting";

  getStoppedStatus: ->
    return "stopped";

  getEndOfTapeStatus: ->
    return "endoftape";

  getDisabledStatus: ->
    return "disabled";

  getRunningMessage: ->
    return "Debugger running";

  getWaitingMessage: ->
    return "Debugger waiting for step"

  getStoppedMessage: ->
    return "Debugger stopped";

  getEndOfTapeMessage: ->
    return "End of tape";

  getDisabledMessage: ->
    return "Level not debuggable"

module.exports =
class StatusUpdateEventFactoryProvider
  instance = null
  @getInstance: ->
    instance ?= new StatusUpdateEventFactory
