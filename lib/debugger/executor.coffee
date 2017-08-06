{BufferedProcess, Emitter} = require 'atom'
path                       = require 'path'

class Executor
  constructor: ->
    @resetFlags()

  startDebugger: ->
    debuggerPath = path.join __dirname, 'debugger.jar'
    command = 'java'
    args = ['-jar', debuggerPath]
    stdout = (output) => @handleOutput output
    exit = (code) => @handleExit code
    @process = new BufferedProcess {command, args, stdout, exit}
    @emitter = new Emitter
    return

  stopDebugger: ->
    if @process?
      @process.kill()
      @handleExit undefined
    return

  handleExit: (code) ->
    @emitStop()
    @emitter.dispose()
    @resetFlags()
    return

  handleOutput: (output) ->
    if output.includes '!!!VIEWCHANNELREADY!!!'
      @viewChannelReady = true

    if output.includes '!!!RUNTIMECHANNELREADY!!!'
      @runtimeChannelReady = true

    if @viewChannelReady && @runtimeChannelReady
      @emitReady()
      @resetFlags()

    return

  emitStop: ->
    @emitter.emit 'execution-stopped'
    return

  onStop: (callback) ->
    @emitter.on 'execution-stopped', callback

  emitReady: ->
    @emitter.emit 'debugger-ready'
    return

  onReady: (callback) ->
    @emitter.on 'debugger-ready', callback

  resetFlags: ->
    @runtimeChannelReady = false
    @viewChannelReady = false
    return

module.exports =
class ExecutorProvider
  instance = null

  @getInstance: ->
    instance ?= new Executor