'use babel';

import {CompositeDisposable} from 'atom';

export default class DebuggerView {
  constructor(debuggerPresenter) {
    this.debuggerPresenter = debuggerPresenter;

    this.element = document.createElement('div');
    this.element.className = 'levels-debugger-ruby';

    this.statusDiv = document.createElement('div');
    this.statusDiv.className = 'status';
    this.element.appendChild(this.statusDiv);

    this.statusSpan = document.createElement('span');
    this.statusSpan.className = 'overflow-ellipsis';
    this.statusDiv.appendChild(this.statusSpan);

    const commandsHeader = document.createElement('div');
    commandsHeader.className = 'header';
    this.element.appendChild(commandsHeader);

    const commandsHeaderSpan = document.createElement('span');
    commandsHeaderSpan.className = 'overflow-ellipsis';
    commandsHeaderSpan.textContent = 'Commands';
    commandsHeader.appendChild(commandsHeaderSpan);

    const commandsDiv = document.createElement('div');
    commandsDiv.className = 'commands';
    this.element.appendChild(commandsDiv);

    const toggleBreakpointButton = document.createElement('button');
    toggleBreakpointButton.className = 'btn';
    toggleBreakpointButton.textContent = 'Toggle Breakpoint';
    toggleBreakpointButton.addEventListener('click', () => this.debuggerPresenter.toggleBreakpoint());
    commandsDiv.appendChild(toggleBreakpointButton);

    const removeAllBreakpointsButton = document.createElement('button');
    removeAllBreakpointsButton.className = 'btn';
    removeAllBreakpointsButton.textContent = 'Remove All Breakpoints';
    removeAllBreakpointsButton.addEventListener('click', () => this.debuggerPresenter.removeAllBreakpoints());
    commandsDiv.appendChild(removeAllBreakpointsButton);

    this.enableDisableAllBreakpointsButton = document.createElement('button');
    this.enableDisableAllBreakpointsButton.className = 'btn';
    this.enableDisableAllBreakpointsButton.textContent = 'Disable All Breakpoints';
    this.enableDisableAllBreakpointsButton.addEventListener('click', () => this.debuggerPresenter.enableDisableAllBreakpoints());
    commandsDiv.appendChild(this.enableDisableAllBreakpointsButton);

    this.startDebuggingButton = document.createElement('button');
    this.startDebuggingButton.className = 'btn';
    this.startDebuggingButton.textContent = 'Start Debugging';
    this.startDebuggingButton.addEventListener('click', () => this.debuggerPresenter.startDebugging());
    commandsDiv.appendChild(this.startDebuggingButton);

    this.stopDebuggingButton = document.createElement('button');
    this.stopDebuggingButton.className = 'btn disabled';
    this.stopDebuggingButton.textContent = 'Stop Debugging';
    this.stopDebuggingButton.addEventListener('click', () => this.debuggerPresenter.stopDebugging());
    commandsDiv.appendChild(this.stopDebuggingButton);

    this.stepButton = document.createElement('button');
    this.stepButton.className = 'btn disabled';
    this.stepButton.textContent = 'Step';
    this.stepButton.addEventListener('click', () => this.debuggerPresenter.step());
    commandsDiv.appendChild(this.stepButton);

    this.stepOverButton = document.createElement('button');
    this.stepOverButton.className = 'btn disabled';
    this.stepOverButton.textContent = 'Step Over';
    this.stepOverButton.addEventListener('click', () => this.debuggerPresenter.stepOver());
    commandsDiv.appendChild(this.stepOverButton);

    this.runToEndOfMethodButton = document.createElement('button');
    this.runToEndOfMethodButton.className = 'btn disabled';
    this.runToEndOfMethodButton.textContent = 'Run To End Of Method';
    this.runToEndOfMethodButton.addEventListener('click', () => this.debuggerPresenter.runToEndOfMethod());
    commandsDiv.appendChild(this.runToEndOfMethodButton);

    this.runToNextBreakpointButton = document.createElement('button');
    this.runToNextBreakpointButton.className = 'btn disabled';
    this.runToNextBreakpointButton.textContent = 'Run To Next Breakpoint';
    this.runToNextBreakpointButton.addEventListener('click', () => this.debuggerPresenter.runToNextBreakpoint());
    commandsDiv.appendChild(this.runToNextBreakpointButton);

    this.stopReplayButton = document.createElement('button');
    this.stopReplayButton.className = 'btn disabled';
    this.stopReplayButton.textContent = 'Stop Replay';
    this.stopReplayButton.addEventListener('click', () => this.debuggerPresenter.stopReplay());
    commandsDiv.appendChild(this.stopReplayButton);

    const variablesHeader = document.createElement('div');
    variablesHeader.className = 'header';
    this.element.appendChild(variablesHeader);

    const variablesHeaderSpan = document.createElement('span');
    variablesHeaderSpan.className = 'overflow-ellipsis';
    variablesHeaderSpan.textContent = 'Defined Variables';
    variablesHeader.appendChild(variablesHeaderSpan);

    const variablesHeadDiv = document.createElement('div');
    variablesHeadDiv.className = 'variables-head';
    this.element.appendChild(variablesHeadDiv);

    const variablesHeadTable = document.createElement('table');
    variablesHeadTable.className = 'table';
    variablesHeadDiv.appendChild(variablesHeadTable);

    const variablesHeadTableHead = document.createElement('thead');
    variablesHeadTable.appendChild(variablesHeadTableHead);

    const variablesHeadTableHeadRow = document.createElement('tr');
    variablesHeadTableHead.appendChild(variablesHeadTableHeadRow);

    const variablesHeadTableHeadVariable = document.createElement('th');
    variablesHeadTableHeadVariable.textContent = 'Variable';
    variablesHeadTableHeadVariable.addEventListener('click', () => this.debuggerPresenter.flipAndSortVariableTable());
    const variablesHeadTableHeadValue = document.createElement('th');
    variablesHeadTableHeadValue.textContent = 'Value';
    const variablesHeadTableHeadAddress = document.createElement('th');
    variablesHeadTableHeadAddress.textContent = 'Address';
    variablesHeadTableHeadRow.appendChild(variablesHeadTableHeadVariable);
    variablesHeadTableHeadRow.appendChild(variablesHeadTableHeadValue);
    variablesHeadTableHeadRow.appendChild(variablesHeadTableHeadAddress);

    const variablesBodyDiv = document.createElement('div');
    variablesBodyDiv.className = 'variables-body';
    this.element.appendChild(variablesBodyDiv);

    const variablesBodyTable = document.createElement('table');
    variablesBodyTable.className = 'table';
    variablesBodyDiv.appendChild(variablesBodyTable);

    this.variablesBodyTableBody = document.createElement('tbody');
    variablesBodyTable.appendChild(this.variablesBodyTableBody);

    const stackHeader = document.createElement('div');
    stackHeader.className = 'header';
    this.element.appendChild(stackHeader);

    const stackHeaderSpan = document.createElement('span');
    stackHeaderSpan.className = 'overflow-ellipsis';
    stackHeaderSpan.textContent = 'Call Stack';
    stackHeader.appendChild(stackHeaderSpan);

    const stackHeadDiv = document.createElement('div');
    stackHeadDiv.className = 'stack-head';
    this.element.appendChild(stackHeadDiv);

    const stackHeadTable = document.createElement('table');
    stackHeadTable.className = 'table';
    stackHeadDiv.appendChild(stackHeadTable);

    const stackHeadTableHead = document.createElement('thead');
    stackHeadTable.appendChild(stackHeadTableHead);

    const stackHeadTableHeadRow = document.createElement('tr');
    stackHeadTableHead.appendChild(stackHeadTableHeadRow);

    const stackHeadTableHeadCall = document.createElement('th');
    stackHeadTableHeadCall.textContent = 'Call';
    const stackHeadTableHeadReplay = document.createElement('th');
    stackHeadTableHeadReplay.textContent = 'Replay';
    stackHeadTableHeadRow.appendChild(stackHeadTableHeadCall);
    stackHeadTableHeadRow.appendChild(stackHeadTableHeadReplay);

    const stackBodyDiv = document.createElement('div');
    stackBodyDiv.className = 'stack-body';
    this.element.appendChild(stackBodyDiv);

    const stackBodyTable = document.createElement('table');
    stackBodyTable.className = 'table';
    stackBodyDiv.appendChild(stackBodyTable);

    this.stackBodyTableBody = document.createElement('tbody');
    stackBodyTable.appendChild(this.stackBodyTableBody);

    this.subscriptions = new CompositeDisposable();

    this.subscriptions.add(this.debuggerPresenter.onRunning(() => this.handleRunning()));
    this.subscriptions.add(this.debuggerPresenter.onStopped(() => this.handleStopped()));
    this.subscriptions.add(this.debuggerPresenter.onReplayStarted(() => this.handleReplayStarted()));
    this.subscriptions.add(this.debuggerPresenter.onReplayStopped(() => this.handleReplayStopped()));
    this.subscriptions.add(this.debuggerPresenter.onCallStackUpdated(() => this.updateCallStack()));
    this.subscriptions.add(this.debuggerPresenter.onVariableTableUpdated(() => this.updateVariableTable()));
    this.subscriptions.add(this.debuggerPresenter.onStatusUpdated(status => this.handleStatusUpdated(status)));
    this.subscriptions.add(this.debuggerPresenter.onAutoSteppingEnabled(() => this.handleEnableDisableSteppingCommands(false)));
    this.subscriptions.add(this.debuggerPresenter.onAutoSteppingDisabled(() => this.handleEnableDisableSteppingCommands(true)));
    this.subscriptions.add(this.debuggerPresenter.onEnableDisableAllBreakpoints(enable => this.handleEnableDisableAllBreakpoints(enable)));
    this.subscriptions.add(this.debuggerPresenter.onEnableDisableAllControls(enable => this.handleEnableDisableAllControls(enable)));

    this.subscriptions.add(atom.tooltips.add(toggleBreakpointButton, {
      title: toggleBreakpointButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:toggle-breakpoint'
    }));

    this.subscriptions.add(atom.tooltips.add(removeAllBreakpointsButton, {
      title: removeAllBreakpointsButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:remove-all-breakpoints'
    }));

    this.subscriptions.add(atom.tooltips.add(this.startDebuggingButton, {
      title: this.startDebuggingButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:start-debugging'
    }));

    this.subscriptions.add(atom.tooltips.add(this.stopDebuggingButton, {
      title: this.stopDebuggingButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:stop-debugging'
    }));

    this.subscriptions.add(atom.tooltips.add(this.stepButton, {
      title: this.stepButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:step'
    }));

    this.subscriptions.add(atom.tooltips.add(this.stepOverButton, {
      title: this.stepOverButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:step-over'
    }));

    this.subscriptions.add(atom.tooltips.add(this.runToEndOfMethodButton, {
      title: this.runToEndOfMethodButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:run-to-end-of-method'
    }));

    this.subscriptions.add(atom.tooltips.add(this.runToNextBreakpointButton, {
      title: this.runToNextBreakpointButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:run-to-next-breakpoint'
    }));

    this.subscriptions.add(atom.tooltips.add(this.stopReplayButton, {
      title: this.stopReplayButton.textContent,
      keyBindingCommand: 'levels-debugger-ruby:stop-replay'
    }));

    this.debuggerPresenter.initDebuggerView();
  }

