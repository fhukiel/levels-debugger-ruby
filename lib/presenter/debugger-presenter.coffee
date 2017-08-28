{CompositeDisposable, Emitter} = require 'atom'
breakpointManager              = require('../common/breakpoint-manager').getInstance()
CallStackFactory               = require '../common/call-stack-factory'
levelsWorkspaceManager         = require('../common/levels-workspace-manager').getInstance()
Position                       = require '../common/position'
PositionUtils                  = require '../common/position-utils'
StatusUpdateEventFactory       = require '../common/status-update-event-factory'
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
    @currentStatusEvent = StatusUpdateEventFactory.createStopped false
    @lastEventBeforeDisabling = @currentStatusEvent
    @lastEventBeforeReplay = null
    @autoSteppingEnabled = false
    @allControlsEnabled = true

    @subscriptions = new CompositeDisposable
    @subscriptions.add @socketChannel.onError (error) => @handleChannelError error
    @subscriptions.add @incomingMessageDispatcher.onReady => @handleReady()
    @subscriptions.add @incomingMessageDispatcher.onTerminate => @handleStopping()
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdated (string) => @emitPositionUpdated string
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdated (string) => @callStackFromString string
    @subscriptions.add @incomingMessageDispatcher.onTableUpdated (string) => @variableTableFromString string
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape => @handleEndOfReplayTape()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled => @emitAutoSteppingEnabled()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled => @emitAutoSteppingDisabled()
    @subscriptions.add executor.onReady => @startExecutableAndConnect()
    @subscriptions.add executor.onStop => @handleStopping()

  destroy: ->
    @disconnectAndCleanup()
    @subscriptions.dispose()
    return

  initDebuggerView: ->
    if @isExecutableInDebuggingMode
      @emitRunning()
      @emitVariableTableUpdated()
      @emitCallStackUpdated()

      if @autoSteppingEnabled
        @emitAutoSteppingEnabled()
      else
        @emitAutoSteppingDisabled()

      if @isReplay
        @emitReplayStarted()

    @emitEnableDisableAllBreakpoints()
    @emitStatusUpdate @currentStatusEvent
    @emitEnableDisableAllControls @allControlsEnabled

  disconnectAndCleanup: ->
    @variableTable = []
    @callStack = []
    @socketChannel.disconnect()
    executor.stopDebugger()
    @isExecutableInDebuggingMode = false
    @stopExecutable()
    variableTableManager.resetSortMode()
    return

  setLevelsWorkspace: (workspace) ->
    levelsWorkspaceManager.attachWorkspace workspace
    workspace.onDidEnterWorkspace => @handleWorkspaceEntered()
    workspace.onDidExitWorkspace => @handleWorkspaceExited()
    return

  startDebugging: ->
    if @saveDocument() && !@isExecutableInDebuggingMode
      executor.startDebugger()
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

  step: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepMessage()
    return

  stepOver: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepOverMessage()
    return

  toggleBreakpoint: ->
    if levelsWorkspaceManager.isActiveLevelDebuggable()
      currentPosition = levelsWorkspaceManager.getActiveTextEditorPosition()
      if breakpointManager.toggle currentPosition
        @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage PositionUtils.fromPoint currentPosition
      else
        @socketChannel.sendMessage OutgoingMessageFactory.createRemoveBreakpointMessage PositionUtils.fromPoint currentPosition
    return

  removeAllBreakpoints: ->
    breakpointManager.removeAll()
    @socketChannel.sendMessage OutgoingMessageFactory.createRemoveAllBreakpointsMessage()
    return

  enableDisableAllBreakpoints: ->
    breakpointManager.flip()
    @sendEnableDisableAllBreakpoints()
    @emitEnableDisableAllBreakpoints()
    return

  runToNextBreakpoint: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToNextBreakpointMessage()
    return

  runToEndOfMethod: ->
    if @isExecutableInDebuggingMode
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToEndOfMethodMessage()
    return

  startReplay: (element) ->
    callID = element.getAttribute 'data-call-id'
    @socketChannel.sendMessage OutgoingMessageFactory.createStartReplayMessage callID

    if !@isReplay && @currentStatusEvent.getStatus() != StatusUpdateEventFactory.END_OF_TAPE_STATUS
      @lastEventBeforeReplay = @currentStatusEvent
    @isReplay = true
    @emitReplayStarted()

    return

  stopReplay: ->
    @socketChannel.sendMessage OutgoingMessageFactory.createStopReplayMessage()
    @isReplay = false
    @emitReplayStopped()
    @emitStatusUpdate @lastEventBeforeReplay
    return

  saveDocument: ->
    textEditor = levelsWorkspaceManager.getActiveTextEditor()

    if textEditor?
      saveHere = textEditor.getPath() ? atom.showSaveDialogSync()

      if saveHere?
        textEditor.saveAs saveHere
        terminal = levelsWorkspaceManager.getActiveTerminal()
        terminal.show()
        terminal.focus()
        return true

    return false

  variableTableFromString: (string) ->
    @variableTable = variableTableManager.fromString string, @variableTable
    @emitVariableTableUpdated()
    return

  getVariableTable: ->
    return @variableTable

  callStackFromString: (string) ->
    @callStack = CallStackFactory.fromString string
    @emitCallStackUpdated()
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

  sendEnableDisableAllBreakpoints: ->
    if breakpointManager.getAreBreakpointsEnabled()
      @socketChannel.sendMessage OutgoingMessageFactory.createEnableAllBreakpointsMessage()
    else
      @socketChannel.sendMessage OutgoingMessageFactory.createDisableAllBreakpointsMessage()
    return

  flipAndSortVariableTable: ->
    variableTableManager.flipSortMode()
    variableTableManager.sort @variableTable
    @emitVariableTableUpdated()
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
    @emitter.on 'enable-disable-all-controls', callback

  onReplayStarted: (callback) ->
    @emitter.on 'replay-started', callback

  onReplayStopped: (callback) ->
    @emitter.on 'replay-stopped', callback

  emitRunning: ->
    @emitter.emit 'running'
    return

  emitStopped: ->
    @emitter.emit 'stopped'
    return

  emitPositionUpdated: (string) ->
    splitted = string.split MessageUtils.DELIMITER
    currentPosition = new Position +splitted[0], +splitted[1]

    breakpointManager.restoreHiddenBreakpoint()
    breakpointManager.hideBreakpoint currentPosition

    if @positionMarker?
      @positionMarker.destroy()
    @positionMarker = levelsWorkspaceManager.addPositionMarker currentPosition

    @emitter.emit 'position-updated', currentPosition
    @emitStatusUpdate StatusUpdateEventFactory.createWaiting @isReplay

    levelsWorkspaceManager.getActiveTextEditor()?.scrollToBufferPosition PositionUtils.toPoint currentPosition
    return

  emitCallStackUpdated: ->
    @emitter.emit 'call-stack-updated'
    return

  emitVariableTableUpdated: ->
    @emitter.emit 'variable-table-updated'
    return

  emitStatusUpdate: (event) ->
    @emitter.emit 'status-updated', event
    @currentStatusEvent = event
    return

  emitAutoSteppingEnabled: ->
    @autoSteppingEnabled = true
    @emitter.emit 'auto-stepping-enabled'
    return

  emitAutoSteppingDisabled: ->
    @autoSteppingEnabled = false
    @emitter.emit 'auto-stepping-disabled'
    return

  emitEnableDisableAllBreakpoints: ->
    @emitter.emit 'enable-disable-all-breakpoints', breakpointManager.getAreBreakpointsEnabled()
    return

  emitEnableDisableAllControls: (enabled) ->
    @allControlsEnabled = enabled
    @emitter.emit 'enable-disable-all-controls', enabled
    return

  emitReplayStarted: ->
    @emitter.emit 'replay-started'
    return

  emitReplayStopped: ->
    @emitter.emit 'replay-stopped'
    return

  handleChannelError: (error) ->
    console.log "A communication channel error occurred: #{error}"
    stopDebugging()
    return

  handleWorkspaceEntered: ->
    @handleLevelChanged()
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    editor?.onDidStartExecution => @handleExecutableStarted()
    editor?.onDidStopExecution => @handleExecutableStopped()
    levelsWorkspaceManager.getWorkspace().onDidChangeActiveLevel => @handleLevelChanged()
    return

  handleWorkspaceExited: ->
    @handleLevelChanged()
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
    @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    return

  handleReady: ->
    @emitRunning()
    for bp in breakpointManager.getBreakpoints()
      @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage bp.getPosition()
    @sendEnableDisableAllBreakpoints()
    return

  handleStopping: ->
    @isReplay = false
    @autoSteppingEnabled = false
    @allControlsEnabled = levelsWorkspaceManager.isActiveLevelDebuggable()
    @emitStopped()
    if @positionMarker?
      @positionMarker.destroy()
    breakpointManager.restoreHiddenBreakpoint()
    @emitStatusUpdate StatusUpdateEventFactory.createStopped @isReplay
    return

  handleEndOfReplayTape: ->
    @emitStatusUpdate StatusUpdateEventFactory.createEndOfTape false
    return

  handleLevelChanged: ->
    if !@isExecutableInDebuggingMode
      if levelsWorkspaceManager.isActiveLevelDebuggable()
        @emitStatusUpdate @lastEventBeforeDisabling
        @emitEnableDisableAllControls true
      else
        if @currentStatusEvent.getStatus() != StatusUpdateEventFactory.DISABLED_STATUS
          @lastEventBeforeDisabling = @currentStatusEvent
        @emitStatusUpdate StatusUpdateEventFactory.createDisabled @isReplay
        @emitEnableDisableAllControls false
    return