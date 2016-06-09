{CompositeDisposable,Emitter} = require('atom')
messageUtils                  = require('./message-utils').getInstance()

module.exports=
class IncomingMessageDispatcher
  constructor: ->
    @emitter = new Emitter();

  dispatch: (message) ->
    # Because messages are read from a stream, multiple messages can be contained in the message string
    if message.indexOf(messageUtils.getFinalSymbol()) > -1
      @handleMessage(messageUtils.removeNewLineSymbol(msg)) for msg in message.split(messageUtils.getFinalSymbol())
    else
      @handleMessage(message)

  handleMessage: (message) ->
    if message? and message.length != 0
      if message.indexOf(messageUtils.getDelimiter()) > -1
        messageCategory = message.split(messageUtils.getDelimiter())[0]
      else
        messageCategory = message;
      if messageCategory is "TABLEUPDATED"
          @emitter.emit('table-updated', message)
      else if messageCategory is "POSITIONUPDATED"
          @emitter.emit('position-updated', message)
      else if messageCategory is "CALLSTACKUPDATED"
          @emitter.emit('callstack-updated', message)
      else if messageCategory is "READY"
          @emitter.emit('ready')
      else if messageCategory is "TERMINATECOMMUNICATION"
          @emitter.emit('terminate-communication')
      else if messageCategory is "ENDOFPLAYBACK"
          @emitter.emit('end-of-playback')
      else if messageCategory is "AUTOSTEPPINGENABLED"
          @emitter.emit('auto-stepping-enabled')
      else if messageCategory is "AUTOSTEPPINGDISABLED"
          @emitter.emit('auto-stepping-disabled')
      else
        console.log "Cannot handle category '#{messageCategory}'"

  onTableUpdate: (callback) ->
    @emitter.on('table-updated', callback)

  onPositionUpdate: (callback) ->
    @emitter.on('position-updated', callback)

  onCallStackUpdate: (callback) ->
    @emitter.on('callstack-updated', callback)

  onReady: (callback) ->
    @emitter.on('ready', callback)

  onTerminate: (callback) ->
    @emitter.on('terminate-communication', callback)

  onEndOfPlayback: (callback) ->
    @emitter.on('end-of-playback', callback)

  onAutoSteppingEnabled: (callback) ->
    @emitter.on('auto-stepping-enabled', callback)

  onAutoSteppingDisabled: (callback) ->
    @emitter.on('auto-stepping-disabled', callback)