  destroy() {
    this.element.remove();
    this.subscriptions.dispose();

    if (this.statusTooltip) {
      this.statusTooltip.dispose();
    }
    if (this.enableDisableAllBreakpointsButtonTooltip) {
      this.enableDisableAllBreakpointsButtonTooltip.dispose();
    }
    if (this.variableTableSubscriptions) {
      this.variableTableSubscriptions.dispose();
    }
    if (this.callStackSubscriptions) {
      this.callStackSubscriptions.dispose();
    }
  }

  getTitle() {
    return 'Levels Debugger Ruby';
  }

  getDefaultLocation() {
    return 'right';
  }

  getAllowedLocations() {
    return ['left', 'right'];
  }

  getURI() {
    return 'atom://levels-debugger-ruby';
  }

  getElement() {
    return this.element;
  }

  enableDisableCommandsOnStartStop(enabled) {
    if (enabled) {
      this.startDebuggingButton.classList.add('disabled');
      this.stopDebuggingButton.classList.remove('disabled');
    } else {
      this.startDebuggingButton.classList.remove('disabled');
      this.stopDebuggingButton.classList.add('disabled');
    }
  }

  handleRunning() {
    this.enableDisableCommandsOnStartStop(true);
  }

  handleStopped() {
    this.updateVariableTable();
    this.updateCallStack();
    this.enableDisableCommandsOnStartStop(false);
    this.stopReplayButton.classList.add('disabled');
  }

