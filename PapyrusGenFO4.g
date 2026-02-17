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

tree grammar PapyrusGenFO4;

options {
    tokenVocab = PapyrusParserFO4;
    ASTLabelType = CommonTree;
}

/*
================================================================================
  TOP-LEVEL SCRIPT RULE
================================================================================

  Entry point for code generation. Processes complete script object.

  Parameters:
    - asSourceFilename: Source file path for .info metadata
    - akObj: ScriptObjectType from semantic analysis phase

  Returns:
    - Template containing complete object definition

  Scope Stack: script_scope
*/

script[string asSourceFilename, ScriptObjectType akObj]
scope {
    string sobjName;                    // Script name
    string sparentName;                 // Parent script name
    IList pobjStructDefinitionsA;       // Struct definitions (FO4)
    IList pobjVarDefinitionsA;          // Variable definitions
    IList pobjPropDefinitionsA;         // Property definitions
    IList pobjPropGroupDefinitionsA;    // Property group definitions (FO4)
    IList pobjUngroupedPropsA;          // Ungrouped property names
    string sinitialState;               // Initial state name (or null)
    IList pobjEmptyStateA;              // Empty state functions/events
    Hashtable pstates;                  // State name → state functions
    bool bhasBeginStateEvent;           // Has OnBeginState event
    bool bhasEndStateEvent;             // Has OnEndState event
    string smodTimeUnix;                // File modification time (Unix)
    string scompileTimeUnix;            // Compilation time (Unix)
    string sfileName;                   // Source filename (quoted)
    string suserName;                   // Username (quoted)
    string scomputerName;               // Computer name (quoted)
    string sobjFlags;                   // User flags bitmask
    string sdocString;                  // Script documentation
    string sconst;                      // "const" or ""
    Hashtable puserFlagsRef;            // Flag name → index map
}
    : ^(OBJECT header definitionOrBlock*)
      // Template: object with all metadata
      -> object(
           objName={$script::sobjName},
           parent={$script::sparentName},
           const={$script::sconst},
           structDefs={$script::pobjStructDefinitionsA},
           variableDefs={$script::pobjVarDefinitionsA},
           properties={$script::pobjPropDefinitionsA},
           propertyGroups={$script::pobjPropGroupDefinitionsA},
           initialState={$script::sinitialState},
           emptyStateFuncs={$script::pobjEmptyStateA},
           stateFuncs={$script::pstates},
           fileName={$script::sfileName},
           modTimeUnix={$script::smodTimeUnix},
           compileTimeUnix={$script::scompileTimeUnix},
           userName={$script::suserName},
           computerName={$script::scomputerName},
           userFlags={$script::sobjFlags},
           userFlagsRef={$script::puserFlagsRef},
           docString={$script::sdocString}
         )
    ;

/*
================================================================================
  HEADER RULE
================================================================================

  Processes script header (name, parent, flags, docstring).

  Side effects:
    - Sets script_scope fields: sobjName, sparentName, sobjFlags, sconst, sdocString
*/

header
    : ^(ID USER_FLAGS ID? DOCSTRING?)
      // Stores in script_scope, no template output
    ;

/*
================================================================================
  DEFINITION OR BLOCK DISPATCHER
================================================================================

  Dispatches to specific definition types (7 alternatives).

  Side effects:
    - Adds definitions to script_scope collections
*/

definitionOrBlock
    : fieldDefinition[false]              // Variable definition
    | function["", ""]                    // Function definition (empty state)
    | eventFunc[""]                       // Event definition (empty state)
    | stateBlock                          // State definition
    | propertyBlock                       // Property definition
    | groupBlock                          // Property group (FO4)
    | structBlock                         // Struct definition (FO4)
    ;

/*
================================================================================
  FIELD DEFINITION (VARIABLE)
================================================================================

  Processes variable/property field definitions.

  Parameter:
    - abOutputDocString: If true, includes docString in template (for struct members)

  Scope Stack: fieldDefinition_scope
  Template: variableDef
*/

