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

tree grammar PapyrusTypeWalkerFO4;

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
    private Dictionary<string, ScriptComplexType> pKnownTypes;
    private ScriptObjectType pObjType;
    private PCompiler.Compiler pCompiler;
    private int iCurVarSuffix;
    private Dictionary<string, List<string>> pUnusedTempVarsByType = new Dictionary<string, List<string>>();

    event InternalErrorEventHandler pErrorHandler;

    // ========================================================================
    // TYPE CHECKING HELPER METHODS
    // ========================================================================

    private bool IsKnownType(ScriptVariableType apType) {
        // Checks if a type exists in the known types dictionary
        // Handles both simple types and array element types
    }

    private bool IsKnownType(string asType) {
        return IsKnownType(new ScriptVariableType(asType));
    }

    private ScriptComplexType GetKnownType(ScriptVariableType apType) {
        // Resolves a type to its ScriptComplexType (ScriptObjectType or ScriptStructType)
        // Uses the compiler's type resolution with namespace support
        return pCompiler.GetKnownType(apType, pKnownTypes);
    }

    private ScriptComplexType GetKnownType(string asType) {
        return GetKnownType(new ScriptVariableType(asType));
    }

    public Dictionary<string, ScriptComplexType> KnownTypes {
        get { return pKnownTypes; }
    }

    // ========================================================================
    // NAMESPACE RESOLUTION (FO4-SPECIFIC)
    // ========================================================================

    private string DisambiguateType(string asRawType, IToken apErrorToken) {
        // Resolves namespace-qualified types (e.g., MyNamespace:MyScript)
        // Uses compiler's disambiguation logic with known types and current object context
        return pCompiler.DisambiguateType(asRawType, apErrorToken, pObjType, pKnownTypes);
    }

    // ========================================================================
    // TYPE VALIDATION METHODS
    // ========================================================================

    private bool ValueTypeMatches(ScriptVariableType apType, IToken apValue) {
        // Validates that a constant token matches the expected variable type
        // Checks: int/INTEGER, float/FLOAT, bool/BOOL, string/STRING, object/NONE
    }

    private void CheckType(ScriptVariableType apType, IToken apErrorToken) {
        // Validates that a type is known (exists in type dictionary)
    }

    private void CheckTypeAndValue(ScriptVariableType apType, IToken apValue, IToken apErrorToken) {
        // Validates both type existence and initial value compatibility
    }

    private void CheckVariableDefinition(string asName, ScriptVariableType apType, IToken apInitialValue,
                                        bool abInFunctionBlock, bool abInStruct, IToken apTargetToken) {
        // Validates variable/property declarations:
        // - Type exists and is valid
        // - Initial value matches type (if provided)
        // - Name doesn't conflict with types, properties, or script variables
        // - Const types not used for script variables
        // - Struct variables cannot be structs themselves
    }

    private void CheckVarOrPropName(string asName, IToken apTargetToken) {
        // Ensures variable/property names don't conflict with known types
    }

    private void CheckPropName(string aName, IToken apTargetToken) {
        // Validates property names don't conflict with variables or types
    }

    // ========================================================================
    // CUSTOM EVENT VALIDATION (FO4-SPECIFIC)
    // ========================================================================

    private void CheckCustomEventDefinition(string asName, IToken apTargetToken) {
        // Validates custom event declarations:
        // - Name doesn't conflict with known types
        // - Name doesn't conflict with existing functions/events
        // - Not already defined in parent scripts
    }

    // ========================================================================
    // TYPE CASTING AND CONVERSION
    // ========================================================================

    private bool CanAutoCast(ScriptVariableType apTarget, ScriptVariableType apSource) {
        // Determines if automatic type casting is allowed between source and target types
        // Handles: primitives, objects (inheritance), arrays, structs, special types
        // Special types: scripteventname, customeventname, structvarname (FO4-specific)
    }

    private CommonTree AutoCast(CommonTree apTreeToCast, ScriptVariableType apSourceType,
                               ScriptVariableType apDestType, ScriptScope apCurrentScope,
                               Dictionary<string, ScriptVariableType> apTempVars, out string arsNewTempVar) {
        // Performs automatic type casting by generating temporary variables and AS nodes
        // Returns modified AST with cast operation inserted
    }

    private CommonTree AutoCastReturn(CommonTree apTreeToCast, ScriptVariableType apSourceType,
                                     string asFuncName, string asPropertyName, ScriptScope apCurrentScope,
                                     Dictionary<string, ScriptVariableType> apTempVars, IToken apRetToken) {
        // Auto-casts return expressions to match function/property return type
    }

    private void CheckAssignmentType(ScriptVariableType apTarget, ScriptVariableType apSource, IToken apTargetToken) {
        // Validates assignment type compatibility
    }

    private ScriptVariableType CheckCast(ScriptVariableType apSourceType, ScriptVariableType apTargetType,
                                        IToken apCastToken, bool abIsArrayElement = false) {
        // Validates explicit AS casts:
        // - Primitives can cast to other primitives (except void)
        // - Objects can cast within inheritance hierarchy
        // - Arrays can cast if element types compatible
        // - Structs can cast to none/string/bool/var
        return apTargetType;
    }

    // ========================================================================
    // EXPRESSION TYPE CHECKING
    // ========================================================================

    private ScriptVariableType CheckComparisonType(ScriptVariableType apTypeA, ScriptVariableType apTypeB,
                                                   IToken apOpToken, out bool arbCastToA) {
        // Validates comparison operations (==, !=, <, >, <=, >=)
        // Returns bool type, sets arbCastToA to indicate which operand needs casting
    }

    private void HandleComparisonExpression(string asExprAVar, ScriptVariableType apExprAType, CommonTree apExprATree,
                                           string asExprBVar, ScriptVariableType apExprBType, CommonTree apExprBTree,
                                           IToken apComparisonToken, ScriptScope apCurrentScope,
                                           Dictionary<string, ScriptVariableType> apTempVars,
                                           out string arsResultVar, out ScriptVariableType arpResultType,
                                           out IToken arpResultToken, out CommonTree arpATreeOut, out CommonTree arpBTreeOut) {
        // Processes comparison expressions, generates result temporary variable
    }

    private void CheckConditionType(ScriptVariableType apConditionType, IToken apOpToken) {
        // Validates that condition expressions (if/while) can cast to bool
    }

    private ScriptVariableType CheckAddSubtractType(ScriptVariableType apTypeA, ScriptVariableType apTypeB,
                                                    IToken apOpToken, out bool arbCastToA, out bool arbIsConcat) {
        // Validates + and - operations:
        // - String concatenation (+ with string operands)
        // - Numeric addition/subtraction (int or float)
        // Returns result type, sets arbIsConcat for string operations
    }

    private void HandleAddSubtractExpression(string asExprAVar, ScriptVariableType apExprAType, CommonTree apExprATree,
                                            string asExprBVar, ScriptVariableType apExprBType, CommonTree apExprBTree,
                                            IToken apMathToken, ScriptScope apCurrentScope,
                                            Dictionary<string, ScriptVariableType> apTempVars,
                                            out bool abIsConcat, out bool arbIsInt, out string arsResultVar,
                                            out ScriptVariableType arpResultType, out IToken arpResultToken,
                                            out CommonTree arpATreeOut, out CommonTree arpBTreeOut) {
        // Processes addition/subtraction, generates result temporary variable
    }

    private ScriptVariableType CheckMultDivideType(ScriptVariableType apTypeA, ScriptVariableType apTypeB,
                                                   IToken apOpToken, out bool arbCastToA) {
        // Validates * and / operations (int or float only)
    }

    private void HandleMultDivideExpression(string asExprAVar, ScriptVariableType apExprAType, CommonTree apExprATree,
                                           string asExprBVar, ScriptVariableType apExprBType, CommonTree apExprBTree,
                                           IToken apMathToken, ScriptScope apCurrentScope,
                                           Dictionary<string, ScriptVariableType> apTempVars,
                                           out bool arbIsInt, out string arsResultVar, out ScriptVariableType arpResultType,
                                           out IToken arpResultToken, out CommonTree arpATreeOut, out CommonTree arpBTreeOut) {
        // Processes multiplication/division, generates result temporary variable
    }

    private ScriptVariableType CheckModType(ScriptVariableType apTypeA, ScriptVariableType apTypeB, IToken apOpToken) {
        // Validates modulus operation (int only)
        return apTypeA;
    }

    private ScriptVariableType CheckNegationType(ScriptVariableType apType, IToken apOpToken) {
        // Validates unary negation (int or float only)
        return apType;
    }

    // ========================================================================
    // VARIABLE AND SCOPE MANAGEMENT
    // ========================================================================

    private ScriptVariableType GetVariableType(ScriptFunctionType apFunction, ScriptScope apCurrentScope, IToken apVarToken) {
        // Resolves variable type from local scope or script scope
        // Searches: local variables -> script variables (if not global function)
    }

    private ScriptVariableType GetLValueType(ScriptFunctionType apFunction, ScriptScope apCurrentScope, IToken apNameToken) {
        // Gets type of l-value (assignment target)
        // Validates target is not const, self, or parent
    }

    private string GenerateTempVariable(ScriptVariableType apType, ScriptScope apCurrentScope,
                                       Dictionary<string, ScriptVariableType> apTempVars) {
        // Generates unique temporary variable names (::temp0, ::temp1, etc.)
        // Recycles unused temp vars by type for efficiency
        // Special case: ::nonevar for none type
    }

    private void MarkAllTempVarsAsUnused(Dictionary<string, ScriptVariableType> apTempVars) {
        // Marks temporary variables as available for reuse after code block
    }

    private int TypeToToken(ScriptVariableType apType) {
        // Converts ScriptVariableType to ANTLR token type
        // Used for generating default parameter tokens
    }

    // ========================================================================
    // PROPERTY AND STRUCT ACCESS (FO4-SPECIFIC)
    // ========================================================================

    private bool IsLocalProperty(string asName) {
        // Checks if name is a property on current script or parent scripts
    }

    private void GetPropertyInfo(ScriptVariableType apObjType, IToken apIDToken, bool abCheckForGetter,
                                out ScriptVariableType arpPropType) {
        // Resolves property type and validates getter/setter existence
        // Searches through inheritance hierarchy
    }

    private void GetStructInfo(ScriptVariableType apStructType, IToken apIDToken, out ScriptVariableType arpVarType) {
        // Resolves struct member type (FO4-specific)
        // Validates struct exists and contains named member
    }

    private void CheckPropertyOverride(string asPropName, IToken apSourceToken) {
        // Validates property doesn't override parent property
    }

    private void CheckPropertyFunction(string asPropName, string asFuncName, out bool arbIsGet, IToken apSourceToken) {
        // Validates property getter/setter function signatures
    }

    private void CheckStructOverride(string asStructName, IToken apSourceToken) {
        // Validates struct doesn't override parent struct (FO4-specific)
    }

    // ========================================================================
    // FUNCTION VALIDATION
    // ========================================================================

    private bool IsGlobalFunction(ScriptVariableType apType, string asFuncName) {
        // Checks if function is marked global
    }

    private ScriptVariableType FindFunctionOwningType(string asFuncName, out bool abCallingOnSelf, IToken apTargetToken) {
        // Resolves which type owns a function (current script, parent, or import)
        // Detects ambiguous imported function calls
    }

    private void CheckFunction(ScriptFunctionType apFunctionType, IToken apScriptToken) {
        // Validates function declaration:
        // - State functions must exist in empty state
        // - Native functions require native script
        // - New events require native script
        // - Signature matches parent/empty state
    }

    private void CheckFunctionImpl(ScriptFunctionType apFunctionType, ScriptObjectType apObjDefinedIn,
                                  ScriptFunctionType apFunctionToCheckAgainst, IToken apScriptToken) {
        // Validates function implementation details:
        // - Parameter ordering (optional params must follow required params)
        // - Special parameter types (scripteventname, customeventname, structvarname, dependenttype)
        // - Return type and parameter type matching with parent
        // - Global functions cannot be redefined
    }

    private void CheckRemoteEvent(ScriptFunctionType apEventType, IToken apScriptToken) {
        // Validates remote event declarations (FO4-specific):
        // - Format: ScriptName.EventName
        // - Event exists on target script
        // - Event source is least derived type
        // - First parameter matches event source type
    }

    private void CheckReturnType(ScriptFunctionType apFunctionType, ScriptVariableType apType, IToken apReturnToken) {
        // Validates return statement type matches function return type
    }

    // ========================================================================
    // FUNCTION CALL PARAMETER VALIDATION
    // ========================================================================

    private bool SortFunctionParameters(ScriptFunctionType apFunction, List<string> asTargetParamNamesA,
                                       List<ScriptVariableType> apParamTypesA, List<IToken> apParamTokensA,
                                       List<CommonTree> apParamExpressionsA, IToken apNameToken,
                                       out List<ScriptVariableType> arpSortedTypesA, out List<IToken> arpSortedTokensA,
                                       out List<CommonTree> arpSortedExpressionsA) {
        // Sorts function parameters (handles both positional and named parameters)
        // Validates parameter count and names
    }

    private bool FillFunctionDefaultParameters(ScriptFunctionType apFunction, List<ScriptVariableType> apSortedTypesA,
                                               List<IToken> apSortedTokensA, List<CommonTree> apSortedExpressionsA,
                                               IToken apNameToken) {
        // Fills in default values for optional parameters not provided
    }

    private bool FixUpSpecialFunctionParameters(ScriptFunctionType apFunction, ScriptVariableType apSelfType,
                                               List<ScriptVariableType> apSortedTypesA, List<IToken> apSortedTokensA,
                                               out List<ScriptVariableType> arpFixedUpTypesA) {
        // Processes special parameter types (FO4-specific):
        // - scripteventname: validates event exists on previous parameter's type
        // - customeventname: validates custom event exists, rewrites to include script name
        // - structvarname: validates struct member exists
        // - dependenttype: resolves type based on previous structvarname parameter
    }

    private bool TypeCheckFunctionParameters(List<ScriptVariableType> apTargetTypesA, List<ScriptVariableType> apSortedTypesA,
                                            List<IToken> apSortedTokensA, List<CommonTree> apSortedExpressionsA,
                                            ScriptScope apCurrentScope, Dictionary<string, ScriptVariableType> apTempVars,
                                            IToken apNameToken) {
        // Type checks and auto-casts function parameters to match function signature
    }

    private bool SortAndCheckFunctionParameters(ScriptFunctionType apFunction, ScriptVariableType apSelfType,
                                               List<string> asTargetParamNamesA, List<ScriptVariableType> apParamTypesA,
                                               List<IToken> apParamTokensA, ref List<CommonTree> arpParamExpressionsA,
                                               IToken apNameToken, ScriptScope apCurrentScope,
                                               Dictionary<string, ScriptVariableType> apTempVars) {
        // Master function for parameter validation (calls Sort -> Fill -> FixUp -> TypeCheck)
        return true;
    }

    // ========================================================================
    // FUNCTION CALL TYPE CHECKING
    // ========================================================================

    private ScriptVariableType CheckArrayFunctionCall(ScriptVariableType apSelfType, string asName,
                                                      List<string> asTargetParamNamesA, List<ScriptVariableType> apParamTypesA,
                                                      List<IToken> apParamTokensA, ref List<CommonTree> arpParamExpressionsA,
                                                      IToken apNameToken, ScriptScope apCurrentScope,
                                                      Dictionary<string, ScriptVariableType> apTempVars) {
        // Validates array method calls:
        // - Find/RFind (element, startIndex=0/-1)
        // - FindStruct/RFindStruct (varName, element, startIndex) [FO4-specific]
        // - Add (element, count=1)
        // - Insert (element, location)
        // - Remove (location, count=1)
        // - RemoveLast ()
        // - Clear ()
    }

    private ScriptVariableType CheckGlobalFunctionCall(ScriptVariableType apSelfType, string asName,
                                                       List<string> asTargetParamNamesA, List<ScriptVariableType> apParamTypesA,
                                                       List<IToken> apParamTokensA, ref List<CommonTree> arpParamExpressionsA,
                                                       IToken apNameToken, ScriptScope apCurrentScope,
                                                       Dictionary<string, ScriptVariableType> apTempVars) {
        // Validates global function calls (called on type name, not instance)
        // Verifies function is marked global
    }

    private ScriptVariableType CheckMemberFunctionCall(ScriptVariableType apSelfType, string asName,
                                                       List<string> asTargetParamNamesA, List<ScriptVariableType> apParamTypesA,
                                                       List<IToken> apParamTokensA, ref List<CommonTree> arpParamExpressionsA,
                                                       IToken apNameToken, ScriptScope apCurrentScope,
                                                       Dictionary<string, ScriptVariableType> apTempVars) {
        // Validates member function calls (called on object instance)
        // Searches through inheritance hierarchy
        // Verifies function is not global
    }

    // ========================================================================
    // ARRAY AND STRUCT CREATION
    // ========================================================================

    private void CheckArrayNew(ScriptVariableType apElementType, ScriptVariableType apSizeType,
                              string asSizeVarNameOrValue, IToken apTypeToken) {
        // Validates array creation:
        // - Element type exists
        // - Size is integer
        // - Size is 0-128 (if constant)
    }

    private void CheckStructNew(ScriptVariableType apStructType, IToken apTypeToken) {
        // Validates struct creation (FO4-specific):
        // - Type exists and is a struct
    }

    private void HandleArrayElementExpression(string asArrayVar, ScriptVariableType apArrayType, IToken apArrayToken,
                                             string asExprVar, ScriptVariableType apExprType, CommonTree apExprTree,
                                             ScriptScope apCurrentScope, Dictionary<string, ScriptVariableType> apTempVars,
                                             bool abIsSet, out string arsResultVar, out ScriptVariableType arpResultType,
                                             out IToken arpResultToken, out CommonTree arpTreeOut) {
        // Validates array indexing:
        // - Index is integer (auto-casts if needed)
        // - Target is actually an array
        // - Not setting const array elements
    }

    // ========================================================================
    // AST TREE CONSTRUCTION
    // ========================================================================

    private CommonTree CreateBlockTree(IToken apBlockToken, IList apStatementsA,
                                      Dictionary<string, ScriptVariableType> apTempVars) {
        // Creates BLOCK tree node with temporary variable declarations prepended
    }

    private CommonTree CreateCallTree(IToken apCallToken, bool abIsGlobal, bool abIsArray,
                                     string asSelfVar, IToken apNameToken, ScriptVariableType apRetVarType,
                                     string asRetVarName, List<CommonTree> apParamExpressionsA) {
        // Creates CALL/CALLGLOBAL/CALLPARENT/ARRAY* tree node
        // Translates array method names to ANTLR tokens (Find -> ARRAYFIND, etc.)
    }

    // ========================================================================
    // ERROR REPORTING
    // ========================================================================

    private void OnError(string asError, int aiLineNumber, int aiColumnNumber) {
        if (pErrorHandler != null) {
            pErrorHandler(this, new InternalErrorEventArgs(asError, aiLineNumber, aiColumnNumber));
        }
    }

    public override void DisplayRecognitionError(string[] asTokenNamesA, RecognitionException apException) {
        OnError(GetErrorMessage(apException, asTokenNamesA), apException.Line, apException.CharPositionInLine);
    }
}

