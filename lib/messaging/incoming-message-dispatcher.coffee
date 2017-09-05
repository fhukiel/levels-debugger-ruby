{Emitter}    = require 'atom'
MessageUtils = require './message-utils'

module.exports =
class IncomingMessageDispatcher
  constructor: ->
    @emitter = new Emitter

  destroy: ->
    @emitter.dispose()
    return

  dispatch: (message) ->
    if message
      if message.includes MessageUtils.FINAL_SYMBOL
        for msg in message.split MessageUtils.FINAL_SYMBOL
          @handleMessage MessageUtils.removeNewlineSymbol msg
      else
        @handleMessage message

    return

  handleMessage: (message) ->
    if message
      messageCategory = message.split(MessageUtils.DELIMITER)[0]

      msg = message.substring messageCategory.length + 1

      switch messageCategory
        when 'TABLEUPDATED' then @emitter.emit 'variable-table-updated', msg
        when 'POSITIONUPDATED' then @emitter.emit 'position-updated', msg
        when 'CALLSTACKUPDATED' then @emitter.emit 'call-stack-updated', msg
        when 'READY' then @emitter.emit 'ready'
        when 'TERMINATECOMMUNICATION' then @emitter.emit 'terminate-communication'
        when 'ENDOFREPLAYTAPE' then @emitter.emit 'end-of-replay-tape'
        when 'AUTOSTEPPINGENABLED' then @emitter.emit 'auto-stepping-enabled'
        when 'AUTOSTEPPINGDISABLED' then @emitter.emit 'auto-stepping-disabled'
        else console.log "Cannot handle message category '#{messageCategory}'!"

    return

  onVariableTableUpdated: (callback) ->
    @emitter.on 'variable-table-updated', callback

  onPositionUpdated: (callback) ->
    @emitter.on 'position-updated', callback

  onCallStackUpdated: (callback) ->
    @emitter.on 'call-stack-updated', callback

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