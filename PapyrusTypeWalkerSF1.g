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

tree grammar PapyrusTypeWalkerSF1;

options { tokenVocab=PapyrusLexerSF1; ASTLabelType=CommonTree; language=CSharp3; }

// ============================================================================
// SCOPE DECLARATIONS
// ============================================================================

// Function scope tracks state, property context, and function type
@members {
    scope function {
        ScriptObjectStateName stateName;
        string propertyName;
        ScriptFunctionType pfunctionType;
    }
}

// Function header scope tracks function ID token for error reporting
@members {
    scope functionHeader {
        IToken IDToken;
    }
}

// Event function scope tracks remote event flag, state, event name, and function type
@members {
    scope eventFunc {
        bool remoteEvent;
        ScriptObjectStateName stateName;
        ScriptFunctionName eventName;
        ScriptFunctionType pfunctionType;
    }
}

// Property block scope tracks which property function is the getter
@members {
    scope propertyBlock {
        bool func0IsGet;
    }
}

// Code block scope tracks function type, current scope, temp vars, and child scope index
@members {
    scope codeBlock {
        ScriptFunctionType pfunctionType;
        ScriptScope pcurrentScope;
        Dictionary<string, ScriptVariableType> ptempVars;
        int inextScopeChild;
    }
}

// Statement scope tracks value expression tree for assignments
@members {
    scope statement {
        CommonTree pvalueExpressionTree;
    }
}

// Local definition scope tracks initial value tree
@members {
    scope localDefinition {
        CommonTree initialValueTree;
    }
}

// L-value scope tracks token, index expression tree, and struct flag
@members {
    scope l_value {
        IToken pvarToken;
        CommonTree pindexExpressionTree;
        bool bisStruct;
    }
}

// Basic l-value scope tracks struct/property flags, token, and index expression
@members {
    scope basic_l_value {
        bool bisStruct;
        bool bisProperty;
        bool bisLocalAutoProperty;
        IToken pvarToken;
        CommonTree pindexExpressionTree;
    }
}

// Expression scopes track expression trees for code generation
@members {
    scope bool_expression {
        CommonTree paTree;
        CommonTree pbTree;
    }
}

@members {
    scope add_expression {
        bool bisInt;
        bool bisConcat;
        CommonTree paTree;
        CommonTree pbTree;
    }
}

@members {
    scope mult_expression {
        bool bisInt;
        CommonTree paTree;
        CommonTree pbTree;
    }
}

@members {
    scope unary_expression {
        bool bisInt;
    }
}

@members {
    scope array_atom {
        CommonTree pindexExpressionTree;
    }
}

@members {
    scope array_func_or_id {
        CommonTree pindexExpressionTree;
    }
}

@members {
    scope func_or_id {
        bool bisStruct;
        bool bisProperty;
        bool bisLocalAutoProperty;
    }
}

@members {
    scope return_stat {
        CommonTree pexpressionTree;
    }
}

// SF1 CONCURRENCY SCOPES
// Lock block scope tracks child scope for guard tracking
@members {
    scope lockBlock {
        ScriptScope childScope;
    }
}

@members {
    scope tryLockBlock {
        ScriptScope childScope;
        string resultVarName;
    }
}

@members {
    scope elseTryLockBlock {
        ScriptScope childScope;
        string resultVarName;
    }
}

// Control flow scopes
@members {
    scope ifBlock {
        ScriptScope pchildScope;
    }
}

@members {
    scope elseIfBlock {
        ScriptScope pchildScope;
    }
}

@members {
    scope elseBlock {
        ScriptScope pchildScope;
    }
}

@members {
    scope whileBlock {
        ScriptScope pchildScope;
    }
}

@members {
    scope function_call {
        List<string> ptargetParamNames;
        List<ScriptVariableType> pparamTypes;
        List<string> pparamVarNames;
        List<IToken> pparamTokens;
        List<CommonTree> pparamExpressions;
        bool isGlobal;
        bool isArray;
        ScriptVariableType pactualReturnType;
    }
}

// ============================================================================
// TOP-LEVEL SCRIPT STRUCTURE
// ============================================================================

