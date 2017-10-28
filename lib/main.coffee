{CompositeDisposable}     = require 'atom'
packageDeps               = require 'atom-package-deps'
levelsWorkspaceManager    = require './common/levels-workspace-manager'
IncomingMessageDispatcher = require './messaging/incoming-message-dispatcher'
SocketChannel             = require './messaging/socket-channel'
DebuggerPresenter         = require './presenter/debugger-presenter'
DebuggerView              = require './views/debugger-view'

module.exports =
  activate: ->
    packageDeps.install 'levels-debugger-ruby'

    @incomingMessageDispatcher = new IncomingMessageDispatcher
    @socketChannel = new SocketChannel 'localhost', 59599, @incomingMessageDispatcher
    @debuggerPresenter = new DebuggerPresenter @incomingMessageDispatcher, @socketChannel

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.addOpener (uri) => @handleOpener uri
    @subscriptions.add atom.commands.add 'atom-workspace',
      'levels-debugger-ruby:toggle-debugger-view': => @toggle()
      'levels-debugger-ruby:toggle-breakpoint': => @debuggerPresenter.toggleBreakpoint()
      'levels-debugger-ruby:remove-all-breakpoints': => @debuggerPresenter.removeAllBreakpoints()
      'levels-debugger-ruby:enable-disable-all-breakpoints': => @debuggerPresenter.enableDisableAllBreakpoints()
      'levels-debugger-ruby:start-debugging': => @debuggerPresenter.startDebugging()
      'levels-debugger-ruby:stop-debugging': => @debuggerPresenter.stopDebugging()
      'levels-debugger-ruby:step': => @debuggerPresenter.step()
      'levels-debugger-ruby:step-over': => @debuggerPresenter.stepOver()
      'levels-debugger-ruby:run-to-end-of-method': => @debuggerPresenter.runToEndOfMethod()
      'levels-debugger-ruby:run-to-next-breakpoint': => @debuggerPresenter.runToNextBreakpoint()
      'levels-debugger-ruby:stop-replay': => @debuggerPresenter.stopReplay()

    return

  deactivate: ->
    @subscriptions.dispose()
    @debuggerView.destroy()
    @debuggerPresenter.destroy()
    @socketChannel.destroy()
    @incomingMessageDispatcher.destroy()
    levelsWorkspaceManager.destroy()
    return

  handleOpener: (uri) ->
    if uri == 'atom://levels-debugger-ruby'
      return new DebuggerView @debuggerPresenter

  toggle: ->
    atom.workspace.toggle 'atom://levels-debugger-ruby'

  consumeLevels: ({workspace}) ->
    levelsWorkspaceManager.attachWorkspace workspace
    return