fieldDefinition[bool abOutputDocString]
scope {
    string sinitialValue;   // Initial value (default "None")
    string sconst;          // "const" or ""
    string sdocString;      // Documentation string
}
    : ^(VAR type ID USER_FLAGS CONST? constant? DOCSTRING?)
      -> variableDef(
           type={$type.sTypeString},
           name={$ID.text},
           userFlags={$USER_FLAGS.text},
           const={$fieldDefinition::sconst},
           initialValue={$fieldDefinition::sinitialValue},
           docString={abOutputDocString ? $fieldDefinition::sdocString : ""}
         )
    ;

/*
================================================================================
  FUNCTION DEFINITION
================================================================================

  Processes function definitions (native or with body).

  Parameters:
    - asState: State name (empty string for empty state)
    - asPropertyName: Property name (if property function, else empty)

  Returns:
    - function_return with sName field (function name)

  Scope Stack: function_scope
  Template: functionDef
*/

function[string asState, string asPropertyName]
scope {
    string sstate;                  // State name
    string sfuncName;               // Function name
    string spropertyName;           // Property name (if property func)
    string sreturnType;             // Return type string
    bool bisNative;                 // Is native function
    bool bisGlobal;                 // Is global function
    IList pfuncParamsA;             // Parameter list
    IList pfuncVarDefinitionsA;     // Local variable definitions
    IList pstatementsA;             // Statement list
    string suserFlags;              // User flags bitmask
    string sdocString;              // Documentation string
    ScriptFunctionType pfuncType;   // Type info from semantic analysis
}
returns [string sName]
    : ^(FUNCTION functionHeader codeBlock?)
      // codeBlock parameters: (IList apStatementsA, IList apVarDefinitionsA, ScriptScope apCurrentScope)
      -> functionDef(
           funcName={$function::sfuncName},
           returnType={$function::sreturnType},
           isNative={$function::bisNative},
           isGlobal={$function::bisGlobal},
           funcParams={$function::pfuncParamsA},
           funcVars={$function::pfuncVarDefinitionsA},
           userFlags={$function::suserFlags},
           body={$function::pstatementsA},
           docString={$function::sdocString}
         )
    ;

/*
================================================================================
  FUNCTION HEADER
================================================================================

  Processes function signature (return type, name, flags, parameters).

  Side effects:
    - Retrieves ScriptFunctionType from pObjType
    - Calls MangleFunctionVariables() for variable collision handling
    - Sets function_scope fields
*/

functionHeader
    : ^(HEADER (type | NONE) ID USER_FLAGS callParameters? DOCSTRING?)
      // Stores in function_scope, no template output
    ;

/*
================================================================================
  EVENT FUNCTION DEFINITION
================================================================================

  Processes event handler definitions (EVENT or REMOTEEVENT).

  Parameter:
    - asState: State name (empty string for empty state)

  Returns:
    - eventFunc_return with sName field (event name)

  Scope Stack: eventFunc_scope
  Template: functionDef
*/

eventFunc[string asState]
scope {
    string sstate;                  // State name
    string sfuncName;               // Event name
    IList pfuncParamsA;             // Parameter list
    IList pfuncVarDefinitionsA;     // Local variable definitions
    IList pstatementsA;             // Statement list
    string suserFlags;              // User flags bitmask
    string sdocString;              // Documentation string
    ScriptFunctionType pfuncType;   // Type info from semantic analysis
}
returns [string sName]
    : ^(EVENT eventHeader[false] codeBlock)
      -> functionDef(...)
    | ^(REMOTEEVENT eventHeader[true] codeBlock)
      -> functionDef(...)
    ;

/*
================================================================================
  EVENT HEADER
================================================================================

  Processes event signature (always returns NONE, has parameters).

  Parameter:
    - bRemoteEvent: If true, mangles event name with MangleRemoteEventName()

  Side effects:
    - Sets eventFunc_scope fields
*/

eventHeader[bool bRemoteEvent]
    : ^(HEADER ID USER_FLAGS callParameters? DOCSTRING?)
      // Stores in eventFunc_scope, no template output
      // Remote events: "ScriptName.EventName" → "::remote_ScriptName_EventName"
    ;

