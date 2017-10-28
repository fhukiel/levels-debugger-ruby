'use babel';

import os from 'os';

const EOL = os.EOL;
const DELIMITER = ';';
const ASSIGN_SYMBOL = '=*=';
const FINAL_SYMBOL = '/!/';

function removeNewlineSymbol(string) {
  if (!string) {
    return null;
  }
  return string.replace(EOL, '');
}

export {EOL, DELIMITER, ASSIGN_SYMBOL, FINAL_SYMBOL, removeNewlineSymbol};