/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * MIT License
 *
 * Copyright 2026 Open Papyrus Project
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

parser grammar PapyrusOptimizeWalkerSSE;

options { tokenVocab=PapyrusLexerSSE; language=Python3; }

// Top-level script structure
// Semantic parameters: ScriptObjectType akObj, OptimizePass aePassType
script                : OBJECT header definitionOrBlock* EOF
                      ;

header                : ID USER_FLAGS ID? DOCSTRING?
                      ;

definitionOrBlock     : fieldDefinition
                      | function
                      | eventFunc
                      | stateBlock
                      | propertyBlock
                      ;

// Field definition (variable declaration at script level)
fieldDefinition       : VAR type ID USER_FLAGS constant?
                      ;

// Function definition
// Semantic parameters: string asState, string asPropertyName
function              : FUNCTION functionHeader codeBlock?
                      ;

functionHeader        : type ID USER_FLAGS callParameters? functionModifier DOCSTRING?
                      | NONE ID USER_FLAGS callParameters? functionModifier DOCSTRING?
                      ;

functionModifier      : (GLOBAL | NATIVE)?
                      ;

// Event definition
// Semantic parameter: string asState
eventFunc             : EVENT eventHeader codeBlock?
                      ;

eventHeader           : HEADER NONE ID USER_FLAGS callParameters? NATIVE? DOCSTRING?
                      ;

// Call parameters (function/event parameters)
callParameters        : callParameter*
                      ;

callParameter         : PARAM type ID constant?
                      ;

// State block
stateBlock            : STATE ID AUTO? stateFuncOrEvent*
                      ;

// Semantic parameter: string asStateName
stateFuncOrEvent      : function
                      | eventFunc
                      ;

// Property block
propertyBlock         : PROPERTY propertyHeader propertyFunc propertyBlock
                      | AUTOPROP propertyHeader ID
                      ;

propertyHeader        : HEADER type ID USER_FLAGS DOCSTRING?
                      ;

// Semantic parameter: string asPropName
propertyFunc          : PROPFUNC function
                      | PROPFUNC
                      ;

// Code block (statement list)
// Semantic parameter: ScriptScope akCurrentScope
codeBlock             : BLOCK statement*
                      ;

// Statements
statement             : localDefinition
                      | EQUALS ID autoCast l_value expression
                      | expression
                      | return_stat
                      | ifBlock
                      | whileBlock
                      ;

// Local variable definition
// Note: VARCLEANUP pass tracks variable usage here
localDefinition       : VAR type ID autoCast expression
                      | VAR type ID
                      ;

// Left-hand side value (assignment target)
l_value               : DOT PAREXPR expression property_set
                      | ARRAYSET ID ID autoCast PAREXPR expression expression
                      | basic_l_value
                      ;

basic_l_value         : DOT array_func_or_id basic_l_value
                      | function_call
                      | property_set
                      | ARRAYSET ID ID autoCast func_or_id expression
                      | ID
                      ;

// Expression hierarchy (operator precedence)
// Logical OR (lowest precedence)
expression            : OR ID expression and_expression
                      | and_expression
                      ;

// Logical AND
and_expression        : AND ID and_expression bool_expression
                      | bool_expression
                      ;

// Boolean comparisons (==, !=, <, >, <=, >=)
bool_expression       : EQ ID autoCast autoCast bool_expression add_expression
                      | NE ID autoCast autoCast bool_expression add_expression
                      | GT ID autoCast autoCast bool_expression add_expression
                      | LT ID autoCast autoCast bool_expression add_expression
                      | GTE ID autoCast autoCast bool_expression add_expression
                      | LTE ID autoCast autoCast bool_expression add_expression
                      | add_expression
                      ;

// Additive operations (+, -, string concatenation)
add_expression        : IADD ID autoCast autoCast add_expression mult_expression
                      | FADD ID autoCast autoCast add_expression mult_expression
                      | ISUBTRACT ID autoCast autoCast add_expression mult_expression
                      | FSUBTRACT ID autoCast autoCast add_expression mult_expression
                      | STRCAT ID autoCast autoCast add_expression mult_expression
                      | mult_expression
                      ;

// Multiplicative operations (*, /, %)
mult_expression       : IMULTIPLY ID autoCast autoCast mult_expression unary_expression
                      | FMULTIPLY ID autoCast autoCast mult_expression unary_expression
                      | IDIVIDE ID autoCast autoCast mult_expression unary_expression
                      | FDIVIDE ID autoCast autoCast mult_expression unary_expression
                      | MOD ID mult_expression unary_expression
                      | unary_expression
                      ;

// Unary operations (-, !)
unary_expression      : INEGATE ID cast_atom
                      | FNEGATE ID cast_atom
                      | NOT ID cast_atom
                      | cast_atom
                      ;

// Type casting
cast_atom             : AS ID dot_atom
                      | dot_atom
                      ;

// Member access (dot notation)
dot_atom              : DOT dot_atom array_func_or_id
                      | array_atom
                      | constant
                      ;

// Array element access
array_atom            : ARRAYGET ID ID autoCast atom expression
                      | atom
                      ;

// Atomic expressions (highest precedence)
atom                  : PAREXPR expression
                      | NEW INTEGER ID
                      | func_or_id
                      ;

// Array element access or function/identifier
array_func_or_id      : ARRAYGET ID ID autoCast func_or_id expression
                      | func_or_id
                      ;

// Function call, property get, array length, or identifier
func_or_id            : function_call
                      | PROPGET ID ID ID
                      | ID
                      | LENGTH ID ID
                      ;

// Property setter
property_set          : PROPSET ID ID ID
                      ;

// Return statement
return_stat           : RETURN autoCast expression
                      | RETURN
                      ;

// Control flow statements
ifBlock               : IF expression codeBlock elseIfBlock* elseBlock?
                      ;

elseIfBlock           : ELSEIF expression codeBlock
                      ;

elseBlock             : ELSE codeBlock
                      ;

whileBlock            : WHILE expression codeBlock
                      ;

// Function calls
function_call         : CALL ID ID ID CALLPARAMS parameters
                      | CALLPARENT ID ID ID CALLPARAMS parameters
                      | CALLGLOBAL ID ID ID CALLPARAMS parameters
                      | ARRAYFIND ID ID CALLPARAMS parameters
                      | ARRAYRFIND ID ID CALLPARAMS parameters
                      ;

parameters            : parameter*
                      ;

parameter             : PARAM autoCast expression
                      ;

// Auto-casting for type conversions
// Note: NORMAL pass may optimize out redundant casts
autoCast              : AS ID ID
                      | AS ID constant
                      | ID
                      | constant
                      ;

// Constant values
constant              : number
                      | STRING
                      | BOOL
                      | NONE
                      ;

number                : (INTEGER | FLOAT)
                      ;

// Type specification (renamed from anyType to match implementation)
type                  : ID
                      | ID LBRACKET RBRACKET
                      | BASETYPE
                      | BASETYPE LBRACKET RBRACKET
                      ;
