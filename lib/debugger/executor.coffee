path                                            = require('path')
{CompositeDisposable, Emitter, BufferedProcess} = require 'atom'
class Excecutor
  constructor: (serializedState) ->
    @resetFlags();

  serialize: ->
  destroy: ->

  startDebugger: ->
    debuggerPath = path.join(__dirname, "debugger.jar");
    console.log "Starting debugger, debugger is in '#{debuggerPath}'!"
    command = "java";
    args = ["-jar", debuggerPath]
    stdout = (output) => @handleOutput(output);
    exit = (code) => @handleExit()
    @process = new BufferedProcess({command, args, stdout, exit})
    @emitter = new Emitter();
    console.log "Debugger started."

  handleExit: (code) ->
    console.log "Debugger exited: #{code}"
    @emitStop();
    @resetFlags();

  handleOutput: (output) ->
    console.log "Received data from Debugger process: #{output}"

    if(output.indexOf("!!!VIEWCHANNELREADY!!!") > -1)
      @viewChannelReady = true;

    if(output.indexOf("!!!RUNTIMECHANNELREADY!!!") > -1)
      @runtimeChannelReady = true;

    if(@viewChannelReady and @runtimeChannelReady)
      @emitReady();
      @resetFlags();

  stopDebugger: ->
    @process.kill();
    @emitStop();

  emitStop: ->
    @emitter.emit('execution-stopped')

  onStop: (callback) ->
    @emitter.on('execution-stopped', callback)

  emitReady: ->
    @emitter.emit('debugger-ready')

  onReady: (callback) ->
    @emitter.on('debugger-ready', callback)

  resetFlags: ->
    @runtimeChannelReady = false;
    @viewChannelReady = false;

module.exports =
class ExecutorProvider
  instance = null
  @getInstance: ->
    instance ?= new Excecutor