// Entry point: Initializes compiler state and walks entire script
// Post-processing: Calls CheckFunctionGuardUsage() to validate guard usage
//                 across all state overrides
script[ScriptObjectType obj, Compiler compiler, Dictionary<string, ScriptComplexType> knownTypes]
    : ^(OBJECT
        header
        definitionOrBlock*
      )
    ;

header
    : ^(ID USER_FLAGS ID? DOCSTRING?)
    ;

// SF1: 10 definition types (FO4 + guardDefinition)
definitionOrBlock
    : fieldDefinition
    | guardDefinition          // SF1: Guard definition for thread safety
    | customEventDefinition
    | function
    | eventFunc
    | stateBlock
    | propertyBlock
    | groupBlock
    | structBlock
    ;

// ============================================================================
// FIELD DEFINITIONS
// ============================================================================

// Type checks: Variable name uniqueness, type validity, const value compatibility
fieldDefinition[bool isStruct]
    : ^(VAR
        type
        ID
        USER_FLAGS
        CONST?
        constant?
        DOCSTRING?
      )
    ;

// ============================================================================
// SF1 GUARD DEFINITIONS
// ============================================================================

// SF1 CONCURRENCY: Guard definition validation
// Checks:
//   - Guard name is unique (CheckGuardDefinition)
//   - Guard name doesn't conflict with variables/functions
// Guards are used with LockGuard/TryLockGuard statements
guardDefinition
    : ^(GUARD ID)
    ;

// ============================================================================
// CUSTOM EVENT DEFINITIONS
// ============================================================================

// Type checks: Custom event name uniqueness
customEventDefinition
    : ^(CUSTOMEVENT ID)
    ;

// ============================================================================
// FUNCTION DEFINITIONS
// ============================================================================

// Type checks: Function signature, parameter types, return type, body statements
// Post-processing: CheckFunction() validates entire function definition
// SF1: Validates RequiresGuard flags and reports unused guards in property functions
function[ScriptObjectStateName stateName, string propertyName] returns [ScriptFunctionName Name]
    scope { function; }
    : ^(FUNCTION
        functionHeader
        codeBlock?
      )
    ;

// Type checks: Return type validity, parameter types, function name uniqueness
// SF1: Function may have RequiresGuard user flag listing required guards
functionHeader returns [ScriptFunctionName FuncName]
    scope { functionHeader; }
    : ^(HEADER
        type
        ID
        USER_FLAGS
        callParameters?
        DOCSTRING?
      )
    | ^(HEADER
        NONE
        ID
        USER_FLAGS
        callParameters?
        DOCSTRING?
      )
    ;

// Not used in type walker (syntax only)
functionModifier
    : GLOBAL
    | NATIVE
    ;

// ============================================================================
// EVENT DEFINITIONS
// ============================================================================

// Type checks: Event signature, parameter types (must be compatible with parent)
// Post-processing: CheckFunction() or CheckRemoteEvent() validates event
eventFunc[ScriptObjectStateName stateName]
    scope { eventFunc; }
    : ^(EVENT
        eventHeader
        codeBlock?
      )
    | ^(REMOTEEVENT
        eventHeader
        codeBlock?
      )
    ;

// Type checks: Event name, parameter types (events always return NONE)
eventHeader
    : ^(HEADER
        NONE
        ID
        USER_FLAGS
        callParameters?
        NATIVE?
        DOCSTRING?
      )
    ;

// ============================================================================
// PARAMETERS
// ============================================================================

// Parameter list (type checking done in callParameter)
callParameters
    : callParameter+
    ;

// Type checks: Parameter type validity, default value compatibility
callParameter
    : ^(PARAM type ID constant?)
    ;

// ============================================================================
// STATE BLOCKS
// ============================================================================

// States contain functions/events that override empty state versions
stateBlock
    : ^(STATE
        ID
        AUTO?
        stateFuncOrEvent*
      )
    ;

stateFuncOrEvent
    : function
    | eventFunc
    ;

// ============================================================================
// PROPERTY BLOCKS
// ============================================================================

