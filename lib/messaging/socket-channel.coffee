{Emitter} = require 'atom'
net       = require 'net'

module.exports =
class SocketChannel
  constructor: (@host, @port, @dispatcher) ->
    @emitter = new Emitter
    @available = false

  destroy: ->
    @disconnect()
    @emitter.dispose()
    return

  connect: ->
    if !@socket?
      @socket = net.createConnection @port, @host
      @socket.setNoDelay true
      @socket.on 'close', => @handleClose()
      @socket.on 'connect', => @handleConnect()
      @socket.on 'data', (data) => @handleData data
      @socket.on 'error', (error) => @handleError error
      @socket.on 'timeout', => @handleTimeout()
    return

  disconnect: ->
    if @socket?
      @socket.end()
      @socket.destroy()
    return

  handleClose: ->
    @socket = null
    @available = false
    return

  handleConnect: ->
    @available = true
    return

  handleData: (buffer) ->
    @dispatcher.dispatch "#{buffer}"
    return

  handleError: (error) ->
    console.log "A channel error occurred: #{error}"
    @emitError()
    return

  handleTimeout: ->
    @disconnect()
    return

  sendMessage: (msg) ->
    if @available
      @socket.write msg
    else
      console.log "Cannot send message '#{msg}', channel not available!"
    return

  emitError: ->
    @emitter.emit 'error'
    return

  onError: (callback) ->
    @emitter.on 'error', callback