/*
================================================================================
  CALL PARAMETERS (FUNCTION/EVENT DECLARATION)
================================================================================

  Processes parameter list (1+ parameters).

  Returns:
    - callParameters_return with kParams (IList of parameter templates)
*/

callParameters
returns [IList kParams]
    : ^(CALLPARAMS callParameter+)
    ;

/*
================================================================================
  CALL PARAMETER (SINGLE PARAMETER DECLARATION)
================================================================================

  Processes single parameter definition.

  Template: funcParam
*/

callParameter
    : ^(PARAM type ID constant?)
      -> funcParam(
           type={$type.sTypeString},
           name={$ID.text},
           defaultValue={$constant.start != null ? $constant.start.text : null}
         )
    ;

/*
================================================================================
  STATE BLOCK
================================================================================

  Processes state definition (STATE nodes).

  Side effects:
    - Stores state functions in script_scope.pstates Hashtable
    - Uses stateConcatinate template for multi-definition states
*/

stateBlock
    : ^(STATE ID USER_FLAGS stateFuncOrEvent*)
      // Collects functions/events, stores in pstates[stateName]
    ;

/*
================================================================================
  STATE FUNCTION OR EVENT
================================================================================

  Processes function or event within a state.

  Parameter:
    - asStateName: State name context
*/

stateFuncOrEvent[string asStateName]
    : function[asStateName, ""]
    | eventFunc[asStateName]
    ;

/*
================================================================================
  PROPERTY BLOCK (FULL OR AUTO)
================================================================================

  Processes property definition (PROPERTY or AUTOPROP).

  Returns:
    - propertyBlock_return with sName field (property name)

  Scope Stack: propertyBlock_scope
  Template: fullProp or autoProp
*/

propertyBlock
scope {
    string spropName;       // Property name
    string spropType;       // Property type string
    string sgroupName;      // Property group name (if in group)
    string spropFlags;      // User flags bitmask
    string sconst;          // "const" or ""
    string sinitialValue;   // Initial value (for auto props)
    string sdocString;      // Documentation string
}
returns [string sName]
    : ^(PROPERTY propertyHeader propertyFunc propertyFunc)
      -> fullProp(...)
    | ^(AUTOPROP propertyHeader constant?)
      -> autoProp(...)
    ;

/*
================================================================================
  PROPERTY HEADER
================================================================================

  Processes property signature (type, name, flags, optional const/default).

  Side effects:
    - Sets propertyBlock_scope fields
*/

propertyHeader
    : ^(HEADER type ID USER_FLAGS CONST? constant? DOCSTRING?)
      // Stores in propertyBlock_scope, no template output
    ;

/*
================================================================================
  PROPERTY FUNCTION (GET/SET)
================================================================================

  Processes property get/set function.

  Parameter:
    - asPropertyName: Property name context
*/

propertyFunc[string asPropertyName]
    : ^(PROPFUNC function["", asPropertyName])
      // Delegates to function() with property context
    ;

/*
================================================================================
  GROUP BLOCK (FO4 FEATURE)
================================================================================

  Processes property group definition.

  Scope Stack: groupBlock_scope
  Template: propertyGroup
*/

groupBlock
scope {
    string sgroupName;      // Group name
    string suserFlags;      // User flags bitmask
    string sdocString;      // Documentation string
    IList ppropEntriesA;    // Property reference list
}
    : ^(GROUP groupHeader groupProperty+)
      -> propertyGroup(
           name={$groupBlock::sgroupName},
           userFlags={$groupBlock::suserFlags},
           docString={$groupBlock::sdocString},
           propertiesInGroup={$groupBlock::ppropEntriesA}
         )
    ;

/*
================================================================================
  GROUP HEADER
================================================================================

  Processes group signature (name, flags, docstring).

  Side effects:
    - Sets groupBlock_scope fields
*/

groupHeader
    : ^(HEADER ID USER_FLAGS DOCSTRING?)
      // Stores in groupBlock_scope, no template output
    ;

