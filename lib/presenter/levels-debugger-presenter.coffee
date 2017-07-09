{CompositeDisposable, Emitter} = require 'atom'
breakpointManager              = require('../common/breakpoint-manager').getInstance()
callStackFactory               = require('../common/call-stack-factory').getInstance()
levelsWorkspaceManager         = require('../common/levels-workspace-manager').getInstance()
Position                       = require '../common/position'
positionUtils                  = require('../common/position-utils').getInstance()
statusFactory                  = require('../common/status-update-event-factory').getInstance()
variableTableManager           = require('../common/variable-table-manager').getInstance()
executor                       = require('../debugger/executor').getInstance()
messageUtils                   = require('../messaging/message-utils').getInstance()
outgoingMessageFactory         = require('../messaging/outgoing-message-factory').getInstance()

module.exports =
class LevelsDebuggerPresenter
  constructor: (@incomingMessageDispatcher, @communicationChannel) ->
    @callStack = new Array
    @variableTable = new Array
    @emitter = new Emitter
    @positionMarker = null
    @isReplay = false
    @isExecutableInDebuggingMode = false
    @currentStatusEvent = statusFactory.createStopped false
    @lastEventBeforeDisabling = @currentStatusEvent
    @lastEventBeforeReplay = null
    @setupSubscriptions()

  setupSubscriptions: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @incomingMessageDispatcher.onReady(=> @handleReady())
    @subscriptions.add @incomingMessageDispatcher.onTerminate(=> @handleStopping())
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdate((string) => @emitPositionUpdate string, @isReplay)
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdate((string) => @callStackFromString string)
    @subscriptions.add @incomingMessageDispatcher.onTableUpdate((string) => @variableTableFromString string)
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape(=> @handleEndOfReplayTape())
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled(=> @emitAutoSteppingEnabled())
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled(=> @emitAutoSteppingDisabled())
    return

  destroy: ->
    @disconnectAndCleanup()
    @subscriptions.dispose()
    return

  setLevelsWorkspace: (workspace) ->
    levelsWorkspaceManager.attachWorkspace workspace
    workspace.onDidEnterWorkspace => @handleWorkspaceEntered()
    workspace.onDidEnterWorkspace => @handleLevelChanged()

  startDebugging: ->
    if @saveDocument() && !@isExecutableInDebuggingMode
      executor.startDebugger()
      executor.onReady => @startExecutableAndConnect()
      executor.onStop => @handleStopping()
    return

  startExecutableAndConnect: ->
    @communicationChannel.connect()
    @isExecutableInDebuggingMode = true
    @runExecutable()
    return

  stopDebugging: ->
    if @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    return

  disconnectAndCleanup: ->
    @variableTable = new Array
    @callStack = new Array
    @communicationChannel.disconnect()
    executor.stopDebugger()
    @isExecutableInDebuggingMode = false
    @stopExecutable()
    variableTableManager.resetSortMode()
    return

  step: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate statusFactory.createRunning(@isReplay)
      @communicationChannel.sendMessage outgoingMessageFactory.createStepMessage()
    return

  stepOver: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate statusFactory.createRunning(@isReplay)
      @communicationChannel.sendMessage outgoingMessageFactory.createStepOverMessage()
    return

  toggleBreakpoint: ->
    currentPosition = levelsWorkspaceManager.getActiveTextEditorPosition()
    if breakpointManager.toggle currentPosition
      @sendBreakpointAdded positionUtils.fromPoint(currentPosition)
    else
      @sendBreakpointRemoved positionUtils.fromPoint(currentPosition)
    return

  removeAllBreakpoints: ->
    breakpointManager.removeAll()
    @sendRemoveAllBreakpoints()
    return

  enableDisableAllBreakpoints: ->
    breakpointManager.flip()
    @sendEnableDisableAllBreakpoints()
    @emitEnableDisableAllBreakpoints breakpointManager.getAreBreakpointsEnabled()
    return

  runToNextBreakpoint: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate statusFactory.createRunning(@isReplay)
      @communicationChannel.sendMessage outgoingMessageFactory.createRunToNextBreakpointMessage()
    return

  runToEndOfMethod: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate statusFactory.createRunning(@isReplay)
      @communicationChannel.sendMessage outgoingMessageFactory.createRunToEndOfMethodMessage()
    return

  startReplay: (element) ->
    id = element.getAttribute 'id'
    @communicationChannel.sendMessage outgoingMessageFactory.createStartReplayMessage("#{id}")

    if !@isReplay && @currentStatusEvent.getStatus() != statusFactory.getEndOfTapeStatus()
      @lastEventBeforeReplay = @currentStatusEvent
    @isReplay = true
    return

  stopReplay: ->
    @communicationChannel.sendMessage outgoingMessageFactory.createStopReplayMessage()
    @isReplay = false
    @emitStatusUpdate @lastEventBeforeReplay
    return

  popFromCallStack: ->
    @callStack.pop()
    @emitCallStackUpdate()
    return

  saveDocument: ->
    textEditor = levelsWorkspaceManager.getActiveTextEditor()
    saveHere = textEditor.getPath() ? atom.showSaveDialogSync()

    if saveHere?
      textEditor.saveAs saveHere
      levelsWorkspaceManager.getActiveTerminal().show()
      levelsWorkspaceManager.getActiveTerminal().focus()
      return true
    return false

  variableTableFromString: (string) ->
    @variableTable = variableTableManager.fromString string, @variableTable
    @emitVariableTableUpdate()
    return

  getVariableTable: ->
    return @variableTable

  callStackFromString: (string) ->
    @callStack = callStackFactory.fromString string
    @emitCallStackUpdate()
    return

  getCallStack: ->
    return @callStack

  runExecutable: ->
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    editor.startExecution {runExecArgs: ['-d']}
    return

  stopExecutable: ->
    workspaceView = atom.views.getView atom.workspace
    atom.commands.dispatch workspaceView, 'levels:stop-execution'
    return

  sendBreakpointRemoved: (breakpointPosition) ->
    @communicationChannel.sendMessage outgoingMessageFactory.createRemoveBreakpointMessage(breakpointPosition)
    return

  sendBreakpointAdded: (breakpointPosition) ->
    @communicationChannel.sendMessage outgoingMessageFactory.createAddBreakpointMessage(breakpointPosition)
    return

  sendRemoveAllBreakpoints: ->
    @communicationChannel.sendMessage outgoingMessageFactory.createRemoveAllBreakpointsMessage()
    return

  sendEnableDisableAllBreakpoints: ->
    if breakpointManager.getAreBreakpointsEnabled()
      @communicationChannel.sendMessage outgoingMessageFactory.createEnableAllBreakpointsMessage()
    else
      @communicationChannel.sendMessage outgoingMessageFactory.createDisableAllBreakpointsMessage()
    return

  flipAndSortVariableTable: ->
    variableTableManager.flipSortMode()
    variableTableManager.sort @variableTable
    @emitVariableTableUpdate()
    return

  onRunning: (callback) ->
    @emitter.on 'running', callback

  onStopped: (callback) ->
    @emitter.on 'stopped', callback

  onPositionUpdated: (callback) ->
    @emitter.on 'position-updated', callback

  onCallStackUpdated: (callback) ->
    @emitter.on 'call-stack-updated', callback

  onVariableTableUpdated: (callback) ->
    @emitter.on 'variable-table-updated', callback

  onStatusUpdated: (callback) ->
    @emitter.on 'status-updated', callback

  onAutoSteppingEnabled: (callback) ->
    @emitter.on 'auto-stepping-enabled', callback

  onAutoSteppingDisabled: (callback) ->
    @emitter.on 'auto-stepping-disabled', callback

  onEnableDisableAllBreakpoints: (callback) ->
    @emitter.on 'enable-disable-all-breakpoints', callback

  onEnableDisableAllControls: (callback) ->
    @emitter.on 'enable-disable-all-commands', callback

  emitEnableDisableAllBreakpoints: (enabled) ->
    @emitter.emit 'enable-disable-all-breakpoints', enabled
    return

  emitDebuggingStarted: ->
    @emitter.emit 'running'
    return

  emitDebuggingStopped: ->
    @emitter.emit 'stopped'
    return

  emitPositionUpdate: (positionString, isReplay) ->
    splitted = positionString.split messageUtils.getDelimiter()
    currentPosition = new Position +splitted[1], +splitted[2]

    breakpointManager.restoreHiddenBreakpoint()
    breakpointManager.hideBreakpoint currentPosition

    if @positionMarker?
      @positionMarker.destroy()
    @positionMarker = levelsWorkspaceManager.addPositionMarker currentPosition

    @emitter.emit 'position-updated', currentPosition
    @emitStatusUpdate statusFactory.createWaiting(isReplay)

    atom.workspace.getActiveTextEditor().scrollToBufferPosition positionUtils.toPoint(currentPosition)
    return

  emitCallStackUpdate: ->
    @emitter.emit 'call-stack-updated'
    return

  emitVariableTableUpdate: ->
    @emitter.emit 'variable-table-updated'
    return

  emitAutoSteppingEnabled: ->
    @emitter.emit 'auto-stepping-enabled'
    return

  emitAutoSteppingDisabled: ->
    @emitter.emit 'auto-stepping-disabled'
    return

  emitStatusUpdate: (event) ->
    @emitter.emit 'status-updated', event
    @currentStatusEvent = event
    return

  emitEnableDisableAllControls: (enabled) ->
    @emitter.emit 'enable-disable-all-commands', enabled
    return

  handleWorkspaceEntered: ->
    levelsWorkspaceManager.getWorkspace().getActiveLevelCodeEditor().onDidStartExecution => @handleExecutableStarted()
    levelsWorkspaceManager.getWorkspace().getActiveLevelCodeEditor().onDidStopExecution => @handleExecutableStopped()
    levelsWorkspaceManager.getWorkspace().onDidChangeActiveLevel => @handleLevelChanged()
    return

  handleExecutableStarted: ->
    if @isExecutableInDebuggingMode
      @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    else
      @emitEnableDisableAllControls false
    return

  handleExecutableStopped: ->
    if @isExecutableInDebuggingMode
      @disconnectAndCleanup()
      @isExecutableInDebuggingMode = false
    @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    return

  handleReady: ->
    @emitDebuggingStarted()
    for bp in breakpointManager.getBreakpoints()
      @sendBreakpointAdded bp.getPosition()
    @sendEnableDisableAllBreakpoints()
    return

  handleStopping: ->
    @isReplay = false
    @emitDebuggingStopped()
    if @positionMarker?
      @positionMarker.destroy()
    breakpointManager.restoreHiddenBreakpoint()
    @emitStatusUpdate statusFactory.createStopped(@isReplay)
    return

  handleEndOfReplayTape: ->
    @emitStatusUpdate statusFactory.createEndOfTape(false)
    return

  handleLevelChanged: ->
    if !@isExecutableInDebuggingMode
      if levelsWorkspaceManager.isActiveLevelDebuggable()
        @emitStatusUpdate @lastEventBeforeDisabling
        @emitEnableDisableAllControls true
      else
        if @currentStatusEvent.getStatus() != statusFactory.getDisabledStatus()
          @lastEventBeforeDisabling = @currentStatusEvent
        @emitStatusUpdate statusFactory.createDisabled(@isReplay)
        @emitEnableDisableAllControls false
    return