// Type checks: Property type, getter/setter signatures, auto property flags
propertyBlock
    scope { propertyBlock; }
    : ^(PROPERTY
        propertyHeader
        propertyFunc
        propertyBlock
      )
    | ^(AUTOPROP
        propertyHeader
        ID
      )
    ;

propertyHeader returns [string Name]
    : ^(HEADER
        type
        ID
        USER_FLAGS
        DOCSTRING?
      )
    ;

// SF1: Property functions may have RequiresGuard flags
// Type checks: Getter must match property type, setter must take property type
propertyFunc returns [bool IsGet]
    : ^(PROPFUNC function)
    | PROPFUNC
    ;

// ============================================================================
// GROUP BLOCKS
// ============================================================================

// FO4: Groups organize properties and variables
groupBlock
    : ^(GROUP
        groupHeader
        groupPropOrField*
      )
    ;

groupHeader
    : ^(HEADER
        ID
        USER_FLAGS
        DOCSTRING?
      )
    ;

groupPropOrField
    : propertyBlock
    | fieldDefinition
    ;

// ============================================================================
// STRUCT BLOCKS
// ============================================================================

// FO4: Struct definitions (value types with fields)
structBlock
    : ^(STRUCT
        structHeader
        fieldDefinition*
      )
    ;

structHeader returns [string sName]
    : ^(HEADER
        ID
        DOCSTRING?
      )
    ;

// ============================================================================
// CODE BLOCKS AND STATEMENTS
// ============================================================================

// Code block: Manages scope, tracks temporary variables
// Type checks: All statements within block
codeBlock[ScriptFunctionType functionType, ScriptScope currentScope]
    scope { codeBlock; }
    : ^(BLOCK statement*)
    ;

// SF1: 8 statement types (FO4 + lockBlock + tryLockBlock)
// Type checks: Each statement type has specific validation rules
statement
    scope { statement; }
    : localDefinition
    | ^(EQUALS
        ID
        l_value
        expression
      )
    | expression
    | return_stat
    | lockBlock            // SF1: Guard lock statement
    | tryLockBlock         // SF1: Try-lock with fallback
    | ifBlock
    | whileBlock
    ;

// Local variable definition with optional initialization
// Type checks: Variable type validity, initializer compatibility
localDefinition
    scope { localDefinition; }
    : ^(VAR
        type
        ID
        expression?
      )
    ;

// ============================================================================
// SF1 CONCURRENCY STATEMENTS
// ============================================================================

// SF1 CONCURRENCY: Lock guard block
// Acquires one or more guards, executes code block, releases guards
// Type checks:
//   - All guard names exist (CheckGuardLock)
//   - Guards not locked in global functions
//   - Tracks locked guards in child scope
lockBlock
    scope { lockBlock; }
    : ^(LOCKGUARD
        ID+             // One or more guard names
        codeBlock
      )
    ;

// SF1 CONCURRENCY: Try-lock guard block with optional fallback
// Attempts to acquire guards, executes success block if acquired,
// otherwise executes fallback block
// Type checks: Same as lockBlock for each guard list
tryLockBlock
    scope { tryLockBlock; }
    : ^(TRYLOCKGUARD
        ID+             // Guards to try locking
        codeBlock       // Success block
        elseTryLockBlock* // Optional else-try blocks
        elseBlock?      // Optional final else block
      )
    ;

// SF1 CONCURRENCY: Else-try-lock block (try alternative guards)
elseTryLockBlock
    scope { elseTryLockBlock; }
    : ^(ELSETRYLOCKGUARD
        ID+             // Alternative guards to try
        codeBlock
      )
    ;

// ============================================================================
// CONTROL FLOW
// ============================================================================

// If statement with optional else-if and else blocks
// Type checks: Condition must be bool-castable
ifBlock
    scope { ifBlock; }
    : ^(IF
        expression
        codeBlock
        elseIfBlock*
        elseBlock?
      )
    ;

elseIfBlock
    scope { elseIfBlock; }
    : ^(ELSEIF
        expression
        codeBlock
      )
    ;

elseBlock
    scope { elseBlock; }
    : ^(ELSE codeBlock)
    ;

// While loop
// Type checks: Condition must be bool-castable
whileBlock
    scope { whileBlock; }
    : ^(WHILE
        expression
        codeBlock
      )
    ;

