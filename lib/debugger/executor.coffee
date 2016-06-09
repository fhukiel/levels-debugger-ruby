path                                            = require('path')
{CompositeDisposable, Emitter, BufferedProcess} = require 'atom'
class Excecutor
  constructor: (serializedState) ->
  serialize: ->
  destroy: ->

  startDebugger: ->
    debuggerPath = path.join(__dirname, "debugger.jar");
    console.log "Starting debugger, debugger is in '#{debuggerPath}'"
    command = "java";
    args = ["-jar", debuggerPath]
    stdout = (output) -> console.log "Received data from Debugger process: #{output}"
    exit = (code) => @handleExit()
    @process = new BufferedProcess({command, args, stdout, exit})
    @emitter = new Emitter();
    console.log "Debugger started."

  handleExit: (code) ->
    console.log "Debugger exited: #{code}"
    @emitStop();

  stopDebugger: ->
    @process.kill();
    @emitStop();

  emitStop: ->
    @emitter.emit('execution-stopped')

  onStop: (callback) ->
    @emitter.on('execution-stopped', callback)

module.exports =
class ExecutorProvider
  instance = null
  @getInstance: ->
    instance ?= new Excecutor