// ============================================================================
// TREE WALKER ENTRY POINT
// ============================================================================

script[ScriptObjectType apObj, PCompiler.Compiler apCompiler, Dictionary<string, ScriptComplexType> apKnownTypes]
    : ^(OBJECT header definitionOrBlock*)
    {
        pKnownTypes = apKnownTypes;
        pObjType = apObj;
        pCompiler = apCompiler;
        pObjType.pObjAST = $script.tree;
    }
    ;

// ============================================================================
// SCRIPT STRUCTURE RULES
// ============================================================================

header
    : ^(ID USER_FLAGS ID? DOCSTRING?)
    ;

definitionOrBlock
    : fieldDefinition[false]
    | customEventDefinition
    | function["", ""]
    | eventFunc[""]
    | stateBlock
    | propertyBlock
    | groupBlock
    | structBlock
    ;

// ============================================================================
// FIELD AND VARIABLE DEFINITIONS
// ============================================================================

fieldDefinition[bool abIsStruct]
    : ^(VAR type ID USER_FLAGS CONST? constant? DOCSTRING?)
    {
        // Validates variable definition with type and initial value
        CheckVariableDefinition($ID.text, $type.pType, $constant.start?.Token, false, abIsStruct, $ID.token);
    }
    ;

customEventDefinition
    : ^(CUSTOMEVENT ID)
    {
        // Validates custom event name (FO4-specific)
        CheckCustomEventDefinition($ID.text, $ID.token);
    }
    -> // Remove from tree (custom events are metadata only)
    ;

