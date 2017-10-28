'use babel';

import CallStackEntry             from './call-stack-entry';
import {DELIMITER, ASSIGN_SYMBOL} from '../messaging/message-utils';

export default function callStackFromString(string) {
  const callStack = [];

  if (string) {
    const splitted = string.split(DELIMITER);

    for (const elem of splitted) {
      const innerSplitted = elem.split(ASSIGN_SYMBOL);
      const entry = new CallStackEntry(innerSplitted[0], innerSplitted[1]);
      callStack.push(entry);
    }
  }

  return callStack;
}