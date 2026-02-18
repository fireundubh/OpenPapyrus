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

// PapyrusOptimizerSF1.g - Starfield Papyrus Optimizer Tree Grammar
//
// Generated from: H:\repos\PapyrusCompiler\PCompilerSF1\PapyrusOptimizer.cs
// Assembly: PCompiler, Version=4.7.0.5 (Starfield)
//
// This is an ANTLR3 tree grammar (documentation only, not meant to be compiled).
// It documents the tree rewriting rules used by the Starfield Papyrus optimizer.
//
// The SF1 optimizer is identical to FO4 with one difference:
//   - validParenRemovalTarget has 29 alternatives (FO4 has 29 too, but SF1 adds
//     ARRAYGETALLMATCHINGSTRUCTS and a second STRUCTGET, while keeping STRUCTSET)
//
// Architecture: TreeRewriter with topdown + bottomup passes
//   - topdown: Scope management (enter functions/states/properties/blocks)
//   - bottomup: 14 optimization sub-passes (scope cleanup + expression optimization)

tree grammar PapyrusOptimizerSF1;

options {
    tokenVocab = PapyrusLexerSF1;
    ASTLabelType = CommonTree;
    language = CSharp3;
    output = AST;
}

@header {
using Antlr.Runtime;
using Antlr.Runtime.Tree;
using System.Collections.Generic;
}

