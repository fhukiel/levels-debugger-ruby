'use babel';

import {Emitter} from 'atom';
import net       from 'net';

export default class SocketChannel {
  constructor(host, port, dispatcher) {
    this.host = host;
    this.port = port;
    this.dispatcher = dispatcher;
    this.emitter = new Emitter();
    this.available = false;
  }

  destroy() {
    this.disconnect();
    this.emitter.dispose();
  }

  connect() {
    if (!this.socket) {
      this.socket = net.createConnection(this.port, this.host);
      this.socket.setNoDelay(true);
      this.socket.on('close', () => this.handleClose());
      this.socket.on('connect', () => this.handleConnect());
      this.socket.on('data', (data) => this.handleData(data));
      this.socket.on('error', () => this.handleError());
      this.socket.on('timeout', () => this.handleTimeout());
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.end();
      this.socket.destroy();
    }
  }

  handleClose() {
    this.socket = null;
    this.available = false;
  }

  handleConnect() {
    this.available = true;
  }

  handleData(buffer) {
    this.dispatcher.dispatch(`${buffer}`);
  }

  handleError() {
    this.emitError();
  }

  handleTimeout() {
    this.disconnect();
  }

  sendMessage(msg) {
    if (this.available) {
      this.socket.write(msg);
    }
  }

  emitError() {
    this.emitter.emit('error');
  }

  onError(callback) {
    return this.emitter.on('error', callback);
  }
}