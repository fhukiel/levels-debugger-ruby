{CompositeDisposable, Emitter, Point} = require 'atom'
{$,$$,View}                           = require('atom-space-pen-views')
Position                              = require('../common/position')
positionUtils                         = require('../common/position-utils').getInstance()
levelsWorkspaceManager                = require('../common/levels-workspace-manager').getInstance()
statusFactory                         = require('../common/status-update-event-factory').getInstance()
variableTableManager                  = require('../common/variable-table-manager').getInstance()
callStackFactory                      = require('../common/call-stack-factory').getInstance()
breakpointManager                     = require('../common/breakpoint-manager').getInstance()
executor                              = require('../debugger/executor').getInstance()
outgoingMessageFactory                = require('../messaging/outgoing-message-factory').getInstance()
messageUtils                          = require('../messaging/message-utils').getInstance()

module.exports =
class DebuggerViewModel
  #-- SETUP
  constructor: (incomingMessageDispatcher, communicationChannel) ->
    @incomingMessageDispatcher = incomingMessageDispatcher
    @communicationChannel = communicationChannel
    @callStack = new Array();
    @variableTable = new Array();
    @emitter = new Emitter();
    @positionMarker = null;
    @isReplay = false;
    @isExecutableInDebuggingMode = false;
    @currentStatusEvent = statusFactory.createStopped(false);
    @lastEventBeforeDisabling = @currentStatusEvent;
    @lastEventBeforeReplay = null;
    @setupSubscriptions();

  setupSubscriptions: ->
    @subscriptions = new CompositeDisposable()
    @subscriptions.add @incomingMessageDispatcher.onReady => @handleReady();
    @subscriptions.add @incomingMessageDispatcher.onTerminate => @handleStopping();
    @subscriptions.add @incomingMessageDispatcher.onPositionUpdate (string) => @emitPositionUpdate(string, @isReplay);
    @subscriptions.add @incomingMessageDispatcher.onCallStackUpdate (string) => @callStackFromString(string);
    @subscriptions.add @incomingMessageDispatcher.onTableUpdate (string) => @variableTableFromString(string);
    @subscriptions.add @incomingMessageDispatcher.onEndOfReplayTape => @handleEndOfReplayTape();
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingEnabled => @emitAutoSteppingEnabled();
    @subscriptions.add @incomingMessageDispatcher.onAutoSteppingDisabled => @emitAutoSteppingDisabled();

  destroy: ->
    @disconnectAndCleanup();
    @subscriptions.dispose()

  setLevelsWorkspace: (ws) ->
    levelsWorkspaceManager.attachWorkspace(ws);
    ws.onDidEnterWorkspace => @handleWorkspaceEntered();
    ws.onDidEnterWorkspace => @handleLevelChanged()

  #-- Bussiness logic
  startDebugging: ->
    console.log "startDebugging called."
    if @saveDocument()
      executor.startDebugger();
      executor.onReady => @startExecutableAndConnect();
      executor.onStop => @handleStopping();

  startExecutableAndConnect: ->
    console.log "Debugger.jar is ready."
    @communicationChannel.connect();
    @isExecutableInDebuggingMode = true;
    @runExecutable();

  stopDebugging: ->
    console.log 'stopDebugging called!'
    if @showConfirmDialog("Stop debugger?")
      @disconnectAndCleanup();

  disconnectAndCleanup: ->
    @variableTable = new Array();
    @callStack = new Array();
    @communicationChannel.disconnect();
    executor.stopDebugger();
    @isExecutableInDebuggingMode = false;
    @stopExecutable();
    variableTableManager.resetSortMode();

  step: ->
    console.log 'Step called!'
    @emitStatusUpdate(statusFactory.createRunning(@isReplay));
    @communicationChannel.sendMessage(outgoingMessageFactory.createStepMessage());

  stepOver: ->
    console.log 'StepOver called!'
    @emitStatusUpdate(statusFactory.createRunning(@isReplay));
    @communicationChannel.sendMessage(outgoingMessageFactory.createStepOverMessage());

  toggleBreakpoint: ->
    console.log "Toggle breakpoint called."
    currentPosition = levelsWorkspaceManager.getActiveTextEditorPosition();
    isNewBreakpoint = breakpointManager.toggle(currentPosition);
    if isNewBreakpoint
      @sendBreakpointAdded(positionUtils.fromPoint(currentPosition));
    else
      @sendBreakpointRemoved(positionUtils.fromPoint(currentPosition));

  removeAllBreakpoints: ->
    console.log "Remove all breakpoints called."
    if @showConfirmDialog("Remove all breakpoints?")
      breakpointManager.removeAll();
      @sendRemoveAllBreakpoints();

  enableDisableAllBreakpoints: ->
    console.log "Enable / disable all breakpoints called, enabled has value #{breakpointManager.getAreBreakpointsEnabled()}."
    breakpointManager.flip();
    @sendEnableDisableAllBreakpoints()
    @emitEnableDisableAllBreakpoints(breakpointManager.getAreBreakpointsEnabled());

  runToNextBreakpoint: ->
    console.log 'RunToNextBreakpoint called.'
    @emitStatusUpdate(statusFactory.createRunning(@isReplay));
    @communicationChannel.sendMessage(outgoingMessageFactory.createRunToNextBreakpointMessage());

  runToEndOfMethod: ->
    console.log "runToEndOfMethod called."
    @emitStatusUpdate(statusFactory.createRunning(@isReplay));
    @communicationChannel.sendMessage(outgoingMessageFactory.createRunToEndOfMethodMessage());

  startReplay: (element)->
    console.log "StartReplay called."
    id = element.getAttribute('id')
    @communicationChannel.sendMessage(outgoingMessageFactory.createStartReplayMessage("#{id}"));
    # Only save currentStatusEvent if not replay in replay and current status isnt 'end of tape'
    if !@isReplay and (@currentStatusEvent.getStatus() isnt statusFactory.getEndOfTapeStatus())
      @lastEventBeforeReplay = @currentStatusEvent;
    @isReplay = true;

  stopReplay: ->
    console.log 'StopReplay called!'
    @communicationChannel.sendMessage(outgoingMessageFactory.createStopReplayMessage());
    @isReplay = false;
    @emitStatusUpdate(@lastEventBeforeReplay)

  popFromCallStack: ->
    @callStack.pop();
    @emitCallStackUpdate();

  #-- Helpers
  saveDocument: ->
    textEditor = levelsWorkspaceManager.getActiveTextEditor()
    saveHere = textEditor.getPath() ? atom.showSaveDialogSync()
    if saveHere?
      textEditor.saveAs(saveHere);
      levelsWorkspaceManager.getActiveTerminal().show()
      levelsWorkspaceManager.getActiveTerminal().focus()
      return true;
    return false;

  variableTableFromString: (string) ->
    @variableTable = variableTableManager.fromString(string, @variableTable);
    @emitVariableTableUpdate();

  getVariableTable: ->
    return @variableTable;

  callStackFromString: (string) ->
    @callStack = callStackFactory.fromString(string);
    @emitCallStackUpdate();

  getCallStack: ->
    return @callStack;

  runExecutable: ->
    editor = levelsWorkspaceManager.getActiveLevelCodeEditor()
    editor.startExecution({runExecArgs: ['-d']})

  stopExecutable: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:stop-execution')

  sendBreakpointRemoved: (breakPointPosition) ->
    @communicationChannel.sendMessage(outgoingMessageFactory.createRemoveBreakpointMessage(breakPointPosition));

  sendBreakpointAdded: (breakPointPosition) ->
    @communicationChannel.sendMessage(outgoingMessageFactory.createAddBreakpointMessage(breakPointPosition));

  sendRemoveAllBreakpoints: ->
    @communicationChannel.sendMessage(outgoingMessageFactory.createRemoveAllBreakpointsMessage());

  sendEnableDisableAllBreakpoints: ->
    if breakpointManager.getAreBreakpointsEnabled()
      @communicationChannel.sendMessage(outgoingMessageFactory.createEnableAllBreakpointsMessage());
    else
      @communicationChannel.sendMessage(outgoingMessageFactory.createDisableAllBreakpointsMessage());

  flipAndSortVariableTable: ->
    variableTableManager.flipSortMode();
    variableTableManager.sort(@variableTable)
    @emitVariableTableUpdate();

  showConfirmDialog: (message) ->
    atom.confirm
      message: message
      buttons:
        Confirm: -> return true;
        Cancel: -> return false;

  #-- Public events
  onRunning: (callback) ->
    @emitter.on('running',callback)

  onStopped: (callback) ->
    @emitter.on('stopped',callback)

  onPositionUpdated: (callback) ->
    @emitter.on('position-updated', callback)

  onCallStackUpdated: (callback) ->
    @emitter.on('call-stack-updated', callback)

  onVariableTableUpdated: (callback) ->
    @emitter.on('variable-table-updated',callback)

  onStatusUpdated: (callback) ->
    @emitter.on('status-updated',callback)

  onAutoSteppingEnabled: (callback) ->
    @emitter.on('auto-stepping-enabled',callback)

  onAutoSteppingDisabled: (callback) ->
    @emitter.on('auto-stepping-disabled',callback)

  onEnableDisableAllBreakpoints: (callback) ->
    @emitter.on('enable-disable-all-breakpoints',callback)

  onEnableDisableAllControls: (callback) ->
    @emitter.on('enable-disable-all-commands',callback)

  #-- Emitters
  emitEnableDisableAllBreakpoints: (enabled) ->
    @emitter.emit('enable-disable-all-breakpoints', enabled)

  emitDebuggingStarted: ->
    console.log "Debugging started"
    @emitter.emit('running')

  emitDebuggingStopped: ->
    console.log "Debugging stopped"
    @emitter.emit('stopped')

  emitPositionUpdate: (positionString, isReplay) ->
    splitted = positionString.split(messageUtils.getDelimiter());
    console.log "Position updated to #{splitted}"
    currentPosition = new Position(+splitted[1], +splitted[2])

    # Restore any shadowed breakpoint's marker
    breakpointManager.restoreHiddenBreakpoint();
    # Hide marker of potential breakpoint at current position
    breakpointManager.hideBreakpoint(currentPosition)

    # remove previous position marker
    if @positionMarker?
      @positionMarker.destroy();
    @positionMarker = levelsWorkspaceManager.addPositionMarker(currentPosition);

    @emitter.emit('position-updated', currentPosition)
    @emitStatusUpdate(statusFactory.createWaiting(isReplay));

    # scroll to position
    atom.workspace.getActiveTextEditor().scrollToBufferPosition(positionUtils.toPoint(currentPosition))

  emitCallStackUpdate: ->
    @emitter.emit('call-stack-updated')

  emitVariableTableUpdate: ->
    @emitter.emit('variable-table-updated')

  emitAutoSteppingEnabled: ->
    @emitter.emit('auto-stepping-enabled')

  emitAutoSteppingDisabled: ->
    @emitter.emit('auto-stepping-disabled')

  emitStatusUpdate: (event) ->
    @emitter.emit('status-updated', event)
    @currentStatusEvent = event;

  emitEnableDisableAllControls: (enabled) ->
    @emitter.emit('enable-disable-all-commands', enabled)

  #-- Event handlers
  handleWorkspaceEntered: ->
    console.log "Workspace entered."
    levelsWorkspaceManager.getWorkspace().getActiveLevelCodeEditor().onDidStartExecution => @handleExecutableStarted();
    levelsWorkspaceManager.getWorkspace().getActiveLevelCodeEditor().onDidStopExecution => @handleExecutableStopped();
    levelsWorkspaceManager.getWorkspace().onDidChangeActiveLevel => @handleLevelChanged();

  handleExecutableStarted: ->
    console.log "Executable started"
    if @isExecutableInDebuggingMode
      @emitEnableDisableAllControls(levelsWorkspaceManager.isActiveLevelDebuggable());
    else
      @emitEnableDisableAllControls(false);

  handleExecutableStopped: ->
    console.log "Executable stopped"
    @disconnectAndCleanup();
    @emitEnableDisableAllControls(levelsWorkspaceManager.isActiveLevelDebuggable());

  handleReady: ->
    @emitDebuggingStarted();
    for breakpoint in breakpointManager.getBreakpoints()
      console.log "Sending breakpoint #{breakpoint.getPosition()} to view."
      @sendBreakpointAdded(breakpoint.getPosition());
    @sendEnableDisableAllBreakpoints();

  handleStopping: ->
    @isReplay = false;
    @emitDebuggingStopped();
    if @positionMarker?
      @positionMarker.destroy();
    breakpointManager.restoreHiddenBreakpoint();
    @emitStatusUpdate(statusFactory.createStopped(@isReplay));

  handleEndOfReplayTape: ->
    @emitStatusUpdate(statusFactory.createEndOfTape(false))

  handleLevelChanged: ->
    if !@isExecutableInDebuggingMode
      isDebuggable = levelsWorkspaceManager.isActiveLevelDebuggable();
      console.log "Level changed, isdebuggable: #{isDebuggable}."
      if isDebuggable
        @emitStatusUpdate(@lastEventBeforeDisabling);
        @emitEnableDisableAllControls(true)
      else
        if @currentStatusEvent.getStatus() isnt statusFactory.getDisabledStatus()
          console.log "Currentstatus: #{@currentStatusEvent.getStatus()}"
          @lastEventBeforeDisabling = @currentStatusEvent;
        @emitStatusUpdate(statusFactory.createDisabled(@isReplay));
        @emitEnableDisableAllControls(false)
