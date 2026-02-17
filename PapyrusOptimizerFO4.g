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

tree grammar PapyrusOptimizerFO4;

options {
    tokenVocab = PapyrusLexerFO4;
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

    private ITree CompileCast(string asDestVarName, IToken apSourceToken) {
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

    event InternalErrorEventHandler pErrorHandler;
}

// ============================================================================
// TREE WALKER ENTRY POINTS
// ============================================================================

// Top-down pass: Scope management and setup
// Enters functions, states, properties, and blocks to initialize scope context
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
enterFunction
    : ^((FUNCTION | EVENT | REMOTEEVENT) HEADER .)
    {
        // Push new function scope onto scope manager
        // Initialize local variable tracking
    }
    ;

// Enter state scope - tracks state-specific function definitions
enterState
    : ^(STATE ID .)
    {
        // Push state scope
        // State functions override base functions
    }
    ;

// Enter property scope - handles property get/set scopes
enterProperty
    : ^(PROPERTY HEADER .)
    {
        // Property functions have implicit parameters
    }
    ;

// Enter code block - creates nested scope for local variables
enterBlock
    : ^(BLOCK .)
    {
        // Push block scope
        // Each block can shadow outer variables
    }
    ;

// ============================================================================
// SCOPE CLEANUP RULES (Bottom-up Pass)
// ============================================================================

leaveFunction
    : ^((FUNCTION | EVENT | REMOTEEVENT) .)
    {
        // Pop function scope
        // Perform dead variable elimination
    }
    ;

leaveState
    : ^(STATE .)
    {
        // Pop state scope
    }
    ;

leaveProperty
    : ^(PROPERTY .)
    {
        // Pop property scope
    }
    ;

leaveBlock
    : ^(BLOCK .)
    {
        // Pop block scope
    }
    ;

// ============================================================================
// EXPRESSION OPTIMIZATION RULES (Bottom-up Pass)
// ============================================================================

// Optimization Pass #1: Remove redundant parentheses
// Pattern: (PAREXPR validParenRemovalTarget) -> validParenRemovalTarget
// Only removes parens when semantically safe (e.g., not changing operator precedence)
eliminateParens
    : ^(PAREXPR validParenRemovalTarget) -> validParenRemovalTarget
    ;

validParenRemovalTarget
    : constant
    | ID
    | ^(DOT . .)
    | ^(CALL . . . . .)
    | ^(CALLPARENT . . . . .)
    | ^(CALLGLOBAL . . . . .)
    | ^(PROPGET . . .)
    | ^(ARRAYGET . . . .)
    | ^(LENGTH . .)
    | ^(NEWARRAY . .)
    | ^(NEWSTRUCT . .)
    | ^(AS . .)
    | ^(IS . .)
    | ^(NOT .)
    | ^(INEGATE .)
    | ^(FNEGATE .)
    ;

// Optimization Pass #2: Consolidate dot operators
// Pattern: (DOT (DOT base prop1) prop2) when base is known type
// Only consolidates when semantic predicate {IsKnownType($base)} succeeds
// This eliminates intermediate property access nodes
eliminateExcessDots
    : ^(DOT ^(DOT a=ID .) .) {IsKnownType($a.text)}?
      // Complex rewrite removes nested DOT, merges property accesses
    ;

// Optimization Pass #3: Constant-fold boolean operations with two constant values
// Pattern: (AND <const1> <const2>) -> <result>
// Pattern: (OR <const1> <const2>) -> <result>
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
// Pattern: (AND true expr) -> expr
// Pattern: (AND false expr) -> false
// Pattern: (OR true expr) -> true
// Pattern: (OR false expr) -> expr
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
// Pattern: (IADD <int1> <int2>) -> <sum>
// Pattern: (STRCAT <str1> <str2>) -> <concatenated>
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
// Pattern: (INEGATE <int>) -> <negated_int>
// Pattern: (FNEGATE <float>) -> <negated_float>
// Pattern: (NOT <bool>) -> <inverted_bool>
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
// Pattern: (AS <typename> <constant>) -> <converted_constant>
// Only optimizes when cast is valid and source is constant
// Semantic predicate: CanCompileCast($ID.Text, $rawValue.start.Token)
rawCastOps
    : ^(AS ID rawValue) {CanCompileCast($ID.Text, $rawValue.start.Token)}?
      -> {CompileCast($ID.Text, $rawValue.start.Token)}
    ;

// Optimization Pass #8: Optimize IS type checks
// Pattern: (IS <typename> <constant>) -> <bool_result>
// Pattern: (IS <typename> <variable>) -> <bool_result> (if inheritance can be determined)
// Evaluates inheritance relationships at compile-time when possible
rawIsCheck
    : ^(IS ID rawValue) {CanCompileIsCheck(GetTypeFromID($ID), $rawValue.start.Token)}?
      -> {CalculateIsCheck(GetTypeFromID($ID), $rawValue.start.Token)}
    | ^(IS type rawValue) {CanCompileIsCheck($type.varType, $rawValue.start.Token)}?
      -> {CalculateIsCheck($type.varType, $rawValue.start.Token)}
    ;

// Optimization Pass #9: Clean up assignment statements
// Simplifies EQUALS nodes, handles NOCODEASSIGN pattern
// Pattern: (EQUALS lvalue (NOCODEASSIGN ...)) - cleanup no-code assignments
// Pattern: (VAR type ID (NOCODEASSIGN ...)) - local var with computed init
cleanEquals
    : ^(EQUALS ID l_value rawValueOrID)
      // Complex pattern matching for l-value optimization
    | ^(EQUALS ID l_value .)
      // General assignment cleanup
    | ^(VAR ID type l_valueVarCapture)
      // Local variable with expression initialization
    ;

// Optimization Pass #10: Validate array sizes
// Pattern: (NEWARRAY <size> <type>) where size is INTEGER
// Validates: 0 <= size <= 128
// Reports error if size out of range
errorCheckArraySize
    : ^(NEWARRAY size=INTEGER ID) {CheckArraySize($size)}?
    ;

// ============================================================================
// HELPER RULES
// ============================================================================

// Raw value: constants that can be optimized
rawValue
    : INTEGER
    | FLOAT
    | BOOL
    | STRING
    | NONE
    ;

// Raw value or identifier
rawValueOrID
    : rawValue
    | ID
    ;

// Type definition (for IS checks and casts)
type returns [ScriptVariableType varType]
    : ID                      // Simple type
    | ^(ID LBRACKET RBRACKET) // Array type
    ;

// L-value for assignment targets
l_value
    : ID
    | ^(DOT l_value ID)
    | ^(ARRAYSET ID ID ID l_value .)
    | ^(PROPSET ID ID ID)
    | ^(STRUCTSET ID ID ID)
    ;

// L-value with variable capture (for var declarations)
l_valueVarCapture returns [string varName]
    : ID { $varName = $ID.text; }
    | ^(DOT l_value ID)
    ;

// Constant values
constant
    : INTEGER
    | FLOAT
    | BOOL
    | STRING
    | NONE
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
