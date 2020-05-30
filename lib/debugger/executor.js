'use babel';

import {BufferedProcess, Emitter} from 'atom';
import path                       from 'path';

class Executor {
  constructor() {
    this.emitter = new Emitter();
    this.resetFlags();
  }

  destroy() {
    this.stopDebugger();
    this.emitter.dispose();
  }

  startDebugger() {
    if (!this.process) {
      const debuggerPath = path.join(__dirname, 'debugger.jar');
      const command = 'java';
      const args = ['-jar', debuggerPath];
      const stdout = output => this.handleOutput(output);
      const exit = () => this.handleExit();
      this.process = new BufferedProcess({command, args, stdout, exit});
    }
  }

  stopDebugger() {
    if (this.process) {
      this.process.kill();
      this.handleExit();
    }
  }

  handleExit() {
    this.process = null;
    this.resetFlags();
    this.emitStop();
  }

  handleOutput(output) {
    if (output.includes('!!!VIEWCHANNELREADY!!!')) {
      this.viewChannelReady = true;
    }

    if (output.includes('!!!RUNTIMECHANNELREADY!!!')) {
      this.runtimeChannelReady = true;
    }

    if (this.viewChannelReady && this.runtimeChannelReady) {
      this.emitReady();
      this.resetFlags();
    }
  }

  emitStop() {
    this.emitter.emit('execution-stopped');
  }

  onStop(callback) {
    return this.emitter.on('execution-stopped', callback);
  }

  emitReady() {
    this.emitter.emit('debugger-ready');
  }

  onReady(callback) {
    return this.emitter.on('debugger-ready', callback);
  }

  resetFlags() {
    this.runtimeChannelReady = false;
    this.viewChannelReady = false;
  }
}

export default new Executor();