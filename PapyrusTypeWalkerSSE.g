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

tree grammar PapyrusTypeWalkerSSE;

options { tokenVocab=PapyrusLexerSSE; ASTLabelType=CommonTree; language=CSharp3; }

// Top-level script structure
// Semantic parameters: ScriptObjectType akObj, Compiler akCompiler,
//                      Dictionary<string,ScriptObjectType> akKnownTypes, Stack<string> akChildNames
// Initializes type system with built-in types (int, float, string, bool)
// Loads parent class if specified in header
script                : ^(OBJECT header definitionOrBlock*)
                      ;

// Script header with optional parent class
// Validates parent class exists and is not a built-in type
// Checks for circular inheritance (cannot extend self or child)
header                : ^(ID USER_FLAGS ID? DOCSTRING?)
                      ;

// Top-level definitions
definitionOrBlock     : fieldDefinition
                      | import_obj
                      | function
                      | eventFunc
                      | stateBlock
                      | propertyBlock
                      ;

// Field definition (script-level variable)
// Validates type exists and is known
// Checks initial value matches declared type
// Ensures variable name doesn't conflict with type names
fieldDefinition       : ^(VAR type ID USER_FLAGS constant?)
                      ;

// Import statement
// Loads imported script type and adds to kImportedTypes
import_obj            : ^(IMPORT ID)
                      ;

// Function definition
// Semantic parameters: string asStateName, string asPropertyName
// Validates function signature against parent class overrides
// Checks return type consistency
// Validates GLOBAL/NATIVE modifiers
function              : ^(FUNCTION functionHeader codeBlock?)
                      ;

functionHeader        : ^(HEADER type ID USER_FLAGS callParameters? functionModifier* DOCSTRING?)
                      | ^(HEADER NONE ID USER_FLAGS callParameters? functionModifier* DOCSTRING?)
                      ;

functionModifier      : GLOBAL
                      | NATIVE
                      ;

// Event definition
// Semantic parameter: string asStateName
// Validates event signature against parent class
// Checks NATIVE modifier validity
eventFunc             : ^(EVENT eventHeader codeBlock?)
                      ;

eventHeader           : ^(HEADER NONE ID USER_FLAGS callParameters? NATIVE? DOCSTRING?)
                      ;

// Function/event parameters
callParameters        : callParameter*
                      ;

// Parameter with optional default value
// Validates default value matches parameter type
callParameter         : ^(PARAM type ID constant?)
                      ;

// State block definition
stateBlock            : ^(STATE ID AUTO? stateFuncOrEvent*)
                      ;

// Semantic parameter: string asStateName
stateFuncOrEvent      : function
                      | eventFunc
                      ;

// Property block definition
// Can be auto-property or full property with get/set functions
propertyBlock         : ^(PROPERTY propertyHeader propertyFunc propertyFunc?)
                      | ^(AUTOPROP propertyHeader ID)
                      ;

propertyHeader        : ^(HEADER type ID USER_FLAGS DOCSTRING?)
                      ;

// Property function (get or set)
// Semantic parameter: string asPropName
// Validates getter returns property type, setter accepts property type
propertyFunc          : ^(PROPFUNC function)
                      ;

// Code block (statement list with scope)
// Semantic parameters: ScriptFunctionType akFunctionType, ScriptScope akCurrentScope
// Manages variable scope for local definitions
// Tracks temporary variables created during type checking
codeBlock             : ^(BLOCK statement*)
                      ;

// Statements
statement             : localDefinition
                      | ^(EQUALS l_value expression)  // Type-checked assignment with auto-cast
                      | expression                     // Expression statement (e.g., function call)
                      | return_stat
                      | ifBlock
                      | whileBlock
                      ;

// Local variable definition
// Validates type exists and name doesn't conflict with script variables/properties
// Checks initial value type matches declared type
// Inserts auto-cast if needed
localDefinition       : ^(VAR type ID expression?)
                      ;

// L-value (assignment target)
// Returns kType for type checking against r-value
l_value               : ^(DOT ^(PAREXPR expression) ID)      // Property setter: expr.prop = value
                      | ^(ARRAYSET ^(PAREXPR expression) expression)  // Array element: expr[idx] = value
                      | basic_l_value
                      ;

// Basic l-value (simple assignment targets)
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
// Validates property setters exist and are writable
basic_l_value         : ^(DOT array_func_or_id basic_l_value?)  // Member access chain
                      | ^(ARRAYSET func_or_id expression)         // Array element access
                      | ID                                         // Simple variable
                      ;

// Expression hierarchy (returns type information)
// All expression rules compute result type and may insert auto-casts

// Logical OR (returns bool)
expression            : ^(OR expression and_expression)
                      | and_expression
                      ;

// Logical AND (returns bool)
and_expression        : ^(AND and_expression bool_expression)
                      | bool_expression
                      ;

