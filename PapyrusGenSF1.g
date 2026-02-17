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

tree grammar PapyrusGenSF1;

options {
    tokenVocab = PapyrusParserSF1;
    ASTLabelType = CommonTree;
}

// ============================================================================
// SCOPE DECLARATIONS
// ============================================================================
//
// Each scope class tracks context during tree walking. Scopes are pushed on
// entry to a rule and popped on exit (in finally blocks).
//
// Fields are listed as comments since ANTLR3 tree grammar syntax doesn't
// support inline field declarations (these are implemented in C#).
// ============================================================================

scope script_scope {
    // Script metadata and definitions
    // string objName                           - Script name
    // string parentName                        - Parent script name
    // List<StringTemplate> objStructDefinitions - Struct definitions
    // List<StringTemplate> objVarDefinitions   - Variable definitions
    // List<StringTemplate> objGuardDefinitions - Guard definitions (SF1)
    // List<StringTemplate> objPropDefinitions  - Property definitions
    // List<StringTemplate> objPropGroupDefinitions - Property groups
    // List<string> objUngroupedProps           - Properties not in groups
    // ScriptObjectStateName initialState       - Initial state
    // List<StringTemplate> objEmptyState       - Empty state definition
    // Dictionary<ScriptObjectStateName, string> states - State mappings
    // bool hasBeginStateEvent                  - Has OnBeginState event
    // bool hasEndStateEvent                    - Has OnEndState event
    // string modTimeUnix                       - File modification time
    // string compileTimeUnix                   - Compilation time
    // string fileName                          - Source file name
    // string userName                          - User name
    // string computerName                      - Computer name
    // string objFlags                          - Object flags
    // Dictionary<string, int> userFlagsRef     - User flag references
    // string docString                         - Documentation string
    // string constFlag                         - Const flag value
}

scope fieldDefinition_scope {
    // Field definition context
    // string initialValue                      - Initial value expression
    // string constFlag                         - Const flag value
    // string docString                         - Documentation string
}

scope function_scope {
    // Function definition context
    // ScriptObjectStateName state              - State context
    // ScriptFunctionName funcName              - Function name
    // string propertyName                      - Property name (if property func)
    // string returnType                        - Return type
    // bool isNative                            - Native flag
    // bool isGlobal                            - Global flag
    // List<StringTemplate> funcParams          - Parameter definitions
    // List<StringTemplate> funcVarDefinitions  - Local variable definitions
    // List<StringTemplate> statements          - Function body statements
    // string userFlags                         - User flags value
    // string docString                         - Documentation string
    // ScriptFunctionType funcType              - Link to typed function object
}

scope eventFunc_scope {
    // Event function context
    // ScriptObjectStateName state              - State context
    // ScriptFunctionName mangledFuncName       - Mangled event name
    // string returnType                        - Return type (always None)
    // bool isNative                            - Native flag
    // bool isGlobal                            - Global flag (always false)
    // List<StringTemplate> funcParams          - Parameter definitions
    // List<StringTemplate> funcVarDefinitions  - Local variable definitions
    // List<StringTemplate> statements          - Event body statements
    // string userFlags                         - User flags value
    // string docString                         - Documentation string
    // ScriptFunctionType funcType              - Link to typed function object
}

scope propertyBlock_scope {
    // Property definition context
    // string propName                          - Property name
    // string propType                          - Property type
    // string userFlags                         - User flags value
    // string docString                         - Documentation string
}

scope groupBlock_scope {
    // Property group context
    // string groupName                         - Group name
    // string userFlags                         - User flags value
    // string docString                         - Documentation string
    // List<string> propEntries                 - Property names in group
}

scope structBlock_scope {
    // Struct definition context
    // string name                              - Struct name
    // List<StringTemplate> varDefinitions      - Member field definitions
}

scope codeBlock_scope {
    // Statement block context
    // List<StringTemplate> varDefs             - Local variable definitions
    // ScriptScope currentScope                 - Link to type system scope
    // int nextScopeChild                       - Child scope index for navigation
}

scope statement_scope {
    // Individual statement context
    // string mangledName                       - Mangled variable name (if needed)
}

scope l_value_scope {
    // Assignment target context
    // string selfName                          - Self reference variable name
}

scope basic_l_value_scope {
    // Simple assignment target context
    // string selfName                          - Self reference variable name
}

scope lockBlock_scope {
    // LockGuard block context (SF1-specific)
    // List<StringTemplate> blockStatements     - Lock body statements
    // ScriptScope childScope                   - Child scope for nested context
}

scope tryLockBlock_scope {
    // TryLockGuard block context (SF1-specific)
    // List<StringTemplate> blockStatements     - Try-lock body statements
    // string endLabel                          - Control flow end label
    // ScriptScope childScope                   - Child scope for success branch
}

scope elseTryLockBlock_scope {
    // ElseTryLockGuard branch context (SF1-specific)
    // List<StringTemplate> blockStatements     - Else-try-lock body statements
    // ScriptScope childScope                   - Child scope for alternate branch
}

scope ifBlock_scope {
    // If statement context
    // List<StringTemplate> blockStatements     - If body statements
    // string endLabel                          - Control flow end label
    // ScriptScope childScope                   - Child scope for if body
}