/*
================================================================================
  GROUP PROPERTY
================================================================================

  Processes property or variable within group.

  Side effects:
    - Adds property to both group list and script property list

  Template: propertyInGroup (for group reference)
*/

groupProperty
    : propertyBlock
      -> propertyInGroup(name={$propertyBlock.sName})
    | fieldDefinition[false]
      -> propertyInGroup(name={$ID.text})
    ;

/*
================================================================================
  STRUCT BLOCK (FO4 FEATURE)
================================================================================

  Processes struct definition.

  Scope Stack: structBlock_scope
  Template: structDef
*/

structBlock
scope {
    string sname;               // Struct name
    IList pvarDefinitionsA;     // Struct member variables
}
    : ^(STRUCT structHeader structField+)
      -> structDef(
           name={$structBlock::sname},
           vars={$structBlock::pvarDefinitionsA}
         )
    ;

/*
================================================================================
  STRUCT HEADER
================================================================================

  Processes struct signature (name only, no flags/docstring).

  Side effects:
    - Sets structBlock_scope.sname
*/

structHeader
    : ^(HEADER ID)
      // Stores in structBlock_scope, no template output
    ;

/*
================================================================================
  STRUCT FIELD
================================================================================

  Processes field within struct.

  Uses fieldDefinition(true) to force docstring output for struct members.
*/

structField
    : fieldDefinition[true]
      // Forces docstring output for struct documentation
    ;

/*
================================================================================
  CODE BLOCK
================================================================================

  Processes code block container (statements and local variables).

  Parameters:
    - apStatementsA: Output list for statement templates
    - apVarDefinitionsA: Output list for local variable definitions
    - apCurrentScope: ScriptScope from semantic analysis

  Scope Stack: codeBlock_scope

  Side effects:
    - Iterates through statements, adds non-null templates to apStatementsA
    - Manages scope child iteration via inextScopeChild
*/

codeBlock[IList apStatementsA, IList apVarDefinitionsA, ScriptScope apCurrentScope]
scope {
    IList pvarDefsA;            // Local variable definitions
    ScriptScope pcurrentScope;  // Current scope from type checking
    int inextScopeChild;        // Next child scope index
}
    : ^(BLOCK statement*)
      // Iterates statements, collects non-null templates
    ;

/*
================================================================================
  STATEMENT
================================================================================

  Processes individual statements (7 alternatives).

  Scope Stack: statement_scope

  Returns template or null (null templates are skipped by codeBlock).
*/

statement
scope {
    string smangledName;  // Mangled variable name
}
    : localDefinition          // Local variable declaration
    | ^(EQUALS l_value expression)       // Assignment
    | ^(NOCODEASSIGN l_value expression) // No-code assignment (optimizer directive)
    | expression                         // Expression statement (function call, etc.)
    | return_stat                        // Return statement
    | ifBlock                            // If/else conditional
    | whileBlock                         // While loop
    ;

/*
================================================================================
  LOCAL DEFINITION (LOCAL VARIABLE DECLARATION)
================================================================================

  Processes local variable declaration with optional initialization.

  Returns:
    - localDefinition_return with sVarName, sExprVar, pExprST, iLineNo

  Template: variableDef

  Side effects:
    - If initialized, generates assignment operation
*/

localDefinition
returns [string sVarName, string sExprVar, StringTemplate pExprST, int iLineNo]
    : ^(VAR type ID expression?)
      -> variableDef(
           type={$type.sTypeString},
           name={$ID.text}
         )
    ;

/*
================================================================================
  L-VALUE (ASSIGNMENT TARGET)
================================================================================

  Processes left-hand side of assignment (3 alternatives).

  Scope Stack: l_value_scope
*/

l_value
scope {
    string sselfName;  // Self variable name
}
    : basic_l_value                      // Simple variable/property
    | ^(ARRAYSET l_value expression expression)  // Array element assignment
    | ^(PROPSET l_value ID expression)   // Property assignment (calls setter)
    ;

/*
================================================================================
  BASIC L-VALUE (SIMPLE ASSIGNMENT TARGET)
================================================================================

  Processes basic assignable values (4 alternatives).

  Scope Stack: basic_l_value_scope
*/

