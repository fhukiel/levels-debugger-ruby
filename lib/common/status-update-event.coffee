module.exports =
class StatusUpdateEvent
  constructor: (@status, @displayMessage, @isBlocking, @styleClass) ->

  getStatus: ->
    return @status

  getDisplayMessage: ->
    return @displayMessage

  isBlockingStatus: ->
    return @isBlocking

  getStyleClass: ->
    return @styleClass