scope elseIfBlock_scope {
    // ElseIf branch context
    // List<StringTemplate> blockStatements     - ElseIf body statements
    // ScriptScope childScope                   - Child scope for elseif body
}

scope elseBlock_scope {
    // Else branch context
    // List<StringTemplate> blockStatements     - Else body statements
    // ScriptScope childScope                   - Child scope for else body
}

scope whileBlock_scope {
    // While loop context
    // List<StringTemplate> blockStatements     - While body statements
    // string startLabel                        - Loop start label
    // string endLabel                          - Loop end label
    // ScriptScope childScope                   - Child scope for loop body
}

scope return_stat_scope {
    // Return statement context
    // List<StringTemplate> scopeExitExpressions - Guard unlocks and cleanup
}

scope array_atom_scope {
    // Array access context
    // string selfName                          - Array variable name
}

scope array_func_or_id_scope {
    // Array function call context
    // string selfName                          - Array variable name
}

scope func_or_id_scope {
    // Function call or identifier context
    // string selfName                          - Object reference for call
}

scope property_set_scope {
    // Property setter context
    // string selfName                          - Object reference
}

scope struct_set_scope {
    // Struct member assignment context
    // string selfName                          - Struct variable name
}

scope function_call_scope {
    // Function call context
    // string selfName                          - Object reference for call
}

// ============================================================================
// TOP-LEVEL SCRIPT STRUCTURE
// ============================================================================
//
// Entry point for code generation. The script rule is called by the compiler
// driver after type checking pass completes.
//
// Parameters (passed from driver, not shown in grammar):
//   - aSourceFilename : string - Source file path for metadata
//   - aObj : ScriptObjectType - Typed script object from PapyrusType pass
//
// Returns: StringTemplate with complete assembly code
// ============================================================================

script
scope script_scope;
    // Initialize script metadata (timestamps, user, computer)
    // Process header for script name, parent, flags, docstring
    // Process all definitions (guards, vars, structs, properties, functions, events)
    // Build final assembly template with all collected definitions
    : header definitionOrBlock*
      -> template(name={...}, parent={...}, flags={...}, guardDefs={...},
                  structDefs={...}, varDefs={...}, propDefs={...},
                  propGroupDefs={...}, states={...}, metadata={...})
    ;

header
    // Extract script name, parent name, user flags, docstring
    // Store in script_scope for final assembly generation
    : scriptType (scriptType)? userFlags DOCSTRING?
    ;

// ============================================================================
// DEFINITIONS AND BLOCKS
// ============================================================================
//
// Dispatcher for all script-level definitions. SF1 has 10 definition types:
//   1. fieldDefinition       - Script-level variables
//   2. guardDefinition       - Guard declarations (SF1-specific)
//   3. customEventDefinition - Custom event declarations
//   4. import_obj            - Import statements (no code generation)
//   5. function              - Function definitions
//   6. eventFunc             - Event handler definitions
//   7. stateBlock            - State definitions with functions/events
//   8. propertyBlock         - Property definitions with get/set
//   9. groupBlock            - Property group definitions
//  10. structBlock           - Struct type definitions
// ============================================================================

definitionOrBlock
    : fieldDefinition
    | guardDefinition       // SF1-specific: Guard variable for concurrency
    | customEventDefinition
    | import_obj
    | function
    | eventFunc
    | stateBlock
    | propertyBlock
    | groupBlock
    | structBlock
    ;

// ----------------------------------------------------------------------------
// FIELD DEFINITION
// ----------------------------------------------------------------------------
// Generates: .variable <name> <type> [<flags>] [= <initialValue>]
// Template: variableDef
// ----------------------------------------------------------------------------

fieldDefinition
scope fieldDefinition_scope;
    // Process variable type, name, flags, optional initial value
    // Add to script_scope.objVarDefinitions
    : anyType ID (constant)? userFlags DOCSTRING?
      -> template(name={...}, type={...}, flags={...}, initialValue={...},
                  docString={...})
    ;

// ----------------------------------------------------------------------------
// GUARD DEFINITION (SF1-Specific)
// ----------------------------------------------------------------------------
// Generates: .guard <name>
// Template: guardDef
//
// Purpose: Declares a guard object for use in LockGuard/TryLockGuard statements.
// Guards are compile-time constructs - no runtime code is generated for the
// definition itself, only a metadata entry.
//
// Example:
//   Guard MyLock ProtectsFunctionLogic
//
// Assembly:
//   .guard MyLock
// ----------------------------------------------------------------------------

guardDefinition
    // Extract guard name from ID token
    // Generate guardDef template
    // Add to script_scope.objGuardDefinitions
    : ID userFlags
      -> template(name={...})
    ;

customEventDefinition
    // Custom event declarations (metadata only, no code generation)
    : ID
    ;

import_obj
    // Import statements (no code generation, processed by type checker)
    : scriptType
    ;

// ============================================================================
// FUNCTION DEFINITIONS
// ============================================================================
//
// Functions are the primary executable units in Papyrus. Each function has:
//   - Return type (or None for void)
//   - Name
//   - Parameters
//   - User flags (Native, Global, access modifiers, etc.)
//   - Body (unless Native)
//
// Code Generation:
//   1. functionHeader: Generate function signature and metadata
//   2. codeBlock: Generate function body (local vars + statements)
//
// Variable Mangling:
//   Before generating code, all variables in the function scope are mangled
//   to handle shadowing (via MangleFunctionVariables helper).
//
// Parameters (semantic, not shown in grammar):
//   - aState : ScriptObjectStateName - State context (empty for script-level)
//   - aPropertyName : string - Property name (if this is a property function)
// ============================================================================

