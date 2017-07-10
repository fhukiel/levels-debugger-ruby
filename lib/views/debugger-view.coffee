{CompositeDisposable}  = require('atom')
{$,$$,ScrollView}      = require('atom-space-pen-views')
MessageUtils           = require '../messaging/message-utils'

module.exports =
class LevelsDebuggerView extends ScrollView

  @content: (debuggerPresenter) ->
   @div id: 'mainDiv', outlet:'mainDiv', class:'debugger-view', =>
    @div id: 'outerDiv', outlet:'outerDiv', class:'outerDiv', =>
      @div id: 'statusDiv', outlet:'statusDiv', class:'statusDiv', =>
        @span id: 'statusSpan', outlet: 'statusSpan'
      @div id: 'flexDiv', outlet:'flexDiv', class:'flexDiv', =>
        @div id: 'resizeHandlerDiv', outlet:'resizeHandlerDiv', class:'resizeHandlerDiv', =>
        @div id: 'commandWrapperDiv', outlet:'commandWrapperDiv', class:'commandWrapperDiv', =>
          @div class: 'controlElementDiv', outlet:'commandsItem', =>
            @div class: 'controlElementHeaderDiv', outlet:'commandsHeader', =>
              @text 'commands'
            @button click: 'toggleBreakpoint', class:'commandButton enabled', id:'toggleBreakpointButton', outlet: 'toggleBreakpointButton', =>
                @text 'Toggle breakpoint'
            @button click: 'removeAllBreakpoints', class:'commandButton enabled', id:'removeAllBreakpointsButton', outlet: 'removeAllBreakpointsButton', =>
                @text 'Remove all breakpoints'
            @button click: 'enableDisableAllBreakpoints', class:'commandButton enabled', id:'enableDisableAllBreakpointsButton', outlet: 'enableDisableAllBreakpointsButton', =>
                @text 'Disable all breakpoints'
            @button click: 'startDebugging', class:'commandButton enabled', id:'startDebuggingButton', outlet: 'startDebuggingButton', =>
                @text 'Start Debugging'
            @button click: 'stopDebugging', class:'commandButton disabled', id:'stopDebuggingButton', outlet: 'stopDebuggingButton', =>
                @text 'Stop Debugging'
            @button click: 'step', class:'commandButton disabled', id:'stepButton', outlet: 'stepButton', =>
                @text 'Step'
            @button click: 'stepOver', class:'commandButton disabled', id:'stepOverButton', outlet: 'stepOverButton', =>
                @text 'Step Over'
            @button click: 'runToEndOfMethod', class:'commandButton disabled', id:'runToEndOfMethodButton', outlet: 'runToEndOfMethodButton', =>
                @text 'Run to end of method'
            @button click: 'runToNextBreakpoint', class:'commandButton disabled', id:'runToNextBreakpointButton', outlet: 'runToNextBreakpointButton', =>
                @text 'Run to next breakpoint'
            @button click: 'stopReplay', class:'commandButton disabled', id:'stopReplayButton', outlet: 'stopReplayButton', =>
                @text 'Stop replay'
          @div class: 'controlElementDiv', outlet:'definedVariablesItem', =>
            @div class: 'controlElementHeaderDiv', outlet:'definedVariablesHeader', =>
              @text 'defined variables'
            @div outlet: 'variableTableDiv', id: 'variableTableDiv', class: 'scrollableTableDiv'
          @div class: 'controlElementDiv', outlet:'callStackItem', =>
            @div class: 'controlElementHeaderDiv', outlet:'callStackHeader', =>
              @text 'call stack'
            @div outlet: 'callStackDiv', id: 'callStackDiv', class: 'scrollableTableDiv'

  initialize: (debuggerPresenter) ->
    @debuggerPresenter = debuggerPresenter;
    @reset();
    @subscriptions = new CompositeDisposable()
    @subscriptions.add debuggerPresenter.onRunning => @handleRunning();
    @subscriptions.add debuggerPresenter.onStopped => @handleStopped();
    @subscriptions.add debuggerPresenter.onCallStackUpdated => @updateCallStack(@debuggerPresenter);
    @subscriptions.add debuggerPresenter.onVariableTableUpdated => @updateVariableTable(@debuggerPresenter);
    @subscriptions.add debuggerPresenter.onStatusUpdated (status) => @handleStatusUpdated(status);
    @subscriptions.add debuggerPresenter.onAutoSteppingEnabled => @handleEnableDisableSteppingCommands(false);
    @subscriptions.add debuggerPresenter.onAutoSteppingDisabled => @handleEnableDisableSteppingCommands(true);
    @subscriptions.add debuggerPresenter.onEnableDisableAllBreakpoints (enable) => @handleEnableDisableAllBreakpoints(enable)
    @subscriptions.add debuggerPresenter.onEnableDisableAllControls (enable) => @handleEnableDisableAllControls(enable)
    @registerEvents();

  destroy: ->
    console.log "Destroying LevelsDebuggerView"
    @subscriptions.dispose()