basic_l_value
scope {
    string sselfName;  // Self variable name
}
    : ID                                 // Simple variable
    | ^(DOT basic_l_value ID)            // Property access
    | ^(ARRAYGET basic_l_value expression) // Array element
    | ^(STRUCTGET basic_l_value ID)      // Struct member (FO4)
    ;

/*
================================================================================
  EXPRESSION (LOGICAL OR - LOWEST PRECEDENCE)
================================================================================

  Processes OR expressions with short-circuit evaluation.

  Returns:
    - expression_return with sRetValue (variable name holding result)

  Generates temporary variables for intermediate results.
*/

expression
returns [string sRetValue]
    : ^(OR expression expression)
      -> threeOpCommand(op="OR", ...)
    | and_expression
    ;

/*
================================================================================
  AND EXPRESSION (LOGICAL AND)
================================================================================

  Processes AND expressions with short-circuit evaluation.

  Returns:
    - and_expression_return with sRetValue
*/

and_expression
returns [string sRetValue]
    : ^(AND and_expression and_expression)
      -> threeOpCommand(op="AND", ...)
    | bool_expression
    ;

/*
================================================================================
  BOOL EXPRESSION (COMPARISON OPERATIONS)
================================================================================

  Processes comparison and type operations (12 alternatives).

  Returns:
    - bool_expression_return with sRetValue

  Operations:
    - Equality: EQ (==), NE (!=)
    - Comparison: LT (<), LTE (<=), GT (>), GTE (>=)
    - Type: IS (type check), AS (type cast)
    - Integer/Float variants determined by operand types
    - String: STRCAT (concatenation)
*/

bool_expression
returns [string sRetValue]
    : ^(EQ bool_expression add_expression)
      -> threeOpCommand(op="CMPEQ", ...)  // Integer or Float variant
    | ^(NE bool_expression add_expression)
      -> threeOpCommand(op="CMPNE", ...)
    | ^(LT bool_expression add_expression)
      -> threeOpCommand(op="CMPLT", ...)
    | ^(LTE bool_expression add_expression)
      -> threeOpCommand(op="CMPLTE", ...)
    | ^(GT bool_expression add_expression)
      -> threeOpCommand(op="CMPGT", ...)
    | ^(GTE bool_expression add_expression)
      -> threeOpCommand(op="CMPGTE", ...)
    | ^(IS bool_expression add_expression)
      -> threeOpCommand(op="IS", ...)
    | ^(AS bool_expression type)
      -> threeOpCommand(op="CAST", ...)
    | ^(STRCAT bool_expression add_expression)
      -> threeOpCommand(op="STRCAT", ...)
    | add_expression
    ;

/*
================================================================================
  ADD EXPRESSION (ADDITION/SUBTRACTION)
================================================================================

  Processes addition/subtraction operations.

  Returns:
    - add_expression_return with sRetValue

  Operations:
    - IADD / FADD (+ operator)
    - ISUBTRACT / FSUBTRACT (- operator)
*/

add_expression
returns [string sRetValue]
    : ^(IADD add_expression mult_expression)
      -> threeOpCommand(op="IADD", ...)
    | ^(ISUBTRACT add_expression mult_expression)
      -> threeOpCommand(op="ISUBTRACT", ...)
    | ^(FADD add_expression mult_expression)
      -> threeOpCommand(op="FADD", ...)
    | ^(FSUBTRACT add_expression mult_expression)
      -> threeOpCommand(op="FSUBTRACT", ...)
    | mult_expression
    ;

/*
================================================================================
  MULT EXPRESSION (MULTIPLICATION/DIVISION/MODULO)
================================================================================

  Processes multiplication/division/modulo operations.

  Returns:
    - mult_expression_return with sRetValue

  Operations:
    - IMULTIPLY / FMULTIPLY (* operator)
    - IDIVIDE / FDIVIDE (/ operator)
    - MOD (% operator, integer only)
*/

