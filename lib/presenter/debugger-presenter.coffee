{CompositeDisposable, Emitter} = require 'atom'
breakpointManager              = require('../common/breakpoint-manager').getInstance()
CallStackFactory               = require '../common/call-stack-factory'
levelsWorkspaceManager         = require('../common/levels-workspace-manager').getInstance()
Position                       = require '../common/position'
PositionUtils                  = require '../common/position-utils'
StatusUpdateEventFactory       = require '../common/status-update-event-factory'
variableTableManager           = require('../common/variable-table-manager').getInstance()
executor                       = require '../debugger/executor'
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
    @isAutoSteppingEnabled = true
    @areAllControlsDisabled = false

    @currentStatusEvent = StatusUpdateEventFactory.createStopped false
    @lastEventBeforeDisabling = @currentStatusEvent
    @lastEventBeforeReplay = null

    @execSubscriptions = null

    @subscriptions = new CompositeDisposable
    @subscriptions.add executor.onReady => @startExecutableAndConnect()
    @subscriptions.add executor.onStop => @handleStop()
    @subscriptions.add levelsWorkspaceManager.onWorkspaceAttached (workspace) => @setLevelsWorkspace workspace
    @subscriptions.add @socketChannel.onError (error) => @handleChannelError error
    @subscriptions.add @incomingMessageDispatcher.onReady => @handleReady()
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdated (string) => @emitPositionUpdated string
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdated (string) => @callStackFromString string
    @subscriptions.add @incomingMessageDispatcher.onVariableTableUpdated (string) => @variableTableFromString string
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape => @handleEndOfReplayTape()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled => @emitAutoSteppingEnabled()
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled => @emitAutoSteppingDisabled()

  destroy: ->
    @disconnectAndCleanup()
    @subscriptions.dispose()
    @execSubscriptions?.dispose()
    return

  initDebuggerView: ->
    isAutoSteppingEnabled = @isAutoSteppingEnabled

    @emitEnableDisableAllBreakpoints()
    @emitStatusUpdated @currentStatusEvent
    @emitEnableDisableAllControls !@areAllControlsDisabled

    if @isExecutableInDebuggingMode
      @emitRunning()
      @emitVariableTableUpdated()
      @emitCallStackUpdated()

      if isAutoSteppingEnabled
        @emitAutoSteppingEnabled()
      else
        @emitAutoSteppingDisabled()

      if @isReplay
        @emitReplayStarted()

    return

  disconnectAndCleanup: ->
    @socketChannel.disconnect()
    @isExecutableInDebuggingMode = false
    executor.stopDebugger()
    @stopExecutable()
    return

  setLevelsWorkspace: (workspace) ->
    @subscriptions.add workspace.onDidEnterWorkspace => @handleWorkspaceEntered()
    @subscriptions.add workspace.onDidExitWorkspace => @handleWorkspaceExited()
    @subscriptions.add workspace.onDidChangeActiveLevel => @handleLevelChanged()
    @subscriptions.add workspace.onDidChangeActiveLevelCodeEditor => @handleLevelCodeEditorChanged()

    if !levelsWorkspaceManager.isActive()
      @handleLevelChanged()

    return

  startDebugging: ->
    if !@areAllControlsDisabled && !@isExecutableInDebuggingMode && @saveDocument()
      executor.startDebugger()
    return

  startExecutableAndConnect: ->
    @socketChannel.connect()
    @isExecutableInDebuggingMode = true
    @debuggingEditorId = levelsWorkspaceManager.getActiveLevelCodeEditor().getId()
    @startExecutable()
    return

  stopDebugging: ->
    if !@areAllControlsDisabled && @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    return

  step: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdated StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepMessage()
    return

  stepOver: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdated StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStepOverMessage()
    return

  toggleBreakpoint: ->
    if !@areAllControlsDisabled
      points = levelsWorkspaceManager.getActiveTextEditorCursorPositions()
      for point in points
        if breakpointManager.toggle point
          @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage PositionUtils.fromPoint point
        else
          @socketChannel.sendMessage OutgoingMessageFactory.createRemoveBreakpointMessage PositionUtils.fromPoint point
    return

  removeAllBreakpoints: ->
    if !@areAllControlsDisabled
      breakpointManager.removeAll()
      @socketChannel.sendMessage OutgoingMessageFactory.createRemoveAllBreakpointsMessage()
    return

  enableDisableAllBreakpoints: ->
    if !@areAllControlsDisabled
      breakpointManager.flip()
      @sendEnableDisableAllBreakpoints()
      @emitEnableDisableAllBreakpoints()
    return

  runToNextBreakpoint: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdated StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToNextBreakpointMessage()
    return

  runToEndOfMethod: ->
    if @areSteppingCommandsEnabled()
      @emitStatusUpdated StatusUpdateEventFactory.createRunning @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createRunToEndOfMethodMessage()
    return

  startReplay: (element) ->
    if !@areAllControlsDisabled && @isExecutableInDebuggingMode && @currentStatusEvent.getStatus() != StatusUpdateEventFactory.RUNNING_STATUS
      callId = element.dataset.callId
      @socketChannel.sendMessage OutgoingMessageFactory.createStartReplayMessage callId

      if !@isReplay && @currentStatusEvent.getStatus() != StatusUpdateEventFactory.END_OF_TAPE_STATUS
        @lastEventBeforeReplay = @currentStatusEvent
      @isReplay = true
      @emitReplayStarted()

    return

  stopReplay: ->
    if !@areAllControlsDisabled && @isReplay
      @socketChannel.sendMessage OutgoingMessageFactory.createStopReplayMessage()
      @isReplay = false
      @emitReplayStopped()
      @emitStatusUpdated @lastEventBeforeReplay
    return

  areSteppingCommandsEnabled: ->
    return !@areAllControlsDisabled && @isExecutableInDebuggingMode && !@isAutoSteppingEnabled

  saveDocument: ->
    textEditor = levelsWorkspaceManager.getActiveTextEditor()

    if textEditor
      saveHere = textEditor.getPath() ? atom.showSaveDialogSync()

      if saveHere
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
    if !@areAllControlsDisabled && @isExecutableInDebuggingMode
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
    point = PositionUtils.toPoint currentPosition

    breakpointManager.restoreHiddenBreakpoint()
    breakpointManager.hideBreakpoint currentPosition

    if @positionMarker
      @positionMarker.destroy()
    @positionMarker = levelsWorkspaceManager.addPositionMarker point

    @emitter.emit 'position-updated', currentPosition
    @emitStatusUpdated StatusUpdateEventFactory.createWaiting @isReplay

    levelsWorkspaceManager.getActiveTextEditor()?.scrollToBufferPosition point
    return

  emitCallStackUpdated: ->
    @emitter.emit 'call-stack-updated'
    return

  emitVariableTableUpdated: ->
    @emitter.emit 'variable-table-updated'
    return

  emitStatusUpdated: (event) ->
    @emitter.emit 'status-updated', event
    @currentStatusEvent = event
    if event.isBlockingStatus()
      @emitAutoSteppingEnabled()
    else
      @emitAutoSteppingDisabled()
    return

  emitAutoSteppingEnabled: ->
    @isAutoSteppingEnabled = true
    @emitter.emit 'auto-stepping-enabled'
    return

  emitAutoSteppingDisabled: ->
    @isAutoSteppingEnabled = false
    @emitter.emit 'auto-stepping-disabled'
    return

  emitEnableDisableAllBreakpoints: ->
    @emitter.emit 'enable-disable-all-breakpoints', breakpointManager.getAreBreakpointsEnabled()
    return

  emitEnableDisableAllControls: (enabled) ->
    @areAllControlsDisabled = !enabled
    @emitter.emit 'enable-disable-all-controls', enabled
    return

  emitReplayStarted: ->
    @emitter.emit 'replay-started'
    return

  emitReplayStopped: ->
    @emitter.emit 'replay-stopped'
    return

  handleChannelError: (error) ->
    @disconnectAndCleanup()
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

  handleReady: ->
    @emitRunning()
    @emitAutoSteppingDisabled()
    for bp in breakpointManager.getBreakpoints()
      @socketChannel.sendMessage OutgoingMessageFactory.createAddBreakpointMessage bp.getPosition()
    @sendEnableDisableAllBreakpoints()
    return

  handleStop: ->
    if @isExecutableInDebuggingMode
      @disconnectAndCleanup()
    @isReplay = false
    @isAutoSteppingEnabled = true
    @variableTable = []
    @callStack = []
    variableTableManager.resetSortMode()
    @emitStopped()
    @emitAutoSteppingEnabled()
    if @positionMarker
      @positionMarker.destroy()
    breakpointManager.restoreHiddenBreakpoint()
    @emitStatusUpdated StatusUpdateEventFactory.createStopped @isReplay
    return

  handleEndOfReplayTape: ->
    @emitStatusUpdated StatusUpdateEventFactory.createEndOfTape false
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
      @execSubscriptions.dispose()
    return

  handleLevelChanged: ->
    if !@isExecutableInDebuggingMode
      if levelsWorkspaceManager.isActiveLevelDebuggable()
        @emitStatusUpdated @lastEventBeforeDisabling
        @emitEnableDisableAllControls true
      else
        if @currentStatusEvent.getStatus() != StatusUpdateEventFactory.DISABLED_STATUS
          @lastEventBeforeDisabling = @currentStatusEvent
        @emitStatusUpdated StatusUpdateEventFactory.createDisabled @isReplay
        @emitEnableDisableAllControls false
    return

  handleLevelCodeEditorChanged: ->
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    if @isExecutableInDebuggingMode
      enabled = @debuggingEditorId == editor.getId()
      @emitEnableDisableAllControls enabled
    else
      @execSubscriptions.dispose()
      @execSubscriptions = new CompositeDisposable
      @execSubscriptions.add editor.onDidStartExecution => @handleExecutableStarted()
      @execSubscriptions.add editor.onDidStopExecution => @handleExecutableStopped()
      if editor.isExecuting()
        @emitEnableDisableAllControls false
      else
        @emitEnableDisableAllControls levelsWorkspaceManager.isActiveLevelDebuggable()
    return