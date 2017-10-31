'use babel';

import {CompositeDisposable, Emitter} from 'atom';
import breakpointManager              from '../common/breakpoint-manager';
import callStackFromString            from '../common/call-stack-factory';
import levelsWorkspaceManager         from '../common/levels-workspace-manager';
import Position                       from '../common/position';
import {fromPoint, toPoint}           from '../common/position-utils';
import * as statusUpdateEventFactory  from '../common/status-update-event-factory';
import variableTableManager           from '../common/variable-table-manager';
import executor                       from '../debugger/executor';
import {DELIMITER}                    from '../messaging/message-utils';
import * as outgoingMessageFactory    from '../messaging/outgoing-message-factory';

export default class DebuggerPresenter {
  constructor(incomingMessageDispatcher, socketChannel) {
    this.incomingMessageDispatcher = incomingMessageDispatcher;
    this.socketChannel = socketChannel;
    this.emitter = new Emitter();

    this.callStack = [];
    this.variableTable = [];
    this.positionMarker = null;
    this.isReplay = false;
    this.isExecutableInDebuggingMode = false;
    this.isAutoSteppingEnabled = true;
    this.areAllControlsDisabled = false;

    this.currentStatusEvent = statusUpdateEventFactory.createStopped(false);
    this.lastEventBeforeDisabling = this.currentStatusEvent;
    this.lastEventBeforeReplay = null;

    this.execSubscriptions = null;

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(executor.onReady(() => this.startExecutableAndConnect()));
    this.subscriptions.add(executor.onStop(() => this.handleStop()));
    this.subscriptions.add(levelsWorkspaceManager.onWorkspaceAttached(workspace => this.setLevelsWorkspace(workspace)));
    this.subscriptions.add(this.socketChannel.onError(() => this.handleChannelError()));
    this.subscriptions.add(this.incomingMessageDispatcher.onReady(() => this.handleReady()));
    this.subscriptions.add(this.incomingMessageDispatcher.onPositionUpdated(string => this.emitPositionUpdated(string)));
    this.subscriptions.add(this.incomingMessageDispatcher.onCallStackUpdated(string => this.callStackFromString(string)));
    this.subscriptions.add(this.incomingMessageDispatcher.onVariableTableUpdated(string => this.variableTableFromString(string)));
    this.subscriptions.add(this.incomingMessageDispatcher.onEndOfReplayTape(() => this.handleEndOfReplayTape()));
    this.subscriptions.add(this.incomingMessageDispatcher.onAutoSteppingEnabled(() => this.emitAutoSteppingEnabled()));
    this.subscriptions.add(this.incomingMessageDispatcher.onAutoSteppingDisabled(() => this.emitAutoSteppingDisabled()));
  }

  destroy() {
    this.disconnectAndCleanup();
    this.subscriptions.dispose();
    if (this.execSubscriptions) {
      this.execSubscriptions.dispose();
    }
  }

  initDebuggerView() {
    const isAutoSteppingEnabled = this.isAutoSteppingEnabled;

    this.emitEnableDisableAllBreakpoints();
    this.emitStatusUpdated(this.currentStatusEvent);
    this.emitEnableDisableAllControls(!this.areAllControlsDisabled);

    if (this.isExecutableInDebuggingMode) {
      this.emitRunning();
      this.emitVariableTableUpdated();
      this.emitCallStackUpdated();

      if (isAutoSteppingEnabled) {
        this.emitAutoSteppingEnabled();
      } else {
        this.emitAutoSteppingDisabled();
      }

      if (this.isReplay) {
        this.emitReplayStarted();
      }
    }
  }

  disconnectAndCleanup() {
    this.socketChannel.disconnect();
    this.isExecutableInDebuggingMode = false;
    executor.stopDebugger();
    this.stopExecutable();
  }

  setLevelsWorkspace(workspace) {
    this.subscriptions.add(workspace.onDidEnterWorkspace(() => this.handleWorkspaceEntered()));
    this.subscriptions.add(workspace.onDidExitWorkspace(() => this.handleWorkspaceExited()));
    this.subscriptions.add(workspace.onDidChangeActiveLevel(() => this.handleLevelChanged()));
    this.subscriptions.add(workspace.onDidChangeActiveLevelCodeEditor(() => this.handleLevelCodeEditorChanged()));

    if (!levelsWorkspaceManager.isActive()) {
      this.handleLevelChanged();
    }
  }