  handleReplayStarted() {
    this.stopReplayButton.classList.remove('disabled');
  }

  handleReplayStopped() {
    this.stopReplayButton.classList.add('disabled');
  }

  updateCallStack() {
    this.stackBodyTableBody.innerHTML = '';

    if (this.callStackSubscriptions) {
      this.callStackSubscriptions.dispose();
    }
    this.callStackSubscriptions = new CompositeDisposable();

    const callStack = this.debuggerPresenter.getCallStack();
    for (let i = callStack.length - 1; i >= 0; i--) {
      const entry = callStack[i];
      const methodAndArgs = entry.getMethodAndArgs();
      const callId = entry.getCallId();

      const row = document.createElement('tr');
      const cellCall = document.createElement('td');
      cellCall.textContent = methodAndArgs;
      const cellReplay = document.createElement('td');
      const replayButton = document.createElement('button');
      replayButton.className = 'btn';
      replayButton.textContent = 'Replay';
      replayButton.dataset.callId = callId;
      replayButton.addEventListener('click', event => this.debuggerPresenter.startReplay(event.target));
      cellReplay.appendChild(replayButton);
      row.appendChild(cellCall);
      row.appendChild(cellReplay);
      this.stackBodyTableBody.appendChild(row);

      this.callStackSubscriptions.add(atom.tooltips.add(replayButton, {title: replayButton.textContent}));
      this.callStackSubscriptions.add(atom.tooltips.add(cellCall, {title: methodAndArgs, html: false}));
    }
  }