function
scope function_scope;
    // Initialize function scope
    // Call MangleFunctionVariables() to handle variable shadowing
    // Process function header for signature and metadata
    // Process function body (if not native)
    // Generate functionDef template with signature + body
    : functionHeader codeBlock?
      -> template(signature={...}, localVars={...}, body={...})
    ;

functionHeader
    // Extract return type, name, parameters, flags, docstring
    // Store in function_scope for body generation
    : anyType? ID callParameters? userFlags DOCSTRING?
    ;

// ============================================================================
// EVENT DEFINITIONS
// ============================================================================
//
// Events are special functions triggered by game engine. They differ from
// regular functions in several ways:
//   - Always have return type None
//   - Cannot be Global
//   - Can be Remote (cross-script calls)
//   - Event names may need mangling for remote events
//
// Remote Event Mangling:
//   Remote events are mangled via MangleRemoteEventName():
//     "OnActivate" → "::remote_OnActivate"
//
// Parameters (semantic, not shown in grammar):
//   - aState : ScriptObjectStateName - State context
// ============================================================================

eventFunc
scope eventFunc_scope;
    // Initialize event scope
    // Call MangleFunctionVariables() to handle variable shadowing
    // Process event header for signature and metadata
    // Mangle name if remote event (via MangleRemoteEventName)
    // Process event body (if not native)
    // Generate functionDef template with signature + body
    : eventHeader codeBlock?
      -> template(signature={...}, localVars={...}, body={...})
    ;

eventHeader
    // Extract event name, parameters, flags, docstring
    // Event name may be qualified (scriptType.ID for remote events)
    // Store in eventFunc_scope for body generation
    // Parameters (semantic): aRemoteEvent : bool
    : eventName callParameters? userFlags DOCSTRING?
    ;

eventName
    // Event name (possibly qualified for remote events)
    : scriptType? ID
    ;

// ============================================================================
// CALL PARAMETERS
// ============================================================================
//
// Parameter definitions for functions and events. Each parameter has:
//   - Type
//   - Name
//   - Optional default value
//
// Returns: List<StringTemplate> with parameter definitions
// ============================================================================

callParameters
    // Process parameter list
    // Return list of parameter templates
    : callParameter*
      -> { List<StringTemplate> }
    ;

callParameter
    // Extract parameter type, name, optional default value
    // Generate parameter template
    : anyType ID constant?
      -> template(type={...}, name={...}, defaultValue={...})
    ;

// ============================================================================
// STATE DEFINITIONS
// ============================================================================
//
// States group functions and events that share common behavior. State-specific
// functions override base script functions while in that state.
//
// Special Events:
//   - OnBeginState : Called when entering state
//   - OnEndState : Called when exiting state
// ============================================================================

stateBlock
    // Extract state name
    // Process all functions and events in state
    // Track OnBeginState/OnEndState events
    // Generate state template with all state functions
    : ID stateFuncOrEvent*
      -> template(name={...}, functions={...}, hasBeginState={...},
                  hasEndState={...})
    ;

stateFuncOrEvent
    // Dispatch to function or eventFunc with state context
    : function
    | eventFunc
    ;

// ============================================================================
// PROPERTY DEFINITIONS
// ============================================================================
//
// Properties are special variables with optional getter/setter functions.
// They can be:
//   - Auto : Compiler generates backing variable and default get/set
//   - AutoReadOnly : Auto with only getter (no setter)
//   - Manual : User provides get/set functions
//
// Code Generation:
//   1. Property definition with type and flags
//   2. Optional get function (propertyFunc)
//   3. Optional set function (propertyFunc)
// ============================================================================

propertyBlock
scope propertyBlock_scope;
    // Extract property name, type, flags, docstring
    // Process optional get/set functions
    // Generate propertyDef template
    // Track property for grouping (script_scope.objUngroupedProps)
    : propertyHeader propertyFunc* propertyFunc*
      -> template(name={...}, type={...}, flags={...},
                  getFunc={...}, setFunc={...})
    ;

propertyHeader
    // Extract property type, name, flags, docstring
    // Store in propertyBlock_scope
    : anyType ID userFlags DOCSTRING?
    ;

propertyFunc
    // Property get/set function
    // Parameters (semantic): aPropName : string
    : codeBlock
    ;

// ============================================================================
// PROPERTY GROUPS
// ============================================================================
//
// Property groups organize properties in the editor. They are purely metadata
// and do not affect runtime behavior.
//
// Ungrouped Properties:
//   Properties not in any group are collected and placed in a default group
//   via HandleUngroupedProperties() helper.
// ============================================================================

groupBlock
scope groupBlock_scope;
    // Extract group name, flags, docstring
    // Process all properties in group
    // Generate propertyGroup template
    : groupHeader groupProperty*
      -> template(name={...}, flags={...}, properties={...}, docString={...})
    ;

