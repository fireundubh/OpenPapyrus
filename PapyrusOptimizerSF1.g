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

parser grammar PapyrusOptimizerSF1;

options { tokenVocab=PapyrusLexerSF1; language=CSharp3; }

// ============================================================================
// TOP-LEVEL SCRIPT STRUCTURE
// ============================================================================

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

fieldDefinition       : VAR anyType ID USER_FLAGS constant?
                      ;

// ============================================================================
// FUNCTION DEFINITIONS
// ============================================================================

function              : FUNCTION functionHeader codeBlock?
                      ;

functionHeader        : anyType ID USER_FLAGS callParameters? functionModifier DOCSTRING?
                      | NONE ID USER_FLAGS callParameters? functionModifier DOCSTRING?
                      ;

functionModifier      : (GLOBAL | NATIVE)?
                      ;

// ============================================================================
// EVENT DEFINITIONS
// ============================================================================

eventFunc             : EVENT eventHeader codeBlock?
                      ;

eventHeader           : HEADER NONE ID USER_FLAGS callParameters? NATIVE? DOCSTRING?
                      ;

// ============================================================================
// PARAMETERS
// ============================================================================

callParameters        : callParameter*
                      ;

callParameter         : PARAM anyType ID constant?
                      ;

// ============================================================================
// STATE BLOCKS
// ============================================================================

stateBlock            : STATE ID AUTO? stateFuncOrEvent*
                      ;

stateFuncOrEvent      : function
                      | eventFunc
                      ;

// ============================================================================
// PROPERTY BLOCKS
// ============================================================================

propertyBlock         : PROPERTY propertyHeader propertyFunc propertyBlock
                      | AUTOPROP propertyHeader ID
                      ;

propertyHeader        : HEADER anyType ID USER_FLAGS DOCSTRING?
                      ;

propertyFunc          : PROPFUNC function
                      | PROPFUNC
                      ;

// ============================================================================
// CODE BLOCKS AND STATEMENTS
// ============================================================================

codeBlock             : BLOCK statement*
                      ;

// Statement types that the optimizer navigates
// Note: Lock blocks (LOCKGUARD, TRYLOCKGUARD) are handled as control flow
// structures similar to if/while blocks. They don't require special
// optimization because:
// - Guards are synchronization primitives (no constant values to fold)
// - Lock acquisition is runtime-determined (no compile-time evaluation)
// - Semantic validation occurs in earlier compiler passes
statement             : localDefinition
                      | EQUALS ID autoCast l_value expression
                      | expression
                      | return_stat
                      | ifBlock
                      | whileBlock
                      ;

localDefinition       : VAR anyType ID autoCast expression
                      | VAR anyType ID
                      ;

// ============================================================================
// L-VALUES (Left-hand side of assignments)
// ============================================================================

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

// ============================================================================
// EXPRESSIONS (Optimization targets)
// ============================================================================

// Logical OR expressions
// singleValueBoolOps optimizes: true OR X -> true, false OR X -> X
// doubleValueBoolOps folds: true OR false -> true
expression            : OR ID expression and_expression
                      | and_expression
                      ;

// Logical AND expressions
// singleValueBoolOps optimizes: false AND X -> false, true AND X -> X
// doubleValueBoolOps folds: true AND false -> false
and_expression        : AND ID and_expression bool_expression
                      | bool_expression
                      ;

// Boolean comparison expressions
// doubleValueMathOps can fold comparisons when both sides are constants
// The ID token stores temporary variable names during AST construction
bool_expression       : EQ ID autoCast autoCast bool_expression add_expression
                      | NE ID autoCast autoCast bool_expression add_expression
                      | GT ID autoCast autoCast bool_expression add_expression
                      | LT ID autoCast autoCast bool_expression add_expression
                      | GTE ID autoCast autoCast bool_expression add_expression
                      | LTE ID autoCast autoCast bool_expression add_expression
                      | add_expression
                      ;