@members {
    private ScriptObjectType pObjType;
    private Dictionary<string, ScriptComplexType> pKnownTypes;
    private ScopeManager pScopeManager = new ScopeManager();

    public void SetUp(ScriptObjectType apObjType, Dictionary<string, ScriptComplexType> apKnownTypes) {
        pObjType = apObjType;
        pKnownTypes = apKnownTypes;
        pScopeManager.Reset(pObjType);
    }

    private bool IsKnownType(string asName) {
        return pKnownTypes.ContainsKey(asName.ToLowerInvariant());
    }

    private bool TryConvertToBool(IToken apValue, out bool arbValue) {
        // Converts INTEGER, FLOAT, BOOL, STRING, NONE to boolean for optimization
        // Used in short-circuit evaluation and constant folding
    }

    private bool CanRemoveAnd(IToken apFirstToken, IToken apSecondToken, out string arsResult) {
        // Returns true if both values are constants and can be folded
        // arsResult = "true" if both true, else "false"
    }

    private bool CanRemoveOr(IToken apFirstToken, IToken apSecondToken, out string arsResult) {
        // Returns true if both values are constants and can be folded
        // arsResult = "true" if either true, else "false"
    }

    private bool CanOptimizeAnd(IToken apFirstToken, out bool arbUseBExpression) {
        // Returns true if first operand is constant
        // arbUseBExpression = true means use second expr (first was true)
        // arbUseBExpression = false means short-circuit to false
    }

    private bool CanOptimizeOr(IToken apFirstToken, out bool arbUseBExpression) {
        // Returns true if first operand is constant
        // arbUseBExpression = true means use second expr (first was false)
        // arbUseBExpression = false means short-circuit to true
    }

    private string CalculateMathResult(IToken apMathToken, string asFirstValue, string asSecondValue) {
        // Performs compile-time arithmetic: IADD, FADD, ISUBTRACT, etc.
        // Handles overflow and division by zero errors
    }

    private string CalculateUnaryResult(int aiOpTokenType, string asValue) {
        // Evaluates unary operations: INEGATE, FNEGATE, NOT
    }

    private bool CanCompileCast(string asDestVarName, IToken apSourceToken) {
        // Validates whether a cast from source to dest type is valid
        // Checks type compatibility and known types
    }

    private ITree CalculateRawCast(string asDestVarName, IToken apSourceToken) {
        // Performs compile-time cast of constant values
        // Creates new token with converted value
    }

    private bool CanCompileIsCheck(ScriptVariableType apDestType, IToken apSourceToken) {
        // Validates whether an IS check can be evaluated at compile-time
        // Checks inheritance relationships for object types
    }

    private ITree CalculateIsCheck(ScriptVariableType apDestType, IToken apSourceToken) {
        // Evaluates IS checks at compile-time, returns BOOL token
    }

    private bool CheckArraySize(IToken apSizeToken) {
        // Validates array size is between 0 and 128
        // Reports error if out of range
    }

    private ScriptComplexType GetKnownType(string asName) {
        // Returns the ScriptComplexType for asName if it exists in pKnownTypes, else null
    }

    private string EnsureFloatingPoint(string asInput) {
        // Appends ".0" if asInput has no decimal point
    }

    private string TrimGarbage(string asInput, char[] akNonGarbageCharsA) {
        // Trims leading characters that are in akNonGarbageCharsA, returns prefix before first non-garbage char
    }

    private int CastStrToInt(string asInput) {
        // Parses asInput to int, progressively trimming trailing chars until TryParse succeeds
    }

    private string TrimQuotes(string asInput) {
        // Removes surrounding quotes from a string literal
    }

    private bool TryGetVariableType(string asVarName, out ScriptVariableType arpVarType) {
        // Checks pObjType and pScopeManager.CurrentScope for variable type
    }

    private ITree PushValueToLValue(ITree apLValueTree, IToken apReplacementValue) {
        // Creates a NOCODEASSIGN tree wrapping the l-value with the replacement value
        // Calls ReplaceLValueTarget to update the target variable in the l-value
    }

    private bool CanPushValueToLValue(ITree apLValueTree) {
        // Returns true if l-value is ARRAYSET, PROPSET, STRUCTSET, or DOT (recursive on child 1)
    }

    private bool ReplaceLValueTarget(ITree apLValueTree, IToken apReplacementValue) {
        // Replaces the target variable in an l-value tree with apReplacementValue
        // ARRAYSET: sets child 0; PROPSET/STRUCTSET: sets child 2; DOT: recurses on child 1
    }

    private ITree PushValueToExpression(ITree apExpressionTree, ITree apLValueTree, IToken apReplacementValue) {
        // Creates a NOCODEASSIGN tree wrapping the expression with the replacement value
        // Calls ReplaceExpressionTarget to update the target in the expression
    }

    private bool CanPushValueToExpression(ITree apExpressionTree) {
        // Returns true if expression type supports value pushing
        // Handles DOT (recurse child 1), PAREXPR (recurse child 0), and ~40 direct token types
    }

    private bool ReplaceExpressionTarget(ITree apExpressionTree, IToken apReplacementValue) {
        // Replaces the target variable in an expression tree with apReplacementValue
        // Different child index depending on expression type
    }

    event InternalErrorEventHandler pErrorHandler;
}

// ============================================================================
// TREE WALKER ENTRY POINTS
// ============================================================================

// Top-down pass: Scope management and setup
// Enters functions, states, properties, and blocks to initialize scope context
// C# topdown() dispatches on:
//   FUNCTION(69), EVENT(61), REMOTEEVENT(124) -> enterFunction
//   STATE(131) -> enterState
//   PROPERTY(116) -> enterProperty
//   BLOCK(24) -> enterBlock
topdown
    : enterFunction
    | enterState
    | enterProperty
    | enterBlock
    ;

// Bottom-up pass: Optimization and cleanup
// Performs 14 optimization passes on the AST:
// 1-4:   Scope cleanup (leave functions/states/properties/blocks)
// 5-6:   Expression simplification (parens, dots)
// 7-10:  Constant folding (bool ops, math ops, unary ops)
// 11-14: Type operations (casts, is checks, equals, array size validation)
bottomup
    : leaveFunction
    | leaveState
    | leaveProperty
    | leaveBlock
    | eliminateParens
    | eliminateExcessDots
    | doubleValueBoolOps
    | singleValueBoolOps
    | doubleValueMathOps
    | unaryOps
    | rawCastOps
    | rawIsCheck
    | cleanEquals
    | errorCheckArraySize
    ;

// ============================================================================
// SCOPE MANAGEMENT RULES (Top-down Pass)
// ============================================================================