groupHeader
    // Extract group name, flags, docstring
    // Store in groupBlock_scope
    : ID userFlags DOCSTRING?
    ;

groupProperty
    // Property reference within group (just the name)
    : ID
      -> template(name={...})
    ;

// ============================================================================
// STRUCT DEFINITIONS
// ============================================================================
//
// Structs are user-defined value types. They consist of named fields with
// types. Structs are passed by value (copied on assignment).
//
// Code Generation:
//   .struct <name>
//       .variable <field1> <type1>
//       .variable <field2> <type2>
//   .endstruct
// ============================================================================

structBlock
scope structBlock_scope;
    // Extract struct name
    // Process all field definitions
    // Generate structDef template
    // Add to script_scope.objStructDefinitions
    : structHeader structField*
      -> template(name={...}, fields={...})
    ;

structHeader
    // Extract struct name
    : ID
    ;

structField
    // Struct field definition
    : anyType ID constant? userFlags DOCSTRING?
      -> template(type={...}, name={...}, defaultValue={...})
    ;

// ============================================================================
// CODE BLOCKS AND STATEMENTS
// ============================================================================
//
// Code blocks contain local variable definitions and statements. They manage
// scope via codeBlock_scope and navigate the ScriptScope tree from the type
// checking pass.
//
// Scope Navigation:
//   - codeBlock_scope.currentScope : ScriptScope (from type checker)
//   - codeBlock_scope.nextScopeChild : Index for child scope navigation
//   - Each nested block increments nextScopeChild to get next child scope
//
// Variable Definitions:
//   Local variables are accumulated in codeBlock_scope.varDefs and emitted
//   at the beginning of the function body.
// ============================================================================

codeBlock
scope codeBlock_scope;
    // Parameters (semantic, passed by caller):
    //   - aBlockStatements : List<StringTemplate> - Output statement list
    //   - aVarDefs : List<StringTemplate> - Output variable definition list
    //   - aScope : ScriptScope - Current scope from type checker
    //
    // Process all statements in block
    // Accumulate variable definitions in aVarDefs
    // Accumulate statement code in aBlockStatements
    : statement*
    ;

// ----------------------------------------------------------------------------
// STATEMENT DISPATCHER
// ----------------------------------------------------------------------------
// Dispatches to specific statement types based on AST node type.
//
// SF1 has 13 statement types (FO4: 11, SF1 adds 2):
//   1. localDefinition     - Local variable declaration
//   2. l_value             - Assignment statement
//   3. lockBlock           - LockGuard block (SF1-specific)
//   4. tryLockBlock        - TryLockGuard block (SF1-specific)
//   5. ifBlock             - If/ElseIf/Else conditional
//   6. whileBlock          - While loop
//   7. return_stat         - Return statement
//   8. expression          - Expression statement (function call, etc.)
//   9. property_set        - Property setter call
//  10. struct_set          - Struct member assignment
//  11. NATIVE              - Native function marker (no code generation)
//  12. NOCODEASSIGN        - No-code assignment marker (optimized out)
//  13. Empty statement     - No operation
// ----------------------------------------------------------------------------

statement
scope statement_scope;
    : localDefinition
    | l_value
    | lockBlock          // SF1-specific
    | tryLockBlock       // SF1-specific
    | ifBlock
    | whileBlock
    | return_stat
    | expression
    | property_set
    | struct_set
    | NATIVE             // No code generation
    | NOCODEASSIGN       // No code generation
    ;

// ----------------------------------------------------------------------------
// LOCAL VARIABLE DEFINITION
// ----------------------------------------------------------------------------
// Generates: .local <name> <type> [= <initialValue>]
// Template: variableDef
//
// Local variables are accumulated in codeBlock_scope.varDefs and emitted at
// the beginning of the function body (not inline with statements).
//
// Return Value:
//   Custom return type with:
//     - VarName : string - Variable name
//     - ExprVar : string - Expression result variable (if initialization)
//     - ExprST : StringTemplate - Expression code template
//     - LineNo : int - Source line number
// ----------------------------------------------------------------------------

localDefinition
    // Extract type and name
    // Process optional initialization expression
    // Generate variable definition template
    // Add to codeBlock_scope.varDefs
    // If initialized, generate assignment statement
    : anyType ID (expression)?
      -> template(type={...}, name={...})
    ;

// ----------------------------------------------------------------------------
// ASSIGNMENT STATEMENT (l_value)
// ----------------------------------------------------------------------------
// Generates: ASSIGN <target> <value>
// Template: assign
//
// Assignment targets can be:
//   - Simple variable: x = expr
//   - Array element: arr[idx] = expr
//   - Struct member: obj.field = expr
//   - Property setter: obj.prop = expr (generates property_set call)
//
// Compound Assignment:
//   +=, -=, *=, /=, %= are expanded to: target = target OP expr
// ----------------------------------------------------------------------------

l_value
scope l_value_scope;
    // Dispatch based on assignment operator:
    //   - EQUALS: Simple assignment
    //   - PLUSEQUALS, MINUSEQUALS, etc.: Compound assignment
    //
    // For compound assignment, expand to: target = target OP expr
    // Generate appropriate arithmetic operation
    : basic_l_value (EQUALS | PLUSEQUALS | MINUSEQUALS | MULTEQUALS |
                     DIVEQUALS | MODEQUALS) expression
      -> template(target={...}, value={...}, op={...}, lineNo={...})
    ;

