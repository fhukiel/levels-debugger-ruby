'use babel';

import {CompositeDisposable}     from 'atom';
import {install}                 from 'atom-package-deps';
import levelsWorkspaceManager    from './common/levels-workspace-manager';
import IncomingMessageDispatcher from './messaging/incoming-message-dispatcher';
import SocketChannel             from './messaging/socket-channel';
import DebuggerPresenter         from './presenter/debugger-presenter';
import DebuggerView              from './views/debugger-view';

export default {
  activate() {
    install('levels-debugger-ruby');

    this.incomingMessageDispatcher = new IncomingMessageDispatcher();
    this.socketChannel = new SocketChannel('localhost', 59599, this.incomingMessageDispatcher);
    this.debuggerPresenter = new DebuggerPresenter(this.incomingMessageDispatcher, this.socketChannel);

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(atom.workspace.addOpener((uri) => this.handleOpener(uri)));
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'levels-debugger-ruby:toggle-debugger-view': () => this.toggle(),
      'levels-debugger-ruby:toggle-breakpoint': () => this.debuggerPresenter.toggleBreakpoint(),
      'levels-debugger-ruby:remove-all-breakpoints': () => this.debuggerPresenter.removeAllBreakpoints(),
      'levels-debugger-ruby:enable-disable-all-breakpoints': () => this.debuggerPresenter.enableDisableAllBreakpoints(),
      'levels-debugger-ruby:start-debugging': () => this.debuggerPresenter.startDebugging(),
      'levels-debugger-ruby:stop-debugging': () => this.debuggerPresenter.stopDebugging(),
      'levels-debugger-ruby:step': () => this.debuggerPresenter.step(),
      'levels-debugger-ruby:step-over': () => this.debuggerPresenter.stepOver(),
      'levels-debugger-ruby:run-to-end-of-method': () => this.debuggerPresenter.runToEndOfMethod(),
      'levels-debugger-ruby:run-to-next-breakpoint': () => this.debuggerPresenter.runToNextBreakpoint(),
      'levels-debugger-ruby:stop-replay': () => this.debuggerPresenter.stopReplay()
    }));
  },

  deactivate() {
    this.subscriptions.dispose();
    this.debuggerView.destroy();
    this.debuggerPresenter.destroy();
    this.socketChannel.destroy();
    this.incomingMessageDispatcher.destroy();
    levelsWorkspaceManager.destroy();
  },

  handleOpener(uri) {
    if (uri === 'atom://levels-debugger-ruby') {
      return new DebuggerView(this.debuggerPresenter);
    }
  },

  toggle() {
    atom.workspace.toggle('atom://levels-debugger-ruby');
  },

  consumeLevels({workspace}) {
    levelsWorkspaceManager.attachWorkspace(workspace);
  }
};