  startDebugging() {
    if (!this.areAllControlsDisabled && !this.isExecutableInDebuggingMode && this.saveDocument()) {
      executor.startDebugger();
    }
  }

  startExecutableAndConnect() {
    this.socketChannel.connect();
    this.isExecutableInDebuggingMode = true;
    this.debuggingEditorId = levelsWorkspaceManager.getActiveLevelCodeEditor().getId();
    this.startExecutable();
  }

  stopDebugging() {
    if (!this.areAllControlsDisabled && this.isExecutableInDebuggingMode) {
      this.disconnectAndCleanup();
    }
  }

  step() {
    if (this.areSteppingCommandsEnabled()) {
      this.emitStatusUpdated(statusUpdateEventFactory.createRunning(this.isReplay));
      this.socketChannel.sendMessage(outgoingMessageFactory.createStepMessage());
    }
  }

  stepOver() {
    if (this.areSteppingCommandsEnabled()) {
      this.emitStatusUpdated(statusUpdateEventFactory.createRunning(this.isReplay));
      this.socketChannel.sendMessage(outgoingMessageFactory.createStepOverMessage());
    }
  }

  toggleBreakpoint() {
    if (!this.areAllControlsDisabled) {
      for (const point of levelsWorkspaceManager.getActiveTextEditorCursorPositions()) {
        if (breakpointManager.toggle(point)) {
          this.socketChannel.sendMessage(outgoingMessageFactory.createAddBreakpointMessage(fromPoint(point)));
        } else {
          this.socketChannel.sendMessage(outgoingMessageFactory.createRemoveBreakpointMessage(fromPoint(point)));
        }
      }
    }
  }

  removeAllBreakpoints() {
    if (!this.areAllControlsDisabled) {
      breakpointManager.removeAll();
      this.socketChannel.sendMessage(outgoingMessageFactory.createRemoveAllBreakpointsMessage());
    }
  }

  enableDisableAllBreakpoints() {
    if (!this.areAllControlsDisabled) {
      breakpointManager.flip();
      this.sendEnableDisableAllBreakpoints();
      this.emitEnableDisableAllBreakpoints();
    }
  }

  runToNextBreakpoint() {
    if (this.areSteppingCommandsEnabled()) {
      this.emitStatusUpdated(statusUpdateEventFactory.createRunning(this.isReplay));
      this.socketChannel.sendMessage(outgoingMessageFactory.createRunToNextBreakpointMessage());
    }
  }

  runToEndOfMethod() {
    if (this.areSteppingCommandsEnabled()) {
      this.emitStatusUpdated(statusUpdateEventFactory.createRunning(this.isReplay));
      this.socketChannel.sendMessage(outgoingMessageFactory.createRunToEndOfMethodMessage());
    }
  }

  startReplay(element) {
    if (!this.areAllControlsDisabled && this.isExecutableInDebuggingMode && (this.currentStatusEvent.getStatus() !== statusUpdateEventFactory.RUNNING_STATUS)) {
      this.socketChannel.sendMessage(outgoingMessageFactory.createStartReplayMessage(element.dataset.callId));

      if (!this.isReplay && (this.currentStatusEvent.getStatus() !== statusUpdateEventFactory.END_OF_TAPE_STATUS)) {
        this.lastEventBeforeReplay = this.currentStatusEvent;
      }
      this.isReplay = true;
      this.emitReplayStarted();
    }
  }

  stopReplay() {
    if (!this.areAllControlsDisabled && this.isReplay) {
      this.socketChannel.sendMessage(outgoingMessageFactory.createStopReplayMessage());
      this.isReplay = false;
      this.emitReplayStopped();
      this.emitStatusUpdated(this.lastEventBeforeReplay);
    }
  }

  areSteppingCommandsEnabled() {
    return !this.areAllControlsDisabled && this.isExecutableInDebuggingMode && !this.isAutoSteppingEnabled;
  }

  saveDocument() {
    const textEditor = levelsWorkspaceManager.getActiveTextEditor();

    if (textEditor) {
      const path = textEditor.getPath();
      const saveHere = path ? path : atom.showSaveDialogSync();

      if (saveHere) {
        textEditor.saveAs(saveHere);
        const terminal = levelsWorkspaceManager.getActiveTerminal();
        terminal.show();
        terminal.focus();

        return true;
      }
    }

    return false;
  }