mult_expression
returns [string sRetValue]
    : ^(IMULTIPLY mult_expression unary_expression)
      -> threeOpCommand(op="IMULTIPLY", ...)
    | ^(IDIVIDE mult_expression unary_expression)
      -> threeOpCommand(op="IDIVIDE", ...)
    | ^(MOD mult_expression unary_expression)
      -> threeOpCommand(op="MOD", ...)
    | ^(FMULTIPLY mult_expression unary_expression)
      -> threeOpCommand(op="FMULTIPLY", ...)
    | ^(FDIVIDE mult_expression unary_expression)
      -> threeOpCommand(op="FDIVIDE", ...)
    | unary_expression
    ;

/*
================================================================================
  UNARY EXPRESSION (UNARY OPERATIONS)
================================================================================

  Processes unary operations (2 alternatives).

  Returns:
    - unary_expression_return with sRetValue

  Operations:
    - NOT (boolean negation)
    - UNARY_MINUS (numeric negation: INEGATE / FNEGATE)
*/

unary_expression
returns [string sRetValue]
    : ^(NOT unary_expression)
      -> twoOpCommand(op="NOT", ...)
    | ^(UNARY_MINUS unary_expression)
      -> twoOpCommand(op="NEGATE", ...)  // INEGATE or FNEGATE
    | cast_atom
    ;

/*
================================================================================
  CAST ATOM (TYPE CASTING)
================================================================================

  Processes explicit type casts (AS operator).

  Returns:
    - cast_atom_return with sRetValue
*/

cast_atom
returns [string sRetValue]
    : ^(AS cast_atom type)
      -> threeOpCommand(op="CAST", ...)
    | dot_atom
    ;

/*
================================================================================
  DOT ATOM (MEMBER ACCESS)
================================================================================

  Processes member access expressions (DOT node).

  Returns:
    - dot_atom_return with sRetValue
*/

dot_atom
returns [string sRetValue]
    : ^(DOT dot_atom ID)
      // Property or struct member access
    | array_atom
    ;

/*
================================================================================
  ARRAY ATOM (ARRAY SUBSCRIPT ACCESS)
================================================================================

  Processes array subscript access (ARRAYGET node).

  Returns:
    - array_atom_return with sRetValue

  Scope Stack: array_atom_scope
*/

array_atom
scope {
    string sselfName;  // Array variable name
}
returns [string sRetValue]
    : ^(ARRAYGET array_atom expression)
      -> arrayGet(...)
    | atom
    ;

/*
================================================================================
  ATOM (ATOMIC EXPRESSIONS - HIGHEST PRECEDENCE)
================================================================================

  Processes atomic expressions (9 alternatives).

  Returns:
    - atom_return with sRetValue
*/

atom
returns [string sRetValue]
    : array_func_or_id           // Array variable or array method call
    | func_or_id                 // Variable or function call
    | ^(PAREXPR expression)      // Parenthesized expression
    | constant                   // Literal value
    | ^(LENGTH atom)             // Array length
    | ^(NEWARRAY type expression) // New array allocation
    | ^(NEWSTRUCT type)          // New struct (FO4)
    | ^(PROPGET atom ID)         // Property getter
    | ^(STRUCTGET atom ID)       // Struct member getter (FO4)
    ;

/*
================================================================================
  ARRAY FUNCTION OR ID (ARRAY METHODS)
================================================================================

  Processes array variable or array method calls (3 alternatives).

  Returns:
    - array_func_or_id_return with sRetValue

  Scope Stack: array_func_or_id_scope

  Array methods (FO4):
    - ARRAYFIND / ARRAYRFIND: Find element by value
    - ARRAYFINDSTRUCT / ARRAYRFINDSTRUCT: Find struct by member value (FO4)
    - ARRAYCLEAR: Clear all elements
*/

array_func_or_id
scope {
    string sselfName;  // Array variable name
}
returns [string sRetValue]
    : ^(ARRAYFIND array_func_or_id expression)
      -> arrayFind(...)
    | ^(ARRAYRFIND array_func_or_id expression)
      -> arrayRFind(...)
    | ^(ARRAYFINDSTRUCT array_func_or_id ID expression)  // FO4
      -> arrayFindStruct(...)
    | ^(ARRAYRFINDSTRUCT array_func_or_id ID expression) // FO4
      -> arrayRFindStruct(...)
    | ^(ARRAYCLEAR array_func_or_id)
      -> arrayClear(...)
    | func_or_id
    ;