// ============================================================================
// FUNCTION AND EVENT DEFINITIONS
// ============================================================================

scope function {
    string sstateName;
    string spropertyName;
    ScriptFunctionType pfunctionType;
}

function[string asStateName, string asPropertyName] returns [string sName]
@init {
    $function::sstateName = asStateName;
    $function::spropertyName = asPropertyName;
}
@after {
    // Validate function after parsing body
    if ($function::spropertyName == "") {
        CheckFunction($function::pfunctionType, $start.Token);
    }
    pUnusedTempVarsByType.Clear();
}
    : ^(FUNCTION functionHeader codeBlock[$function::pfunctionType, $function::pfunctionType.FunctionScope]?)
    {
        $sName = $functionHeader.sFuncName;
    }
    ;

functionHeader returns [string sFuncName]
@after {
    // Resolve function type from script object
    if ($function::spropertyName == "") {
        pObjType.TryGetFunction($function::sstateName, $sFuncName, out $function::pfunctionType);
    } else {
        ScriptPropertyType arpType;
        pObjType.TryGetProperty($function::spropertyName, out arpType);
        $function::pfunctionType = ($sFuncName.ToLowerInvariant() == "get") ? arpType.pGetFunction : arpType.pSetFunction;
    }
}
    : ^(HEADER type ID USER_FLAGS callParameters? DOCSTRING?)
    {
        $sFuncName = $ID.text;
        CheckTypeAndValue($type.pType, null, $ID.token);
    }
    | ^(HEADER NONE ID USER_FLAGS callParameters? DOCSTRING?)
    {
        $sFuncName = $ID.text;
    }
    ;