// Return statement with optional value
// Type checks: Return value type must match function return type
return_stat
    scope { return_stat; }
    : ^(RETURN expression?)
    ;

// ============================================================================
// L-VALUES (Left-hand side of assignments)
// ============================================================================

// L-value: Target of assignment (variable, property, array element)
// Type checks: L-value must be writable, type must be known
// SF1: Validates guard locks for variable/property access
l_value returns [ScriptVariableType pVarType, string sVarName]
    scope { l_value; }
    : ^(DOT
        ^(PAREXPR expression)
        property_set
      )
    | ^(ARRAYSET
        ID
        ID
        func_or_id
        expression
      )
    | basic_l_value
    ;

// Basic l-value: Simple variable or property access
basic_l_value returns [ScriptVariableType pType, string sVarName]
    scope { basic_l_value; }
    : ^(DOT
        array_func_or_id
        basic_l_value
      )
    | function_call
    | property_set
    | ^(ARRAYSET
        ID
        ID
        func_or_id
        expression
      )
    | ID
    ;

// ============================================================================
// EXPRESSIONS (Type inference and validation)
// ============================================================================

// OR expression: Logical OR with short-circuit semantics
// Type inference: Result is always bool
expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ^(OR
        ID
        expression
        and_expression
      )
    | and_expression
    ;

// AND expression: Logical AND with short-circuit semantics
// Type inference: Result is always bool
and_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ^(AND
        ID
        and_expression
        bool_expression
      )
    | bool_expression
    ;

// Boolean comparison expressions
// Type inference: Result is always bool
// Type checks: Operands must be comparable (HandleComparisonExpression)
bool_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { bool_expression; }
    : ^(EQ
        bool_expression
        add_expression
      )
    | ^(NE
        bool_expression
        add_expression
      )
    | ^(GT
        bool_expression
        add_expression
      )
    | ^(LT
        bool_expression
        add_expression
      )
    | ^(GTE
        bool_expression
        add_expression
      )
    | ^(LTE
        bool_expression
        add_expression
      )
    | add_expression
    ;

// Addition/subtraction expressions
// Type inference: int + int = int, float + float = float, string + X = string
// Type checks: Operands must be numeric or string (for concat)
add_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { add_expression; }
    : ^(PLUS
        add_expression
        mult_expression
      )
    | ^(MINUS
        add_expression
        mult_expression
      )
    | mult_expression
    ;

// Multiplication/division/modulo expressions
// Type inference: int * int = int, float * float = float
// Type checks: Operands must be numeric, no division by zero (runtime)
mult_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { mult_expression; }
    : ^(MULT
        mult_expression
        unary_expression
      )
    | ^(DIVIDE
        mult_expression
        unary_expression
      )
    | ^(MOD
        mult_expression
        unary_expression
      )
    | unary_expression
    ;

// Unary expressions (negation, logical NOT)
// Type inference: -int = int, -float = float, NOT bool = bool
// Type checks: Operand must be numeric (for -) or bool (for NOT)
unary_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { unary_expression; }
    : ^(UNARY_MINUS cast_atom)
    | ^(NOT cast_atom)
    | cast_atom
    ;

// Cast expression: Explicit type conversion
// Type checks: Cast must be valid (CheckCast)
cast_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ^(AS
        ID
        dot_atom
      )
    | dot_atom
    ;

// Dot accessor expression: Member access (property, function)
// Type checks: Member must exist on owner type
// SF1: Validates guard locks for property/function access
dot_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ^(DOT
        dot_atom
        array_func_or_id
      )
    | array_atom
    | constant
    ;

// Array element access
// Type checks: Index must be int, base must be array type
array_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { array_atom; }
    : ^(ARRAYGET
        ID
        ID
        atom
        expression
      )
    | atom
    ;

// Atomic expressions (constants, variables, function calls, parenthesized expressions)
// Type inference: Type depends on atomic element
atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ^(PAREXPR expression)
    | ^(NEW INTEGER ID)          // Array allocation: new Type[size]
    | ^(NEWSTRUCT ID)            // FO4: Struct instantiation
    | func_or_id
    ;

