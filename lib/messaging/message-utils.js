'use babel';

import os from 'os';

export const EOL = os.EOL;
export const DELIMITER = ';';
export const ASSIGN_SYMBOL = '=*=';
export const FINAL_SYMBOL = '/!/';

export function removeNewlineSymbol(string) {
  if (!string) {
    return null;
  }
  return string.replace(EOL, '');
}