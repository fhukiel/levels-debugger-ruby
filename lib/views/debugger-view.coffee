{CompositeDisposable} = require 'atom'
MessageUtils          = require '../messaging/message-utils'

module.exports =
class DebuggerView
  constructor: (@debuggerPresenter) ->
    @element = document.createElement 'div'
    @element.className = 'levels-debugger-ruby'

    @statusDiv = document.createElement 'div'
    @statusDiv.className = 'status'
    @element.appendChild @statusDiv

    @commandsHeader = document.createElement 'div'
    @commandsHeader.className = 'header'
    @commandsHeader.innerHTML = 'Commands'
    @commandsHeader.title = 'Commands'
    @element.appendChild @commandsHeader

    @commandsDiv = document.createElement 'div'
    @commandsDiv.className = 'commands'
    @element.appendChild @commandsDiv

    @toggleBreakpointButton = document.createElement 'button'
    @toggleBreakpointButton.className = 'btn'
    @toggleBreakpointButton.innerHTML = 'Toggle Breakpoint'
    @toggleBreakpointButton.title = 'Toggle Breakpoint'
    @toggleBreakpointButton.addEventListener 'click', => @toggleBreakpoint()
    @commandsDiv.appendChild @toggleBreakpointButton

    @removeAllBreakpointsButton = document.createElement 'button'
    @removeAllBreakpointsButton.className = 'btn'
    @removeAllBreakpointsButton.innerHTML = 'Remove All Breakpoints'
    @removeAllBreakpointsButton.title = 'Remove All Breakpoints'
    @removeAllBreakpointsButton.addEventListener 'click', => @removeAllBreakpoints()
    @commandsDiv.appendChild @removeAllBreakpointsButton

    @enableDisableAllBreakpointsButton = document.createElement 'button'
    @enableDisableAllBreakpointsButton.className = 'btn'
    @enableDisableAllBreakpointsButton.innerHTML = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.title = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.addEventListener 'click', => @enableDisableAllBreakpoints()
    @commandsDiv.appendChild @enableDisableAllBreakpointsButton

    @startDebuggingButton = document.createElement 'button'
    @startDebuggingButton.className = 'btn'
    @startDebuggingButton.innerHTML = 'Start Debugging'
    @startDebuggingButton.title = 'Start Debugging'
    @startDebuggingButton.addEventListener 'click', => @startDebugging()
    @commandsDiv.appendChild @startDebuggingButton

    @stopDebuggingButton = document.createElement 'button'
    @stopDebuggingButton.className = 'btn'
    @stopDebuggingButton.disabled = true
    @stopDebuggingButton.innerHTML = 'Stop Debugging'
    @stopDebuggingButton.title = 'Stop Debugging'
    @stopDebuggingButton.addEventListener 'click', => @stopDebugging()
    @commandsDiv.appendChild @stopDebuggingButton

    @stepButton = document.createElement 'button'
    @stepButton.className = 'btn'
    @stepButton.disabled = true
    @stepButton.innerHTML = 'Step'
    @stepButton.title = 'Step'
    @stepButton.addEventListener 'click', => @step()
    @commandsDiv.appendChild @stepButton

    @stepOverButton = document.createElement 'button'
    @stepOverButton.className = 'btn'
    @stepOverButton.disabled = true
    @stepOverButton.innerHTML = 'Step Over'
    @stepOverButton.title = 'Step Over'
    @stepOverButton.addEventListener 'click', => @stepOver()
    @commandsDiv.appendChild @stepOverButton

    @runToEndOfMethodButton = document.createElement 'button'
    @runToEndOfMethodButton.className = 'btn'
    @runToEndOfMethodButton.disabled = true
    @runToEndOfMethodButton.innerHTML = 'Run To End Of Method'
    @runToEndOfMethodButton.title = 'Run To End Of Method'
    @runToEndOfMethodButton.addEventListener 'click', => @runToEndOfMethod()
    @commandsDiv.appendChild @runToEndOfMethodButton

    @runToNextBreakpointButton = document.createElement 'button'
    @runToNextBreakpointButton.className = 'btn'
    @runToNextBreakpointButton.disabled = true
    @runToNextBreakpointButton.innerHTML = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.title = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.addEventListener 'click', => @runToNextBreakpoint()
    @commandsDiv.appendChild @runToNextBreakpointButton

    @stopReplayButton = document.createElement 'button'
    @stopReplayButton.className = 'btn'
    @stopReplayButton.disabled = true
    @stopReplayButton.innerHTML = 'Stop Replay'
    @stopReplayButton.title = 'Stop Replay'
    @stopReplayButton.addEventListener 'click', => @stopReplay()
    @commandsDiv.appendChild @stopReplayButton

    @variablesHeader = document.createElement 'div'
    @variablesHeader.className = 'header'
    @variablesHeader.innerHTML = 'Defined Variables'
    @variablesHeader.title = 'Defined Variables'
    @element.appendChild @variablesHeader

    @variablesDiv = document.createElement 'div'
    @variablesDiv.className = 'variables'
    @element.appendChild @variablesDiv

    @variablesTable = document.createElement 'table'
    @variablesTable.className = 'table'
    @variablesDiv.appendChild @variablesTable

    @variablesTableHead = document.createElement 'thead'
    @variablesTable.appendChild @variablesTableHead

    @variablesTableBody = document.createElement 'tbody'
    @variablesTable.appendChild @variablesTableBody

    @variablesTableHeader = document.createElement 'tr'
    @variablesTableHead.appendChild @variablesTableHeader

    @variablesTableHeaderVariable = document.createElement 'th'
    @variablesTableHeaderVariable.innerHTML = 'Variable'
    @variablesTableHeaderVariable.title = 'Variable'
    @variablesTableHeaderVariable.addEventListener 'click', => @sortVariableTableByName()
    @variablesTableHeaderValue = document.createElement 'th'
    @variablesTableHeaderValue.innerHTML = 'Value'
    @variablesTableHeaderValue.title = 'Value'
    @variablesTableHeaderAddress = document.createElement 'th'
    @variablesTableHeaderAddress.innerHTML = 'Address'
    @variablesTableHeaderAddress.title = 'Address'
    @variablesTableHeader.appendChild @variablesTableHeaderVariable
    @variablesTableHeader.appendChild @variablesTableHeaderValue
    @variablesTableHeader.appendChild @variablesTableHeaderAddress

    @stackHeader = document.createElement 'div'
    @stackHeader.className = 'header'
    @stackHeader.innerHTML = 'Call Stack'
    @stackHeader.title = 'Call Stack'
    @element.appendChild @stackHeader

    @stackDiv = document.createElement 'div'
    @stackDiv.className = 'stack'
    @element.appendChild @stackDiv

    @stackTable = document.createElement 'table'
    @stackTable.className = 'table'
    @stackDiv.appendChild @stackTable

    @stackTableHead = document.createElement 'thead'
    @stackTable.appendChild @stackTableHead

    @stackTableBody = document.createElement 'tbody'
    @stackTable.appendChild @stackTableBody

    @stackTableHeader = document.createElement 'tr'
    @stackTableHead.appendChild @stackTableHeader

    @stackTableHeaderCall = document.createElement 'th'
    @stackTableHeaderCall.innerHTML = 'Call'
    @stackTableHeaderCall.title = 'Call'
    @stackTableHeaderReplay = document.createElement 'th'
    @stackTableHeaderReplay.innerHTML = 'Replay'
    @stackTableHeaderReplay.title = 'Replay'
    @stackTableHeader.appendChild @stackTableHeaderCall
    @stackTableHeader.appendChild @stackTableHeaderReplay

    @reset()

    @subscriptions = new CompositeDisposable
    @subscriptions.add @debuggerPresenter.onRunning => @handleRunning()
    @subscriptions.add @debuggerPresenter.onStopped => @handleStopped()
    @subscriptions.add @debuggerPresenter.onCallStackUpdated => @updateCallStack @debuggerPresenter
    @subscriptions.add @debuggerPresenter.onVariableTableUpdated => @updateVariableTable @debuggerPresenter
    @subscriptions.add @debuggerPresenter.onStatusUpdated (status) => @handleStatusUpdated status
    @subscriptions.add @debuggerPresenter.onAutoSteppingEnabled => @handleEnableDisableSteppingCommands false
    @subscriptions.add @debuggerPresenter.onAutoSteppingDisabled => @handleEnableDisableSteppingCommands true
    @subscriptions.add @debuggerPresenter.onEnableDisableAllBreakpoints (enable) => @handleEnableDisableAllBreakpoints enable
    @subscriptions.add @debuggerPresenter.onEnableDisableAllControls (enable) => @handleEnableDisableAllControls enable

  destroy: ->
    @element.remove()
    @subscriptions.dispose()

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

  startDebugging: ->
    @debuggerPresenter.startDebugging()

  stopDebugging: ->
    @debuggerPresenter.stopDebugging()

  step: ->
    @debuggerPresenter.step()

  stepOver: ->
    @debuggerPresenter.stepOver()

  runToNextBreakpoint: ->
    @debuggerPresenter.runToNextBreakpoint()

  runToEndOfMethod: ->
    @debuggerPresenter.runToEndOfMethod()

  toggleBreakpoint: ->
    @debuggerPresenter.toggleBreakpoint()

  removeAllBreakpoints: ->
    @debuggerPresenter.removeAllBreakpoints()

  enableDisableAllBreakpoints: ->
    @debuggerPresenter.enableDisableAllBreakpoints()

  startReplay: (event) ->
    @stopReplayButton.disabled = false
    @debuggerPresenter.startReplay event.target

  stopReplay: ->
    @stopReplayButton.disabled = true
    @debuggerPresenter.stopReplay()

  enableDisableCommandsOnStartStop: (enabled) ->
    @stopDebuggingButton.disabled = !enabled
    @handleEnableDisableSteppingCommands enabled

  updateVariableTable: (debuggerPresenter) ->
    @clearTableBody @variablesTableBody

    if debuggerPresenter?
      for entry in debuggerPresenter.getVariableTable()
        name = "#{entry.getName()}"
        value = "#{entry.getValue()}"
        address = "#{entry.getAddress()}"
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
        @variablesTableBody.appendChild row

  updateCallStack: (debuggerPresenter) ->
    @clearTableBody @stackTableBody

    if debuggerPresenter?
      for value in debuggerPresenter.getCallStack() by -1
        splitted = value.split MessageUtils.getAssignSymbol()
        methodAndArgs = splitted[0]
        callID = splitted[1]

        row = document.createElement 'tr'
        cellCall = document.createElement 'td'
        cellCall.innerHTML = methodAndArgs
        cellCall.title = methodAndArgs
        cellReplay = document.createElement 'td'
        replayButton = document.createElement 'button'
        replayButton.className = 'btn'
        replayButton.innerHTML = 'Replay'
        replayButton.title = 'Replay'
        replayButton.setAttribute 'call-id', callID
        replayButton.addEventListener 'click', (event) => @startReplay event
        cellReplay.appendChild replayButton
        row.appendChild cellCall
        row.appendChild cellReplay
        @stackTableBody.appendChild row

  reset: ->
    @updateCallStack undefined
    @updateVariableTable undefined

  sortVariableTableByName: ->
    @debuggerPresenter.flipAndSortVariableTable()

  handleRunning: ->
    @reset()
    @enableDisableCommandsOnStartStop true
    @startDebuggingButton.disabled = true

  handleStopped: ->
    @reset()
    @enableDisableCommandsOnStartStop false
    @stopReplayButton.disabled = true
    @startDebuggingButton.disabled = false

  handleEnableDisableSteppingCommands: (enabled) ->
    disabled = !enabled
    @stepButton.disabled = disabled
    @stepOverButton.disabled = disabled
    @runToNextBreakpointButton.disabled = disabled
    @runToEndOfMethodButton.disabled = disabled

  handleEnableDisableAllBreakpoints: (enabled) ->
    text = if enabled then 'Disable All Breakpoints' else 'Enable All Breakpoints'
    @enableDisableAllBreakpointsButton.innerHTML = text
    @enableDisableAllBreakpointsButton.title = text

  handleStatusUpdated: (event) ->
    @statusDiv.className = 'status ' + event.getStyleClass()
    @statusDiv.innerHTML = event.getDisplayMessage()
    @statusDiv.title = event.getDisplayMessage()
    @handleEnableDisableSteppingCommands !event.isBlockingStatus()

  handleEnableDisableAllControls: (enabled) ->
    @element.setAttribute 'disabled', !enabled

  clearTableBody: (tableBody) ->
    i = tableBody.rows.length
    while i-- > 0
      tableBody.deleteRow i