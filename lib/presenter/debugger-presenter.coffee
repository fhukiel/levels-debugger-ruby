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
    @emitter = new Emitter
    @callStack = []
    @variableTable = []
    @positionMarker = null
    @isReplay = false
    @isExecutableInDebuggingMode = false
    @currentStatusEvent = StatusUpdateEventFactory.createStopped false
    @lastEventBeforeDisabling = @currentStatusEvent
    @lastEventBeforeReplay = null
    @autoSteppingEnabled = true
    @allControlsDisabled = false

    @subscriptions = new CompositeDisposable
    @subscriptions.add executor.onReady => @startExecutableAndConnect()
    @subscriptions.add executor.onStop => @handleStopping()
    @subscriptions.add levelsWorkspaceManager.onWorkspaceAttached (workspace) => @setLevelsWorkspace workspace
    @subscriptions.add @socketChannel.onError (error) => @handleChannelError error
    @subscriptions.add @incomingMessageDispatcher.onReady => @handleReady()
    @subscriptions.add @incomingMessageDispatcher.onTerminate => @handleStopping()
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdated (string) => @emitPositionUpdated string
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdated (string) => @callStackFromString string
    @subscriptions.add @incomingMessageDispatcher.onTableUpdated (string) => @variableTableFromString string
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape => @handleEndOfReplayTape()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled => @emitAutoSteppingEnabled()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled => @emitAutoSteppingDisabled()

  destroy: ->
    @disconnectAndCleanup()
    @subscriptions.dispose()
    @execSubscriptions?.dispose()
    return

  initDebuggerView: ->
    autoSteppingEnabled = @autoSteppingEnabled

    @emitEnableDisableAllBreakpoints()
    @emitStatusUpdate @currentStatusEvent
    @emitEnableDisableAllControls !@allControlsDisabled

    if @isExecutableInDebuggingMode
      @emitRunning()
      @emitVariableTableUpdated()
      @emitCallStackUpdated()

      if autoSteppingEnabled
        @emitAutoSteppingEnabled()
      else
        @emitAutoSteppingDisabled()

      if @isReplay
        @emitReplayStarted()

  disconnectAndCleanup: ->
    @socketChannel.disconnect()
    executor.stopDebugger()
    @isExecutableInDebuggingMode = false
    @stopExecutable()
    return

  setLevelsWorkspace: (workspace) ->
    @subscriptions.add workspace.onDidEnterWorkspace => @handleWorkspaceEntered()
    @subscriptions.add workspace.onDidExitWorkspace => @handleWorkspaceExited()
    @subscriptions.add workspace.onDidChangeActiveLevel => @handleLevelChanged()
    @subscriptions.add workspace.onDidChangeActiveLevelCodeEditor => @handleActiveLevelCodeEditorChanged()

    if !levelsWorkspaceManager.getActiveLevelCodeEditor()?
      @handleLevelChanged()

    return

  startDebugging: ->
    if !@allControlsDisabled && !@isExecutableInDebuggingMode && @saveDocument()
      executor.startDebugger()
    return

  startExecutableAndConnect: ->
    @socketChannel.connect()
    @isExecutableInDebuggingMode = true
    @debuggingEditorId = levelsWorkspaceManager.getActiveLevelCodeEditor().getId()
    @startExecutable()
    return

  stopDebugging: ->
    if !@allControlsDisabled && @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    return

  step: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepMessage()
    return

  stepOver: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepOverMessage()
    return

  toggleBreakpoint: ->
    if !@allControlsDisabled && levelsWorkspaceManager.isActiveLevelDebuggable()
      positions = levelsWorkspaceManager.getActiveTextEditorCursorPositions()
      for pos in positions
        if breakpointManager.toggle pos
          @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage PositionUtils.fromPoint pos
        else
          @socketChannel.sendMessage OutgoingMessageFactory.createRemoveBreakpointMessage PositionUtils.fromPoint pos
    return

  removeAllBreakpoints: ->
    if !@allControlsDisabled
      breakpointManager.removeAll()
      @socketChannel.sendMessage OutgoingMessageFactory.createRemoveAllBreakpointsMessage()
    return

  enableDisableAllBreakpoints: ->
    if !@allControlsDisabled
      breakpointManager.flip()
      @sendEnableDisableAllBreakpoints()
      @emitEnableDisableAllBreakpoints()
    return

  runToNextBreakpoint: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToNextBreakpointMessage()
    return

  runToEndOfMethod: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdate StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToEndOfMethodMessage()
    return

  startReplay: (element) ->
    if !@allControlsDisabled && @isExecutableInDebuggingMode
      callID = element.getAttribute 'data-call-id'
      @socketChannel.sendMessage OutgoingMessageFactory.createStartReplayMessage callID

      if !@isReplay && @currentStatusEvent.getStatus() != StatusUpdateEventFactory.END_OF_TAPE_STATUS
        @lastEventBeforeReplay = @currentStatusEvent
      @isReplay = true
      @emitReplayStarted()

    return

  stopReplay: ->
    if !@allControlsDisabled && @isExecutableInDebuggingMode && @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStopReplayMessage()
      @isReplay = false
      @emitReplayStopped()
      @emitStatusUpdate @lastEventBeforeReplay
    return

  areSteppingCommandsEnabled: ->
    return !@allControlsDisabled && @isExecutableInDebuggingMode && !@autoSteppingEnabled

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

  startExecutable: ->
    levelsWorkspaceManager.getActiveLevelCodeEditor().startExecution {runExecArgs: ['-d']}
    return

  stopExecutable: ->
    levelsWorkspaceManager.getActiveLevelCodeEditor().stopExecution()
    return

  sendEnableDisableAllBreakpoints: ->
    if breakpointManager.getAreBreakpointsEnabled()
      @socketChannel.sendMessage OutgoingMessageFactory.createEnableAllBreakpointsMessage()
    else
      @socketChannel.sendMessage OutgoingMessageFactory.createDisableAllBreakpointsMessage()
    return

  flipAndSortVariableTable: ->
    if !@allControlsDisabled && @isExecutableInDebuggingMode
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
    @positionMarker = levelsWorkspaceManager.addPositionMarker PositionUtils.toPoint currentPosition

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
    if event.isBlockingStatus()
      @emitAutoSteppingEnabled()
    else
      @emitAutoSteppingDisabled()
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
    @allControlsDisabled = !enabled
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
    @disconnectAndCleanup()
    return

  handleWorkspaceEntered: ->
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    if @isExecutableInDebuggingMode
      enabled = @debuggingEditorId == editor.getId()
      @emitEnableDisableAllControls enabled
    else
      @handleLevelChanged()
      @execSubscriptions = new CompositeDisposable
      @execSubscriptions.add editor.onDidStartExecution => @handleExecutableStarted()
      @execSubscriptions.add editor.onDidStopExecution => @handleExecutableStopped()
      if editor.isExecuting()
        @emitEnableDisableAllControls false
    return

  handleWorkspaceExited: ->
    if @isExecutableInDebuggingMode
      @emitEnableDisableAllControls false
    else
      @handleLevelChanged()
      @execSubscriptions?.dispose()
    return

  handleActiveLevelCodeEditorChanged: ->
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    if @isExecutableInDebuggingMode
      enabled = @debuggingEditorId == editor.getId()
      @emitEnableDisableAllControls enabled
    else
      @execSubscriptions?.dispose()
      @execSubscriptions = new CompositeDisposable
      @execSubscriptions.add editor.onDidStartExecution => @handleExecutableStarted()
      @execSubscriptions.add editor.onDidStopExecution => @handleExecutableStopped()
      if editor.isExecuting()
        @emitEnableDisableAllControls false
    return

  handleExecutableStarted: ->
    if !@isExecutableInDebuggingMode
      @emitEnableDisableAllControls false
    return

  handleExecutableStopped: ->
    if @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    return

  reset: ->
    @isReplay = false
    @autoSteppingEnabled = true
    @variableTable = []
    @callStack = []
    @isExecutableInDebuggingMode = false
    variableTableManager.resetSortMode()

  handleReady: ->
    @emitRunning()
    @emitAutoSteppingDisabled()
    for bp in breakpointManager.getBreakpoints()
      @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage bp.getPosition()
    @sendEnableDisableAllBreakpoints()
    return

  handleStopping: ->
    @reset()
    @emitStopped()
    @emitAutoSteppingEnabled()
    if @positionMarker?
      @positionMarker.destroy()
    breakpointManager.restoreHiddenBreakpoint()
    @emitStatusUpdate StatusUpdateEventFactory.createStopped @isReplay
    return

  handleEndOfReplayTape: ->
    @emitStatusUpdate StatusUpdateEventFactory.createEndOfTape false
    return

  handleLevelChanged: ->
    if @isExecutableInDebuggingMode
      @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    else
      if levelsWorkspaceManager.isActiveLevelDebuggable()
        @emitStatusUpdate @lastEventBeforeDisabling
        @emitEnableDisableAllControls true
      else
        if @currentStatusEvent.getStatus() != StatusUpdateEventFactory.DISABLED_STATUS
          @lastEventBeforeDisabling = @currentStatusEvent
        @emitStatusUpdate StatusUpdateEventFactory.createDisabled @isReplay
        @emitEnableDisableAllControls false
    return