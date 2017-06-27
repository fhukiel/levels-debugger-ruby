{BufferedProcess, Emitter} = require('atom')
path                       = require('path')

class Executor
  constructor: ->
    @resetFlags()

  startDebugger: ->
    debuggerPath = path.join(__dirname, "debugger.jar")
    command = "java"
    args = ["-jar", debuggerPath]
    stdout = (output) => @handleOutput(output)
    exit = (code) => @handleExit(code)
    @process = new BufferedProcess({command, args, stdout, exit})
    @emitter = new Emitter()

  handleExit: (code) ->
    @emitStop()
    @emitter.dispose()
    @resetFlags()

  handleOutput: (output) ->
    if (output.indexOf('!!!VIEWCHANNELREADY!!!') > -1)
      @viewChannelReady = true

    if (output.indexOf('!!!RUNTIMECHANNELREADY!!!') > -1)
      @runtimeChannelReady = true

    if (@viewChannelReady && @runtimeChannelReady)
      @emitReady()
      @resetFlags()

  stopDebugger: ->
    @process.kill()
    @emitStop()
    @emitter.dispose()

  emitStop: ->
    @emitter.emit('execution-stopped')

  onStop: (callback) ->
    @emitter.on('execution-stopped', callback)

  emitReady: ->
    @emitter.emit('debugger-ready')

  onReady: (callback) ->
    @emitter.on('debugger-ready', callback)

  resetFlags: ->
    @runtimeChannelReady = false
    @viewChannelReady = false

module.exports =
class ExecutorProvider
  instance = null

  @getInstance: ->
    instance ?= new Executor()