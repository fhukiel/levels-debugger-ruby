{CompositeDisposable, Emitter} = require 'atom'
breakpointManager              = require('../common/breakpoint-manager').getInstance()
CallStackFactory               = require '../common/call-stack-factory'
levelsWorkspaceManager         = require('../common/levels-workspace-manager').getInstance()
Position                       = require '../common/position'
PositionUtils                  = require '../common/position-utils'
StatusFactory                  = require '../common/status-update-event-factory'
variableTableManager           = require('../common/variable-table-manager').getInstance()
executor                       = require('../debugger/executor').getInstance()
MessageUtils                   = require '../messaging/message-utils'
OutgoingMessageFactory         = require '../messaging/outgoing-message-factory'

module.exports =
class DebuggerPresenter
  constructor: (@incomingMessageDispatcher, @socketChannel) ->
    @callStack = []
    @variableTable = []
    @emitter = new Emitter
    @positionMarker = null
    @isReplay = false
    @isExecutableInDebuggingMode = false
    @currentStatusEvent = StatusFactory.createStopped false
    @lastEventBeforeDisabling = @currentStatusEvent
    @lastEventBeforeReplay = null
    @setupSubscriptions()

  setupSubscriptions: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add @socketChannel.onError (error) => @handleChannelError error
    @subscriptions.add @incomingMessageDispatcher.onReady => @handleReady()
    @subscriptions.add @incomingMessageDispatcher.onTerminate => @handleStopping()
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdate (string) => @emitPositionUpdate string, @isReplay
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdate (string) => @callStackFromString string
    @subscriptions.add @incomingMessageDispatcher.onTableUpdate (string) => @variableTableFromString string
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape => @handleEndOfReplayTape()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled => @emitAutoSteppingEnabled()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled => @emitAutoSteppingDisabled()
    return

  destroy: ->
    @disconnectAndCleanup()
    @subscriptions.dispose()
    return

  setLevelsWorkspace: (workspace) ->
    levelsWorkspaceManager.attachWorkspace workspace
    workspace.onDidEnterWorkspace => @handleWorkspaceEntered()
    workspace.onDidEnterWorkspace => @handleLevelChanged()

    if levelsWorkspaceManager.getActiveLevelCodeEditor()?
      @handleWorkspaceEntered()
    @handleLevelChanged()

  startDebugging: ->
    if @saveDocument() && !@isExecutableInDebuggingMode
      executor.startDebugger()
      executor.onReady => @startExecutableAndConnect()
      executor.onStop => @handleStopping()
    return

  startExecutableAndConnect: ->
    @socketChannel.connect()
    @isExecutableInDebuggingMode = true
    @runExecutable()
    return

  stopDebugging: ->
    if @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    return

  disconnectAndCleanup: ->
    @variableTable = []
    @callStack = []
    @socketChannel.disconnect()
    executor.stopDebugger()
    @isExecutableInDebuggingMode = false
    @stopExecutable()
    variableTableManager.resetSortMode()
    return

  step: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepMessage()
    return

  stepOver: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepOverMessage()
    return

  toggleBreakpoint: ->
    currentPosition = levelsWorkspaceManager.getActiveTextEditorPosition()
    if breakpointManager.toggle currentPosition
      @sendBreakpointAdded PositionUtils.fromPoint currentPosition
    else
      @sendBreakpointRemoved PositionUtils.fromPoint currentPosition
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
      @emitStatusUpdate StatusFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToNextBreakpointMessage()
    return

  runToEndOfMethod: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToEndOfMethodMessage()
    return

  startReplay: (element) ->
    id = element.getAttribute 'callID'
    @socketChannel.sendMessage OutgoingMessageFactory.createStartReplayMessage "#{id}"

    if !@isReplay && @currentStatusEvent.getStatus() != StatusFactory.getEndOfTapeStatus()
      @lastEventBeforeReplay = @currentStatusEvent
    @isReplay = true
    return

  stopReplay: ->
    @socketChannel.sendMessage OutgoingMessageFactory.createStopReplayMessage()
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
    @callStack = CallStackFactory.fromString string
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
    @socketChannel.sendMessage OutgoingMessageFactory.createRemoveBreakpointMessage breakpointPosition
    return

  sendBreakpointAdded: (breakpointPosition) ->
    @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage breakpointPosition
    return

  sendRemoveAllBreakpoints: ->
    @socketChannel.sendMessage OutgoingMessageFactory.createRemoveAllBreakpointsMessage()
    return

  sendEnableDisableAllBreakpoints: ->
    if breakpointManager.getAreBreakpointsEnabled()
      @socketChannel.sendMessage OutgoingMessageFactory.createEnableAllBreakpointsMessage()
    else
      @socketChannel.sendMessage OutgoingMessageFactory.createDisableAllBreakpointsMessage()
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
    splitted = positionString.split MessageUtils.getDelimiter()
    currentPosition = new Position +splitted[1], +splitted[2]

    breakpointManager.restoreHiddenBreakpoint()
    breakpointManager.hideBreakpoint currentPosition

    if @positionMarker?
      @positionMarker.destroy()
    @positionMarker = levelsWorkspaceManager.addPositionMarker currentPosition

    @emitter.emit 'position-updated', currentPosition
    @emitStatusUpdate StatusFactory.createWaiting isReplay

    atom.workspace.getActiveTextEditor().scrollToBufferPosition PositionUtils.toPoint currentPosition
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

  handleChannelError: (error) ->
    console.log "A communication channel error occurred: #{error}"
    stopDebugging()
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
    @emitStatusUpdate StatusFactory.createStopped @isReplay
    return

  handleEndOfReplayTape: ->
    @emitStatusUpdate StatusFactory.createEndOfTape false
    return

  handleLevelChanged: ->
    if !@isExecutableInDebuggingMode
      if levelsWorkspaceManager.isActiveLevelDebuggable()
        @emitStatusUpdate @lastEventBeforeDisabling
        @emitEnableDisableAllControls true
      else
        if @currentStatusEvent.getStatus() != StatusFactory.getDisabledStatus()
          @lastEventBeforeDisabling = @currentStatusEvent
        @emitStatusUpdate StatusFactory.createDisabled @isReplay
        @emitEnableDisableAllControls false
    return