{Emitter}    = require 'atom'
MessageUtils = require './message-utils'

module.exports =
class IncomingMessageDispatcher
  constructor: ->
    @emitter = new Emitter

  dispatch: (message) ->
    if message?
      if message.includes MessageUtils.getFinalSymbol()
        for msg in message.split MessageUtils.getFinalSymbol()
          @handleMessage MessageUtils.removeNewLineSymbol(msg)
      else
        @handleMessage message
    return

  handleMessage: (message) ->
    if message? && message.length != 0
      if message.includes MessageUtils.getDelimiter()
        messageCategory = message.split(MessageUtils.getDelimiter())[0]
      else
        messageCategory = message

      if messageCategory == 'TABLEUPDATED'
        @emitter.emit 'table-updated', message
      else if messageCategory == 'POSITIONUPDATED'
        @emitter.emit 'position-updated', message
      else if messageCategory == 'CALLSTACKUPDATED'
        @emitter.emit 'callstack-updated', message
      else if messageCategory == 'READY'
        @emitter.emit 'ready'
      else if messageCategory == 'TERMINATECOMMUNICATION'
        @emitter.emit 'terminate-communication'
      else if messageCategory == 'ENDOFREPLAYTAPE'
        @emitter.emit 'end-of-replay-tape'
      else if messageCategory == 'AUTOSTEPPINGENABLED'
        @emitter.emit 'auto-stepping-enabled'
      else if messageCategory == 'AUTOSTEPPINGDISABLED'
        @emitter.emit 'auto-stepping-disabled'
      else
        console.log "Cannot handle message category '#{messageCategory}'!"
    return

  onTableUpdate: (callback) ->
    @emitter.on 'table-updated', callback

  onPositionUpdate: (callback) ->
    @emitter.on 'position-updated', callback

  onCallStackUpdate: (callback) ->
    @emitter.on 'callstack-updated', callback

  onReady: (callback) ->
    @emitter.on 'ready', callback

  onTerminate: (callback) ->
    @emitter.on 'terminate-communication', callback

  onEndOfReplayTape: (callback) ->
    @emitter.on 'end-of-replay-tape', callback

  onAutoSteppingEnabled: (callback) ->
    @emitter.on 'auto-stepping-enabled', callback

  onAutoSteppingDisabled: (callback) ->
    @emitter.on 'auto-stepping-disabled', callback