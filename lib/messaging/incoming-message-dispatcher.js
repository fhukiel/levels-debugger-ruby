'use babel';

import {Emitter}                                      from 'atom';
import {DELIMITER, FINAL_SYMBOL, removeNewlineSymbol} from './message-utils';

export default class IncomingMessageDispatcher {
  constructor() {
    this.emitter = new Emitter();
  }

  destroy() {
    this.emitter.dispose();
  }

  dispatch(message) {
    if (message) {
      if (message.includes(FINAL_SYMBOL)) {
        for (const msg of message.split(FINAL_SYMBOL)) {
          this.handleMessage(removeNewlineSymbol(msg));
        }
      } else {
        this.handleMessage(message);
      }
    }
  }

  handleMessage(message) {
    if (message) {
      const messageCategory = message.split(DELIMITER)[0];
      const msg = message.substring(messageCategory.length + DELIMITER.length);

      switch (messageCategory) {
        case 'TABLEUPDATED':
          this.emitter.emit('variable-table-updated', msg);
          break;
        case 'POSITIONUPDATED':
          this.emitter.emit('position-updated', msg);
          break;
        case 'CALLSTACKUPDATED':
          this.emitter.emit('call-stack-updated', msg);
          break;
        case 'READY':
          this.emitter.emit('ready');
          break;
        case 'TERMINATECOMMUNICATION':
          this.emitter.emit('terminate-communication');
          break;
        case 'ENDOFREPLAYTAPE':
          this.emitter.emit('end-of-replay-tape');
          break;
        case 'AUTOSTEPPINGENABLED':
          this.emitter.emit('auto-stepping-enabled');
          break;
        case 'AUTOSTEPPINGDISABLED':
          this.emitter.emit('auto-stepping-disabled');
          break;
        default:
      }
    }
  }

  onVariableTableUpdated(callback) {
    return this.emitter.on('variable-table-updated', callback);
  }

  onPositionUpdated(callback) {
    return this.emitter.on('position-updated', callback);
  }

  onCallStackUpdated(callback) {
    return this.emitter.on('call-stack-updated', callback);
  }

  onReady(callback) {
    return this.emitter.on('ready', callback);
  }

  onTerminate(callback) {
    return this.emitter.on('terminate-communication', callback);
  }

  onEndOfReplayTape(callback) {
    return this.emitter.on('end-of-replay-tape', callback);
  }

  onAutoSteppingEnabled(callback) {
    return this.emitter.on('auto-stepping-enabled', callback);
  }

  onAutoSteppingDisabled(callback) {
    return this.emitter.on('auto-stepping-disabled', callback);
  }
}