// Enter function scope - initializes function-level scope for variable tracking
// Tree pattern: ^((FUNCTION|EVENT|REMOTEEVENT) ^(HEADER type ID .*) .?)
// C# enterFunction(): matches token 61|69|124, then DOWN, HEADER subtree with type() and ID
// Action: pScopeManager.EnterFunction(new ScriptFunctionName(ID.Text))
enterFunction
    : ^((FUNCTION | EVENT | REMOTEEVENT) ^(HEADER type name=ID .*) .?)
    {
        pScopeManager.EnterFunction(new ScriptFunctionName($name.text));
    }
    ;

// Enter state scope - tracks state-specific function definitions
// C# enterState(): matches STATE(131), DOWN, ID, then wildcards
// Action: pScopeManager.EnterState(new ScriptObjectStateName(ID.Text))
enterState
    : ^(STATE name=ID .*)
    {
        pScopeManager.EnterState(new ScriptObjectStateName($name.text));
    }
    ;

// Enter property scope - handles property get/set scopes
// C# enterProperty(): matches PROPERTY(116), DOWN, HEADER subtree with type() and ID
// Action: pScopeManager.EnterProperty(new ScriptPropertyName(ID.Text))
enterProperty
    : ^(PROPERTY ^(HEADER type name=ID .*) .*)
    {
        pScopeManager.EnterProperty(new ScriptPropertyName($name.text));
    }
    ;

// Enter code block - creates nested scope for local variables
// C# enterBlock(): matches BLOCK(24) leaf token
// Action: pScopeManager.EnterBlock()
enterBlock
    : BLOCK
    {
        pScopeManager.EnterBlock();
    }
    ;

// ============================================================================
// SCOPE CLEANUP RULES (Bottom-up Pass)
// ============================================================================

// Leave function scope
// C# leaveFunction(): matches FUNCTION(69)|EVENT(61)|REMOTEEVENT(124) leaf token
// Action: pScopeManager.LeaveFunction()
leaveFunction
    : (FUNCTION | EVENT | REMOTEEVENT)
    {
        pScopeManager.LeaveFunction();
    }
    ;

// Leave state scope
// C# leaveState(): matches STATE(131) leaf token
// Action: pScopeManager.LeaveState()
leaveState
    : STATE
    {
        pScopeManager.LeaveState();
    }
    ;

// Leave property scope
// C# leaveProperty(): matches PROPERTY(116) leaf token
// Action: pScopeManager.LeaveProperty()
leaveProperty
    : PROPERTY
    {
        pScopeManager.LeaveProperty();
    }
    ;

// Leave code block
// C# leaveBlock(): matches BLOCK(24) leaf token
// Action: pScopeManager.LeaveBlock()
leaveBlock
    : BLOCK
    {
        pScopeManager.LeaveBlock();
    }
    ;

// ============================================================================
// EXPRESSION OPTIMIZATION RULES (Bottom-up Pass)
// ============================================================================

// Optimization Pass #1: Remove redundant parentheses
// Pattern: (PAREXPR validParenRemovalTarget) -> validParenRemovalTarget
// Only removes parens when the child is safe to unwrap
eliminateParens
    : ^(PAREXPR validParenRemovalTarget) -> validParenRemovalTarget
    ;

