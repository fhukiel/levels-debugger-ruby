{Emitter} = require 'atom'
net       = require 'net'

module.exports =
class SocketChannel
  constructor: (@dispatcher) ->
    @port = 59599
    @host = 'localhost'
    @emitter = new Emitter
    @available = false

  connect: ->
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

    @available = false
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
    console.log "An error occurred: #{error}"
    @emitter.emit 'channel-error'
    return

  handleTimeout: ->
    @socket.destroy()
    @available = false
    return

  sendMessage: (msg) ->
    if @available
      @socket.write msg
    else
      console.log "Cannot send message '#{msg}', channel not available!"
    return

  onError: (callback) ->
    @emitter.on 'channel-error', callback