{CompositeDisposable} = require 'atom'

module.exports =
class DebuggerView
  constructor: (@debuggerPresenter) ->
    @element = document.createElement 'div'
    @element.className = 'levels-debugger-ruby'

    @statusDiv = document.createElement 'div'
    @statusDiv.className = 'status'
    @element.appendChild @statusDiv

    @statusSpan = document.createElement 'span'
    @statusSpan.className = 'overflow-ellipsis'
    @statusDiv.appendChild @statusSpan

    commandsHeader = document.createElement 'div'
    commandsHeader.className = 'header'
    @element.appendChild commandsHeader

    commandsHeaderSpan = document.createElement 'span'
    commandsHeaderSpan.className = 'overflow-ellipsis'
    commandsHeaderSpan.textContent = 'Commands'
    commandsHeader.appendChild commandsHeaderSpan

    commandsDiv = document.createElement 'div'
    commandsDiv.className = 'commands'
    @element.appendChild commandsDiv

    toggleBreakpointButton = document.createElement 'button'
    toggleBreakpointButton.className = 'btn'
    toggleBreakpointButton.textContent = 'Toggle Breakpoint'
    toggleBreakpointButton.addEventListener 'click', => @debuggerPresenter.toggleBreakpoint()
    commandsDiv.appendChild toggleBreakpointButton

    removeAllBreakpointsButton = document.createElement 'button'
    removeAllBreakpointsButton.className = 'btn'
    removeAllBreakpointsButton.textContent = 'Remove All Breakpoints'
    removeAllBreakpointsButton.addEventListener 'click', => @debuggerPresenter.removeAllBreakpoints()
    commandsDiv.appendChild removeAllBreakpointsButton

    @enableDisableAllBreakpointsButton = document.createElement 'button'
    @enableDisableAllBreakpointsButton.className = 'btn'
    @enableDisableAllBreakpointsButton.textContent = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.addEventListener 'click', => @debuggerPresenter.enableDisableAllBreakpoints()
    commandsDiv.appendChild @enableDisableAllBreakpointsButton

    @startDebuggingButton = document.createElement 'button'
    @startDebuggingButton.className = 'btn'
    @startDebuggingButton.textContent = 'Start Debugging'
    @startDebuggingButton.addEventListener 'click', => @debuggerPresenter.startDebugging()
    commandsDiv.appendChild @startDebuggingButton

    @stopDebuggingButton = document.createElement 'button'
    @stopDebuggingButton.className = 'btn disabled'
    @stopDebuggingButton.textContent = 'Stop Debugging'
    @stopDebuggingButton.addEventListener 'click', => @debuggerPresenter.stopDebugging()
    commandsDiv.appendChild @stopDebuggingButton

    @stepButton = document.createElement 'button'
    @stepButton.className = 'btn disabled'
    @stepButton.textContent = 'Step'
    @stepButton.addEventListener 'click', => @debuggerPresenter.step()
    commandsDiv.appendChild @stepButton

    @stepOverButton = document.createElement 'button'
    @stepOverButton.className = 'btn disabled'
    @stepOverButton.textContent = 'Step Over'
    @stepOverButton.addEventListener 'click', => @debuggerPresenter.stepOver()
    commandsDiv.appendChild @stepOverButton

    @runToEndOfMethodButton = document.createElement 'button'
    @runToEndOfMethodButton.className = 'btn disabled'
    @runToEndOfMethodButton.textContent = 'Run To End Of Method'
    @runToEndOfMethodButton.addEventListener 'click', => @debuggerPresenter.runToEndOfMethod()
    commandsDiv.appendChild @runToEndOfMethodButton

    @runToNextBreakpointButton = document.createElement 'button'
    @runToNextBreakpointButton.className = 'btn disabled'
    @runToNextBreakpointButton.textContent = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.addEventListener 'click', => @debuggerPresenter.runToNextBreakpoint()
    commandsDiv.appendChild @runToNextBreakpointButton

    @stopReplayButton = document.createElement 'button'
    @stopReplayButton.className = 'btn disabled'
    @stopReplayButton.textContent = 'Stop Replay'
    @stopReplayButton.addEventListener 'click', => @debuggerPresenter.stopReplay()
    commandsDiv.appendChild @stopReplayButton

    variablesHeader = document.createElement 'div'
    variablesHeader.className = 'header'
    @element.appendChild variablesHeader

    variablesHeaderSpan = document.createElement 'span'
    variablesHeaderSpan.className = 'overflow-ellipsis'
    variablesHeaderSpan.textContent = 'Defined Variables'
    variablesHeader.appendChild variablesHeaderSpan

    variablesHeadDiv = document.createElement 'div'
    variablesHeadDiv.className = 'variables-head'
    @element.appendChild variablesHeadDiv

    variablesHeadTable = document.createElement 'table'
    variablesHeadTable.className = 'table'
    variablesHeadDiv.appendChild variablesHeadTable

    variablesHeadTableHead = document.createElement 'thead'
    variablesHeadTable.appendChild variablesHeadTableHead

    variablesHeadTableHeadRow = document.createElement 'tr'
    variablesHeadTableHead.appendChild variablesHeadTableHeadRow

    variablesHeadTableHeadVariable = document.createElement 'th'
    variablesHeadTableHeadVariable.textContent = 'Variable'
    variablesHeadTableHeadVariable.addEventListener 'click', => @debuggerPresenter.flipAndSortVariableTable()
    variablesHeadTableHeadValue = document.createElement 'th'
    variablesHeadTableHeadValue.textContent = 'Value'
    variablesHeadTableHeadAddress = document.createElement 'th'
    variablesHeadTableHeadAddress.textContent = 'Address'
    variablesHeadTableHeadRow.appendChild variablesHeadTableHeadVariable
    variablesHeadTableHeadRow.appendChild variablesHeadTableHeadValue
    variablesHeadTableHeadRow.appendChild variablesHeadTableHeadAddress

    variablesBodyDiv = document.createElement 'div'
    variablesBodyDiv.className = 'variables-body'
    @element.appendChild variablesBodyDiv

    variablesBodyTable = document.createElement 'table'
    variablesBodyTable.className = 'table'
    variablesBodyDiv.appendChild variablesBodyTable

    @variablesBodyTableBody = document.createElement 'tbody'
    variablesBodyTable.appendChild @variablesBodyTableBody

    stackHeader = document.createElement 'div'
    stackHeader.className = 'header'
    @element.appendChild stackHeader

    stackHeaderSpan = document.createElement 'span'
    stackHeaderSpan.className = 'overflow-ellipsis'
    stackHeaderSpan.textContent = 'Call Stack'
    stackHeader.appendChild stackHeaderSpan

    stackHeadDiv = document.createElement 'div'
    stackHeadDiv.className = 'stack-head'
    @element.appendChild stackHeadDiv

    stackHeadTable = document.createElement 'table'
    stackHeadTable.className = 'table'
    stackHeadDiv.appendChild stackHeadTable

    stackHeadTableHead = document.createElement 'thead'
    stackHeadTable.appendChild stackHeadTableHead

    stackHeadTableHeadRow = document.createElement 'tr'
    stackHeadTableHead.appendChild stackHeadTableHeadRow

    stackHeadTableHeadCall = document.createElement 'th'
    stackHeadTableHeadCall.textContent = 'Call'
    stackHeadTableHeadReplay = document.createElement 'th'
    stackHeadTableHeadReplay.textContent = 'Replay'
    stackHeadTableHeadRow.appendChild stackHeadTableHeadCall
    stackHeadTableHeadRow.appendChild stackHeadTableHeadReplay

    stackBodyDiv = document.createElement 'div'
    stackBodyDiv.className = 'stack-body'
    @element.appendChild stackBodyDiv

    stackBodyTable = document.createElement 'table'
    stackBodyTable.className = 'table'
    stackBodyDiv.appendChild stackBodyTable

    @stackBodyTableBody = document.createElement 'tbody'
    stackBodyTable.appendChild @stackBodyTableBody

    @subscriptions = new CompositeDisposable

    @subscriptions.add @debuggerPresenter.onRunning => @handleRunning()
    @subscriptions.add @debuggerPresenter.onStopped => @handleStopped()
    @subscriptions.add @debuggerPresenter.onReplayStarted => @handleReplayStarted()
    @subscriptions.add @debuggerPresenter.onReplayStopped => @handleReplayStopped()
    @subscriptions.add @debuggerPresenter.onCallStackUpdated => @updateCallStack()
    @subscriptions.add @debuggerPresenter.onVariableTableUpdated => @updateVariableTable()
    @subscriptions.add @debuggerPresenter.onStatusUpdated (status) => @handleStatusUpdated status
    @subscriptions.add @debuggerPresenter.onAutoSteppingEnabled => @handleEnableDisableSteppingCommands false
    @subscriptions.add @debuggerPresenter.onAutoSteppingDisabled => @handleEnableDisableSteppingCommands true
    @subscriptions.add @debuggerPresenter.onEnableDisableAllBreakpoints (enable) => @handleEnableDisableAllBreakpoints enable
    @subscriptions.add @debuggerPresenter.onEnableDisableAllControls (enable) => @handleEnableDisableAllControls enable

    @subscriptions.add atom.tooltips.add toggleBreakpointButton,
      title: toggleBreakpointButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:toggle-breakpoint'
    @subscriptions.add atom.tooltips.add removeAllBreakpointsButton,
      title: removeAllBreakpointsButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:remove-all-breakpoints'
    @subscriptions.add atom.tooltips.add @startDebuggingButton,
      title: @startDebuggingButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:start-debugging'
    @subscriptions.add atom.tooltips.add @stopDebuggingButton,
      title: @stopDebuggingButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:stop-debugging'
    @subscriptions.add atom.tooltips.add @stepButton,
      title: @stepButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:step'
    @subscriptions.add atom.tooltips.add @stepOverButton,
      title: @stepOverButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:step-over'
    @subscriptions.add atom.tooltips.add @runToEndOfMethodButton,
      title: @runToEndOfMethodButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:run-to-end-of-method'
    @subscriptions.add atom.tooltips.add @runToNextBreakpointButton,
      title: @runToNextBreakpointButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:run-to-next-breakpoint'
    @subscriptions.add atom.tooltips.add @stopReplayButton,
      title: @stopReplayButton.textContent
      keyBindingCommand: 'levels-debugger-ruby:stop-replay'

    @debuggerPresenter.initDebuggerView()

  destroy: ->
    @element.remove()
    @subscriptions.dispose()
    @statusTooltip?.dispose()
    @enableDisableAllBreakpointsButtonTooltip?.dispose()
    @variableTableSubscriptions?.dispose()
    @callStackSubscriptions?.dispose()
    return

  getTitle: ->
    return 'Levels Debugger Ruby'

  getDefaultLocation: ->
    return 'right'

  getAllowedLocations: ->
    return ['left', 'right']

  getURI: ->
    return 'atom://levels-debugger-ruby'

  getElement: ->
    return @element

  enableDisableCommandsOnStartStop: (enabled) ->
    if enabled
      @startDebuggingButton.classList.add 'disabled'
      @stopDebuggingButton.classList.remove 'disabled'
    else
      @startDebuggingButton.classList.remove 'disabled'
      @stopDebuggingButton.classList.add 'disabled'
    return

  handleRunning: ->
    @enableDisableCommandsOnStartStop true
    return

  handleStopped: ->
    @updateVariableTable()
    @updateCallStack()
    @enableDisableCommandsOnStartStop false
    @stopReplayButton.classList.add 'disabled'
    return

  handleReplayStarted: ->
    @stopReplayButton.classList.remove 'disabled'
    return

  handleReplayStopped: ->
    @stopReplayButton.classList.add 'disabled'
    return

  updateCallStack: ->
    @stackBodyTableBody.innerHTML = ''
    @callStackSubscriptions?.dispose()
    @callStackSubscriptions = new CompositeDisposable

    for entry in @debuggerPresenter.getCallStack() by -1
      methodAndArgs = entry.getMethodAndArgs()
      callId = entry.getCallId()

      row = document.createElement 'tr'
      cellCall = document.createElement 'td'
      cellCall.textContent = methodAndArgs
      cellReplay = document.createElement 'td'
      replayButton = document.createElement 'button'
      replayButton.className = 'btn'
      replayButton.textContent = 'Replay'
      replayButton.dataset.callId = callId
      replayButton.addEventListener 'click', (event) => @debuggerPresenter.startReplay event.target
      cellReplay.appendChild replayButton
      row.appendChild cellCall
      row.appendChild cellReplay
      @stackBodyTableBody.appendChild row

      @callStackSubscriptions.add atom.tooltips.add replayButton, title: replayButton.textContent
      @callStackSubscriptions.add atom.tooltips.add cellCall, {title: methodAndArgs, html: false}

    return

  updateVariableTable: ->
    @variablesBodyTableBody.innerHTML = ''
    @variableTableSubscriptions?.dispose()
    @variableTableSubscriptions = new CompositeDisposable

    for entry in @debuggerPresenter.getVariableTable()
      name = entry.getName()
      value = entry.getValue()
      address = entry.getAddress()

      row = document.createElement 'tr'
      if entry.isChanged()
        row.className = 'highlight'

      cellName = document.createElement 'td'
      cellName.textContent = name
      cellValue = document.createElement 'td'
      cellValue.textContent = value
      cellAddress = document.createElement 'td'
      cellAddress.textContent = address
      row.appendChild cellName
      row.appendChild cellValue
      row.appendChild cellAddress

      @variablesBodyTableBody.appendChild row

      @variableTableSubscriptions.add atom.tooltips.add cellName, {title: name, html: false}
      @variableTableSubscriptions.add atom.tooltips.add cellValue, {title: value, html: false}
      @variableTableSubscriptions.add atom.tooltips.add cellAddress, {title: address, html: false}

    return

  handleStatusUpdated: (status) ->
    text = status.getDisplayMessage()
    @statusDiv.className = 'status ' + status.getStyleClass()
    @statusSpan.textContent = text
    @statusTooltip?.dispose()
    @statusTooltip = atom.tooltips.add @statusSpan, title: text
    return

  handleEnableDisableSteppingCommands: (enabled) ->
    if enabled
      @stepButton.classList.remove 'disabled'
      @stepOverButton.classList.remove 'disabled'
      @runToNextBreakpointButton.classList.remove 'disabled'
      @runToEndOfMethodButton.classList.remove 'disabled'
    else
      @stepButton.classList.add 'disabled'
      @stepOverButton.classList.add 'disabled'
      @runToNextBreakpointButton.classList.add 'disabled'
      @runToEndOfMethodButton.classList.add 'disabled'
    return

  handleEnableDisableAllBreakpoints: (enabled) ->
    text = if enabled then 'Disable All Breakpoints' else 'Enable All Breakpoints'
    @enableDisableAllBreakpointsButton.textContent = text
    @enableDisableAllBreakpointsButtonTooltip?.dispose()
    @enableDisableAllBreakpointsButtonTooltip = atom.tooltips.add @enableDisableAllBreakpointsButton,
      title: text
      keyBindingCommand: 'levels-debugger-ruby:enable-disable-all-breakpoints'
    return

  handleEnableDisableAllControls: (enabled) ->
    if enabled
      @element.classList.remove 'disabled'
    else
      @element.classList.add 'disabled'
    return