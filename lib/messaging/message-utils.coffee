module.exports =
class MessageUtils
  @getDelimiter: ->
    return ';'

  @getAssignSymbol: ->
    return '=*='

  @getFinalSymbol: ->
    return '/!/'

  @getNewLineSymbol: ->
    return require('os').EOL

  @removeNewLineSymbol: (string) ->
    return string?.replace(MessageUtils.getNewLineSymbol(), '')