module.exports =
class StatusUpdateEvent
  constructor: (status, displayMessage, isBlocking, styleClass) ->
    @status = status;
    @displayMessage = displayMessage;
    @isBlocking = isBlocking;
    @styleClass = styleClass

  getStatus: ->
    return @status

  getDisplayMessage: ->
    return @displayMessage

  isBlockingStatus: ->
    return @isBlocking

  getStyleClass: ->
    return @styleClass