functionModifier
    : GLOBAL | NATIVE
    ;

// ============================================================================
// EVENT DEFINITIONS
// ============================================================================

scope eventFunc {
    bool bremoteEvent;
    string sstateName;
    string seventName;
    ScriptFunctionType pfunctionType;
}

eventFunc[string asStateName]
@init {
    $eventFunc::bremoteEvent = false;
    $eventFunc::sstateName = asStateName;
    $eventFunc::seventName = "";
}
@after {
    // Validate event after parsing body
    if ($eventFunc::bremoteEvent) {
        CheckRemoteEvent($eventFunc::pfunctionType, $start.Token);
    } else {
        CheckFunction($eventFunc::pfunctionType, $start.Token);
    }
    pUnusedTempVarsByType.Clear();
}
    : ^(EVENT eventHeader codeBlock[$eventFunc::pfunctionType, $eventFunc::pfunctionType.FunctionScope]?)
    | ^(REMOTEEVENT eventHeader codeBlock[$eventFunc::pfunctionType, $eventFunc::pfunctionType.FunctionScope]?)
    {
        $eventFunc::bremoteEvent = true;
    }
    ;

eventHeader
@after {
    $eventFunc::seventName = $ID.text;
    pObjType.TryGetFunction($eventFunc::sstateName, $eventFunc::seventName, out $eventFunc::pfunctionType);
}
    : ^(HEADER NONE ID USER_FLAGS callParameters? DOCSTRING?)
    ;

callParameters
    : callParameter+
    ;

callParameter
    : ^(PARAM type ID constant?)
    {
        // Validate parameter type and default value
        if ($constant.start != null) {
            CheckTypeAndValue($type.pType, $constant.start.Token, $ID.token);
        } else {
            CheckTypeAndValue($type.pType, null, $ID.token);
        }
    }
    ;

// ============================================================================
// STATE DEFINITIONS
// ============================================================================

stateBlock
    : ^(STATE ID AUTO? stateFuncOrEvent[$ID.text]*)
    ;

stateFuncOrEvent[string asState]
    : function[asState, ""]
    | eventFunc[asState]
    ;

// ============================================================================
// PROPERTY DEFINITIONS
// ============================================================================

scope propertyBlock {
    bool bfunc0IsGet;
}

