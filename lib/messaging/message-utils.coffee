class MessageUtils
  getDelimiter: ->
    return ';'

  getAssignSymbol: ->
    return '=*='

  getFinalSymbol: ->
    return '/!/'

  getNewLineSymbol: ->
    return require('os').EOL

  removeNewLineSymbol: (string) ->
    return string?.replace('\n', '').replace '\r', ''

module.exports =
class MessageUtilsProvider
  instance = null

  @getInstance: ->
    instance ?= new MessageUtils