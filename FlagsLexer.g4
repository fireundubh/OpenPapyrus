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

lexer grammar FlagsLexer;

FLAG        : F L A G;

SCRIPT      : S C R I P T;

PROPERTY    : P R O P E R T Y;

VARIABLE    : V A R I A B L E;

STRUCTVAR   : S T R U C T V A R;

FUNCTION    : F U N C T I O N;

GROUP       : G R O U P;

OPEN_BRACE  : '{';

CLOSE_BRACE : '}';

AND         : '&';

ID          : ALPHA ( NUMBER | ALPHA+ );

NUMBER      : DIGIT+;

WS          : WS_CHAR+
            -> skip;

COMMENT     : ( '/*' .*? '*/'
            | '//' ~[\n]* )
            -> skip;

fragment A  : [aA];
fragment B  : [bB];
fragment C  : [cC];
fragment D  : [dD];
fragment E  : [eE];
fragment F  : [fF];
fragment G  : [gG];
fragment H  : [hH];
fragment I  : [iI];
fragment J  : [jJ];
fragment K  : [kK];
fragment L  : [lL];
fragment M  : [mM];
fragment N  : [nN];
fragment O  : [oO];
fragment P  : [pP];
fragment Q  : [qQ];
fragment R  : [rR];
fragment S  : [sS];
fragment T  : [tT];
fragment U  : [uU];
fragment V  : [vV];
fragment W  : [wW];
fragment X  : [xX];
fragment Y  : [yY];
fragment Z  : [zZ];

fragment
ALPHA       : [a-zA-Z_];

fragment
DIGIT       : [0-9];

fragment
WS_CHAR     : [ \t\n\r];
