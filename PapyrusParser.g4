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

parser grammar PapyrusParser;

options { tokenVocab=PapyrusLexer; language=Python3; }

script                : terminator header ( COMMENT | definitionOrBlock )* EOF
                      ;

header                : SCRIPTNAME scriptType ( EXTENDS scriptType )? userFlags terminator DOCSTRING?
                      ;

userFlags             : userFlag*
                      ;

userFlag              : NATIVE
                      | GLOBAL
                      | AUTO
                      | AUTOREADONLY
                      | DEBUGONLY
                      | BETAONLY
                      | CONST
                      | ID
                      | HIDDENFLAG   // TODO: without this priority, "Hidden" flag does not tokenize (???)
                      | CONDITIONAL  // TODO: without this priority, "Conditional" flag does not tokenize (???)
                      | MANDATORY    // TODO: without this priority, this rule would fall back to the generic ID
                      ;

definitionOrBlock     : fieldDefinition
                      | customEventDefinition
                      | import_obj
                      | function
                      | eventFunc
                      | stateBlock
                      | propertyBlock
                      | groupBlock
                      | structBlock
                      ;

fieldDefinition       : anyType ID ( EQUALS signedConstant )? userFlags terminator DOCSTRING?
                      ;

customEventDefinition : CUSTOMEVENT ID terminator
                      ;

import_obj            : IMPORT scriptType terminator
                      ;

function              : functionHeader functionBlock?
                      ;

functionHeader        : anyType? FUNCTION ID LPAREN callParameters? RPAREN userFlags terminator DOCSTRING?
                      ;

functionBlock         : NATIVE terminator
                      | terminator ENDFUNCTION
                      | terminator statement* ENDFUNCTION terminator
                      ;

eventFunc             : eventHeader eventBlock
                      ;

eventHeader           : EVENT eventName LPAREN callParameters? RPAREN userFlags terminator DOCSTRING?
                      ;

eventName             : scriptType DOT ID
                      | ID DOT ID
                      | ID
                      ;

eventBlock            : terminator ENDEVENT
                      | terminator statement* ENDEVENT terminator
                      ;

callParameters        : callParameter ( COMMA callParameter )*
                      ;

callParameter         : anyType ID? ( EQUALS signedConstant )?
                      | SCRIPTEVENTNAME ID
                      | CUSTOMEVENTNAME ID
                      | STRUCTVARNAME ID
                      ;

stateBlock            : AUTO? STATE ID terminator stateFuncOrEvent* ENDSTATE terminator
                      ;

stateFuncOrEvent      : function
                      | eventFunc
                      ;

propertyBlock         : propertyHeader ( propertyFunc* ENDPROPERTY )? terminator
                      ;

propertyHeader        : anyType PROPERTY ID ( EQUALS signedConstant )? userFlags terminator DOCSTRING?
                      ;

propertyFunc          : function
                      ;

groupBlock            : groupHeader propertyBlock* ENDGROUP
                      ;

groupHeader           : GROUP ID userFlags terminator DOCSTRING?
                      ;

structBlock           : structHeader fieldDefinition* ENDSTRUCT terminator
                      ;

structHeader          : STRUCT ID terminator
                      ;

statement             : localDefinition
                      | l_value PLUSEQUALS expression terminator
                      | l_value MINUSEQUALS expression terminator
                      | l_value MULTEQUALS expression terminator
                      | l_value DIVEQUALS expression terminator
                      | l_value MODEQUALS expression terminator
                      | l_value EQUALS expression terminator
                      | expression terminator
                      | return_stat
                      | ifBlock
                      | whileBlock
                      ;

l_value               : LPAREN expression RPAREN DOT ID
                      | LPAREN expression RPAREN LBRACKET expression RBRACKET
                      | basic_l_value
                      ;

basic_l_value         : array_func_or_id DOT basic_l_value
                      | func_or_id LBRACKET expression RBRACKET
                      | ID
                      ;

localDefinition       : anyType ID (EQUALS expression CONST?)? terminator DOCSTRING?
                      ;

expression            : and_expression ( OR and_expression )*
                      ;

and_expression        : bool_expression ( AND bool_expression )*
                      ;

bool_expression       : add_expression ( ( EQ | GT | GTE | LT | LTE | NE ) add_expression )*
                      ;

add_expression        : mult_expression ( ( PLUS | MINUS ) mult_expression )*
                      ;

mult_expression       : unary_expression ( ( MULT | DIVIDE | MOD ) unary_expression )*
                      ;

unary_expression      : MINUS cast_atom
                      | NOT cast_atom
                      | cast_atom
                      ;

cast_atom             : dot_atom ( ( AS | IS ) anyType )?
                      ;

dot_atom              : array_atom ( DOT array_func_or_id )*
                      | unsignedConstant
                      ;

array_atom            : atom ( LBRACKET expression RBRACKET )
                      | atom
                      ;

atom                  : LPAREN expression RPAREN
                      | new_expr
                      | func_or_id
                      ;

new_expr              : NEW BASETYPE LBRACKET expression RBRACKET
                      | NEW scriptType ( LBRACKET expression RBRACKET )?
                      ;

array_func_or_id      : function_call LBRACKET expression RBRACKET
                      | ID LBRACKET expression RBRACKET
                      | func_or_id
                      ;

func_or_id            : function_call
                      | scriptType
                      | LENGTH
                      ;

return_stat           : RETURN expression? terminator
                      ;

ifBlock               : IF expression terminator statement* elseIfBlock* elseBlock? ENDIF terminator
                      ;

elseIfBlock           : ELSEIF expression terminator statement*
                      ;

elseBlock             : ELSE terminator statement*
                      ;

whileBlock            : WHILE expression terminator statement* ENDWHILE terminator
                      ;

function_call         : ID LPAREN parameters? RPAREN
                      ;

parameters            : parameter ( COMMA parameter )*
                      ;

parameter             : ( ID EQUALS )? expression
                      ;

signedConstant        : signedNumber
                      | STRING
                      | BOOL
                      | NONE
                      ;

unsignedConstant      : unsignedNumber
                      | STRING
                      | BOOL
                      | NONE
                      ;

signedNumber          : MINUS unsignedNumber
                      | unsignedNumber
                      ;

unsignedNumber        : INTEGER
                      | FLOAT
                      ;

anyType               : scriptType
                      | scriptType LBRACKET RBRACKET
                      | BASETYPE
                      | BASETYPE LBRACKET RBRACKET
                      ;

scriptType            : ID ( COLON ID )*
                      ;

terminator            : COMMENT? EOL*
                      ;
