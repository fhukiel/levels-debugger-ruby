'use babel';

import StatusUpdateEvent from './status-update-event';

export const RUNNING_STATUS = 'running';
export const WAITING_STATUS = 'waiting';
export const STOPPED_STATUS = 'stopped';
export const END_OF_TAPE_STATUS = 'endoftape';
export const DISABLED_STATUS = 'disabled';

export const RUNNING_MESSAGE = 'Debugger Running';
export const WAITING_MESSAGE = 'Debugger Waiting For Step';
export const STOPPED_MESSAGE = 'Debugger Stopped';
export const END_OF_TAPE_MESSAGE = 'End Of Tape';
export const DISABLED_MESSAGE = 'Level Not Debuggable';

function createMessage(isReplay, message) {
  if (isReplay) {
    return `(REPLAY) ${message}`;
  } else {
    return message;
  }
}

function createStyleClass(isReplay, status) {
  let styleClass = `status-${status}`;
  if (isReplay) {
    styleClass += ' status-replay';
  }

  return styleClass;
}

function createGeneric(isReplay, message, status, isBlocking) {
  const msg = createMessage(isReplay, message);
  const styleClass = createStyleClass(isReplay, status);

  return new StatusUpdateEvent(status, msg, isBlocking, styleClass);
}

export function createDisabled(isReplay) {
  return createGeneric(isReplay, DISABLED_MESSAGE, DISABLED_STATUS, true);
}

export function createRunning(isReplay) {
  return createGeneric(isReplay, RUNNING_MESSAGE, RUNNING_STATUS, true);
}

export function createWaiting(isReplay) {
  return createGeneric(isReplay, WAITING_MESSAGE, WAITING_STATUS, false);
}

export function createStopped(isReplay) {
  return createGeneric(isReplay, STOPPED_MESSAGE, STOPPED_STATUS, true);
}

export function createEndOfTape(isReplay) {
  return createGeneric(isReplay, END_OF_TAPE_MESSAGE, END_OF_TAPE_STATUS, true);
}