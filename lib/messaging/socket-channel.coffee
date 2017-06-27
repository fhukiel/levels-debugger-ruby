{Emitter} = require('atom')
net       = require('net')

module.exports =
class SocketChannel
  constructor: (@dispatcher) ->
    @port = 59599
    @host = 'localhost'
    @emitter = new Emitter()
    @available = false

  connect: ->
    @socket = net.createConnection(@port, @host)
    @socket.setNoDelay(true)
    @socket.on('close', => @handleClose())
    @socket.on('connect', => @handleConnect())
    @socket.on('data', (data) => @handleData(data))
    @socket.on('error', (error) => @handleError(error))
    @socket.on('timeout', => @handleTimeout())

  disconnect: ->
    if @socket?
      @socket.end()
      @socket.destroy()

    @available = false

  handleClose: ->
    @socket = null
    @available = false

  handleConnect: ->
    @available = true

  handleData: (buffer) ->
    @dispatcher.dispatch("#{buffer}")

  handleError: (error) ->
    console.log("An error occurred: #{error}")
    @emitter.emit('channel-error')

  handleTimeout: ->
    @socket.destroy()
    @available = false

  sendMessage: (msg) ->
    if @available
      @socket.write(msg)
    else
      console.log("Cannot send message '#{msg}', channel not available!")

  onError: (callback) ->
    @emitter.on('channel-error', callback)