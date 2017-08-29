VariableTableEntry = require './variable-table-entry'
MessageUtils       = require '../messaging/message-utils'

class VariableTableManager
  constructor: ->
    @resetSortMode()

  resetSortMode: ->
    @sortAscending = true
    return

  flipSortMode: ->
    @sortAscending = !@sortAscending

  fromString: (string, oldTable) ->
    variableTable = []

    if string? && string.length != 0
      splitted = string.split MessageUtils.DELIMITER

      for elem in splitted
        innerSplitted = elem.split MessageUtils.ASSIGN_SYMBOL
        entry = new VariableTableEntry innerSplitted[0], innerSplitted[1], innerSplitted[2]
        variableTable.push entry

      @sort variableTable
      @markChangedEntries oldTable, variableTable

    return variableTable

  markChangedEntries: (oldTable, newTable) ->
    for newEntry in newTable
      hasChanged = true

      for oldEntry in oldTable
        if oldEntry.equals newEntry
          hasChanged = false
          if oldEntry.isChanged()
            newEntry.setChanged true
            newEntry.setChangedExpiresAt oldEntry.getChangedExpiresAt()
          break

      if hasChanged
        newEntry.setChanged true

    return

  sort: (table) ->
    if @sortAscending
      table?.sort (e1, e2) -> if e1.getName() >= e2.getName() then 1 else -1
    else
      table?.sort (e1, e2) -> if e1.getName() <= e2.getName() then 1 else -1
    return

module.exports =
class VariableTableManagerProvider
  instance = null

  @getInstance: ->
    instance ?= new VariableTableManager