/*
================================================================================
  FUNC OR ID (FUNCTION CALL OR IDENTIFIER)
================================================================================

  Processes variable or function call (2 alternatives).

  Returns:
    - func_or_id_return with sRetValue

  Scope Stack: func_or_id_scope
*/

func_or_id
scope {
    string sselfName;  // Self variable name (for calls)
}
returns [string sRetValue]
    : function_call
    | ID
    ;

/*
================================================================================
  PROPERTY SET (PROPERTY SETTER OPERATION)
================================================================================

  Processes property assignment via setter function.

  Scope Stack: property_set_scope
*/

property_set
scope {
    string sselfName;  // Object variable name
}
    : ^(PROPSET l_value ID expression)
      -> propertySet(...)
    ;

/*
================================================================================
  STRUCT SET (STRUCT MEMBER SETTER - FO4 FEATURE)
================================================================================

  Processes struct member assignment.

  Scope Stack: struct_set_scope
*/

struct_set
scope {
    string sselfName;  // Struct variable name
}
    : ^(STRUCTSET l_value ID expression)
      -> structSet(...)
    ;

/*
================================================================================
  RETURN STATEMENT
================================================================================

  Processes return statement.

  Template: returnCommand
*/

return_stat
    : ^(RETURN expression?)
      -> returnCommand(value={$expression.sRetValue})
    ;

/*
================================================================================
  IF BLOCK (IF STATEMENT)
================================================================================

  Processes if statement with optional elseif/else clauses.

  Scope Stack: ifBlock_scope

  Templates: ifCommand, gotoCommand

  Control flow:
    - Evaluate condition
    - If false, jump to next elseif/else/end label
    - Execute true block
    - Jump to end label
*/

ifBlock
scope {
    IList pblockStatementsA;    // Statement list
    string sendLabel;           // End label
    ScriptScope pchildScope;    // Child scope
}
    : ^(IF expression codeBlock elseIfBlock* elseBlock?)
      -> ifCommand(...) + gotoCommand(...)
    ;

/*
================================================================================
  ELSE IF BLOCK
================================================================================

  Processes else-if clause.

  Scope Stack: elseIfBlock_scope
*/

elseIfBlock
scope {
    IList pblockStatementsA;    // Statement list
    ScriptScope pchildScope;    // Child scope
}
    : ^(ELSEIF expression codeBlock)
      // Generates label, condition, jump
    ;

/*
================================================================================
  ELSE BLOCK
================================================================================

  Processes else clause.

  Scope Stack: elseBlock_scope
*/

elseBlock
scope {
    IList pblockStatementsA;    // Statement list
    ScriptScope pchildScope;    // Child scope
}
    : ^(ELSE codeBlock)
      // Generates label, statements
    ;

/*
================================================================================
  WHILE BLOCK (WHILE LOOP)
================================================================================

  Processes while loop.

  Scope Stack: whileBlock_scope

  Templates: labelCommand, whileCommand, gotoCommand

  Control flow:
    - Start label
    - Evaluate condition
    - If false, jump to end label
    - Execute loop body
    - Jump to start label
    - End label
*/

whileBlock
scope {
    IList pblockStatementsA;    // Statement list
    string sStartLabel;         // Loop start label
    string sendLabel;           // Loop end label
    ScriptScope pchildScope;    // Child scope
}
    : ^(WHILE expression codeBlock)
      -> labelCommand(label={$whileBlock::sStartLabel})
       + whileCommand(...)
       + gotoCommand(label={$whileBlock::sStartLabel})
       + labelCommand(label={$whileBlock::sendLabel})
    ;

