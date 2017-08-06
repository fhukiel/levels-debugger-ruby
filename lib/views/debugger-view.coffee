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

    @buttonsHeader = document.createElement 'div'
    @buttonsHeader.className = 'header'
    @buttonsHeader.innerHTML = 'Commands'
    @element.appendChild @buttonsHeader

    @buttonsDiv = document.createElement 'div'
    @buttonsDiv.className = 'buttons'
    @element.appendChild @buttonsDiv

    @toggleBreakpointButton = document.createElement 'button'
    @toggleBreakpointButton.className = 'btn'
    @toggleBreakpointButton.innerHTML = 'Toggle Breakpoint'
    @toggleBreakpointButton.addEventListener 'click', => @toggleBreakpoint()
    @buttonsDiv.appendChild @toggleBreakpointButton

    @removeAllBreakpointsButton = document.createElement 'button'
    @removeAllBreakpointsButton.className = 'btn'
    @removeAllBreakpointsButton.innerHTML = 'Remove All Breakpoints'
    @removeAllBreakpointsButton.addEventListener 'click', => @removeAllBreakpoints()
    @buttonsDiv.appendChild @removeAllBreakpointsButton

    @enableDisableAllBreakpointsButton = document.createElement 'button'
    @enableDisableAllBreakpointsButton.className = 'btn'
    @enableDisableAllBreakpointsButton.innerHTML = 'Disable All Breakpoints'
    @enableDisableAllBreakpointsButton.addEventListener 'click', => @enableDisableAllBreakpoints()
    @buttonsDiv.appendChild @enableDisableAllBreakpointsButton

    @startDebuggingButton = document.createElement 'button'
    @startDebuggingButton.className = 'btn'
    @startDebuggingButton.innerHTML = 'Start Debugging'
    @startDebuggingButton.addEventListener 'click', => @startDebugging()
    @buttonsDiv.appendChild @startDebuggingButton

    @stopDebuggingButton = document.createElement 'button'
    @stopDebuggingButton.className = 'btn'
    @stopDebuggingButton.disabled = true
    @stopDebuggingButton.innerHTML = 'Stop Debugging'
    @stopDebuggingButton.addEventListener 'click', => @stopDebugging()
    @buttonsDiv.appendChild @stopDebuggingButton

    @stepButton = document.createElement 'button'
    @stepButton.className = 'btn'
    @stepButton.disabled = true
    @stepButton.innerHTML = 'Step'
    @stepButton.addEventListener 'click', => @step()
    @buttonsDiv.appendChild @stepButton

    @stepOverButton = document.createElement 'button'
    @stepOverButton.className = 'btn'
    @stepOverButton.disabled = true
    @stepOverButton.innerHTML = 'Step Over'
    @stepOverButton.addEventListener 'click', => @stepOver()
    @buttonsDiv.appendChild @stepOverButton

    @runToEndOfMethodButton = document.createElement 'button'
    @runToEndOfMethodButton.className = 'btn'
    @runToEndOfMethodButton.disabled = true
    @runToEndOfMethodButton.innerHTML = 'Run To End Of Method'
    @runToEndOfMethodButton.addEventListener 'click', => @runToEndOfMethod()
    @buttonsDiv.appendChild @runToEndOfMethodButton

    @runToNextBreakpointButton = document.createElement 'button'
    @runToNextBreakpointButton.className = 'btn'
    @runToNextBreakpointButton.disabled = true
    @runToNextBreakpointButton.innerHTML = 'Run To Next Breakpoint'
    @runToNextBreakpointButton.addEventListener 'click', => @runToNextBreakpoint()
    @buttonsDiv.appendChild @runToNextBreakpointButton

    @stopReplayButton = document.createElement 'button'
    @stopReplayButton.className = 'btn'
    @stopReplayButton.disabled = true
    @stopReplayButton.innerHTML = 'Stop Replay'
    @stopReplayButton.addEventListener 'click', => @stopReplay()
    @buttonsDiv.appendChild @stopReplayButton

    @variablesHeader = document.createElement 'div'
    @variablesHeader.className = 'header'
    @variablesHeader.innerHTML = 'Defined Variables'
    @element.appendChild @variablesHeader

    @variablesDiv = document.createElement 'div'
    @variablesDiv.className = 'variables'
    @element.appendChild @variablesDiv

    @variablesTable = document.createElement 'table'
    @variablesTable.className = 'table'
    @variablesDiv.appendChild @variablesTable

    @variablesTableHeader = document.createElement 'tr'
    @variablesTable.appendChild @variablesTableHeader

    @variablesTableHeaderVariable = document.createElement 'th'
    @variablesTableHeaderVariable.innerHTML = 'Variable'
    @variablesTableHeaderVariable.addEventListener 'dblclick', => @sortVariableTableByName()
    @variablesTableHeaderValue = document.createElement 'th'
    @variablesTableHeaderValue.innerHTML = 'Value'
    @variablesTableHeaderAddress = document.createElement 'th'
    @variablesTableHeaderAddress.innerHTML = 'Address'
    @variablesTableHeader.appendChild @variablesTableHeaderVariable
    @variablesTableHeader.appendChild @variablesTableHeaderValue
    @variablesTableHeader.appendChild @variablesTableHeaderAddress

    @stackHeader = document.createElement 'div'
    @stackHeader.className = 'header'
    @stackHeader.innerHTML = 'Call Stack'
    @element.appendChild @stackHeader

    @stackDiv = document.createElement 'div'
    @stackDiv.className = 'stack'
    @element.appendChild @stackDiv

    @stackTable = document.createElement 'table'
    @stackTable.className = 'table'
    @stackDiv.appendChild @stackTable

    @stackTableHeader = document.createElement 'tr'
    @stackTable.appendChild @stackTableHeader

    @stackTableHeaderCall = document.createElement 'th'
    @stackTableHeaderCall.innerHTML = 'Call'
    @stackTableHeaderReplay = document.createElement 'th'
    @stackTableHeaderReplay.innerHTML = 'Replay'
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
    @clearTable @variablesTable

    if debuggerPresenter?
      for entry in debuggerPresenter.getVariableTable()
        name = "#{entry.getName()}"
        value = "#{entry.getValue()}"
        address = "#{entry.getAddress()}"
        cellClass = if entry.isChanged() then 'highlight' else ''

        row = document.createElement 'tr'
        row.className = cellClass
        rowName = document.createElement 'td'
        rowName.innerHTML = name
        rowValue = document.createElement 'td'
        rowValue.innerHTML = value
        rowAddress = document.createElement 'td'
        rowAddress.innerHTML = address
        row.appendChild rowName
        row.appendChild rowValue
        row.appendChild rowAddress
        @variablesTable.appendChild row

  updateCallStack: (debuggerPresenter) ->
    @clearTable @stackTable

    if debuggerPresenter?
      for value in debuggerPresenter.getCallStack() by -1
        splitted = value.split MessageUtils.getAssignSymbol()
        methodAndArgs = splitted[0]
        callID = splitted[1]

        row = document.createElement 'tr'
        rowCall = document.createElement 'td'
        rowCall.innerHTML = methodAndArgs
        rowReplay = document.createElement 'td'
        replayButton = document.createElement 'button'
        replayButton.className = 'btn'
        replayButton.innerHTML = 'Replay'
        replayButton.setAttribute 'callID', callID
        replayButton.addEventListener 'click', (event) => @startReplay event
        rowReplay.appendChild replayButton
        row.appendChild rowCall
        row.appendChild rowReplay
        @stackTable.appendChild row

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
    @stepButton.disabled = !enabled
    @stepOverButton.disabled = !enabled
    @runToNextBreakpointButton.disabled = !enabled
    @runToEndOfMethodButton.disabled = !enabled

  handleEnableDisableAllBreakpoints: (enabled) ->
    text = if enabled then 'Disable All Breakpoints' else 'Enable All Breakpoints'
    @enableDisableAllBreakpointsButton.innerHTML = text

  handleStatusUpdated: (event) ->
    @statusDiv.className = event.getStyleClass()
    @statusDiv.innerHTML = event.getDisplayMessage()
    @handleEnableDisableSteppingCommands !event.isBlockingStatus()

  handleEnableDisableAllControls: (enabled) ->
    @element.setAttribute 'disabled', !enabled

  clearTable: (table) ->
    rows = table.rows
    i = rows.length
    while --i
      table.deleteRow i