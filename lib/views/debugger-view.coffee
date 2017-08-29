{CompositeDisposable} = require 'atom'

module.exports =
class DebuggerView
  constructor: (@debuggerPresenter) ->
    @element = document.createElement 'div'
    @element.className = 'levels-debugger-ruby'

    @statusDiv = document.createElement 'div'
    @statusDiv.className = 'status'
    @element.appendChild @statusDiv

    commandsHeader = document.createElement 'div'
    commandsHeader.className = 'header'
    commandsHeader.innerHTML = 'Commands'
    commandsHeader.title = 'Commands'
    @element.appendChild commandsHeader

    commandsDiv = document.createElement 'div'
    commandsDiv.className = 'commands'
    @element.appendChild commandsDiv

    toggleBreakpointButton = document.createElement 'button'
    toggleBreakpointButton.className = 'btn'
    toggleBreakpointButton.innerHTML = 'Toggle Breakpoint'
    toggleBreakpointButton.title = 'Toggle Breakpoint'
    toggleBreakpointButton.addEventListener 'click', => @toggleBreakpoint()
    commandsDiv.appendChild toggleBreakpointButton

    removeAllBreakpointsButton = document.createElement 'button'
    removeAllBreakpointsButton.className = 'btn'
    removeAllBreakpointsButton.innerHTML = 'Remove All Breakpoints'
    removeAllBreakpointsButton.title = 'Remove All Breakpoints'
    removeAllBreakpointsButton.addEventListener 'click', => @removeAllBreakpoints()
    commandsDiv.appendChild removeAllBreakpointsButton

    @enableDisableAllBreakpointsButton = document.createElement 'button'
    @enableDisableAllBreakpointsButton.className = 'btn'
    @enableDisableAllBreakpointsButton.innerHTML = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.title = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.addEventListener 'click', => @enableDisableAllBreakpoints()
    commandsDiv.appendChild @enableDisableAllBreakpointsButton

    @startDebuggingButton = document.createElement 'button'
    @startDebuggingButton.className = 'btn'
    @startDebuggingButton.innerHTML = 'Start Debugging'
    @startDebuggingButton.title = 'Start Debugging'
    @startDebuggingButton.addEventListener 'click', => @startDebugging()
    commandsDiv.appendChild @startDebuggingButton

    @stopDebuggingButton = document.createElement 'button'
    @stopDebuggingButton.className = 'btn'
    @stopDebuggingButton.disabled = true
    @stopDebuggingButton.innerHTML = 'Stop Debugging'
    @stopDebuggingButton.title = 'Stop Debugging'
    @stopDebuggingButton.addEventListener 'click', => @stopDebugging()
    commandsDiv.appendChild @stopDebuggingButton

    @stepButton = document.createElement 'button'
    @stepButton.className = 'btn'
    @stepButton.disabled = true
    @stepButton.innerHTML = 'Step'
    @stepButton.title = 'Step'
    @stepButton.addEventListener 'click', => @step()
    commandsDiv.appendChild @stepButton

    @stepOverButton = document.createElement 'button'
    @stepOverButton.className = 'btn'
    @stepOverButton.disabled = true
    @stepOverButton.innerHTML = 'Step Over'
    @stepOverButton.title = 'Step Over'
    @stepOverButton.addEventListener 'click', => @stepOver()
    commandsDiv.appendChild @stepOverButton

    @runToEndOfMethodButton = document.createElement 'button'
    @runToEndOfMethodButton.className = 'btn'
    @runToEndOfMethodButton.disabled = true
    @runToEndOfMethodButton.innerHTML = 'Run To End Of Method'
    @runToEndOfMethodButton.title = 'Run To End Of Method'
    @runToEndOfMethodButton.addEventListener 'click', => @runToEndOfMethod()
    commandsDiv.appendChild @runToEndOfMethodButton

    @runToNextBreakpointButton = document.createElement 'button'
    @runToNextBreakpointButton.className = 'btn'
    @runToNextBreakpointButton.disabled = true
    @runToNextBreakpointButton.innerHTML = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.title = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.addEventListener 'click', => @runToNextBreakpoint()
    commandsDiv.appendChild @runToNextBreakpointButton

    @stopReplayButton = document.createElement 'button'
    @stopReplayButton.className = 'btn'
    @stopReplayButton.disabled = true
    @stopReplayButton.innerHTML = 'Stop Replay'
    @stopReplayButton.title = 'Stop Replay'
    @stopReplayButton.addEventListener 'click', => @stopReplay()
    commandsDiv.appendChild @stopReplayButton

    variablesHeader = document.createElement 'div'
    variablesHeader.className = 'header'
    variablesHeader.innerHTML = 'Defined Variables'
    variablesHeader.title = 'Defined Variables'
    @element.appendChild variablesHeader

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
    variablesHeadTableHeadVariable.innerHTML = 'Variable'
    variablesHeadTableHeadVariable.title = 'Variable'
    variablesHeadTableHeadVariable.addEventListener 'click', => @sortVariableTableByName()
    variablesHeadTableHeadValue = document.createElement 'th'
    variablesHeadTableHeadValue.innerHTML = 'Value'
    variablesHeadTableHeadValue.title = 'Value'
    variablesHeadTableHeadAddress = document.createElement 'th'
    variablesHeadTableHeadAddress.innerHTML = 'Address'
    variablesHeadTableHeadAddress.title = 'Address'
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
    stackHeader.innerHTML = 'Call Stack'
    stackHeader.title = 'Call Stack'
    @element.appendChild stackHeader

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
    stackHeadTableHeadCall.innerHTML = 'Call'
    stackHeadTableHeadCall.title = 'Call'
    stackHeadTableHeadReplay = document.createElement 'th'
    stackHeadTableHeadReplay.innerHTML = 'Replay'
    stackHeadTableHeadReplay.title = 'Replay'
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

    @debuggerPresenter.initDebuggerView()

  destroy: ->
    @element.remove()
    @subscriptions.dispose()
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

  toggleBreakpoint: ->
    @debuggerPresenter.toggleBreakpoint()

  removeAllBreakpoints: ->
    @debuggerPresenter.removeAllBreakpoints()

  enableDisableAllBreakpoints: ->
    @debuggerPresenter.enableDisableAllBreakpoints()

  startDebugging: ->
    @debuggerPresenter.startDebugging()

  stopDebugging: ->
    @debuggerPresenter.stopDebugging()

  step: ->
    @debuggerPresenter.step()

  stepOver: ->
    @debuggerPresenter.stepOver()

  runToEndOfMethod: ->
    @debuggerPresenter.runToEndOfMethod()

  runToNextBreakpoint: ->
    @debuggerPresenter.runToNextBreakpoint()

  startReplay: (event) ->
    @debuggerPresenter.startReplay event.target

  stopReplay: ->
    @debuggerPresenter.stopReplay()

  clearTableBody: (tableBody) ->
    i = tableBody.rows.length
    while i-- > 0
      tableBody.deleteRow i
    return

  clearTables: ->
    @clearTableBody @stackBodyTableBody
    @clearTableBody @variablesBodyTableBody
    return

  sortVariableTableByName: ->
    @debuggerPresenter.flipAndSortVariableTable()

  enableDisableCommandsOnStartStop: (enabled) ->
    @startDebuggingButton.disabled = enabled
    @stopDebuggingButton.disabled = !enabled
    return

  handleRunning: ->
    @enableDisableCommandsOnStartStop true
    return

  handleStopped: ->
    @clearTables()
    @enableDisableCommandsOnStartStop false
    @stopReplayButton.disabled = true
    return

  handleReplayStarted: ->
    @stopReplayButton.disabled = false
    return

  handleReplayStopped: ->
    @stopReplayButton.disabled = true
    return

  updateCallStack: ->
    @clearTableBody @stackBodyTableBody

    for entry in @debuggerPresenter.getCallStack() by -1
      methodAndArgs = entry.getMethodAndArgs()
      callID = entry.getCallID()

      row = document.createElement 'tr'
      cellCall = document.createElement 'td'
      cellCall.innerHTML = methodAndArgs
      cellCall.title = methodAndArgs
      cellReplay = document.createElement 'td'
      replayButton = document.createElement 'button'
      replayButton.className = 'btn'
      replayButton.innerHTML = 'Replay'
      replayButton.title = 'Replay'
      replayButton.setAttribute 'data-call-id', callID
      replayButton.addEventListener 'click', (event) => @startReplay event
      cellReplay.appendChild replayButton
      row.appendChild cellCall
      row.appendChild cellReplay
      @stackBodyTableBody.appendChild row

    return

  updateVariableTable: ->
    @clearTableBody @variablesBodyTableBody

    for entry in @debuggerPresenter.getVariableTable()
      name = entry.getName()
      value = entry.getValue()
      address = entry.getAddress()
      rowClass = if entry.isChanged() then 'highlight' else ''

      row = document.createElement 'tr'
      row.className = rowClass
      cellName = document.createElement 'td'
      cellName.innerHTML = name
      cellName.title = name
      cellValue = document.createElement 'td'
      cellValue.innerHTML = value
      cellValue.title = value
      cellAddress = document.createElement 'td'
      cellAddress.innerHTML = address
      cellAddress.title = address
      row.appendChild cellName
      row.appendChild cellValue
      row.appendChild cellAddress
      @variablesBodyTableBody.appendChild row

    return

  handleStatusUpdated: (status) ->
    text = status.getDisplayMessage()
    @statusDiv.className = 'status ' + status.getStyleClass()
    @statusDiv.innerHTML = text
    @statusDiv.title = text
    return

  handleEnableDisableSteppingCommands: (enabled) ->
    disabled = !enabled
    @stepButton.disabled = disabled
    @stepOverButton.disabled = disabled
    @runToNextBreakpointButton.disabled = disabled
    @runToEndOfMethodButton.disabled = disabled
    return

  handleEnableDisableAllBreakpoints: (enabled) ->
    text = if enabled then 'Disable All Breakpoints' else 'Enable All Breakpoints'
    @enableDisableAllBreakpointsButton.innerHTML = text
    @enableDisableAllBreakpointsButton.title = text
    return

  handleEnableDisableAllControls: (enabled) ->
    @element.setAttribute 'disabled', !enabled
    return