  variableTableFromString(string) {
    this.variableTable = variableTableManager.fromString(string, this.variableTable);
    this.emitVariableTableUpdated();
  }

  getVariableTable() {
    return this.variableTable;
  }

  callStackFromString(string) {
    this.callStack = callStackFromString(string);
    this.emitCallStackUpdated();
  }

  getCallStack() {
    return this.callStack;
  }

  startExecutable() {
    levelsWorkspaceManager.getActiveLevelCodeEditor().startExecution({runExecArgs: ['-d']});
  }

  stopExecutable() {
    levelsWorkspaceManager.getActiveLevelCodeEditor().stopExecution();
  }

  sendEnableDisableAllBreakpoints() {
    if (breakpointManager.getAreBreakpointsEnabled()) {
      this.socketChannel.sendMessage(outgoingMessageFactory.createEnableAllBreakpointsMessage());
    } else {
      this.socketChannel.sendMessage(outgoingMessageFactory.createDisableAllBreakpointsMessage());
    }
  }

  flipAndSortVariableTable() {
    if (!this.areAllControlsDisabled && this.isExecutableInDebuggingMode) {
      variableTableManager.flipSortMode();
      variableTableManager.sort(this.variableTable);
      this.emitVariableTableUpdated();
    }
  }

  onRunning(callback) {
    return this.emitter.on('running', callback);
  }

  onStopped(callback) {
    return this.emitter.on('stopped', callback);
  }

  onPositionUpdated(callback) {
    return this.emitter.on('position-updated', callback);
  }

  onCallStackUpdated(callback) {
    return this.emitter.on('call-stack-updated', callback);
  }

  onVariableTableUpdated(callback) {
    return this.emitter.on('variable-table-updated', callback);
  }

  onStatusUpdated(callback) {
    return this.emitter.on('status-updated', callback);
  }

  onAutoSteppingEnabled(callback) {
    return this.emitter.on('auto-stepping-enabled', callback);
  }

  onAutoSteppingDisabled(callback) {
    return this.emitter.on('auto-stepping-disabled', callback);
  }

  onEnableDisableAllBreakpoints(callback) {
    return this.emitter.on('enable-disable-all-breakpoints', callback);
  }

  onEnableDisableAllControls(callback) {
    return this.emitter.on('enable-disable-all-controls', callback);
  }

  onReplayStarted(callback) {
    return this.emitter.on('replay-started', callback);
  }

  onReplayStopped(callback) {
    return this.emitter.on('replay-stopped', callback);
  }

  emitRunning() {
    this.emitter.emit('running');
  }

  emitStopped() {
    this.emitter.emit('stopped');
  }

  emitPositionUpdated(string) {
    const splitted = string.split(DELIMITER);
    const currentPosition = new Position(+splitted[0], +splitted[1]);
    const point = toPoint(currentPosition);

    breakpointManager.restoreHiddenBreakpoint();
    breakpointManager.hideBreakpoint(currentPosition);

    if (this.positionMarker) {
      this.positionMarker.destroy();
    }
    this.positionMarker = levelsWorkspaceManager.addPositionMarker(point);

    this.emitter.emit('position-updated', currentPosition);
    this.emitStatusUpdated(statusUpdateEventFactory.createWaiting(this.isReplay));

    const textEditor = levelsWorkspaceManager.getActiveTextEditor();
    if (textEditor) {
      textEditor.scrollToBufferPosition(point);
    }
  }

  emitCallStackUpdated() {
    this.emitter.emit('call-stack-updated');
  }

  emitVariableTableUpdated() {
    this.emitter.emit('variable-table-updated');
  }

  emitStatusUpdated(event) {
    this.emitter.emit('status-updated', event);
    this.currentStatusEvent = event;
    if (event.isBlockingStatus()) {
      this.emitAutoSteppingEnabled();
    } else {
      this.emitAutoSteppingDisabled();
    }
  }

  emitAutoSteppingEnabled() {
    this.isAutoSteppingEnabled = true;
    this.emitter.emit('auto-stepping-enabled');
  }

  emitAutoSteppingDisabled() {
    this.isAutoSteppingEnabled = false;
    this.emitter.emit('auto-stepping-disabled');
  }

  emitEnableDisableAllBreakpoints() {
    this.emitter.emit('enable-disable-all-breakpoints', breakpointManager.getAreBreakpointsEnabled());
  }

