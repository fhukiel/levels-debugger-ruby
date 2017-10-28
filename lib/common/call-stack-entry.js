'use babel';

export default class CallStackEntry {
  constructor(methodAndArgs, callId) {
    this.methodAndArgs = methodAndArgs;
    this.callId = callId;
  }

  getMethodAndArgs() {
    return this.methodAndArgs;
  }

  getCallId() {
    return this.callId;
  }
}