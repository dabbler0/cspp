grammar CSPP;

block
  : statement*
  ;

statement
  : assignStatement
  | ifStatement
  | forStatement
  | expressionStatement
  | whileStatement
  | repeatStatement
  | procedureStatement
  | returnStatement
  ;

assignStatement
  : Identifier LeftArrow expression
  ;

ifStatement
  : 'IF' '(' expression ')' '{' block '}'
  | 'IF' '(' expression ')' '{' block '}' 'ELSE' '{' block '}'
  ;

forStatement
  : 'FOR' 'EACH' Identifier 'IN' expression '{' block '}'
  ;

whileStatement
  : 'REPEAT' 'UNTIL' expression '{' block '}'
  ;

repeatStatement
  : 'REPEAT' expression 'TIMES' '{' block '}'
  ;

expressionStatement
  : expression
  ;

procedureStatement
  : 'PROCEDURE' Identifier '(' paramList ')' '{' block '}'
  ;

paramList
  : Identifier
  | paramList ',' Identifier
  ;

returnStatement
  : 'RETURN' expression
  ;

expression
  : logicalOrExpression
  ;

logicalOrExpression
  : logicalAndExpression
  | logicalOrExpression 'OR' logicalAndExpression
  ;

logicalAndExpression
  : relationalExpression
  | logicalAndExpression 'AND' relationalExpression
  ;

relationalExpression
  : additiveExpression
  | relationalExpression '=' additiveExpression
  | relationalExpression NotEqualTo additiveExpression
  | relationalExpression '<' additiveExpression
  | relationalExpression '>' additiveExpression
  | relationalExpression GreaterThanOrEqualTo additiveExpression
  | relationalExpression LessThanOrEqualTo additiveExpression
  ;

additiveExpression
  : multiplicativeExpression
  | additiveExpression '+' multiplicativeExpression
  | additiveExpression '-' multiplicativeExpression
  ;

multiplicativeExpression
  : primaryExpression
  | multiplicativeExpression '*' primaryExpression
  | multiplicativeExpression '/' primaryExpression
  | multiplicativeExpression 'MOD' primaryExpression
  ;

primaryExpression
  : arrayLiteral
  | functionCall
  | Identifier
  | Integer
  | '(' expression ')'
  ;

arrayLiteral
  : '[' arrayList ']'
  ;

arrayList
  : expression
  | arrayList ',' expression
  ;

argumentList
  : expression
  | argumentList ',' expression
  ;

functionCall
  : Identifier '(' argumentList ')'
  ;

LParen : '(' ;
RParen : ')';

If : 'IF' ;
Else : 'ELSE' ;
While : 'WHILE' ;
Until : 'UNTIL' ;
For : 'FOR' ;
Each : 'EACH' ;
In : 'IN' ;
Procedure : 'PROCEDURE' ;
Return : 'RETURN' ;

Plus : '+' ;
Minus : '-' ;
Times : '*' ;
DividedBy : '/' ;
Mod : 'MOD' ;
Or : 'OR' ;
And : 'AND' ;
Not : 'NOT' ;
LeftArrow : '<-' ; // TODO change to unicode leftarrow
EqualTo : '=' ;
LessThan : '<' ;
GreaterThan : '>' ;
NotEqualTo : '!=' ; // TODO change to unicode neq
GreaterThanOrEqualTo : '>=' ; // TODO change to unique geq
LessThanOrEqualTo : '<=' ; // TODO change to unique leq

Identifier : [a-zA-Z_] [0-9a-zA-Z]* ;
Integer : [0-9]+ ;

Whitespace : [ \t\n]+ -> skip ;

