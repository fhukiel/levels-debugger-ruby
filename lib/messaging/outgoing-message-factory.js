'use babel';

import {EOL, DELIMITER} from './message-utils';

function createMessage(msg) {
  return msg + EOL;
}

function positionToString(position) {
  return position.getLine() + DELIMITER + position.getColumn();
}

export function createAddBreakpointMessage(position) {
  return createMessage(`ADDBREAKPOINT${DELIMITER}${positionToString(position)}`);
}

export function createRemoveBreakpointMessage(position) {
  return createMessage(`REMOVEBREAKPOINT${DELIMITER}${positionToString(position)}`);
}

export function createRunToNextBreakpointMessage() {
  return createMessage('RUNTONEXTBREAKPOINT');
}

export function createRunToEndOfMethodMessage() {
  return createMessage('RUNTOENDOFMETHOD');
}

export function createEnableAllBreakpointsMessage() {
  return createMessage('ENABLEALLBREAKPOINTS');
}

export function createDisableAllBreakpointsMessage() {
  return createMessage('DISABLEALLBREAKPOINTS');
}

export function createStartReplayMessage(callId) {
  return createMessage(`STARTREPLAY${DELIMITER}${callId}`);
}

export function createStepMessage() {
  return createMessage('STEP');
}

export function createStepOverMessage() {
  return createMessage('STEPOVER');
}

export function createStopReplayMessage() {
  return createMessage('STOPREPLAY');
}

export function createRemoveAllBreakpointsMessage() {
  return createMessage('REMOVEALLBREAKPOINTS');
}