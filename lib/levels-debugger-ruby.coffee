{CompositeDisposable}     = require 'atom'
packageDeps               = require 'atom-package-deps'
IncomingMessageDispatcher = require './messaging/incoming-message-dispatcher'
SocketChannel             = require './messaging/socket-channel'
DebuggerPresenter         = require './presenter/debugger-presenter'
DebuggerView              = require './views/debugger-view'

module.exports =
  activate: (state) ->
    packageDeps.install('levels-debugger-ruby').then(console.log 'All dependencies installed, good to go!')

    incomingMessageDispatcher = new IncomingMessageDispatcher
    socketChannel = new SocketChannel incomingMessageDispatcher
    @debuggerPresenter = new DebuggerPresenter incomingMessageDispatcher, socketChannel
    @debuggerView = new DebuggerView @debuggerPresenter

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.addOpener (uri) => @handleOpener uri
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:toggle-debugger-view': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:toggle-breakpoint': => @debuggerPresenter?.toggleBreakpoint()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:remove-all-breakpoints': => @debuggerPresenter?.removeAllBreakpoints()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:enable-disable-all-breakpoints': => @debuggerPresenter?.enableDisableAllBreakpoints()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:start-debugging': => @debuggerPresenter?.startDebugging()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:stop-debugging': => @debuggerPresenter?.stopDebugging()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:step': => @debuggerPresenter?.step()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:step-over': => @debuggerPresenter?.stepOver()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:run-to-end-of-method': => @debuggerPresenter?.runToEndOfMethod()
    @subscriptions.add atom.commands.add 'atom-workspace', 'levels-debugger-ruby:run-to-next-breakpoint': => @debuggerPresenter?.runToNextBreakpoint()
    @subscriptions.add atom.workspace.getLeftDock().onWillDestroyPaneItem (event) => @handleOnWillDestroyPaneItem event
    @subscriptions.add atom.workspace.getLeftDock().onDidDestroyPaneItem (event) => @handleOnDidDestroyPaneItem event
    @subscriptions.add atom.workspace.getRightDock().onWillDestroyPaneItem (event) => @handleOnWillDestroyPaneItem event
    @subscriptions.add atom.workspace.getRightDock().onDidDestroyPaneItem (event) => @handleOnDidDestroyPaneItem event

  deactivate: ->
    @debuggerView.destroy()
    @debuggerPresenter.destroy()
    @subscriptions.dispose()

  handleOpener: (uri) ->
    if uri == 'atom://levels-debugger-ruby'
      return @debuggerView

  handleOnWillDestroyPaneItem: (event) ->
    if event.item.getURI() == 'atom://levels-debugger-ruby'
      @debuggerPresenter.destroy()
      @debuggerPresenter = null

  handleOnDidDestroyPaneItem: (event) ->
    if event.item.getURI() == 'atom://levels-debugger-ruby'
      incomingMessageDispatcher = new IncomingMessageDispatcher
      socketChannel = new SocketChannel incomingMessageDispatcher
      @debuggerPresenter = new DebuggerPresenter incomingMessageDispatcher, socketChannel
      @debuggerView = new DebuggerView @debuggerPresenter
      @debuggerPresenter.setLevelsWorkspace @levelsWorkspace

  toggle: ->
    atom.workspace.toggle 'atom://levels-debugger-ruby'

  consumeLevels: ({workspace}) ->
    @levelsWorkspace = workspace
    @debuggerPresenter.setLevelsWorkspace @levelsWorkspace