// Valid targets for parenthesis removal (29 alternatives in SF1)
// Cases 1-6: Leaf constants/identifiers
// Cases 7-9: Property/struct access and array length
// Case 10: Return statement (with optional child)
// Cases 11-13: Function calls (CALL, CALLPARENT, CALLGLOBAL)
// Cases 14-15: Array get/set
// Cases 16-20: Array manipulation (add, insert, removelast, remove, clear)
// Cases 21-22: Array find/rfind
// Cases 23-24: Array struct find/rfind
// Case 25: ARRAYGETALLMATCHINGSTRUCTS (SF1-specific array operation)
// Cases 26-27: New array/struct
// Case 28: STRUCTGET (second occurrence - duplicate for DFA disambiguation)
// Case 29: STRUCTSET
validParenRemovalTarget
    : ID                                    // case 1: Simple identifier
    | STRING                                // case 2: String literal
    | BOOL                                  // case 3: Boolean literal
    | NONE                                  // case 4: None literal
    | INTEGER                               // case 5: Integer literal
    | FLOAT                                 // case 6: Float literal
    | ^(PROPGET .+)                         // case 7: Property getter
    | ^(STRUCTGET .+)                       // case 8: Struct field getter
    | ^(LENGTH .+)                          // case 9: Array length
    | RETURN                                // case 10: Return statement (leaf or tree)
    | ^(CALL .+)                            // case 11: Method call
    | ^(CALLPARENT .+)                      // case 12: Parent method call
    | ^(CALLGLOBAL .+)                      // case 13: Global function call
    | ^(ARRAYGET .+)                        // case 14: Array element access
    | ^(ARRAYSET .+)                        // case 15: Array element set
    | ^(ARRAYADD .+)                        // case 16: Array add
    | ^(ARRAYINSERT .+)                     // case 17: Array insert
    | ^(ARRAYREMOVELAST .+)                 // case 18: Array remove last
    | ^(ARRAYREMOVE .+)                     // case 19: Array remove
    | ^(ARRAYCLEAR .+)                      // case 20: Array clear
    | ^(ARRAYFIND .+)                       // case 21: Array find
    | ^(ARRAYRFIND .+)                      // case 22: Array reverse find
    | ^(ARRAYFINDSTRUCT .+)                 // case 23: Array find struct
    | ^(ARRAYRFINDSTRUCT .+)               // case 24: Array reverse find struct
    | ^(ARRAYGETALLMATCHINGSTRUCTS .+)      // case 25: Get all matching structs
    | ^(NEWARRAY .+)                        // case 26: New array
    | ^(NEWSTRUCT .+)                       // case 27: New struct
    | ^(STRUCTGET .+)                       // case 28: Struct field getter (DFA duplicate)
    | ^(STRUCTSET .+)                       // case 29: Struct field set
    ;

// Optimization Pass #2: Consolidate dot operators
// 3 alternatives in C# eliminateExcessDots():
//   case 1: ^(DOT ID ^(DOT . .+)) -> consolidates DOT chains (generic)
//   case 2: ^(DOT ID ^(STRUCTSET . . .)) -> consolidates DOT+STRUCTSET
//   case 3: ^(DOT ID ^(PROPSET . . .)) -> consolidates DOT+PROPSET
// Semantic predicate: {IsKnownType($a.text)}
eliminateExcessDots
    : ^(DOT a=ID ^(DOT . .+)) {IsKnownType($a.text)}?
      // Rewrite: merges nested DOT into single access
    | ^(DOT a=ID ^(STRUCTSET self=. var=. source=.)) {IsKnownType($a.text)}?
      -> ^(STRUCTSET $self $var $source)
    | ^(DOT a=ID ^(PROPSET self=. prop=. source=.)) {IsKnownType($a.text)}?
      -> ^(PROPSET $self $prop $source)
    ;

// Optimization Pass #3: Constant-fold boolean operations with two constant values
// Pattern: ^(AND ID rawValue rawValue) -> BOOL[result]
// Pattern: ^(OR ID rawValue rawValue) -> BOOL[result]
// Semantic predicate validates both operands are constant
scope {
    string sFinalValue;
}
doubleValueBoolOps
    : ^(AND ID a=rawValue b=rawValue)
      {CanRemoveAnd($a.start.Token, $b.start.Token, out $doubleValueBoolOps::sFinalValue)}?
      -> BOOL[$doubleValueBoolOps::sFinalValue]
    | ^(OR ID a=rawValue b=rawValue)
      {CanRemoveOr($a.start.Token, $b.start.Token, out $doubleValueBoolOps::sFinalValue)}?
      -> BOOL[$doubleValueBoolOps::sFinalValue]
    ;

