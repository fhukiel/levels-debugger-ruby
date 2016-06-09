net = require 'net'
{CompositeDisposable,Emitter} = require('atom')

module.exports =
class SocketChannel
  constructor: (incomingMessageDispatcher) ->
    @port = 59599;
    @dispatcher = incomingMessageDispatcher
    @host = 'localhost'
    @emitter = new Emitter();
    @available = false;

  connect: ->
    console.log "Connecting to #{@host}:#{@port}"
    @socket = net.createConnection @port, @host
    @socket.setNoDelay(true)
    @socket.on 'close', () => @handleClose();
    @socket.on 'connect', () => @handleConnect();
    # this is a bit messy but because of the weird scoping rules, it's just easier to pass the dispatcher
    @socket.on 'data', (data) => handleData(data, @dispatcher);
    @socket.on 'drain', () => @handleDrain();
    @socket.on 'end', () => @handleEnd();
    @socket.on 'error', (error) => handleError(error, @emitter);
    @socket.on 'lookup', () => @handleLookup();
    @socket.on 'timeout', () => @handleTimeout();

  disconnect: ->
    if @socket?
      @socket.end();
      @socket.destroy();
    @available = false;

  handleClose: ->
    console.log "Connection to #{@host}:#{@port} closed."
    @socket = null;
    @available = false;

  handleConnect: ->
    console.log "Opened connection to #{@host}:#{@port}"
    @available = true;

  handleData = (buffer, dispatcher) ->
    console.log "Received: #{buffer}"
    dispatcher.dispatch("#{buffer}");

  handleDrain: ->
    console.log "Received drain event, write buffer is now empty."

  handleEnd: ->
    console.log "Peer sent FIN."

  handleError = (error, emitter) ->
    console.log "An error occurred: #{error}."
    emitter.emit('channel-error')

  handleLookup: ->
    console.log "Resolved the host, about to connect."

  handleTimeout: ->
    console.log "The socket has timed out. It will be destroyed now."
    @socket.destroy()
    @available = false;

  sendMessage: (msg) ->
    if @available
      console.log "Sending message #{msg}"
      written = @socket.write msg;
    else
      console.log "Cannot send message '#{msg}', channel not available."

  onError: (callback) ->
    @emitter.on('channel-error', callback)
