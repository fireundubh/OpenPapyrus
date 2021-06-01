/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * MIT License
 *
 * Copyright 2021 Open Papyrus Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

lexer grammar PapyrusLexer;

SCRIPTNAME      : S C R I P T N A M E;

FUNCTION        : F U N C T I O N;

ENDFUNCTION     : E N D F U N C T I O N;

EVENT           : E V E N T;

ENDEVENT        : E N D E V E N T;

CUSTOMEVENT     : C U S T O M E V E N T;

NATIVE          : N A T I V E;

GLOBAL          : G L O B A L;

CONST           : C O N S T;

DEBUGONLY       : D E B U G O N L Y;

BETAONLY        : B E T A O N L Y;

RETURN          : R E T U R N;

AS              : A S;

IS              : I S;

IF              : I F;

ELSEIF          : E L S E I F;

ELSE            : E L S E;

ENDIF           : E N D I F;

EXTENDS         : E X T E N D S;

IMPORT          : I M P O R T;

HIDDENFLAG      : H I D D E N;

CONDITIONAL     : C O N D I T I O N A L;

MANDATORY       : M A N D A T O R Y;

AUTO            : A U T O;

AUTOREADONLY    : A U T O R E A D O N L Y;

STRUCT          : S T R U C T;

ENDSTRUCT       : E N D S T R U C T;

STATE           : S T A T E;

ENDSTATE        : E N D S T A T E;

PROPERTY        : P R O P E R T Y;

ENDPROPERTY     : E N D P R O P E R T Y;

GROUP           : G R O U P;

ENDGROUP        : E N D G R O U P;

WHILE           : W H I L E;

ENDWHILE        : E N D W H I L E;

SCRIPTEVENTNAME : S C R I P T E V E N T N A M E;

CUSTOMEVENTNAME : C U S T O M E V E N T N A M E;

STRUCTVARNAME   : S T R U C T V A R N A M E;

DEPENDENTTYPE   : D E P E N D E N T T Y P E;

VOID            : V O I D;

BASETYPE        : I N T
                | F L O A T
                | S T R I N G
                | B O O L
//                | V A R
                ;

NONE            : N O N E;

NEW             : N E W;

LENGTH          : L E N G T H;

BOOL            : T R U E
                | F A L S E
                ;

ID              : [A-Z_a-z] ([0-9A-Z_a-z]+)?
                ;

INTEGER         : DIGIT+
                | '0' X (DIGIT | HEX_DIGIT)+
                ;

FLOAT           : DIGIT+ (DOT DIGIT+)
                | DOT DIGIT+
                ;

STRING          : DQUOTE .*? DQUOTE;

DOCSTRING       : LBRACE .*? RBRACE
                | LBRACE RBRACE
                ;

LPAREN          : '(';

RPAREN          : ')';

LBRACE          : '{';

RBRACE          : '}';

LBRACKET        : '[';

RBRACKET        : ']';

COMMA           : ',';

EQUALS          : '=';

PLUS            : '+';

MINUS           : '-';

MULT            : '*';

DIVIDE          : '/';

MOD             : '%';

DOT             : '.';

DQUOTE          : '"';

NOT             : '!';

EQ              : '==';

NE              : '!=';

GT              : '>';

LT              : '<';

GTE             : '>=';

LTE             : '<=';

OR              : '||';

AND             : '&&';

COLON           : ':';

PLUSEQUALS      : '+=';

MINUSEQUALS     : '-=';

MULTEQUALS      : '*=';

DIVEQUALS       : '/=';

MODEQUALS       : '%=';

EOL             : '\r'? '\n'
                -> skip;

WS              : WS_CHAR+
                -> skip;

EAT_EOL         : '\\' WS_CHAR* EOL
                -> skip;

COMMENT         : (';/' .*? '/;'
                | ';' ~[\n]*);

fragment A      : [aA];
fragment B      : [bB];
fragment C      : [cC];
fragment D      : [dD];
fragment E      : [eE];
fragment F      : [fF];
fragment G      : [gG];
fragment H      : [hH];
fragment I      : [iI];
fragment J      : [jJ];
fragment K      : [kK];
fragment L      : [lL];
fragment M      : [mM];
fragment N      : [nN];
fragment O      : [oO];
fragment P      : [pP];
fragment Q      : [qQ];
fragment R      : [rR];
fragment S      : [sS];
fragment T      : [tT];
fragment U      : [uU];
fragment V      : [vV];
fragment W      : [wW];
fragment X      : [xX];
fragment Y      : [yY];
fragment Z      : [zZ];

fragment
ALPHA           : [a-zA-Z]
                ;

fragment
DIGIT           : '0'..'9'
                ;

fragment
HEX_DIGIT       : [a-fA-F]
                ;

fragment
WS_CHAR         : [ \t]
                ;