# Taken from LaKrMe's levels package
  resizeStarted: =>
    $(document).on('mousemove',@resize)
    $(document).on('mouseup',@resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove',@resize)
    $(document).off('mouseup',@resizeStopped)

  resize: ({pageX,which}) =>
    return @resizeStopped() unless which is 1
    newWidth = $(document.body).width() - pageX;
    @width(newWidth);
# end taken from LaKrMe's levels package

# ------------------------------------------------------------------------------
# -----------------------------LINKS TO PRESENTER-------------------------------
# ------------------------------------------------------------------------------
  startDebugging: ->
    @debuggerPresenter.startDebugging();

  stopDebugging: ->
    @debuggerPresenter.stopDebugging();

  step: ->
    @debuggerPresenter.step();

  stepOver: ->
    @debuggerPresenter.stepOver();

  runToNextBreakpoint: ->
    @debuggerPresenter.runToNextBreakpoint();

  runToEndOfMethod: ->
    @debuggerPresenter.runToEndOfMethod();

  toggleBreakpoint: ->
    @debuggerPresenter.toggleBreakpoint();

  removeAllBreakpoints: ->
    @debuggerPresenter.removeAllBreakpoints();

  enableDisableAllBreakpoints: ->
    @debuggerPresenter.enableDisableAllBreakpoints();

  startReplay: (event) ->
    stopReplayButton.className = "commandButton enabled ";
    @debuggerPresenter.startReplay(event.target);

  stopReplay: ->
    stopReplayButton.className = "commandButton disabled ";
    @debuggerPresenter.stopReplay();

# ------------------------------------------------------------------------------
# -----------------------------HELPERS------------------------------------------
# ------------------------------------------------------------------------------
  enableDisableCommandsOnStartStop: (enabled) ->
    console.log "Commandos will be enabled/disabled, enabled has value #{enabled}"
    status = if enabled then "enabled" else "disabled"
    stopDebuggingButton.className = "commandButton " + status;
    @handleEnableDisableSteppingCommands(enabled);

  updateVariableTable: (debuggerPresenter) ->
    $('#variableTableDiv').empty();
    @variableTable = $$ ->
      @table class:'scrollableTable', id:'variableTable', outlet:'variableTable', =>
        @th class:'variableTableCell variableNameHeader', id:'variableNameHeader', =>
          @span =>
            @text 'variable'
        @th class:'variableTableCell', =>
          @span  =>
            @text 'value'
        @th class:'variableTableCell', =>
          @span  =>
            @text 'address'
        if debuggerPresenter?
          for entry in debuggerPresenter.getVariableTable()
            name = "#{entry.getName()}"
            value = "#{entry.getValue()}"
            address = "#{entry.getAddress()}";
            cellClass = if entry.isChanged() then "variableTableCell highlighted-cell" else "variableTableCell"
            # entry.setChanged(false);
            @tr class:'highlightableRow variableRow', name:name, value:value, address:address, =>
              @td class:cellClass, id:'nameCell', name:name, value:value, address:address,=>
                @div class:'ellipsisDiv', id:'nameDiv', name:name, value:value, address:address,=>
                  @text entry.getName();
              @td class:cellClass, id:'valueCell', name:name, value:value, address:address,  =>
                @div class:'ellipsisDiv', id:'valueDiv', name:name, value:value, address:address,=>
                  @text entry.getValue();
              @td class:cellClass, id:'addressCell', name:name, value:value, address:address,=>
                @div class:'ellipsisDiv', id:'addressDiv', name:name, value:value, address:address,=>
                  @text entry.getAddress();
    @variableTableDiv.append(@variableTable);

  updateCallStack: (debuggerPresenter) ->
    $('#callStackDiv').empty();
    @callStackTable = $$ ->
      @table class:'scrollableTable', id:'callStackTable', outlet:'callStackTable', =>
        @th class:'callStackTableCell', =>
          @span =>
            @text 'calls'
        @th class:'callStackTableCell', =>
          @span  =>
            @text 'replay'
        if debuggerPresenter?
          for value in debuggerPresenter.getCallStack() by -1
            splitted = value.split(MessageUtils.getAssignSymbol())
            methodAndArgs = splitted[0]
            callId = splitted[1];
            linkId = "link#{callId}";
            @tr class:'highlightableRow callRow', call:methodAndArgs,=>
              @td class:'callStackTableCell', call:methodAndArgs,=>
                @div class:'ellipsisDiv', call:methodAndArgs,=>
                    @text methodAndArgs
              @td class:'callStackTableCell', =>
                @div class:'ellipsisDiv', =>
                  @button class:'dynamicButton', id:callId, =>
                      @text 'Replay'
    @callStackDiv.append(@callStackTable);
    @registerEvents();

  reset: ->
    console.log 'Clearing callStackDiv.'
    @updateCallStack(undefined)
    console.log 'Clearing variableTableDiv.'
    @updateVariableTable(undefined)

  registerEvents: ->
    @off();
    @on 'click', '.dynamicButton', (event) =>
      @startReplay(event);
    @on 'mousedown', '.resizeHandlerDiv', =>
      @resizeStarted()
    @on 'dblclick', '.variableRow', (event) =>
      @showVariableModal(event);
    @on 'dblclick', '.callRow', (event) =>
      @showCallModal(event);
    @on 'click', '.variableNameHeader', (event) =>
      @sortVariableTableByName();

  showVariableModal: (event) ->
    element = event.target;
    name = element.getAttribute('name')
    value = element.getAttribute('value')
    address = element.getAttribute('address')
    if name? and value? and address?
      value = @wrapLongText(element.getAttribute('value'))
      atom.confirm
        message:"Variable"
        detailedMessage:"Name:    #{name}\nAddress: #{address}\nValue:      #{value}"

  showCallModal: (event) ->
    element = event.target;
    call = element.getAttribute('call');
    if call?
      call = @wrapLongText(call)
      atom.confirm
        message:"Call"
        detailedMessage:"#{call}"

  sortVariableTableByName: ->
    @debuggerPresenter.flipAndSortVariableTable();

  wrapLongText: (text) ->
    lineLength = 45;
    if text.length > lineLength
      returnText = ""
      splitAt = 0;
      while splitAt < text.length
        returnText += text.substring(splitAt, splitAt+lineLength) + "\n"
        splitAt += lineLength;
      return returnText;
    return text;

# ------------------------------------------------------------------------------
# -----------------------------EVENT HANDLERS-----------------------------------
# ------------------------------------------------------------------------------
  handleRunning: ->
    @reset();
    @enableDisableCommandsOnStartStop(true);
    startDebuggingButton.className = "commandButton disabled";

  handleStopped: ->
    @reset();
    @enableDisableCommandsOnStartStop(false);
    stopReplayButton.className = "commandButton disabled ";
    startDebuggingButton.className = "commandButton enabled";

  handleEnableDisableSteppingCommands: (enabled) ->
    console.log "Stepping commandos will be enabled/disabled, enabled has value #{enabled}"
    status = if enabled then "enabled" else "disabled"
    stepButton.className = "commandButton " + status;
    stepOverButton.className = "commandButton " + status;
    runToNextBreakpointButton.className = "commandButton " + status;
    runToEndOfMethodButton.className = "commandButton " + status;

  handleEnableDisableAllBreakpoints: (enabled) ->
    console.log "Changing enable/disable all breakpoints button text."
    text = if enabled then "Disable all breakpoints" else "Enable all breakpoints";
    enableDisableAllBreakpointsButton.innerHTML = text;

  handleStatusUpdated: (event) ->
    console.log "Updating to #{event.getStatus()}, isBlocking: #{event.isBlockingStatus()}"
    statusSpan.className = event.getStyleClass();
    statusSpan.innerHTML = event.getDisplayMessage();
    @handleEnableDisableSteppingCommands(!event.isBlockingStatus());

  handleEnableDisableAllControls: (enabled) ->
    console.log "View is enabling/disabling all controls, enabled is: #{enabled}"
    className = if enabled then "outerDiv" else "outerDiv disabledDiv"
    $('#outerDiv').attr('class', className);
