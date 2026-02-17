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

tree grammar PapyrusReleaseProcessorFO4;

options {
    tokenVocab = PapyrusLexerSF1;
    ASTLabelType = CommonTree;
    language = CSharp3;
    output = AST;
    rewrite = true;
    backtrack = true;
    filter = true;
}

@header {
using Antlr.Runtime;
using Antlr.Runtime.Tree;
using System.Collections.Generic;
}

@members {
    // -------------------------------------------------------------------------
    // Runtime state (set before each pass via SetUp)
    // -------------------------------------------------------------------------

    private ScriptObjectType pObjType;
    private Dictionary<string, ScriptComplexType> pKnownTypes;
    private ScopeManager pScopeManager = new ScopeManager();
    private bool release;
    private bool final;

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    /// <summary>
    /// Configures the processor before walking the AST.
    /// Called by Compiler.cs once per script, before invoking the TreeRewriter.
    /// </summary>
    public void SetUp(
        ScriptObjectType apObjType,
        Dictionary<string, ScriptComplexType> apKnownTypes,
        bool aRelease,
        bool aFinal)
    {
        pObjType = apObjType;
        pKnownTypes = apKnownTypes;
        pScopeManager.Reset(apObjType);
        release = aRelease;
        final = aFinal;
    }

    // -------------------------------------------------------------------------
    // Scope query helpers
    // -------------------------------------------------------------------------

    private bool IsInDebugOnlyScope()
    {
        ScriptFunctionType currentFunction = pScopeManager.CurrentFunction;
        return (currentFunction != null && currentFunction.bDebugOnly) || pObjType.DebugOnly;
    }

    private bool IsInBetaOnlyScope()
    {
        ScriptFunctionType currentFunction = pScopeManager.CurrentFunction;
        return (currentFunction != null && currentFunction.bBetaOnly) || pObjType.BetaOnly;
    }

    // -------------------------------------------------------------------------
    // Function lookup helpers
    // -------------------------------------------------------------------------

    /// <summary>
    /// SF1 change: aFuncName is now ScriptFunctionName (a typed wrapper) instead of string.
    /// The typed wrapper allows case-insensitive comparison and namespace-aware lookup
    /// consistent with the rest of the SF1 type system.
    /// </summary>
    private bool GetFuncAndTest(
        string aSelf,
        ScriptFunctionName aFuncName,
        bool aIsGlobal,
        FunctionPassesDelegate aDelegate)
    {
        string key = "";
        if (aIsGlobal)
        {
            key = aSelf.ToLowerInvariant();
        }
        else
        {
            string lowerSelf = aSelf.ToLowerInvariant();
            ScriptVariableType arType;
            if (pObjType.TryGetVariable(lowerSelf, out arType) ||
                pScopeManager.CurrentScope.TryGetVariable(lowerSelf, out arType))
            {
                key = arType.VarType;
            }
        }

        bool result = false;
        if (pKnownTypes.ContainsKey(key))
        {
            ScriptObjectType apObjType = pKnownTypes[key] as ScriptObjectType;
            ScriptFunctionType arFuncType = null;
            while (apObjType != null && arFuncType == null)
            {
                if (!apObjType.TryGetFunction(aFuncName, out arFuncType) || arFuncType == null)
                    apObjType = apObjType.pParentObj;
            }
            result = aDelegate(apObjType, arFuncType);
        }
        return result;
    }

    private static bool IsDebugFunction(ScriptObjectType apObjType, ScriptFunctionType apFuncType)
    {
        bool flag = false;
        if (apObjType != null) flag = apObjType.DebugOnly;
        if (!flag && apFuncType != null) flag = apFuncType.bDebugOnly;
        return flag;
    }

    private static bool IsBetaFunction(ScriptObjectType apObjType, ScriptFunctionType apFuncType)
    {
        bool flag = false;
        if (apObjType != null) flag = apObjType.BetaOnly;
        if (!flag && apFuncType != null) flag = apFuncType.bBetaOnly;
        return flag;
    }

    // -------------------------------------------------------------------------
    // Main predicate: should this call site be stripped?
    // -------------------------------------------------------------------------

    /// <summary>
    /// SF1 change: aFuncName is ScriptFunctionName. The call sites wrap the raw ID
    /// token text: new ScriptFunctionName($name.text)
    /// </summary>
    private bool ShouldRemoveFunctionCall(string aSelf, ScriptFunctionName aFuncName, bool aIsGlobal)
    {
        bool remove = false;
        if (release)
            remove = !IsInDebugOnlyScope() &&
                     GetFuncAndTest(aSelf, aFuncName, aIsGlobal,
                                    new FunctionPassesDelegate(IsDebugFunction));
        if (final && !remove)
            remove = !IsInBetaOnlyScope() &&
                     GetFuncAndTest(aSelf, aFuncName, aIsGlobal,
                                    new FunctionPassesDelegate(IsBetaFunction));
        return remove;
    }

    private delegate bool FunctionPassesDelegate(ScriptObjectType apObjType, ScriptFunctionType apFuncType);
}