// Optimization Pass #4: Short-circuit boolean operations with one constant value
// Pattern: ^(AND ID true expr) -> expr; ^(AND ID false expr) -> false
// Pattern: ^(OR ID true expr) -> true; ^(OR ID false expr) -> expr
scope {
    bool bUseBExpression;
}
singleValueBoolOps
    : ^(AND ID a=rawValue b=.)
      {CanOptimizeAnd($a.start.Token, out $singleValueBoolOps::bUseBExpression)}?
      -> {$singleValueBoolOps::bUseBExpression}? $b
      -> BOOL["false"]
    | ^(OR ID a=rawValue b=.)
      {CanOptimizeOr($a.start.Token, out $singleValueBoolOps::bUseBExpression)}?
      -> {$singleValueBoolOps::bUseBExpression}? $b
      -> BOOL["true"]
    ;

// Optimization Pass #5: Constant-fold arithmetic operations
// Handles: IADD, FADD, ISUBTRACT, FSUBTRACT, IMULTIPLY, FMULTIPLY, IDIVIDE, FDIVIDE, MOD, STRCAT
// Pattern: ^(op constant1 constant2) -> result_constant
scope {
    string sFinalValue;
}
doubleValueMathOps
    : ^(op=IADD a=INTEGER b=INTEGER)
      -> INTEGER[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=FADD a=FLOAT b=FLOAT)
      -> FLOAT[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=ISUBTRACT a=INTEGER b=INTEGER)
      -> INTEGER[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=FSUBTRACT a=FLOAT b=FLOAT)
      -> FLOAT[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=IMULTIPLY a=INTEGER b=INTEGER)
      -> INTEGER[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=FMULTIPLY a=FLOAT b=FLOAT)
      -> FLOAT[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=IDIVIDE a=INTEGER b=INTEGER)
      -> INTEGER[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=FDIVIDE a=FLOAT b=FLOAT)
      -> FLOAT[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=MOD a=INTEGER b=INTEGER)
      -> INTEGER[CalculateMathResult($op, $a.text, $b.text)]
    | ^(op=STRCAT a=STRING b=STRING)
      -> STRING[CalculateMathResult($op, $a.text, $b.text)]
    ;

// Optimization Pass #6: Constant-fold unary operations
// Pattern: ^(INEGATE int) -> negated_int
// Pattern: ^(FNEGATE float) -> negated_float
// Pattern: ^(NOT bool) -> inverted_bool
scope {
    string sFinalValue;
}
unaryOps
    : ^(op=INEGATE a=INTEGER)
      -> INTEGER[CalculateUnaryResult($op.type, $a.text)]
    | ^(op=FNEGATE a=FLOAT)
      -> FLOAT[CalculateUnaryResult($op.type, $a.text)]
    | ^(op=NOT a=BOOL)
      -> BOOL[CalculateUnaryResult($op.type, $a.text)]
    ;

// Optimization Pass #7: Optimize type casts
// Pattern: ^(AS ID rawValue) -> converted_constant
// Semantic predicate: CanCompileCast($ID.Text, $rawValue.start.Token)
// Action: CalculateRawCast($ID.Text, $rawValue.start.Token)
rawCastOps
    : ^(AS ID rawValue) {CanCompileCast($ID.Text, $rawValue.start.Token)}?
      -> {CalculateRawCast($ID.Text, $rawValue.start.Token)}
    ;

// Optimization Pass #8: Optimize IS type checks
// Two alternatives:
//   1. ^(IS ID rawValue type) - IS check with constant value
//   2. ^(IS ID source=ID type) - IS check with variable
// Semantic predicate: CanCompileIsCheck($type.pType, source.Token)
// Action: CalculateIsCheck($type.pType, source.Token)
rawIsCheck
    : ^(IS ID rawValue type) {CanCompileIsCheck($type.pType, $rawValue.start.Token)}?
      -> {CalculateIsCheck($type.pType, $rawValue.start.Token)}
    | ^(IS ID source=ID type) {CanCompileIsCheck($type.pType, $source.Token)}?
      -> {CalculateIsCheck($type.pType, $source.Token)}
    ;