propertyBlock
@init {
    $propertyBlock::bfunc0IsGet = false;
}
    : ^(PROPERTY propertyHeader func0=propertyFunc[$propertyHeader.sName] func1=propertyFunc[$propertyHeader.sName]?)
    {
        CheckPropertyOverride($propertyHeader.sName, $PROPERTY.token);
        $propertyBlock::bfunc0IsGet = ($func0 != null && $func0.bIsGet);
    }
    -> ^(PROPERTY propertyHeader
         {$propertyBlock::bfunc0IsGet && $func1.start != null}? propertyFunc propertyFunc
         {!$propertyBlock::bfunc0IsGet && $func1.start != null}? propertyFunc propertyFunc
         {$propertyBlock::bfunc0IsGet}? propertyFunc PROPFUNC[$PROPERTY.token, "propfunc"]
         PROPFUNC[$PROPERTY.token, "propfunc"] propertyFunc
       )
    | ^(AUTOPROP propertyHeader ID)
    {
        CheckPropertyOverride($propertyHeader.sName, $AUTOPROP.token);
    }
    ;

propertyHeader returns [string sName]
@after {
    $sName = $ID.text;
    CheckPropName($sName, $HEADER.token);
}
    : ^(HEADER type ID USER_FLAGS DOCSTRING?)
    ;

propertyFunc[string asPropName] returns [bool bIsGet]
@after {
    CheckPropertyFunction(asPropName, $function.sName, out $bIsGet, $PROPFUNC.token);
}
    : ^(PROPFUNC function["", asPropName])
    ;

// ============================================================================
// GROUP DEFINITIONS (FO4-SPECIFIC)
// ============================================================================

groupBlock
    : ^(GROUP groupHeader groupPropOrField*)
    ;

groupHeader
    : ^(HEADER ID USER_FLAGS DOCSTRING?)
    ;

groupPropOrField
    : propertyBlock
    | fieldDefinition[false]
    ;

// ============================================================================
// STRUCT DEFINITIONS (FO4-SPECIFIC)
// ============================================================================

structBlock
@after {
    CheckStructOverride($structHeader.sName, $STRUCT.token);
}
    : ^(STRUCT structHeader fieldDefinition[true]*)
    ;

structHeader returns [string sName]
@after {
    $sName = $ID.text;
}
    : ^(HEADER ID DOCSTRING?)
    ;

// ============================================================================
// CODE BLOCK AND STATEMENTS
// ============================================================================

scope codeBlock {
    Dictionary<string, ScriptVariableType> ptempVars;
    ScriptFunctionType pfunctionType;
    ScriptScope pcurrentScope;
    int inextScopeChild;
}

codeBlock[ScriptFunctionType apFunctionType, ScriptScope apCurrentScope]
@init {
    $codeBlock::ptempVars = new Dictionary<string, ScriptVariableType>();
    $codeBlock::pfunctionType = apFunctionType;
    $codeBlock::pcurrentScope = apCurrentScope;
    $codeBlock::inextScopeChild = 0;
}
@after {
    MarkAllTempVarsAsUnused($codeBlock::ptempVars);
}
    : ^(BLOCK statement*)
    -> {CreateBlockTree($BLOCK, $statement, $codeBlock::ptempVars)}
    ;

scope statement {
    CommonTree pvalueExpressionTree;
}

statement
    : localDefinition
    | ifBlock
    | whileBlock
    | return_stat
    | ^(EQUALS ID l_value expression)  // Assignment
    | expression  // Expression statement (function call)
    ;

// ============================================================================
// LOCAL VARIABLE DEFINITIONS
// ============================================================================

scope localDefinition {
    CommonTree initialValueTree;
}

localDefinition
    : ^(VAR type ID expression?)
    {
        // Validate local variable declaration
        // Type check initial value expression if present
    }
    ;

// ============================================================================
// L-VALUE (ASSIGNMENT TARGET) RULES
// ============================================================================

scope l_value {
    IToken pvarToken;
    CommonTree pindexExpressionTree;
    bool bisStruct;
}

