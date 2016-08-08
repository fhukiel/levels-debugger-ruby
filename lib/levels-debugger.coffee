{CompositeDisposable}     = require 'atom'
{$}                       = require('atom-space-pen-views')
executor                  = require('./debugger/executor').getInstance()
SocketChannel             = require('./messaging/socket-channel')
outgoingMessageFactory    = require('./messaging/outgoing-message-factory').getInstance()
messageUtils              = require('./messaging/message-utils').getInstance()
IncomingMessageDispatcher = require('./messaging/incoming-message-dispatcher')
DebuggerPresenter         = require('./presenter/levels-debugger-presenter')
LevelsDebuggerView        = require('./views/levels-debugger-view')
packageDeps               = require('atom-package-deps')

module.exports = LevelsDebugger =
  levelsDebuggerView: null
  subscriptions: null

  activate: (state) ->
    console.log 'Levels-debugger activated.'
    packageDeps.install('levels-debugger-ruby')
      .then(console.log('All dependencies installed, good to go'))
    @incomingMessageDispatcher = new IncomingMessageDispatcher();
    @communicationChannel = new SocketChannel(@incomingMessageDispatcher);
    @debuggerPresenter = new DebuggerPresenter(@incomingMessageDispatcher, @communicationChannel);
    @levelsDebuggerView = new LevelsDebuggerView(@debuggerPresenter)
    @debuggerPanel = atom.workspace.addRightPanel(item: @levelsDebuggerView, visible:false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:startDebugging': => @debuggerPresenter.startDebugging();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:stopDebugging': => @debuggerPresenter.stopDebugging();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:step': => @debuggerPresenter.step();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:stepOver': => @debuggerPresenter.stepOver();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:runToNextBreakpoint': => @debuggerPresenter.runToNextBreakpoint();
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger:toggleBreakpoint': => @debuggerPresenter.toggleBreakpoint();
    @subscriptions.add @communicationChannel.onError (error) => @handleChannelError(error);
    @levelsWorkspace = null;

  deactivate: ->
    console.log("Levels-debugger deactivated.")
    @debuggerPresenter.destroy();
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
    @debuggerPresenter.setLevelsWorkspace(@levelsWorkspace);
    workspace.onDidEnterWorkspace =>
      @debuggerPanel.show()
    workspace.onDidExitWorkspace =>
      @debuggerPanel.hide()