// ============================================================================
// FUNCTION AND ARRAY OPERATIONS
// ============================================================================

// Array element access or function call in array context
// SF1: Validates guard locks for function calls
array_func_or_id returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { array_func_or_id; }
    : ^(ARRAYGET
        ID
        ID
        func_or_id
        expression
      )
    | func_or_id
    ;

// Function call, property access, or simple identifier
// Type inference: Variable from scope, property from owner type, function return type
// SF1: Validates guard locks for property/function access
func_or_id returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    scope { func_or_id; }
    : function_call
    | ^(PROPGET
        ID
        ID
        ID
      )
    | ID
    | ^(LENGTH
        ID
        ID
      )
    ;

// Property setter access (used in l_value)
// SF1: Validates guard locks for property write access
property_set
    : ^(PROPSET
        ID
        ID
        ID
      )
    ;

// ============================================================================
// FUNCTION CALLS
// ============================================================================

// Function call with parameters
// Type checks: Function exists, parameters match signature, return type
// SF1: Validates guard locks for function call, checks access modifiers
function_call returns [ScriptVariableType pType, string VarName, IToken pVarToken]
    scope { function_call; }
    : ^(CALL
        ID              // Result temp var
        ID              // Owner type
        ID              // Function name
        ^(CALLPARAMS parameters)
      )
    | ^(CALLPARENT
        ID              // Result temp var
        ID              // Owner type
        ID              // Function name
        ^(CALLPARAMS parameters)
      )
    | ^(CALLGLOBAL
        ID              // Result temp var
        ID              // Owner type
        ID              // Function name
        ^(CALLPARAMS parameters)
      )
    | ^(ARRAYFIND
        ID              // Result temp var
        ID              // Array var
        ^(CALLPARAMS parameters)
      )
    | ^(ARRAYRFIND
        ID              // Result temp var
        ID              // Array var
        ^(CALLPARAMS parameters)
      )
    | ^(ARRAYFINDSTRUCT
        ID              // Result temp var
        ID              // Array var
        ^(CALLPARAMS parameters)
      )
    | ^(ARRAYRFINDSTRUCT
        ID              // Result temp var
        ID              // Array var
        ^(CALLPARAMS parameters)
      )
    | ^(ARRAYGETALLMATCHINGSTRUCTS
        ID              // Result temp var
        ID              // Array var
        ^(CALLPARAMS parameters)
      )
    ;

// Parameter list for function calls
parameters
    : parameter*
    ;

// Single parameter with optional automatic cast
// Type checks: Parameter type matches function signature
parameter
    : ^(PARAM expression)
    ;

// ============================================================================
// TYPE SYSTEM
// ============================================================================

// Type specification (ID or ID[] for arrays, BASETYPE for primitives)
// Type checks: Type must be known, namespace resolution if qualified
type returns [ScriptVariableType pType]
    : ID                        // Simple type or namespace-qualified (ID:ID:ID)
    | ^(ID LBRACKET RBRACKET)  // Array type
    | BASETYPE                  // Built-in type (int, float, bool, string)
    | ^(BASETYPE LBRACKET RBRACKET) // Built-in array type
    ;

// ============================================================================
// CONSTANTS
// ============================================================================

// Constant values (literals)
// Returns type and token for type checking in field initializers and default parameters
constant returns [ScriptVariableType pType, IToken pVarToken]
    : number    { $pType = $number.pType; $pVarToken = $number.pVarToken; }
    | STRING    { $pType = new ScriptVariableType("string"); $pVarToken = $STRING.token; }
    | BOOL      { $pType = new ScriptVariableType("bool"); $pVarToken = $BOOL.token; }
    | NONE      { $pType = new ScriptVariableType("none"); $pVarToken = $NONE.token; }
    ;

// Numeric literals (sign handled in unary_expression)
// Returns type and token for propagation to constant rule
number returns [ScriptVariableType pType, IToken pVarToken]
    : INTEGER   { $pType = new ScriptVariableType("int"); $pVarToken = $INTEGER.token; }
    | FLOAT     { $pType = new ScriptVariableType("float"); $pVarToken = $FLOAT.token; }
    ;