/*
================================================================================
  FUNCTION CALL (FUNCTION INVOCATION)
================================================================================

  Processes function calls (12 alternatives).

  Returns:
    - function_call_return with sRetValue

  Scope Stack: function_call_scope

  Call types:
    1. CALL - Local method call (self.method)
    2. CALLPARENT - Parent method call (parent.method)
    3. CALLGLOBAL - Static method call (Class.method)
    4-12. Array operations: ARRAYADD, ARRAYINSERT, ARRAYREMOVELAST, ARRAYREMOVE,
                           ARRAYCLEAR, ARRAYFIND, ARRAYRFIND,
                           ARRAYFINDSTRUCT, ARRAYRFINDSTRUCT (FO4)

  Templates: callLocal, callParent, callGlobal, array operation templates
*/

function_call
scope {
    string sselfName;  // Self/receiver variable name
}
returns [string sRetValue]
    : ^(CALL func_or_id ID parameters)
      -> callLocal(...)
    | ^(CALLPARENT func_or_id ID parameters)
      -> callParent(...)
    | ^(CALLGLOBAL func_or_id ID parameters)
      -> callGlobal(...)
    | ^(ARRAYADD func_or_id expression)
      -> arrayAdd(...)
    | ^(ARRAYINSERT func_or_id expression expression)
      -> arrayInsert(...)
    | ^(ARRAYREMOVELAST func_or_id)
      -> arrayRemoveLast(...)
    | ^(ARRAYREMOVE func_or_id expression)
      -> arrayRemove(...)
    | ^(ARRAYCLEAR func_or_id)
      -> arrayClear(...)
    | ^(ARRAYFIND func_or_id expression)
      -> arrayFind(...)
    | ^(ARRAYRFIND func_or_id expression)
      -> arrayRFind(...)
    | ^(ARRAYFINDSTRUCT func_or_id ID expression)  // FO4
      -> arrayFindStruct(...)
    | ^(ARRAYRFINDSTRUCT func_or_id ID expression) // FO4
      -> arrayRFindStruct(...)
    ;

/*
================================================================================
  PARAMETERS (FUNCTION CALL ARGUMENTS)
================================================================================

  Processes function call argument list (1+ parameters).

  Returns:
    - parameters_return with pParamVarsA (IList of parameter variable names)
*/

parameters
returns [IList pParamVarsA]
    : parameter+
    ;

/*
================================================================================
  PARAMETER (SINGLE FUNCTION CALL ARGUMENT)
================================================================================

  Processes single function call argument.

  Returns:
    - parameter_return with sVarName (parameter variable name)
*/

parameter
returns [string sVarName]
    : expression
    ;

/*
================================================================================
  ID OR CONSTANT (IDENTIFIER OR CONSTANT VALUE)
================================================================================

  Processes identifier or constant value.

  Returns:
    - idOrConstant_return with sRetValue
*/

idOrConstant
returns [string sRetValue]
    : ID
    | constant
    ;

/*
================================================================================
  CONSTANT (LITERAL VALUES)
================================================================================

  Processes literal values (5 alternatives).

  Side effects:
    - Strings are quoted via MakeQuotedString()
*/

constant
    : number
    | STRING
    | BOOL
    | NONE
    ;

/*
================================================================================
  NUMBER (NUMERIC LITERALS)
================================================================================

  Processes numeric literals (2 alternatives).

  Note: MINUS is handled in unary_expression, not here.
*/

number
    : INTEGER
    | FLOAT
    ;

/*
================================================================================
  TYPE (TYPE SPECIFIER)
================================================================================

  Processes type specifiers (4 alternatives).

  Returns:
    - type_return with sTypeString (type string representation)

  FO4 Features:
    - DEPENDENTTYPE: Namespaced type (ScriptName:StructName)
    - Array syntax: type[] or namespace:type[]
*/

type
returns [string sTypeString]
    : ID                                    // Simple type: Int, String, Actor
    | DEPENDENTTYPE                         // Namespaced: ScriptName:StructName (FO4)
    | DEPENDENTTYPE LBRACKET RBRACKET       // Array of namespaced type (FO4)
    | BASETYPE LBRACKET RBRACKET            // Array of simple type
    ;

/*
================================================================================
  END OF GRAMMAR
================================================================================
*/
