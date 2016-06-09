VariableTableEntry   = require('./variable-table-entry');
messageUtils         = require('../messaging/message-utils').getInstance()

class VariableTableManager
  constructor: (serializedState) ->
    @sortAscending = true;

  resetSortMode: ->
    @sortAscending = true;

  flipSortMode: ->
    @sortAscending = !@sortAscending;

  fromString: (string, oldTable) ->
    variableTable = new Array();
    splitted = string?.split(messageUtils.getDelimiter());
    for i in [1 .. splitted.length]
      string = splitted[i]
      if string?
        innerSplitted = string.split(messageUtils.getAssignSymbol());
        entry = new VariableTableEntry(innerSplitted[0], innerSplitted[1], innerSplitted[2]);
        variableTable.push(entry)
    @sort(variableTable);
    @markChangedEntries(oldTable, variableTable);
    return variableTable

  markChangedEntries: (oldTable, newTable)->
    for newEntry in newTable
      hasChanged = true;
      for oldEntry in oldTable
        if oldEntry.equals(newEntry)
          hasChanged=false;
          if oldEntry.isChanged()
            newEntry.setChanged(true);
            # Keep the changed flag alive if its not expired
            newEntry.setChangedExpiresAt(oldEntry.getChangedExpiresAt());
          break;
      if hasChanged
        console.log "#{newEntry.getName()} has changed."
        newEntry.setChanged(true);

  sort: (table)->
    console.log "Sorting by name"
    if @sortAscending
      table.sort (e1,e2) ->
        return if e1.getName() >= e2.getName() then 1 else -1
    else
      table.sort (e1,e2) ->
        return if e1.getName() <= e2.getName() then 1 else -1

module.exports =
class VariableTableManagerProvider
  instance = null
  @getInstance: ->
    instance ?= new VariableTableManager
