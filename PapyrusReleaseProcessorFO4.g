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
    tokenVocab = PapyrusLexerFO4;
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
    /// <param name="apObjType">The script being compiled.</param>
    /// <param name="apKnownTypes">All types visible from this script.</param>
    /// <param name="aRelease">True when compiling in release mode (strips DebugOnly calls).</param>
    /// <param name="aFinal">True when compiling in final mode (strips BetaOnly calls).</param>
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

    /// <summary>
    /// Returns true if the current function (or its enclosing script) is DebugOnly.
    /// Used to suppress removal when the call site is itself debug-only.
    /// </summary>
    private bool IsInDebugOnlyScope()
    {
        ScriptFunctionType currentFunction = pScopeManager.CurrentFunction;
        return (currentFunction != null && currentFunction.bDebugOnly) || pObjType.DebugOnly;
    }

    /// <summary>
    /// Returns true if the current function (or its enclosing script) is BetaOnly.
    /// Used to suppress removal when the call site is itself beta-only.
    /// </summary>
    private bool IsInBetaOnlyScope()
    {
        ScriptFunctionType currentFunction = pScopeManager.CurrentFunction;
        return (currentFunction != null && currentFunction.bBetaOnly) || pObjType.BetaOnly;
    }

    // -------------------------------------------------------------------------
    // Function lookup helpers (used by ShouldRemoveFunctionCall)
    // -------------------------------------------------------------------------

    /// <summary>
    /// Looks up the function identified by (aSelf, aFuncName, aIsGlobal) in the
    /// known-types dictionary and invokes aDelegate to test whether the call
    /// should be removed. Walks up the inheritance chain if the function is
    /// not found on the immediate type.
    /// </summary>
    private bool GetFuncAndTest(
        string aSelf,
        string aFuncName,
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
            ScriptVariableType arpType;
            if (pObjType.TryGetVariable(lowerSelf, out arpType) ||
                pScopeManager.CurrentScope.TryGetVariable(lowerSelf, out arpType))
            {
                key = arpType.VarType;
            }
        }

        bool result = false;
        if (pKnownTypes.ContainsKey(key))
        {
            ScriptObjectType apObjType = pKnownTypes[key] as ScriptObjectType;
            ScriptFunctionType arpFuncType = null;
            while (apObjType != null && arpFuncType == null)
            {
                if (!apObjType.TryGetFunction(aFuncName, out arpFuncType) || arpFuncType == null)
                    apObjType = apObjType.pParentObj;
            }
            result = aDelegate(apObjType, arpFuncType);
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
    /// Returns true if the function call at this site should be removed.
    ///
    /// Release mode: removes DebugOnly calls unless the calling scope is itself DebugOnly.
    /// Final mode:   removes BetaOnly calls unless the calling scope is itself BetaOnly.
    ///
    /// Both conditions may be true simultaneously.
    /// </summary>
    private bool ShouldRemoveFunctionCall(string aSelf, string aFuncName, bool aIsGlobal)
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
//
// ANTLR3 TreeRewriter invokes topdown() when entering each node and bottomup()
// when leaving each node. Scope bookkeeping happens in topdown; actual tree
// rewrites happen in bottomup.
//
// Because filter=true and backtrack=true, each alternative is tried speculatively
// and silently skipped if it does not match or a semantic predicate fails.

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
// Called when the walker first enters a FUNCTION, EVENT, or REMOTEEVENT node.
// Extracts the function name from the HEADER child subtree and pushes the
// function onto the scope stack.
//
// Tree structure matched:
//   ^( (FUNCTION | EVENT | REMOTEEVENT)
//      ^(HEADER type funcName=ID .*)   ; HEADER subtree: return type + name + params
//      .? )                             ; optional flags child after HEADER
// -----------------------------------------------------------------------------
enterFunction
    : ^( (FUNCTION | EVENT | REMOTEEVENT)
         ^(HEADER type funcName=ID .*)
         .? )
    { pScopeManager.EnterFunction($funcName.text); }
    ;

// -----------------------------------------------------------------------------
// enterState
//
// Called when the walker first enters a STATE node.
// Extracts the state name and pushes the state onto the scope stack.
//
// Tree structure matched:
//   ^(STATE stateName=ID .*)
// -----------------------------------------------------------------------------
enterState
    : ^(STATE stateName=ID .*)
    { pScopeManager.EnterState($stateName.text); }
    ;

// -----------------------------------------------------------------------------
// enterProperty
//
// Called when the walker first enters a PROPERTY node.
// Extracts the property name from the HEADER child subtree and pushes the
// property onto the scope stack.
//
// Tree structure matched:
//   ^( PROPERTY
//      ^(HEADER type propName=ID .*)   ; HEADER subtree: type + name + flags
//      .* )                             ; remaining children (get/set functions)
// -----------------------------------------------------------------------------
enterProperty
    : ^(PROPERTY
         ^(HEADER type propName=ID .*)
         .*)
    { pScopeManager.EnterProperty($propName.text); }
    ;

// -----------------------------------------------------------------------------
// enterBlock
//
// Called when the walker first enters a BLOCK node (if/else/while/for body).
// Pushes a new variable scope block.
//
// Matches: BLOCK (leaf node only — the root token, not a subtree)
// -----------------------------------------------------------------------------
enterBlock
    : BLOCK
    { pScopeManager.EnterBlock(); }
    ;

// =============================================================================
// Scope-leave rules (bottomup)
// =============================================================================

// -----------------------------------------------------------------------------
// leaveFunction
//
// Called when the walker exits a FUNCTION, EVENT, or REMOTEEVENT node.
// Pops the function scope.
//
// Note: Each alternative matches only the root token (leaf match), because
// bottomup rules see the root after all children have been processed.
// -----------------------------------------------------------------------------
leaveFunction
    : FUNCTION    { pScopeManager.LeaveFunction(); }
    | EVENT       { pScopeManager.LeaveFunction(); }
    | REMOTEEVENT { pScopeManager.LeaveFunction(); }
    ;

// -----------------------------------------------------------------------------
// leaveState
//
// Called when the walker exits a STATE node. Pops the state scope.
// -----------------------------------------------------------------------------
leaveState
    : STATE
    { pScopeManager.LeaveState(); }
    ;

// -----------------------------------------------------------------------------
// leaveProperty
//
// Called when the walker exits a PROPERTY node. Pops the property scope.
// -----------------------------------------------------------------------------
leaveProperty
    : PROPERTY
    { pScopeManager.LeaveProperty(); }
    ;

// -----------------------------------------------------------------------------
// leaveBlock
//
// Called when the walker exits a BLOCK node. Pops the block scope.
// -----------------------------------------------------------------------------
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
// Core rewrite rule: replaces a debug-only or beta-only function call with
// just its return variable identifier, effectively making it a no-op.
//
// The return variable (retvar) is preserved so that any assignment expression
// that captures the return value still has a valid right-hand side. The retvar
// identifier itself will be cleaned up by PapyrusVarCleaner in the next pass.
//
// Semantic predicate: ShouldRemoveFunctionCall(selfOrObjType, funcName, isGlobal)
//   - Returns true only when all of the following hold:
//       1. release=true (or final=true for BetaOnly calls)
//       2. The called function is flagged DebugOnly (or BetaOnly)
//       3. The calling scope is NOT itself DebugOnly (or BetaOnly)
//
// Tree structures matched and rewritten:
//
//   Instance call:
//     ^(CALL self=ID name=ID retvar=ID callparams=.)
//       {ShouldRemoveFunctionCall($self, $name, false)}?
//     -> ID[$retvar.token, $retvar.text]
//
//   Parent call:
//     ^(CALLPARENT self=ID name=ID retvar=ID callparams=.)
//       {ShouldRemoveFunctionCall($self, $name, false)}?
//     -> ID[$retvar.token, $retvar.text]
//
//   Global call:
//     ^(CALLGLOBAL objType=ID name=ID retvar=ID callparams=.)
//       {ShouldRemoveFunctionCall($objType, $name, true)}?
//     -> ID[$retvar.token, $retvar.text]
//
// CALL/CALLPARENT/CALLGLOBAL node child layout (4 children):
//   child 0: self or objType (ID) — receiver variable or type name
//   child 1: name (ID)            — function name
//   child 2: retvar (ID)          — return variable name (or "_none" / temp var)
//   child 3: callparams (any)     — CALLPARAMS subtree
// -----------------------------------------------------------------------------
functionCall
    // Instance method call (CALL): receiver is a variable
    : ^(CALL self=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($self.text, $name.text, false)}?
      -> ID[$retvar.token, $retvar.text]

    // Parent method call (CALLPARENT): receiver is the parent class
    | ^(CALLPARENT self=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($self.text, $name.text, false)}?
      -> ID[$retvar.token, $retvar.text]

    // Global (static) call (CALLGLOBAL): receiver is a type name
    | ^(CALLGLOBAL objType=ID name=ID retvar=ID .)
        {ShouldRemoveFunctionCall($objType.text, $name.text, true)}?
      -> ID[$retvar.token, $retvar.text]
    ;

// =============================================================================
// Helper rules
// =============================================================================

// -----------------------------------------------------------------------------
// type
//
// Matches a Papyrus type reference: a base type token optionally followed by
// array brackets [].
//
// Examples:
//   Int         -> matches '.'
//   String[]    -> matches '. LBRACKET RBRACKET'
//   Actor       -> matches '.'
//   Actor[]     -> matches '. LBRACKET RBRACKET'
//
// Note: This rule is used inside function/property/variable header subtrees
// to consume the type portion before reaching the name identifier.
// -----------------------------------------------------------------------------
type
    : . (LBRACKET RBRACKET)?
    ;
