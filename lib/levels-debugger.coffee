{CompositeDisposable}     = require 'atom'
{$}                       = require('atom-space-pen-views')
executor                  = require('./debugger/executor').getInstance()
SocketChannel             = require('./messaging/socket-channel')
outgoingMessageFactory    = require('./messaging/outgoing-message-factory').getInstance()
messageUtils              = require('./messaging/message-utils').getInstance()
IncomingMessageDispatcher = require('./messaging/incoming-message-dispatcher')
DebuggerViewModel         = require('./viewmodels/debugger-viewmodel')
LevelsDebuggerView        = require('./views/levels-debugger-view')

module.exports = LevelsDebugger =
  levelsDebuggerView: null
  subscriptions: null

  activate: (state) ->
    console.log 'Levels-debugger activated.'
    @incomingMessageDispatcher = new IncomingMessageDispatcher();
    @communicationChannel = new SocketChannel(@incomingMessageDispatcher);
    @debuggerModel = new DebuggerViewModel(@incomingMessageDispatcher, @communicationChannel);
    @levelsDebuggerView = new LevelsDebuggerView(@debuggerModel)
    @debuggerPanel = atom.workspace.addRightPanel(item: @levelsDebuggerView, visible:false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:startDebugging': => @debuggerModel.startDebugging();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:stopDebugging': => @debuggerModel.stopDebugging();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:step': => @debuggerModel.step();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:stepOver': => @debuggerModel.stepOver();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:runToNextBreakpoint': => @debuggerModel.runToNextBreakpoint();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:toggleBreakpoint': => @debuggerModel.toggleBreakpoint();
    @subscriptions.add @communicationChannel.onError (error) => @handleChannelError(error);
    @levelsWorkspace = null;

  deactivate: ->
    console.log("Levels-debugger deactivated.")
    @debuggerModel.destroy();
    @levelsDebuggerView.destroy()
    @debuggerPanel.destroy()
    @subscriptions.dispose()

  serialize: ->
    levelsDebuggerViewState: @levelsDebuggerView.serialize()

  toggle: ->
    console.log 'Levels-debugger was toggled!'
    if @debuggerPanel.isVisible()
      @debuggerPanel.hide()
    else
      @debuggerPanel.show()

  handleChannelError: (error)->
    atom.confirm
      message:"CommunicationChannel error"
      detailedMessage:"A communicationChannel error occurred: #{error}"

  consumeLevels: ({workspace}) ->
    @levelsWorkspace = workspace;
    @debuggerModel.setLevelsWorkspace(@levelsWorkspace);
    workspace.onDidEnterWorkspace =>
      @debuggerPanel.show()
    workspace.onDidExitWorkspace =>
      @debuggerPanel.hide()