  updateVariableTable() {
    this.variablesBodyTableBody.innerHTML = '';

    if (this.variableTableSubscriptions) {
      this.variableTableSubscriptions.dispose();
    }
    this.variableTableSubscriptions = new CompositeDisposable();

    for (const entry of this.debuggerPresenter.getVariableTable()) {
      const name = entry.getName();
      const value = entry.getValue();
      const address = entry.getAddress();

      const row = document.createElement('tr');
      if (entry.isChanged()) {
        row.className = 'highlight';
      }

      const cellName = document.createElement('td');
      cellName.textContent = name;
      const cellValue = document.createElement('td');
      cellValue.textContent = value;
      const cellAddress = document.createElement('td');
      cellAddress.textContent = address;
      row.appendChild(cellName);
      row.appendChild(cellValue);
      row.appendChild(cellAddress);

      this.variablesBodyTableBody.appendChild(row);

      this.variableTableSubscriptions.add(atom.tooltips.add(cellName, {title: name, html: false}));
      this.variableTableSubscriptions.add(atom.tooltips.add(cellValue, {title: value, html: false}));
      this.variableTableSubscriptions.add(atom.tooltips.add(cellAddress, {title: address, html: false}));
    }
  }

  handleStatusUpdated(status) {
    const text = status.getDisplayMessage();
    this.statusDiv.className = `status ${status.getStyleClass()}`;
    this.statusSpan.textContent = text;

    if (this.statusTooltip) {
      this.statusTooltip.dispose();
    }
    this.statusTooltip = atom.tooltips.add(this.statusSpan, {title: text});
  }

  handleEnableDisableSteppingCommands(enabled) {
    if (enabled) {
      this.stepButton.classList.remove('disabled');
      this.stepOverButton.classList.remove('disabled');
      this.runToNextBreakpointButton.classList.remove('disabled');
      this.runToEndOfMethodButton.classList.remove('disabled');
    } else {
      this.stepButton.classList.add('disabled');
      this.stepOverButton.classList.add('disabled');
      this.runToNextBreakpointButton.classList.add('disabled');
      this.runToEndOfMethodButton.classList.add('disabled');
    }
  }

  handleEnableDisableAllBreakpoints(enabled) {
    const text = enabled ? 'Disable All Breakpoints' : 'Enable All Breakpoints';
    this.enableDisableAllBreakpointsButton.textContent = text;

    if (this.enableDisableAllBreakpointsButtonTooltip) {
      this.enableDisableAllBreakpointsButtonTooltip.dispose();
    }
    this.enableDisableAllBreakpointsButtonTooltip = atom.tooltips.add(this.enableDisableAllBreakpointsButton, {
      title: text,
      keyBindingCommand: 'levels-debugger-ruby:enable-disable-all-breakpoints'
    });
  }

  handleEnableDisableAllControls(enabled) {
    if (enabled) {
      this.element.classList.remove('disabled');
    } else {
      this.element.classList.add('disabled');
    }
  }
}