// Boolean comparisons (returns bool)
// Auto-casts operands to common type if compatible
bool_expression       : ^(EQ bool_expression add_expression)     // Equal
                      | ^(NE bool_expression add_expression)     // Not equal
                      | ^(GT bool_expression add_expression)     // Greater than
                      | ^(LT bool_expression add_expression)     // Less than
                      | ^(GTE bool_expression add_expression)    // Greater or equal
                      | ^(LTE bool_expression add_expression)    // Less or equal
                      | add_expression
                      ;

// Additive operations
// Returns int, float, or string (for concatenation)
// Auto-casts operands to common type (int/float promotion, string concat)
add_expression        : ^(PLUS add_expression mult_expression)   // Generic addition (rewritten to IADD/FADD/STRCAT)
                      | ^(MINUS add_expression mult_expression)  // Generic subtraction (rewritten to ISUBTRACT/FSUBTRACT)
                      | mult_expression
                      ;

// Multiplicative operations
// Returns int or float
// Auto-casts operands to common type (int/float promotion)
mult_expression       : ^(MULT mult_expression unary_expression)   // Generic multiply (rewritten to IMULTIPLY/FMULTIPLY)
                      | ^(DIVIDE mult_expression unary_expression) // Generic divide (rewritten to IDIVIDE/FDIVIDE)
                      | ^(MOD mult_expression unary_expression)    // Modulo (int only)
                      | unary_expression
                      ;

// Unary operations
// Validates operand type is numeric (for negation) or any (for NOT)
unary_expression      : ^(UNARY_MINUS cast_atom)  // Negation (rewritten to INEGATE/FNEGATE)
                      | ^(NOT cast_atom)          // Logical NOT (returns bool)
                      | cast_atom
                      ;

// Type casting
// Validates cast is valid (compatible types or upcast)
cast_atom             : ^(AS dot_atom type)
                      | dot_atom
                      ;

// Member access (dot notation)
// Validates properties and functions exist on object type
dot_atom              : ^(DOT dot_atom array_func_or_id)
                      | array_atom
                      | constant
                      ;

// Array element access
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
// Validates index type is int, returns array element type
array_atom            : ^(ARRAYGET atom expression)
                      | atom
                      ;

// Atomic expressions
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
atom                  : ^(PAREXPR expression)              // Parenthesized expression
                      | ^(NEW (BASETYPE | ID) INTEGER)     // Array allocation
                      | func_or_id
                      ;

// Array element access or function/identifier
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
array_func_or_id      : ^(ARRAYGET func_or_id expression)
                      | func_or_id
                      ;

// Function call, property get, array length, or identifier
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
// Validates function signatures, property getters, and returns appropriate type
func_or_id            : function_call
                      | ^(PROPGET ID ID)      // Property getter access
                      | ID                    // Variable reference
                      | ^(LENGTH ID)          // Array.Length property
                      ;

// Return statement
// Validates return type matches function signature
// Inserts auto-cast if needed
return_stat           : ^(RETURN expression?)
                      ;

// Control flow statements
ifBlock               : ^(IF expression codeBlock elseIfBlock* elseBlock?)
                      ;

elseIfBlock           : ^(ELSEIF expression codeBlock)
                      ;

elseBlock             : ^(ELSE codeBlock)
                      ;

whileBlock            : ^(WHILE expression codeBlock)
                      ;

// Function call (all variants)
// Semantic parameters: ScriptVariableType akSelfType, string asSelfName
// Validates:
// - Function exists on target type (or in parent hierarchy)
// - Parameter types match (with auto-casting)
// - GLOBAL functions not called on variables
// - Member functions not called on types alone
// - Array functions (Find, RFind) called on arrays
function_call         : ^(CALL ID ^(CALLPARAMS parameters?))        // Member function call
                      | ^(CALLPARENT ID ^(CALLPARAMS parameters?))  // Parent function call
                      | ^(CALLGLOBAL ID ^(CALLPARAMS parameters?))  // Global function call
                      | ^(ARRAYFIND ID ^(CALLPARAMS parameters?))   // Array.Find
                      | ^(ARRAYRFIND ID ^(CALLPARAMS parameters?))  // Array.RFind
                      ;

parameters            : parameter*
                      ;

// Function parameter (actual argument)
// Validates parameter type matches expected type
// Inserts auto-cast if needed
parameter             : ^(PARAM ID? expression)
                      ;

// Constant values (literals)
constant              : number
                      | STRING
                      | BOOL
                      | NONE
                      ;

number                : INTEGER
                      | FLOAT
                      ;

// Type specification
// Validates type is known (built-in or loaded script)
type                  : ID                      // Simple type
                      | ID LBRACKET RBRACKET    // Array type
                      | BASETYPE                // Built-in type reference
                      | BASETYPE LBRACKET RBRACKET  // Built-in array type
                      ;