basic_l_value
scope basic_l_value_scope;
    // Dispatch based on l-value type:
    //   - ID: Simple variable
    //   - dot_atom: Struct member access
    //   - array_atom: Array element access
    //   - property_set: Property setter call
    //   - struct_set: Struct member via setter
    : ID
    | dot_atom
    | array_atom
    ;

// ----------------------------------------------------------------------------
// LOCK GUARD BLOCK (SF1-Specific)
// ----------------------------------------------------------------------------
// Generates:
//   LockGuard <guard1>
//   LockGuard <guard2>
//   ...
//   <block statements>
//   ...
//   UnlockGuard <guard2>   ; Reverse order
//   UnlockGuard <guard1>
//
// Template: lockBlock
//
// Key Features:
//   - Multiple guards can be locked in sequence
//   - Guards are unlocked in LIFO order (reverse acquisition)
//   - Scope exit (return) auto-unlocks via GenerateScopeExitExpressions()
//
// Syntax:
//   LockGuard Guard1, Guard2
//       ; critical section
//   EndLockGuard
//
// Implementation:
//   1. Lock all guards in order
//   2. Execute block statements
//   3. Unlock all guards in reverse order
// ----------------------------------------------------------------------------

lockBlock
scope lockBlock_scope;
    // Extract list of guard names
    // Process codeBlock for critical section
    // Generate lockBlock template with:
    //   - guards: List of guard names
    //   - blockStatements: Critical section code
    // Template automatically generates unlock in reverse order
    : ID+ codeBlock
      -> template(guards={...}, blockStatements={...}, lineNo={...},
                  endLineNo={...})
    ;

// ----------------------------------------------------------------------------
// TRY LOCK GUARD BLOCK (SF1-Specific)
// ----------------------------------------------------------------------------
// Generates:
//   TryLockGuard <guard1> <resultVar>
//   Jump_if_not <resultVar> label0
//       <success block>
//   UnlockGuard <guard1>
//   Jump endLabel
//   label0:
//   TryLockGuard <guard2> <resultVar>
//   Jump_if_not <resultVar> label1
//       <alternate block>
//   UnlockGuard <guard2>
//   Jump endLabel
//   label1:
//       <else block>
//   endLabel:
//
// Template: tryLockBlock
//
// Key Features:
//   - Non-blocking lock acquisition
//   - Multiple alternate branches (elseTryLockBlock)
//   - Optional final else block if all locks fail
//   - Each successful branch unlocks before jumping to end
//
// Syntax:
//   TryLockGuard ResultVar Guard1
//       ; success branch
//   ElseTryLockGuard ResultVar Guard2
//       ; alternate branch
//   Else
//       ; failure branch
//   EndTryLockGuard
// ----------------------------------------------------------------------------

tryLockBlock
scope tryLockBlock_scope;
    // Extract result variable name
    // Extract list of guard names for primary try-lock
    // Process success block (codeBlock)
    // Process alternate branches (elseTryLockBlock*)
    // Process optional final else block
    // Generate tryLockBlock template with:
    //   - resultVar: Boolean result variable
    //   - guards: Primary guard list
    //   - blockStatements: Success block
    //   - eltryBlocks: Alternate branches
    //   - blockElse: Final else block
    //   - endLabel: Control flow end label
    : ID ID+ codeBlock elseTryLockBlock* elseBlock?
      -> template(resultVar={...}, guards={...}, blockStatements={...},
                  eltryBlocks={...}, blockElse={...}, endLabel={...},
                  lineNo={...})
    ;

elseTryLockBlock
scope elseTryLockBlock_scope;
    // Extract result variable name
    // Extract list of guard names for alternate try-lock
    // Process alternate block (codeBlock)
    // Generate elseTryLockBlock template with:
    //   - resultVar: Boolean result variable
    //   - guards: Alternate guard list
    //   - blockStatements: Alternate block
    //   - labelElse: Label for next branch
    //   - endLabel: Control flow end label (from tryLockBlock_scope)
    : ID ID+ codeBlock
      -> template(resultVar={...}, guards={...}, blockStatements={...},
                  labelElse={...}, endLabel={...}, lineNo={...})
    ;

// ----------------------------------------------------------------------------
// IF STATEMENT
// ----------------------------------------------------------------------------
// Generates:
//   <condition expression>
//   Jump_if_not <condition> label0
//       <if block>
//   Jump endLabel
//   label0:
//   <elseif condition>
//   Jump_if_not <condition> label1
//       <elseif block>
//   Jump endLabel
//   label1:
//       <else block>
//   endLabel:
//
// Template: ifBlock, elseIfBlock, elseBlock
// ----------------------------------------------------------------------------

ifBlock
scope ifBlock_scope;
    // Evaluate condition expression
    // Process if block (codeBlock)
    // Process elseif branches (elseIfBlock*)
    // Process optional else block
    // Generate ifBlock template with control flow labels
    : expression codeBlock elseIfBlock* elseBlock?
      -> template(condition={...}, condExpressions={...},
                  blockStatements={...}, elifBlocks={...}, blockElse={...},
                  endLabel={...}, lineNo={...})
    ;

