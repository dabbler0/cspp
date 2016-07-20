antlr4 = require 'antlr4'
CSPPLexer = require './CSPPLexer'
CSPPParser = require './CSPPParser'

# Parsing
exports.parse = parse = (text) ->
  chars = new antlr4.InputStream text
  lexer = new CSPPLexer.CSPPLexer chars
  tokens = new antlr4.CommonTokenStream lexer
  parser = new CSPPParser.CSPPParser tokens

  parser._errHandler = new antlr4.error.BailErrorStrategy()

  parser.buildParseTrees = true

  return transform parser.block text

transform = (node, parent = null) ->
  result = {}
  if node.children?
    result.type = node.parser.ruleNames[node.ruleIndex]
    result.children = (transform(child, result) for child in node.children)
  else
    result.children = []
    result.type = (node.parser ? node.parentCtx.parser).symbolicNames[node.symbol.type]
    result.text = node.symbol.text
  return result

# EVALUATION
class Procedure
  constructor: (@parentEvalContext, @params, @block, @name = '<anonymous function>') ->

  run: (args) ->
    runContext = new EvalContext @parentEvalContext

    for arg, i in args
      runContext.variables[@params[i]] = arg

    runContext._debugIdentifier = @name + '(' + args.join(',') + ')'

    return runContext.evalBlock @block

exports.NativeProcedure = class NativeProcedure extends Procedure
  constructor: (@code) ->

  run: (args) -> return @code args

exports.DEFAULT_GLOBALS = DEFAULT_GLOBALS = {
  'DISPLAY': new NativeProcedure((args) ->
     console.log args[0]
     return null
  )
}

exports.createGlobalContext = createGlobalContext = ->
  context = new EvalContext(null)
  for v of DEFAULT_GLOBALS
    context.variables[v] = DEFAULT_GLOBALS[v]
  context._debugIdentifier = '<global context>'
  return context

