'use babel';

import VariableTableEntry         from './variable-table-entry';
import {DELIMITER, ASSIGN_SYMBOL} from '../messaging/message-utils';

class VariableTableManager {
  constructor() {
    this.resetSortMode();
  }

  resetSortMode() {
    this.sortAscending = true;
  }

  flipSortMode() {
    this.sortAscending = !this.sortAscending;
  }

  fromString(string, oldTable) {
    const variableTable = [];

    if (string) {
      const splitted = string.split(DELIMITER);

      for (const elem of splitted) {
        const innerSplitted = elem.split(ASSIGN_SYMBOL);
        const entry = new VariableTableEntry(innerSplitted[0], innerSplitted[1], innerSplitted[2]);
        variableTable.push(entry);
      }

      this.sort(variableTable);
      this.markChangedEntries(oldTable, variableTable);
    }

    return variableTable;
  }

  markChangedEntries(oldTable, newTable) {
    for (const newEntry of newTable) {
      let hasChanged = true;

      for (const oldEntry of oldTable) {
        if (oldEntry.equals(newEntry)) {
          hasChanged = false;
          if (oldEntry.isChanged()) {
            newEntry.setChanged(true);
            newEntry.setChangedExpiresAt(oldEntry.getChangedExpiresAt());
          }
          break;
        }
      }

      if (hasChanged) {
        newEntry.setChanged(true);
      }
    }
  }

  sort(table) {
    if (table) {
      if (this.sortAscending) {
        table.sort((x, y) => x.getName() >= y.getName() ? 1 : -1);
      } else {
        table.sort((x, y) => x.getName() <= y.getName() ? 1 : -1);
      }
    }
  }
}

export default new VariableTableManager();