// Optimization Pass #9: Clean up assignment statements
// Three alternatives:
//   1. ^(EQUALS ID l_value rawValueOrID) - Push constant to l-value target
//   2. ^(EQUALS ID l_valueVarCapture .) - Push expression value to captured var
//   3. ^(VAR type ID .) - Simplify local var with computed init
cleanEquals
    : ^(EQUALS ID l_value rawValueOrID)
      {CanPushValueToLValue($l_value.tree)}?
      -> {PushValueToLValue($l_value.tree, $rawValueOrID.start.Token)}
    | ^(EQUALS ID l_valueVarCapture source=.)
      {CanPushValueToExpression($source)}?
      -> {PushValueToExpression($source, $l_valueVarCapture.tree, $l_valueVarCapture.pTargetVar)}
    | ^(VAR type name=ID source=.)
      {CanPushValueToExpression($source)}?
      -> ^(VAR type $name {PushValueToExpression($source, null, $name.Token)})
    ;

// Optimization Pass #10: Validate array sizes
// Pattern: ^(NEWARRAY INTEGER ID) where INTEGER is the size
// Validates: 0 <= size <= 128
// Reports error if size out of range, rewrites size to 0
errorCheckArraySize
    : ^(NEWARRAY size=INTEGER ID) {CheckArraySize($size.Token)}?
      -> NEWARRAY INTEGER["0"] ID
    ;

// ============================================================================
// HELPER RULES
// ============================================================================

// Raw value: constants that can be optimized
// 5 alternatives: INTEGER(84), FLOAT(65), STRING(133), BOOL(25), NONE(107)
rawValue
    : INTEGER
    | FLOAT
    | STRING
    | BOOL
    | NONE
    ;

// Raw value or identifier
// 2 alternatives: rawValue (constants) or ID (variables)
rawValueOrID
    : rawValue
    | ID
    ;

// Type definition (for IS checks and casts)
// Returns pType: the ScriptVariableType for the parsed type
// 5 alternatives:
//   1. NONE -> ScriptVariableType("None")
//   2. ID -> ScriptVariableType(ID.text)
//   3. ID LBRACKET RBRACKET -> ScriptVariableType(ID.text + "[]")
//   4. BASETYPE -> ScriptVariableType(BASETYPE.text)
//   5. BASETYPE LBRACKET RBRACKET -> ScriptVariableType(BASETYPE.text + "[]")
type returns [ScriptVariableType pType]
    : NONE
      { $pType = new ScriptVariableType($NONE.text); }
    | ID
      { $pType = new ScriptVariableType($ID.text); }
    | ID LBRACKET RBRACKET
      { $pType = new ScriptVariableType($ID.text + "[]"); }
    | BASETYPE
      { $pType = new ScriptVariableType($BASETYPE.text); }
    | BASETYPE LBRACKET RBRACKET
      { $pType = new ScriptVariableType($BASETYPE.text + "[]"); }
    ;

// L-value for assignment targets
// 5 alternatives: ARRAYSET(17), STRUCTSET(136), PROPSET(119), DOT(42), ID(78)
l_value
    : ^(ARRAYSET .+)
    | ^(STRUCTSET .+)
    | ^(PROPSET .+)
    | ^(DOT . l_value)
    | ID
    ;