  emitEnableDisableAllControls(enabled) {
    this.areAllControlsDisabled = !enabled;
    this.emitter.emit('enable-disable-all-controls', enabled);
  }

  emitReplayStarted() {
    this.emitter.emit('replay-started');
  }

  emitReplayStopped() {
    this.emitter.emit('replay-stopped');
  }

  handleChannelError() {
    this.disconnectAndCleanup();
  }

  handleExecutableStarted() {
    if (!this.isExecutableInDebuggingMode) {
      this.emitEnableDisableAllControls(false);
    }
  }

  handleExecutableStopped() {
    if (this.isExecutableInDebuggingMode) {
      this.disconnectAndCleanup();
    }
    this.emitEnableDisableAllControls(levelsWorkspaceManager.isActiveLevelDebuggable());
  }

  handleReady() {
    this.emitRunning();
    this.emitAutoSteppingDisabled();
    for (const bp of breakpointManager.getBreakpoints()) {
      this.socketChannel.sendMessage(outgoingMessageFactory.createAddBreakpointMessage(bp.getPosition()));
    }
    this.sendEnableDisableAllBreakpoints();
  }

  handleStop() {
    if (this.isExecutableInDebuggingMode) {
      this.disconnectAndCleanup();
    }

    this.isReplay = false;
    this.isAutoSteppingEnabled = true;
    this.variableTable = [];
    this.callStack = [];
    variableTableManager.resetSortMode();
    this.emitStopped();
    this.emitAutoSteppingEnabled();

    if (this.positionMarker) {
      this.positionMarker.destroy();
    }
    breakpointManager.restoreHiddenBreakpoint();

    this.emitStatusUpdated(statusUpdateEventFactory.createStopped(this.isReplay));
  }

  handleEndOfReplayTape() {
    this.emitStatusUpdated(statusUpdateEventFactory.createEndOfTape(false));
  }

  handleWorkspaceEntered() {
    const editor = levelsWorkspaceManager.getActiveLevelCodeEditor();

    if (this.isExecutableInDebuggingMode) {
      const enabled = this.debuggingEditorId === editor.getId();
      this.emitEnableDisableAllControls(enabled);
    } else {
      this.handleLevelChanged();

      this.execSubscriptions = new CompositeDisposable();
      this.execSubscriptions.add(editor.onDidStartExecution(() => this.handleExecutableStarted()));
      this.execSubscriptions.add(editor.onDidStopExecution(() => this.handleExecutableStopped()));

      if (editor.isExecuting()) {
        this.emitEnableDisableAllControls(false);
      }
    }
  }

  handleWorkspaceExited() {
    if (this.isExecutableInDebuggingMode) {
      this.emitEnableDisableAllControls(false);
    } else {
      this.handleLevelChanged();
      this.execSubscriptions.dispose();
    }
  }

  handleLevelChanged() {
    if (!this.isExecutableInDebuggingMode) {
      if (levelsWorkspaceManager.isActiveLevelDebuggable()) {
        this.emitStatusUpdated(this.lastEventBeforeDisabling);
        this.emitEnableDisableAllControls(true);
      } else {
        if (this.currentStatusEvent.getStatus() !== statusUpdateEventFactory.DISABLED_STATUS) {
          this.lastEventBeforeDisabling = this.currentStatusEvent;
        }
        this.emitStatusUpdated(statusUpdateEventFactory.createDisabled(this.isReplay));
        this.emitEnableDisableAllControls(false);
      }
    }
  }

  handleLevelCodeEditorChanged() {
    const editor = levelsWorkspaceManager.getActiveLevelCodeEditor();

    if (this.isExecutableInDebuggingMode) {
      const enabled = this.debuggingEditorId === editor.getId();
      this.emitEnableDisableAllControls(enabled);
    } else {
      this.execSubscriptions.dispose();
      this.execSubscriptions = new CompositeDisposable();
      this.execSubscriptions.add(editor.onDidStartExecution(() => this.handleExecutableStarted()));
      this.execSubscriptions.add(editor.onDidStopExecution(() => this.handleExecutableStopped()));

      if (editor.isExecuting()) {
        this.emitEnableDisableAllControls(false);
      } else {
        this.emitEnableDisableAllControls(levelsWorkspaceManager.isActiveLevelDebuggable());
      }
    }
  }
}