// Addition/subtraction expressions
// doubleValueMathOps folds:
// - IADD: integer addition (5 + 3 -> 8)
// - FADD: float addition (2.0 + 1.5 -> 3.5)
// - ISUBTRACT: integer subtraction (10 - 3 -> 7)
// - FSUBTRACT: float subtraction (5.0 - 2.0 -> 3.0)
// - STRCAT: string concatenation ("Hello" + " World" -> "Hello World")
add_expression        : IADD ID autoCast autoCast add_expression mult_expression
                      | FADD ID autoCast autoCast add_expression mult_expression
                      | ISUBTRACT ID autoCast autoCast add_expression mult_expression
                      | FSUBTRACT ID autoCast autoCast add_expression mult_expression
                      | STRCAT ID autoCast autoCast add_expression mult_expression
                      | mult_expression
                      ;

// Multiplication/division expressions
// doubleValueMathOps folds:
// - IMULTIPLY: integer multiplication (4 * 5 -> 20)
// - FMULTIPLY: float multiplication (2.0 * 3.0 -> 6.0)
// - IDIVIDE: integer division (10 / 2 -> 5)
// - FDIVIDE: float division (6.0 / 2.0 -> 3.0) with epsilon check
// - MOD: modulo operation (10 % 3 -> 1)
mult_expression       : IMULTIPLY ID autoCast autoCast mult_expression unary_expression
                      | FMULTIPLY ID autoCast autoCast mult_expression unary_expression
                      | IDIVIDE ID autoCast autoCast mult_expression unary_expression
                      | FDIVIDE ID autoCast autoCast mult_expression unary_expression
                      | MOD ID mult_expression unary_expression
                      | unary_expression
                      ;

// Unary expressions
// unaryOps folds:
// - INEGATE: integer negation (-5 -> -5 token, -(-5) -> 5)
// - FNEGATE: float negation (-(2.0) -> -2.0)
// - NOT: boolean negation (NOT true -> false)
unary_expression      : INEGATE ID cast_atom
                      | FNEGATE ID cast_atom
                      | NOT ID cast_atom
                      | cast_atom
                      ;

// Type casting
// rawCastOps removes redundant casts:
// - Int to Int cast (removed)
// - Float to Float cast (removed)
// - Object to same type cast (removed if inheritance allows)
cast_atom             : AS ID dot_atom
                      | dot_atom
                      ;

// Dot accessor expressions
// eliminateExcessDots consolidates redundant dot operators
dot_atom              : DOT dot_atom array_func_or_id
                      | array_atom
                      | constant
                      ;

// Array access expressions
array_atom            : ARRAYGET ID ID autoCast atom expression
                      | atom
                      ;

// Atomic expressions
// eliminateParens removes safe parentheses when they don't affect precedence
atom                  : PAREXPR expression
                      | NEW INTEGER ID
                      | func_or_id
                      ;

// ============================================================================
// FUNCTION AND ARRAY OPERATIONS
// ============================================================================

array_func_or_id      : ARRAYGET ID ID autoCast func_or_id expression
                      | func_or_id
                      ;

func_or_id            : function_call
                      | PROPGET ID ID ID
                      | ID
                      | LENGTH ID ID
                      ;

property_set          : PROPSET ID ID ID
                      ;

// ============================================================================
// CONTROL FLOW
// ============================================================================

return_stat           : RETURN autoCast expression
                      | RETURN
                      ;

ifBlock               : IF expression codeBlock elseIfBlock* elseBlock?
                      ;

elseIfBlock           : ELSEIF expression codeBlock
                      ;

elseBlock             : ELSE codeBlock
                      ;

whileBlock            : WHILE expression codeBlock
                      ;

// ============================================================================
// FUNCTION CALLS
// ============================================================================

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

// ============================================================================
// TYPE CASTING AND CONSTANTS
// ============================================================================

// autoCast represents automatic type conversion in the AST
// The optimizer uses this to track cast operations for rawCastOps
autoCast              : AS ID ID
                      | AS ID constant
                      | ID
                      | constant
                      ;

constant              : number
                      | STRING
                      | BOOL
                      | NONE
                      ;

// Note: MINUS is handled in unary_expression, not here
// This is intentional - sign is part of expression parsing, not tokenization
number                : (INTEGER | FLOAT)
                      ;

// ============================================================================
// TYPE SYSTEM
// ============================================================================

anyType               : ID
                      | ID LBRACKET RBRACKET
                      | BASETYPE
                      | BASETYPE LBRACKET RBRACKET
                      ;