// L-value with variable capture (for cleanEquals optimization)
// Returns pTargetVar: the IToken of the variable being assigned to
// 5 alternatives matching l_value, but capturing the target variable:
//   1. ARRAYSET: captures first ID child (var) as pTargetVar
//   2. STRUCTSET: captures third child (param ID) as pTargetVar
//   3. PROPSET: captures third child (param ID) as pTargetVar
//   4. DOT: recursively captures from nested l_valueVarCapture
//   5. ID: captures itself as pTargetVar
l_valueVarCapture returns [IToken pTargetVar]
    : ^(ARRAYSET var=ID self=. arrayExpr=. indexExpr=.)
      { $pTargetVar = $var.Token; }
      -> ^(ARRAYSET $var $self $arrayExpr $indexExpr)
    | ^(STRUCTSET self=. structVar=. param=ID)
      { $pTargetVar = $param.Token; }
      -> ^(STRUCTSET $self $structVar $param)
    | ^(PROPSET self=. prop=. param=ID)
      { $pTargetVar = $param.Token; }
      -> ^(PROPSET $self $prop $param)
    | ^(DOT left=. l_valueVarCapture)
      { $pTargetVar = $l_valueVarCapture.pTargetVar; }
      -> ^(DOT $left l_valueVarCapture)
    | ID
      { $pTargetVar = $ID.Token; }
    ;

// ============================================================================
// SEMANTIC PREDICATES DOCUMENTATION
// ============================================================================

// IsKnownType(string): Checks if type exists in known types dictionary
//   Used in: eliminateExcessDots
//   Purpose: Only optimize dot chains for validated types

// CanRemoveAnd/CanRemoveOr(IToken, IToken, out string): Constant folding predicate
//   Used in: doubleValueBoolOps
//   Returns: true if both operands are constants
//   Output: "true" or "false" result string

// CanOptimizeAnd/CanOptimizeOr(IToken, out bool): Short-circuit predicate
//   Used in: singleValueBoolOps
//   Returns: true if first operand is constant
//   Output: whether to use second expression or short-circuit

// CanCompileCast(string, IToken): Cast validation predicate
//   Used in: rawCastOps
//   Returns: true if cast is valid and can be performed at compile-time
//   Checks: Type compatibility, variable existence
//
// CalculateRawCast(string, IToken): Performs compile-time cast
//   Used in: rawCastOps (rewrite)
//   Returns: ITree with converted constant value

// CanCompileIsCheck(ScriptVariableType, IToken): IS check validation
//   Used in: rawIsCheck
//   Returns: true if type check can be evaluated at compile-time
//   Checks: Inheritance relationships, type compatibility

// CheckArraySize(IToken): Array size validation
//   Used in: errorCheckArraySize
//   Returns: false if size invalid (reports error)
//   Validates: 0 <= size <= 128

// ============================================================================
// OPTIMIZATION ARCHITECTURE NOTES
// ============================================================================

// The optimizer uses a two-pass strategy:
//
// PASS 1 (topdown): Pre-order traversal
//   - enterFunction, enterState, enterProperty, enterBlock
//   - Initializes scope context for variable resolution
//   - Builds scope hierarchy for nested blocks
//
// PASS 2 (bottomup): Post-order traversal
//   - Processes children before parents (bottom-up)
//   - Enables multi-pass constant folding: (5 + (3 + 2)) -> (5 + 5) -> 10
//   - 4 cleanup passes: leaveFunction, leaveState, leaveProperty, leaveBlock
//   - 10 optimization passes: see individual rule documentation above
//
// Scope Management:
//   - ScopeManager tracks variable declarations and types
//   - Each function/block creates nested scope
//   - Variables resolved through scope hierarchy
//   - Dead variable elimination uses scope usage tracking
//
// Error Handling:
//   - Semantic predicates fail gracefully (no optimization)
//   - Division by zero detected in CalculateMathResult
//   - Numeric overflow caught and reported
//   - Array size validation at compile-time
//
// Tree Rewriting:
//   - Uses ANTLR3 tree rewriting with -> operators
//   - RewriteRuleStreams track nodes for reuse
//   - Preserves token metadata (line numbers, etc.)
//   - Replaces subtrees in-place via adaptor.ReplaceChildren
//
// SF1 vs FO4 Differences:
//   - validParenRemovalTarget: SF1 adds ARRAYGETALLMATCHINGSTRUCTS (case 25)
//     and has a second STRUCTGET alternative (case 28) for DFA disambiguation
//   - All other rules are identical between SF1 and FO4
//   - No concurrency-specific optimization (guards/locks are not optimized
//     because they are runtime synchronization primitives)