elseIfBlock
scope elseIfBlock_scope;
    // Evaluate condition expression
    // Process elseif block (codeBlock)
    // Generate elseIfBlock template with control flow labels
    : expression codeBlock
      -> template(condition={...}, condExpressions={...},
                  blockStatements={...}, labelElse={...},
                  endLabel={...}, lineNo={...})
    ;

elseBlock
scope elseBlock_scope;
    // Process else block (codeBlock)
    // Generate elseBlock template
    : codeBlock
      -> template(blockStatements={...})
    ;

// ----------------------------------------------------------------------------
// WHILE LOOP
// ----------------------------------------------------------------------------
// Generates:
//   startLabel:
//   <condition expression>
//   Jump_if_not <condition> endLabel
//       <loop block>
//   Jump startLabel
//   endLabel:
//
// Template: whileBlock
// ----------------------------------------------------------------------------

whileBlock
scope whileBlock_scope;
    // Generate start and end labels
    // Evaluate condition expression
    // Process loop block (codeBlock)
    // Generate whileBlock template with control flow labels
    : expression codeBlock
      -> template(condition={...}, condExpressions={...},
                  blockStatements={...}, startLabel={...}, endLabel={...},
                  lineNo={...})
    ;

// ----------------------------------------------------------------------------
// RETURN STATEMENT
// ----------------------------------------------------------------------------
// Generates:
//   <scope exit expressions>  ; Guard unlocks (SF1)
//   Return <value>
//
// Template: returnStatement
//
// SF1 Guard Unlocking:
//   Before returning, all guards held by the current scope (and parent scopes
//   up to the function boundary) must be unlocked in LIFO order.
//
//   This is handled by GenerateScopeExitExpressions() helper:
//     - Calls currentScope.BuildGuardsToUnlockOnExit()
//     - Generates unlockGuards templates in reverse order
//     - Inserts before return statement
//
// Example:
//   Function Test()
//       LockGuard Lock1
//           LockGuard Lock2
//               Return 42  ; Must unlock Lock2, then Lock1
//           EndLockGuard
//       EndLockGuard
//   EndFunction
//
// Generated:
//   UnlockGuard Lock2
//   UnlockGuard Lock1
//   Return ::temp0
// ----------------------------------------------------------------------------

return_stat
scope return_stat_scope;
    // Process optional return expression
    // Call GenerateScopeExitExpressions() to generate guard unlocks (SF1)
    // Generate returnStatement template with:
    //   - retValue: Expression result (or "None" for void)
    //   - retExpr: Expression code
    //   - scopeExitExpressions: Guard unlocks (SF1)
    //   - lineNo: Source line number
    : expression?
      -> template(retValue={...}, retExpr={...},
                  scopeExitExpressions={...}, lineNo={...})
    ;

// ============================================================================
// EXPRESSIONS
// ============================================================================
//
// Expressions are evaluated bottom-up and return two values:
//   1. Template: StringTemplate with code to compute the expression
//   2. RetValue: Temporary variable name holding the result
//
// Example:
//   a + b
//
//   Returns:
//     Template: iadd ::temp2 a b
//     RetValue: "::temp2"
//
// Parent expressions reference child RetValue:
//   (a + b) * c
//
//   Child 1 (a + b):
//     Template: iadd ::temp2 a b
//     RetValue: "::temp2"
//
//   Child 2 (c):
//     Template: (none, just a variable)
//     RetValue: "c"
//
//   Parent (* operation):
//     Template: imul ::temp3 ::temp2 c
//     RetValue: "::temp3"
//
// Expression Precedence (highest to lowest):
//   1. atom                : Literals, identifiers, function calls
//   2. array_atom          : Array indexing (arr[idx])
//   3. dot_atom            : Member access (obj.field)
//   4. cast_atom           : Type casting (expr AS Type, expr IS Type)
//   5. unary_expression    : Unary minus (-expr), logical NOT (NOT expr)
//   6. mult_expression     : Multiply, divide, modulo (*, /, %)
//   7. add_expression      : Add, subtract, string concat (+, -, +)
//   8. bool_expression     : Comparisons (==, !=, <, >, <=, >=)
//   9. and_expression      : Logical AND
//  10. expression          : Logical OR (lowest precedence)
// ============================================================================

expression returns [string RetValue]
    // Logical OR (lowest precedence)
    // Short-circuit evaluation: true OR X → true
    : and_expression (OR and_expression)*
      -> template(leftVar={...}, rightVar={...}, resultVar={...},
                  leftExpr={...}, rightExpr={...}, lineNo={...})
    ;

and_expression returns [string RetValue]
    // Logical AND
    // Short-circuit evaluation: false AND X → false
    : bool_expression (AND bool_expression)*
      -> template(leftVar={...}, rightVar={...}, resultVar={...},
                  leftExpr={...}, rightExpr={...}, lineNo={...})
    ;

bool_expression returns [string RetValue]
    // Comparison operations (==, !=, <, >, <=, >=)
    : add_expression ((EQ | NE | GT | LT | GTE | LTE) add_expression)?
      -> template(leftVar={...}, rightVar={...}, resultVar={...},
                  leftExpr={...}, rightExpr={...}, op={...}, lineNo={...})
    ;