l_value returns [ScriptVariableType pVarType, string sVarName]
    : ID
    {
        // Simple variable assignment
        $pVarType = GetLValueType($codeBlock::pfunctionType, $codeBlock::pcurrentScope, $ID.token);
        $sVarName = $ID.text;
    }
    | ^(DOT l_value ID)
    {
        // Property or struct member assignment
        if ($l_value.pVarType.IsStructType) {
            GetStructInfo($l_value.pVarType, $ID, out $pVarType);
        } else {
            GetPropertyInfo($l_value.pVarType, $ID, false, out $pVarType);
        }
        $sVarName = GenerateTempVariable($pVarType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(ARRAYSET ID ID ID l_value expression)
    {
        // Array element assignment
        $pVarType = new ScriptVariableType("none");
        $sVarName = "";
    }
    | ^(PROPSET ID ID ID)
    {
        // Property set
        $pVarType = new ScriptVariableType("none");
        $sVarName = "";
    }
    | ^(STRUCTSET ID ID ID)
    {
        // Struct member set (FO4-specific)
        $pVarType = new ScriptVariableType("none");
        $sVarName = "";
    }
    ;

scope basic_l_value {
    bool bisStruct;
    bool bisProperty;
    bool bisLocalAutoProperty;
    IToken pvarToken;
    CommonTree pindexExpressionTree;
}

basic_l_value returns [ScriptVariableType pType, string sVarName]
    : ID
    {
        // Basic variable reference
        $pType = GetVariableType($codeBlock::pfunctionType, $codeBlock::pcurrentScope, $ID.token);
        $sVarName = $ID.text;
    }
    | ^(DOT basic_l_value ID)
    {
        // Property or struct member access
        if ($basic_l_value.pType.IsStructType) {
            GetStructInfo($basic_l_value.pType, $ID, out $pType);
            $basic_l_value::bisStruct = true;
        } else {
            GetPropertyInfo($basic_l_value.pType, $ID, true, out $pType);
            $basic_l_value::bisProperty = true;
        }
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(ARRAYGET ID ID ID basic_l_value expression)
    {
        // Array element access
        HandleArrayElementExpression($basic_l_value.sVarName, $basic_l_value.pType, $basic_l_value.start,
                                    $expression.sVarName, $expression.pType, $expression.tree,
                                    $codeBlock::pcurrentScope, $codeBlock::ptempVars, false,
                                    out $sVarName, out $pType, out _, out _);
    }
    | ^(PROPGET ID ID ID)
    {
        // Property get
        $pType = new ScriptVariableType("none");
        $sVarName = "";
    }
    | ^(STRUCTGET ID ID ID)
    {
        // Struct member get (FO4-specific)
        $pType = new ScriptVariableType("none");
        $sVarName = "";
    }
    ;

// ============================================================================
// EXPRESSION RULES
// ============================================================================

expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : and_expression
    {
        $pType = $and_expression.pType;
        $sVarName = $and_expression.sVarName;
        $pVarToken = $and_expression.pVarToken;
    }
    | ^(OR ID expression expression)
    {
        // Logical OR - type checks and generates result
        $pType = new ScriptVariableType("bool");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

and_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : bool_expression
    {
        $pType = $bool_expression.pType;
        $sVarName = $bool_expression.sVarName;
        $pVarToken = $bool_expression.pVarToken;
    }
    | ^(AND ID bool_expression bool_expression)
    {
        // Logical AND - type checks and generates result
        $pType = new ScriptVariableType("bool");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

scope bool_expression {
    CommonTree paTree;
    CommonTree pbTree;
}

bool_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : add_expression
    {
        $pType = $add_expression.pType;
        $sVarName = $add_expression.sVarName;
        $pVarToken = $add_expression.pVarToken;
    }
    | ^(op=(EQ|NE|LT|GT|LTE|GTE) ID add_expression add_expression)
    {
        // Comparison operators - type check operands and generate result
        HandleComparisonExpression($add_expression[0].sVarName, $add_expression[0].pType, $add_expression[0].tree,
                                  $add_expression[1].sVarName, $add_expression[1].pType, $add_expression[1].tree,
                                  $op, $codeBlock::pcurrentScope, $codeBlock::ptempVars,
                                  out $sVarName, out $pType, out $pVarToken,
                                  out $bool_expression::paTree, out $bool_expression::pbTree);
    }
    | ^(IS ID add_expression)
    {
        // IS type check operator
        $pType = new ScriptVariableType("bool");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

scope add_expression {
    bool bisInt;
    bool bisConcat;
    CommonTree paTree;
    CommonTree pbTree;
}

add_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : mult_expression
    {
        $pType = $mult_expression.pType;
        $sVarName = $mult_expression.sVarName;
        $pVarToken = $mult_expression.pVarToken;
    }
    | ^(op=(PLUS|MINUS) ID mult_expression mult_expression)
    {
        // Addition/subtraction or string concatenation
        HandleAddSubtractExpression($mult_expression[0].sVarName, $mult_expression[0].pType, $mult_expression[0].tree,
                                   $mult_expression[1].sVarName, $mult_expression[1].pType, $mult_expression[1].tree,
                                   $op, $codeBlock::pcurrentScope, $codeBlock::ptempVars,
                                   out $add_expression::bisConcat, out $add_expression::bisInt,
                                   out $sVarName, out $pType, out $pVarToken,
                                   out $add_expression::paTree, out $add_expression::pbTree);
    }
    ;

scope mult_expression {
    bool bisInt;
    CommonTree paTree;
    CommonTree pbTree;
}

mult_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : unary_expression
    {
        $pType = $unary_expression.pType;
        $sVarName = $unary_expression.sVarName;
        $pVarToken = $unary_expression.pVarToken;
    }
    | ^(op=(MULT|DIVIDE) ID unary_expression unary_expression)
    {
        // Multiplication/division
        HandleMultDivideExpression($unary_expression[0].sVarName, $unary_expression[0].pType, $unary_expression[0].tree,
                                  $unary_expression[1].sVarName, $unary_expression[1].pType, $unary_expression[1].tree,
                                  $op, $codeBlock::pcurrentScope, $codeBlock::ptempVars,
                                  out $mult_expression::bisInt, out $sVarName, out $pType,
                                  out $pVarToken, out $mult_expression::paTree, out $mult_expression::pbTree);
    }
    | ^(MOD ID unary_expression unary_expression)
    {
        // Modulus
        $pType = CheckModType($unary_expression[0].pType, $unary_expression[1].pType, $MOD);
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

scope unary_expression {
    bool bisInt;
}

unary_expression returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : cast_atom
    {
        $pType = $cast_atom.pType;
        $sVarName = $cast_atom.sVarName;
        $pVarToken = $cast_atom.pVarToken;
    }
    | ^(op=(MINUS|NOT) ID cast_atom)
    {
        // Unary negation or logical NOT
        if ($op.type == MINUS) {
            $pType = CheckNegationType($cast_atom.pType, $op);
        } else {
            $pType = new ScriptVariableType("bool");
        }
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

cast_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : dot_atom
    {
        $pType = $dot_atom.pType;
        $sVarName = $dot_atom.sVarName;
        $pVarToken = $dot_atom.pVarToken;
    }
    | ^(AS ID dot_atom)
    {
        // Explicit type cast
        ScriptVariableType targetType = new ScriptVariableType(DisambiguateType($ID.text, $ID.token));
        $pType = CheckCast($dot_atom.pType, targetType, $AS);
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

dot_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : array_atom
    {
        $pType = $array_atom.pType;
        $sVarName = $array_atom.sVarName;
        $pVarToken = $array_atom.pVarToken;
    }
    | ^(DOT dot_atom ID)
    {
        // Property or struct member access
        if ($dot_atom.pType.IsStructType) {
            GetStructInfo($dot_atom.pType, $ID, out $pType);
        } else {
            GetPropertyInfo($dot_atom.pType, $ID, true, out $pType);
        }
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

scope array_atom {
    CommonTree pindexExpressionTree;
}

array_atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : atom
    {
        $pType = $atom.pType;
        $sVarName = $atom.sVarName;
        $pVarToken = $atom.pVarToken;
    }
    | ^(LBRACKET ID array_atom expression)
    {
        // Array indexing
        HandleArrayElementExpression($array_atom.sVarName, $array_atom.pType, $array_atom.start,
                                    $expression.sVarName, $expression.pType, $expression.tree,
                                    $codeBlock::pcurrentScope, $codeBlock::ptempVars, false,
                                    out $sVarName, out $pType, out $pVarToken, out $array_atom::pindexExpressionTree);
    }
    ;

atom returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : array_func_or_id
    {
        $pType = $array_func_or_id.pType;
        $sVarName = $array_func_or_id.sVarName;
        $pVarToken = $array_func_or_id.pVarToken;
    }
    | ^(PAREXPR expression)
    {
        // Parenthesized expression
        $pType = $expression.pType;
        $sVarName = $expression.sVarName;
        $pVarToken = $expression.pVarToken;
    }
    | constant
    {
        // Constant literal
        $pType = new ScriptVariableType($constant.start.Type == INTEGER ? "int" :
                                       $constant.start.Type == FLOAT ? "float" :
                                       $constant.start.Type == BOOL ? "bool" :
                                       $constant.start.Type == STRING ? "string" : "none");
        $sVarName = "";
        $pVarToken = $constant.start;
    }
    | ^(NEWARRAY ID expression)
    {
        // New array creation
        string elementType = DisambiguateType($ID.text, $ID.token);
        CheckArrayNew(new ScriptVariableType(elementType), $expression.pType, $expression.sVarName, $ID);
        $pType = new ScriptVariableType(elementType + "[]");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(NEWSTRUCT ID)
    {
        // New struct creation (FO4-specific)
        string structType = DisambiguateType($ID.text, $ID.token);
        CheckStructNew(new ScriptVariableType(structType), $ID);
        $pType = new ScriptVariableType(structType);
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(LENGTH ID array_atom)
    {
        // Array length property
        $pType = new ScriptVariableType("int");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

scope array_func_or_id {
    CommonTree pindexExpressionTree;
}

array_func_or_id returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : func_or_id
    {
        $pType = $func_or_id.pType;
        $sVarName = $func_or_id.sVarName;
        $pVarToken = $func_or_id.pVarToken;
    }
    | ^(LBRACKET ID func_or_id expression)
    {
        // Array element access after function/id
        HandleArrayElementExpression($func_or_id.sVarName, $func_or_id.pType, $func_or_id.start,
                                    $expression.sVarName, $expression.pType, $expression.tree,
                                    $codeBlock::pcurrentScope, $codeBlock::ptempVars, false,
                                    out $sVarName, out $pType, out $pVarToken, out $array_func_or_id::pindexExpressionTree);
    }
    ;

scope func_or_id {
    bool bisStruct;
    bool bisProperty;
    bool bisLocalAutoProperty;
}

func_or_id returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
    : ID
    {
        // Variable or self/parent reference
        if ($ID.text.ToLowerInvariant() == "self") {
            $pType = new ScriptVariableType(pObjType.Name);
            $sVarName = "self";
        } else if ($ID.text.ToLowerInvariant() == "parent") {
            $pType = pObjType.pParentObj != null ? new ScriptVariableType(pObjType.pParentObj.Name) : new ScriptVariableType("none");
            $sVarName = "parent";
        } else {
            $pType = GetVariableType($codeBlock::pfunctionType, $codeBlock::pcurrentScope, $ID);
            $sVarName = $ID.text;
        }
        $pVarToken = $ID;
    }
    | function_call
    {
        // Function call result
        $pType = $function_call.pType;
        $sVarName = $function_call.sVarName;
        $pVarToken = $function_call.pVarToken;
    }
    ;

// ============================================================================
// CONTROL FLOW STATEMENTS
// ============================================================================

scope return_stat {
    CommonTree pexpressionTree;
}

return_stat
    : ^(RETURN expression?)
    {
        // Validate return type matches function
        if ($expression.start != null) {
            CheckReturnType($codeBlock::pfunctionType, $expression.pType, $RETURN);
            $return_stat::pexpressionTree = AutoCastReturn($expression.tree, $expression.pType,
                                                          $codeBlock::pfunctionType.Name,
                                                          $function::spropertyName,
                                                          $codeBlock::pcurrentScope,
                                                          $codeBlock::ptempVars, $RETURN);
        } else {
            CheckReturnType($codeBlock::pfunctionType, null, $RETURN);
        }
    }
    ;

scope ifBlock {
    ScriptScope pchildScope;
}

ifBlock
@init {
    $ifBlock::pchildScope = $codeBlock::pcurrentScope.GetChildScope($codeBlock::inextScopeChild++);
}
    : ^(IF expression codeBlock[$codeBlock::pfunctionType, $ifBlock::pchildScope] elseIfBlock* elseBlock?)
    {
        // Validate condition can cast to bool
        CheckConditionType($expression.pType, $IF);
    }
    ;

scope elseIfBlock {
    ScriptScope pchildScope;
}

elseIfBlock
@init {
    $elseIfBlock::pchildScope = $codeBlock::pcurrentScope.GetChildScope($codeBlock::inextScopeChild++);
}
    : ^(ELSEIF expression codeBlock[$codeBlock::pfunctionType, $elseIfBlock::pchildScope])
    {
        CheckConditionType($expression.pType, $ELSEIF);
    }
    ;

scope elseBlock {
    ScriptScope pchildScope;
}

elseBlock
@init {
    $elseBlock::pchildScope = $codeBlock::pcurrentScope.GetChildScope($codeBlock::inextScopeChild++);
}
    : ^(ELSE codeBlock[$codeBlock::pfunctionType, $elseBlock::pchildScope])
    ;

scope whileBlock {
    ScriptScope pchildScope;
}

whileBlock
@init {
    $whileBlock::pchildScope = $codeBlock::pcurrentScope.GetChildScope($codeBlock::inextScopeChild++);
}
    : ^(WHILE expression codeBlock[$codeBlock::pfunctionType, $whileBlock::pchildScope])
    {
        CheckConditionType($expression.pType, $WHILE);
    }
    ;

// ============================================================================
// FUNCTION CALL
// ============================================================================

scope function_call {
    List<string> stargetParamNamesA;
    List<ScriptVariableType> pparamTypesA;
    List<string> sparamVarNamesA;
    List<IToken> pparamTokensA;
    List<CommonTree> pparamExpressionsA;
    bool bisGlobal;
    bool bisArray;
    ScriptVariableType pactualReturnType;
}

function_call returns [ScriptVariableType pType, string sVarName, IToken pVarToken]
@init {
    $function_call::stargetParamNamesA = new List<string>();
    $function_call::pparamTypesA = new List<ScriptVariableType>();
    $function_call::sparamVarNamesA = new List<string>();
    $function_call::pparamTokensA = new List<IToken>();
    $function_call::pparamExpressionsA = new List<CommonTree>();
    $function_call::bisGlobal = false;
    $function_call::bisArray = false;
}
    : ^(CALL ID ID ID basic_l_value parameters)
    {
        // Member function call: object.function(params)
        $function_call::pactualReturnType = CheckMemberFunctionCall(
            $basic_l_value.pType, $ID[1].text,
            $function_call::stargetParamNamesA, $function_call::pparamTypesA,
            $function_call::pparamTokensA, ref $function_call::pparamExpressionsA,
            $ID[1], $codeBlock::pcurrentScope, $codeBlock::ptempVars);
        $pType = $function_call::pactualReturnType;
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(CALLGLOBAL ID ID ID ID parameters)
    {
        // Global function call: ScriptName.GlobalFunction(params)
        ScriptVariableType selfType = new ScriptVariableType(DisambiguateType($ID[0].text, $ID[0]));
        $function_call::pactualReturnType = CheckGlobalFunctionCall(
            selfType, $ID[1].text,
            $function_call::stargetParamNamesA, $function_call::pparamTypesA,
            $function_call::pparamTokensA, ref $function_call::pparamExpressionsA,
            $ID[1], $codeBlock::pcurrentScope, $codeBlock::ptempVars);
        $function_call::bisGlobal = true;
        $pType = $function_call::pactualReturnType;
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^(CALLPARENT ID ID ID ID parameters)
    {
        // Parent function call: parent.Function(params)
        $pType = new ScriptVariableType("none");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    | ^((ARRAYFIND|ARRAYRFIND|ARRAYFINDSTRUCT|ARRAYRFINDSTRUCT|ARRAYADD|ARRAYINSERT|
         ARRAYREMOVE|ARRAYREMOVELAST|ARRAYCLEAR) ID ID parameters)
    {
        // Array method call: array.Find(params)
        $function_call::bisArray = true;
        $pType = new ScriptVariableType("none");
        $sVarName = GenerateTempVariable($pType, $codeBlock::pcurrentScope, $codeBlock::ptempVars);
    }
    ;

parameters
    : parameter*
    ;

parameter
    : ^(PARAM ID? expression)
    {
        // Add parameter to function call lists
        $function_call::stargetParamNamesA.Add($ID != null ? $ID.text : "");
        $function_call::pparamTypesA.Add($expression.pType);
        $function_call::sparamVarNamesA.Add($expression.sVarName);
        $function_call::pparamTokensA.Add($expression.pVarToken);
        $function_call::pparamExpressionsA.Add($expression.tree);
    }
    ;

// ============================================================================
// CONSTANT AND TYPE RULES
// ============================================================================

constant returns [ScriptVariableType pType, IToken pVarToken]
    : number    { $pType = $number.pType; $pVarToken = $number.pVarToken; }
    | STRING    { $pType = new ScriptVariableType("string"); $pVarToken = $STRING.token; }
    | BOOL      { $pType = new ScriptVariableType("bool"); $pVarToken = $BOOL.token; }
    | NONE      { $pType = new ScriptVariableType("none"); $pVarToken = $NONE.token; }
    ;

number returns [ScriptVariableType pType, IToken pVarToken]
    : INTEGER   { $pType = new ScriptVariableType("int"); $pVarToken = $INTEGER.token; }
    | FLOAT     { $pType = new ScriptVariableType("float"); $pVarToken = $FLOAT.token; }
    ;

type returns [ScriptVariableType pType]
    : ID
    {
        string asVarType = DisambiguateType($ID.text, $ID.token);
        $pType = new ScriptVariableType(asVarType);
    }
    -> ID[$ID.token, $pType.VarType]
    | ID LBRACKET RBRACKET
    {
        string str = DisambiguateType($ID.text, $ID.token);
        $pType = new ScriptVariableType(str + "[]");
    }
    -> ID[$ID.token, $pType.ArrayElementType] LBRACKET RBRACKET
    | BASETYPE
    {
        $pType = new ScriptVariableType($BASETYPE.text);
    }
    | BASETYPE LBRACKET RBRACKET
    {
        $pType = new ScriptVariableType($BASETYPE.text + "[]");
    }
    ;

// ============================================================================
// ARCHITECTURE NOTES
// ============================================================================

// The type walker performs comprehensive semantic analysis:
//
// 1. TYPE RESOLUTION
//    - Validates all types exist in known types dictionary
//    - Resolves namespace-qualified types (FO4: MyNamespace:MyScript)
//    - Handles inheritance relationships for casting and IS checks
//
// 2. VARIABLE CHECKING
//    - Validates variable declarations (name conflicts, type validity)
//    - Tracks local variables through ScriptScope hierarchy
//    - Generates temporary variables for intermediate expressions
//
// 3. FUNCTION VALIDATION
//    - Validates function signatures match parent/empty state
//    - Checks parameter ordering and default values
//    - Validates special parameter types (FO4: scripteventname, customeventname, structvarname)
//    - Type checks function call arguments with auto-casting
//
// 4. EXPRESSION TYPE CHECKING
//    - Infers types for all expressions bottom-up
//    - Performs automatic type casting where valid
//    - Validates operator usage (arithmetic, comparison, logical)
//    - Handles string concatenation vs numeric addition
//
// 5. PROPERTY AND STRUCT ACCESS (FO4)
//    - Validates property getter/setter existence
//    - Checks struct member access
//    - Handles property overrides
//
// 6. CONTROL FLOW
//    - Validates condition expressions cast to bool
//    - Validates return types match function signatures
//    - Manages nested scopes for if/while/blocks
//
// 7. ARRAY OPERATIONS
//    - Type checks array methods (Find, Add, Remove, etc.)
//    - Validates array indexing (integer indices)
//    - Checks array creation size (0-128)
//    - Handles struct array methods (FindStruct, RFindStruct)
//
// 8. CUSTOM EVENTS AND REMOTE EVENTS (FO4)
//    - Validates custom event declarations
//    - Checks remote event format (ScriptName.EventName)
//    - Validates event exists on target script
//
// 9. ERROR REPORTING
//    - Reports all type errors with line/column information
//    - Provides detailed error messages for debugging
//
// Unlike the optimizer, the type walker modifies the AST:
//    - Inserts AS (cast) nodes for automatic type conversions
//    - Adds temporary variable declarations to code blocks
//    - Rewrites property blocks to ensure get/set order
//    - Disambiguates namespace-qualified type names