// =============================================================================
// TreeRewriter entry points (filter = true)
// =============================================================================

topdown
    : enterFunction
    | enterState
    | enterProperty
    | enterBlock
    ;

bottomup
    : leaveFunction
    | leaveState
    | leaveProperty
    | leaveBlock
    | functionCall
    ;

// =============================================================================
// Scope-enter rules (topdown)
// =============================================================================

// -----------------------------------------------------------------------------
// enterFunction
//
// SF1 change: EnterFunction() takes ScriptFunctionName instead of a raw string.
//
// Tree structure matched (unchanged from FO4):
//   ^( (FUNCTION | EVENT | REMOTEEVENT)
//      ^(HEADER type funcName=ID .*)
//      .? )
// -----------------------------------------------------------------------------
enterFunction
    : ^( (FUNCTION | EVENT | REMOTEEVENT)
         ^(HEADER type funcName=ID .*)
         .? )
    { pScopeManager.EnterFunction(new ScriptFunctionName($funcName.text)); }
    ;

// -----------------------------------------------------------------------------
// enterState
//
// SF1 change: EnterState() takes ScriptObjectStateName instead of a raw string.
//
// Tree structure matched (unchanged from FO4):
//   ^(STATE stateName=ID .*)
// -----------------------------------------------------------------------------
enterState
    : ^(STATE stateName=ID .*)
    { pScopeManager.EnterState(new ScriptObjectStateName($stateName.text)); }
    ;

// -----------------------------------------------------------------------------
// enterProperty
//
// Tree structure matched (unchanged from FO4):
//   ^(PROPERTY ^(HEADER type propName=ID .*) .*)
// -----------------------------------------------------------------------------
enterProperty
    : ^(PROPERTY
         ^(HEADER type propName=ID .*)
         .*)
    { pScopeManager.EnterProperty($propName.text); }
    ;

// -----------------------------------------------------------------------------
// enterBlock
// -----------------------------------------------------------------------------
enterBlock
    : BLOCK
    { pScopeManager.EnterBlock(); }
    ;

// =============================================================================
// Scope-leave rules (bottomup)
// =============================================================================

leaveFunction
    : FUNCTION    { pScopeManager.LeaveFunction(); }
    | EVENT       { pScopeManager.LeaveFunction(); }
    | REMOTEEVENT { pScopeManager.LeaveFunction(); }
    ;

leaveState
    : STATE
    { pScopeManager.LeaveState(); }
    ;

leaveProperty
    : PROPERTY
    { pScopeManager.LeaveProperty(); }
    ;

leaveBlock
    : BLOCK
    { pScopeManager.LeaveBlock(); }
    ;

// =============================================================================
// Tree rewrite rules (bottomup)
// =============================================================================

// -----------------------------------------------------------------------------
// functionCall
//
// SF1 change: ShouldRemoveFunctionCall() now takes ScriptFunctionName for the
// function name argument. Each predicate wraps $name.text in a ScriptFunctionName
// constructor call at the call site.
//
// All three tree patterns and the rewrite (-> $retvar) are otherwise unchanged
// from FO4. See PapyrusReleaseProcessorFO4.g for detailed documentation.
//
// CALL/CALLPARENT/CALLGLOBAL node child layout (4 children, unchanged from FO4):
//   child 0: self or objType (ID)
//   child 1: name (ID)
//   child 2: retvar (ID)
//   child 3: callparams (any)
// -----------------------------------------------------------------------------
functionCall
    // Instance method call
    : ^(CALL self=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($self.text, new ScriptFunctionName($name.text), false)}?
      -> ID[$retvar.token, $retvar.text]

    // Parent method call
    | ^(CALLPARENT self=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($self.text, new ScriptFunctionName($name.text), false)}?
      -> ID[$retvar.token, $retvar.text]

    // Global (static) call
    | ^(CALLGLOBAL objType=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($objType.text, new ScriptFunctionName($name.text), true)}?
      -> ID[$retvar.token, $retvar.text]
    ;

// =============================================================================
// Helper rules
// =============================================================================

// -----------------------------------------------------------------------------
// type
//
// Matches a Papyrus type reference: a base type token optionally followed by [].
// Unchanged from FO4 — only token numbers differ (LBRACKET=89, RBRACKET=123).
// -----------------------------------------------------------------------------
type
    : . (LBRACKET RBRACKET)?
    ;