add_expression returns [string RetValue]
    // Addition, subtraction, string concatenation (+, -, +)
    // Operators:
    //   - IADD: Integer addition
    //   - FADD: Float addition
    //   - ISUBTRACT: Integer subtraction
    //   - FSUBTRACT: Float subtraction
    //   - STRCAT: String concatenation
    : mult_expression ((IADD | FADD | ISUBTRACT | FSUBTRACT | STRCAT)
                       mult_expression)*
      -> template(leftVar={...}, rightVar={...}, resultVar={...},
                  leftExpr={...}, rightExpr={...}, op={...}, lineNo={...})
    ;

mult_expression returns [string RetValue]
    // Multiplication, division, modulo (*, /, %)
    // Operators:
    //   - IMULTIPLY: Integer multiplication
    //   - FMULTIPLY: Float multiplication
    //   - IDIVIDE: Integer division
    //   - FDIVIDE: Float division
    //   - MOD: Integer modulo
    : unary_expression ((IMULTIPLY | FMULTIPLY | IDIVIDE | FDIVIDE | MOD)
                        unary_expression)*
      -> template(leftVar={...}, rightVar={...}, resultVar={...},
                  leftExpr={...}, rightExpr={...}, op={...}, lineNo={...})
    ;

unary_expression returns [string RetValue]
    // Unary operations (-, NOT)
    // Operators:
    //   - INEGATE: Integer negation
    //   - FNEGATE: Float negation
    //   - NOT: Logical negation
    : cast_atom
    | (INEGATE | FNEGATE | NOT) cast_atom
      -> template(resultVar={...}, operand={...}, operandExpr={...},
                  op={...}, lineNo={...})
    ;

cast_atom returns [string RetValue]
    // Type casting and type checking (AS, IS)
    // Operators:
    //   - AS: Type cast (may fail at runtime)
    //   - IS: Type check (returns Bool)
    : dot_atom
    | dot_atom AS anyType
      -> template(resultVar={...}, operand={...}, operandExpr={...},
                  targetType={...}, lineNo={...})
    | dot_atom IS anyType
      -> template(resultVar={...}, operand={...}, operandExpr={...},
                  targetType={...}, lineNo={...})
    ;

dot_atom returns [string RetValue]
    // Member access (obj.field)
    // Also handles struct member access (struct.field)
    : array_atom
    | array_atom DOT ID
      -> template(resultVar={...}, object={...}, objectExpr={...},
                  member={...}, lineNo={...})
    ;

array_atom returns [string RetValue]
scope array_atom_scope;
    // Array element access (arr[idx])
    // Also handles array function calls (arr.Find(...))
    : atom
    | array_func_or_id LBRACKET expression RBRACKET
      -> template(resultVar={...}, array={...}, arrayExpr={...},
                  index={...}, indexExpr={...}, lineNo={...})
    ;

atom returns [string RetValue]
    // Atomic expressions (literals, identifiers, function calls, parentheses)
    : func_or_id
    | constant
    | NEW anyType LBRACKET expression RBRACKET     // New array
      -> template(resultVar={...}, type={...}, size={...},
                  sizeExpr={...}, lineNo={...})
    | NEW anyType                                  // New struct
      -> template(resultVar={...}, type={...}, lineNo={...})
    | LPAREN expression RPAREN                     // Parenthesized expression
      -> { /* Return child expression */ }
    ;

array_func_or_id returns [string RetValue]
scope array_func_or_id_scope;
    // Array function calls or array variable reference
    // Array functions (13 total):
    //   - Find, RFind, FindStruct, RFindStruct
    //   - GetAllMatchingStructs
    //   - Add, Insert, Remove, RemoveLast, Clear
    //   - Length (property access)
    : ID
    | ID DOT ID callParameters?
      -> template(resultVar={...}, array={...}, method={...},
                  args={...}, paramExpressions={...}, lineNo={...})
    ;

func_or_id returns [string RetValue]
scope func_or_id_scope;
    // Function call or identifier
    : ID
    | function_call
    ;

// ============================================================================
// PROPERTY AND STRUCT SETTERS
// ============================================================================
//
// Property and struct setters are special assignment operations that generate
// function calls instead of direct assignments.
//
// Property Setter:
//   obj.prop = value
//   → callLocal obj "set_prop" value
//
// Struct Setter:
//   struct.field = value
//   → structset struct field value
// ============================================================================

property_set
scope property_set_scope;
    // Property setter call
    // Generate callLocal template with property setter name
    : ID DOT ID EQUALS expression
      -> template(object={...}, property={...}, value={...},
                  valueExpr={...}, lineNo={...})
    ;

struct_set
scope struct_set_scope;
    // Struct member assignment
    // Generate structset template
    : ID DOT ID EQUALS expression
      -> template(struct={...}, member={...}, value={...},
                  valueExpr={...}, lineNo={...})
    ;

// ============================================================================
// FUNCTION CALLS
// ============================================================================
//
// Function calls come in three varieties:
//   1. Local calls:  obj.func(args)   → callLocal
//   2. Parent calls: parent.func(args) → callParent
//   3. Global calls: Type.func(args)   → callGlobal
//
// All function calls return a temporary variable holding the result.
//
// Special cases:
//   - Array function calls (handled by array_func_or_id)
//   - Property setter calls (handled by property_set)
//   - Struct setters (handled by struct_set)
// ============================================================================