exports.EvalContext = class EvalContext
  constructor: (@parent, @_debugIdentifier) ->
    @variables = {}

  printClosures: ->
    result = []
    head = @
    until head is null
      result.push head._debugIdentifier
      head = head.parent
    return result.join ', '

  getVar: (variableName) ->
    if variableName of @variables
      return @variables[variableName]
    else if @parent?
      return @parent.getVar variableName
    else
      throw new Error 'Undefined variable: ' + variableName

  setExistentVar: (variableName, value) ->

    if variableName of @variables
      @variables[variableName] = value
      return true

    else if @parent?
      return @parent.setExistentVar variableName

    else
      return false

  setVar: (variableName, value) ->
    unless @setExistentVar variableName, value
      @variables[variableName] = value
    return true

  evalBlock: (block) ->
    for child in block.children
      returnValue = @evalStatement child
      if returnValue?
        return returnValue

    return null

  evalStatement: (statement) ->
    statement = statement.children[0]

    switch statement.type
      when 'assignStatement'
        return @evalAssignStatement statement
      when 'ifStatement'
        return @evalIfStatement statement
      when 'forStatement'
        return @evalForStatement statement
      when 'whileStatement'
        return @evalWhileStatement statement
      when 'repeatStatement'
        return @evalRepeatStatement statement
      when 'expressionStatement'
        return @evalExpressionStatement statement
      when 'procedureStatement'
        return @evalProcedureStatement statement
      when 'returnStatement'
        return @evalReturnStatement statement

  evalAssignStatement: (assignStatement) ->
    variableName = assignStatement.children[0].text
    value = @evalExpression assignStatement.children[2]

    @setVar variableName, value

    return null

  evalIfStatement: (ifStatement) ->
    condition = @evalExpression ifStatement.children[2]

    if condition
      return @evalBlock ifStatement.children[5]
    else if ifStatement.children.length is 11
      return @evalBlock ifStatement.children[9]
    else
      return null

  evalForStatement: (forStatement) ->
    variableName = forStatement.children[2].text
    list = @evalExpression forStatement.children[4]

    for el, i in list
      childContext = new EvalContext(@)
      childContext.evalBlock forStatement.children[6]

    return null

  evalWhileStatement: (whileStatement) ->
    condition = whileStatement.children[2]

    until @evalExpression condition
      result = @evalBlock whileStatement.children[4]
      if result?
        return result

    return null

  evalRepeatStatement: (repeatStatement) ->
    times = @evalExpression repeatStatement.children[1]

    for i in [1..times]
      result = @evalBlock repeatStatement.children[4]
      if result?
        return result

    return null

  evalExpressionStatement: (expressionStatement) ->
    @evalExpression expressionStatement.children[0]
    return null

  toParamList: (paramList) ->
    if paramList.children.length is 3
      result = @toParamList paramList.children[0]
      result.push paramList.children[2].text
      return result

    else
      return [paramList.children[0].text]

  evalProcedureStatement: (procedureStatement) ->
    variableName = procedureStatement.children[1].text
    paramList = @toParamList procedureStatement.children[3]
    block = procedureStatement.children[6]

    @setVar variableName, new Procedure @, paramList, block, variableName

    return null

  evalReturnStatement: (returnStatement) ->
    return @evalExpression returnStatement.children[1]

  evalExpression: (expression) ->
    @evalLogicalOrExpression expression.children[0]

  evalLogicalOrExpression: (logicalOrExpression) ->
    if logicalOrExpression.children.length is 3
      return @evalLogicalOrExpression(logicalOrExpression.children[0]) or @evalLogicalAndExpression(logicalOrExpression.children[1])
    else
      return @evalLogicalAndExpression(logicalOrExpression.children[0])

  evalLogicalAndExpression: (logicalAndExpression) ->
    if logicalAndExpression.children.length is 3
      return @evalLogicalAndExpression(logicalAndExpression.children[0]) and @evalRelationalExpression(logicalAndExpression.children[1])
    else
      return @evalRelationalExpression(logicalAndExpression.children[0])

  evalRelationalExpression: (relationalExpression) ->
    if relationalExpression.children.length is 1
      return @evalAdditiveExpression(relationalExpression.children[0])

    else
      left = @evalRelationalExpression relationalExpression.children[0]
      right = @evalAdditiveExpression relationalExpression.children[2]
      switch relationalExpression.children[1].type
        when 'EqualTo'
          return left is right
        when 'NotEqualTo'
          return left isnt right
        when 'LessThan'
          return left < right
        when 'GreaterThan'
          return left > right
        when 'LessThanOrEqualTo'
          return left <= right
        when 'GreaterThanOrEqualTo'
          return left >= right

  evalAdditiveExpression: (additiveExpression) ->
    if additiveExpression.children.length is 1
      return @evalMultiplicativeExpression additiveExpression.children[0]
    else
      left = @evalAdditiveExpression additiveExpression.children[0]
      right = @evalMultiplicativeExpression additiveExpression.children[2]
      switch additiveExpression.children[1].type
        when 'Plus'
          return left + right
        when 'Minus'
          return left - right

  evalMultiplicativeExpression: (multiplicativeExpression) ->
    if multiplicativeExpression.children.length is 1
      return @evalPrimaryExpression multiplicativeExpression.children[0]
    else
      left = @evalMultiplicativeExpression multiplicativeExpression.children[0]
      right = @evalPrimaryExpression multiplicativeExpression.children[2]
      switch multiplicativeExpression.children[1].type
        when 'Times'
          return left * right
        when 'DividedBy'
          return left / right # TODO integer division
        when 'Mod'
          return left % right

  evalPrimaryExpression: (primaryExpression) ->
    if primaryExpression.children.length is 3
      return @evalExpression primaryExpression.children[1]
    else
      switch primaryExpression.children[0].type
        when 'arrayLiteral'
          return @evalArrayLiteral primaryExpression.children[0]
        when 'functionCall'
          return @evalFunctionCall primaryExpression.children[0]
        when 'Identifier'
          variableName = primaryExpression.children[0].text
          return @getVar(variableName)
        when 'Integer'
          intAsString = primaryExpression.children[0].text
          return parseInt(intAsString)

  # TODO evalArrayLiteral

  evalFunctionCall: (functionCall) ->
    functionName = functionCall.children[0].text
    args = @evalArgumentList functionCall.children[2]

    result = @getVar(functionName).run args
    return result

  evalArgumentList: (argumentList) ->
    if argumentList.children.length is 1
      return [@evalExpression(argumentList.children[0])]
    else
      allButOne = @evalArgumentList argumentList.children[0]
      allButOne.push @evalExpression argumentList.children[1]

      return allButOne

exports.interpret = interpret = (tree) ->
  (new EvalContext(createGlobalContext(), '<MAIN RUNTIME>')).evalBlock tree