function_call returns [string RetValue]
scope function_call_scope;
    // Dispatch based on call type (CALL, CALLPARENT, CALLGLOBAL)
    // Extract function name and parameters
    // Generate appropriate call template (callLocal, callParent, callGlobal)
    // Return temporary variable holding result
    : CALL ID ID ID callParameters?
      -> template(selfName={...}, name={...}, retValue={...},
                  args={...}, paramExpressions={...}, lineNo={...})
    | CALLPARENT ID ID ID callParameters?
      -> template(name={...}, retValue={...}, args={...},
                  paramExpressions={...}, lineNo={...})
    | CALLGLOBAL ID ID ID callParameters?
      -> template(scriptName={...}, name={...}, retValue={...},
                  args={...}, paramExpressions={...}, lineNo={...})
    ;

// ============================================================================
// FUNCTION PARAMETERS
// ============================================================================
//
// Function call arguments. Each parameter is an expression that is evaluated
// and passed to the function.
//
// Returns: List<string> with parameter variable names (from expression.RetValue)
// ============================================================================

parameters returns [List<string> ParamVars]
    // Process parameter list
    // Evaluate each parameter expression
    // Collect parameter variable names (expression.RetValue)
    : parameter+
    ;

parameter
    // Evaluate parameter expression
    // Return parameter variable name
    : expression
      -> { expression.RetValue }
    ;

// ============================================================================
// UTILITY RULES
// ============================================================================
//
// Low-level parsing rules for identifiers, constants, types, etc.
// ============================================================================

idOrConstant returns [string Value]
    // Identifier or constant value
    : ID
    | constant
    ;

constant
    // Constant literals (integer, float, string, bool, none)
    : INTEGER
    | FLOAT
    | STRING
    | BOOL
    | NONE
    ;

number
    // Numeric literals (integer or float)
    // Note: Sign is handled by unary_expression, not here
    : INTEGER
    | FLOAT
    ;

type returns [string TypeString]
    // Type reference (simple or array)
    // Examples:
    //   - Int
    //   - String[]
    //   - Actor
    //   - MyStruct[]
    : ID
    | ID LBRACKET RBRACKET      // Array type
    | BASETYPE
    | BASETYPE LBRACKET RBRACKET
    ;

anyType
    // Any type reference (used in parameter/variable declarations)
    : type
    ;

scriptType
    // Script type reference (possibly namespaced in FO4/SF1)
    // Examples:
    //   - Actor
    //   - MyNamespace:MyScript
    : ID (COLON ID)*
    ;

userFlags
    // User flags (native, global, access modifiers, etc.)
    // Parsed but not shown in grammar (handled semantically)
    // Results in integer flag value
    ;

// ============================================================================
// HELPER METHODS (Implemented in C#, not grammar rules)
// ============================================================================
//
// These methods are called by the tree walker but are not grammar rules.
// They are implemented in PapyrusGen.cs.
//
// String Handling:
//   - MakeQuotedString(string aOriginalString) : string
//     Escapes and quotes string literals for assembly output.
//     Example: foo\nbar → "foo\\nbar"
//
// Variable Name Mangling:
//   - MangleVariableName(string aOriginalName) : string
//     Generates mangled name for shadowed variable.
//     Example: myVar → ::mangled_myVar_0
//
//   - MangleFunctionVariables(ScriptFunctionType aFunction) : void
//     Mangles all variables in function scope to handle shadowing.
//
//   - MangleScopeVariables(ScriptScope aCurrentScope,
//                          HashSet<string> aAlreadyDefinedVars) : void
//     Recursively mangles variables in scope and children.
//
// Guard Unlocking (SF1-specific):
//   - GenerateScopeExitExpressions(ScriptScope aScope, int aLineNumber)
//     : List<StringTemplate>
//     Generates unlockGuards templates for return/scope exit.
//     Guards are unlocked in LIFO order (reverse acquisition).
//
// Event Name Mangling:
//   - MangleRemoteEventName(ScriptFunctionName aName) : string
//     Mangles remote event names.
//     Example: OnActivate → ::remote_OnActivate
//
// Label Generation:
//   - GenerateLabel() : string
//     Generates unique labels for control flow.
//     Pattern: label0, label1, label2, ...
//     Uses CurLabelSuffix field (incremented per call).
//
// Timestamp Helpers:
//   - ToUnixTime(DateTime aTime) : long
//     Converts DateTime to Unix timestamp.
//
//   - GetFileModTimeUnix(string aFilePath) : long
//     Gets file modification time as Unix timestamp.
//
//   - GetCompileTimeUnix() : long
//     Gets current compile time as Unix timestamp.
//
// Flag Handling:
//   - ConstructUserFlagRefInfo() : Dictionary<string, int>
//     Builds dictionary of flag name → flag index.
//     Used for emitting flag references in assembly.
//
// Property Grouping:
//   - HandleUngroupedProperties(List<string> aUngroupedProps,
//                                List<StringTemplate> aGroupDefinitions) : void
//     Creates default group for properties not in any explicit group.
//
// ============================================================================

// ============================================================================
// END OF GRAMMAR
// ============================================================================
