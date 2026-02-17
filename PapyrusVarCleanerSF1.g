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

tree grammar PapyrusVarCleanerSF1;

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
using Antlr.Runtime.Misc;
using Antlr.Runtime.Tree;
}

@members {
    // -------------------------------------------------------------------------
    // Runtime state (set before each pass via SetUp)
    // -------------------------------------------------------------------------

    private CleanupPass ePassType;
    private ScriptObjectType pObjType;
    private ScopeManager pScopeManager = new ScopeManager();

    /// <summary>
    /// True while the walker is inside a VAR definition's own header subtree.
    /// Suppresses flagging the variable's own name as "used" during SCAN.
    /// </summary>
    private bool bInVarDefinition;

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    /// <summary>
    /// Configures the cleaner before walking the AST.
    /// Must be called before each pass (SCAN and CLEANUP separately).
    /// </summary>
    /// <param name="apObjType">The script being compiled.</param>
    /// <param name="aePassType">SCAN to collect usage info; CLEANUP to remove unused vars.</param>
    public void SetUp(ScriptObjectType apObjType, CleanupPass aePassType)
    {
        ePassType = aePassType;
        pObjType = apObjType;
        bInVarDefinition = false;
        pScopeManager.Reset(pObjType);
    }

    // -------------------------------------------------------------------------
    // Usage tracking helpers
    // -------------------------------------------------------------------------

    /// <summary>
    /// Returns true if the given variable name was seen in at least one
    /// non-definition usage during the SCAN pass.
    ///
    /// During the CLEANUP pass, if the scope has no usage data for this name
    /// (i.e., it was never defined in scope), returns true (keep it).
    /// </summary>
    public bool IsVarUsed(string asVarName)
    {
        bool arUsed = true;
        if (ePassType == CleanupPass.CLEANUP && pScopeManager.CurrentScope != null)
            pScopeManager.CurrentScope.TryGetVarUsed(asVarName, out arUsed);
        return arUsed;
    }

    /// <summary>
    /// Records that the given identifier was referenced (not as a definition).
    /// Called during SCAN pass only, and only when NOT inside a VAR definition.
    /// </summary>
    public void HandleIDUse(string asID)
    {
        if (bInVarDefinition || pScopeManager.CurrentScope == null)
            return;
        pScopeManager.CurrentScope.TryFlagVarAsUsed(asID);
    }

    // -------------------------------------------------------------------------
    // Pass type enum
    // -------------------------------------------------------------------------

    /// <summary>
    /// Controls which rules are active during a given walk.
    ///   SCAN:    enterVarDefinition + flagVarAsUsed active (collect usage)
    ///   CLEANUP: leaveVarDefinition active (remove unused vars)
    /// </summary>
    public enum CleanupPass
    {
        SCAN,
        CLEANUP
    }
}

// =============================================================================
// TreeRewriter entry points (filter = true)
// =============================================================================
//
// ANTLR3 TreeRewriter invokes topdown() when entering each node and bottomup()
// when leaving each node. Both passes are active on each walker invocation;
// the semantic predicates {ePassType == CleanupPass.SCAN}? and
// {ePassType == CleanupPass.CLEANUP}? gate which rules fire.

topdown
    : enterFunction
    | enterState
    | enterProperty
    | enterBlock
    | enterVarDefinition
    ;

bottomup
    : leaveFunction
    | leaveState
    | leaveProperty
    | leaveBlock
    | leaveVarDefinition
    | flagVarAsUsed
    ;

// =============================================================================
// Scope-enter rules (topdown)
// =============================================================================

// -----------------------------------------------------------------------------
// enterFunction
//
// SF1 change: EnterFunction() takes ScriptFunctionName instead of a raw string.
//
// Called when the walker first enters a FUNCTION, EVENT, or REMOTEEVENT node.
// During SCAN: additionally clears the scope's used-var set so the next pass
// can detect which variables were referenced.
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
    {
        pScopeManager.EnterFunction(new ScriptFunctionName($funcName.text));
        if (ePassType == CleanupPass.SCAN && pScopeManager.CurrentScope != null)
            pScopeManager.CurrentScope.ClearUsedVars();
    }
    ;

// -----------------------------------------------------------------------------
// enterState
//
// SF1 change: EnterState() takes ScriptObjectStateName instead of a raw string.
//
// Called when the walker first enters a STATE node.
//
// Tree structure matched:
//   ^(STATE stateName=ID .*)
// -----------------------------------------------------------------------------
enterState
    : ^(STATE stateName=ID .*)
    { pScopeManager.EnterState(new ScriptObjectStateName($stateName.text)); }
    ;

// -----------------------------------------------------------------------------
// enterProperty
//
// Called when the walker first enters a PROPERTY node.
//
// Tree structure matched:
//   ^( PROPERTY
//      ^(HEADER type propName=ID .*)
//      .* )
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
// Called when the walker first enters a BLOCK node (if/else/while body).
// Pushes a new variable scope block onto the scope stack.
// -----------------------------------------------------------------------------
enterBlock
    : BLOCK
    { pScopeManager.EnterBlock(); }
    ;

// -----------------------------------------------------------------------------
// enterVarDefinition
//
// Active during SCAN pass only.
//
// Sets bInVarDefinition = true so that the variable's own name (seen as an ID
// child of the VAR node) is NOT flagged as a usage reference. This prevents
// the variable definition from counting as a use of itself.
//
// Tree structure matched:
//   ^(VAR type varName=.)   ; varName is consumed as wildcard (name not needed here)
//
// Semantic predicate: only active during SCAN pass.
// -----------------------------------------------------------------------------
enterVarDefinition
    : ^(VAR type .)
        {ePassType == CleanupPass.SCAN}?
    { bInVarDefinition = true; }
    ;

// =============================================================================
// Scope-leave rules (bottomup)
// =============================================================================

// -----------------------------------------------------------------------------
// leaveFunction
//
// Called when the walker exits a FUNCTION, EVENT, or REMOTEEVENT node.
// -----------------------------------------------------------------------------
leaveFunction
    : FUNCTION    { pScopeManager.LeaveFunction(); }
    | EVENT       { pScopeManager.LeaveFunction(); }
    | REMOTEEVENT { pScopeManager.LeaveFunction(); }
    ;

// -----------------------------------------------------------------------------
// leaveState
// -----------------------------------------------------------------------------
leaveState
    : STATE
    { pScopeManager.LeaveState(); }
    ;

// -----------------------------------------------------------------------------
// leaveProperty
// -----------------------------------------------------------------------------
leaveProperty
    : PROPERTY
    { pScopeManager.LeaveProperty(); }
    ;

// -----------------------------------------------------------------------------
// leaveBlock
// -----------------------------------------------------------------------------
leaveBlock
    : BLOCK
    { pScopeManager.LeaveBlock(); }
    ;

// -----------------------------------------------------------------------------
// leaveVarDefinition
//
// Active during both SCAN and CLEANUP passes (no pass predicate — it applies
// the rewrite unconditionally, but the rewrite logic checks IsVarUsed() which
// only removes nodes when ePassType == CLEANUP).
//
// During SCAN:    clears bInVarDefinition and determines whether the variable
//                 will be cleaned up in the next pass (sets bCleanup scope flag).
// During CLEANUP: removes the VAR node if the variable was unused.
//
// Rewrite logic:
//   - If bCleanup (variable was not referenced during SCAN):
//       Replace ^(VAR type varName) with ID[$varName.token, "unused var"]
//       This is a marker node that a subsequent pass may use for diagnostics.
//   - If !bCleanup (variable is used):
//       Reconstruct the original ^(VAR type varName) unchanged.
//
// Grammar scope: leaveVarDefinition_scope tracks bCleanup across action/rewrite.
//
// Tree structure matched:
//   ^(VAR type varName=ID)
// -----------------------------------------------------------------------------
leaveVarDefinition
scope { bool bCleanup; }
    : ^(VAR type varName=ID)
        {
            bInVarDefinition = false;
            $leaveVarDefinition::bCleanup = !IsVarUsed($varName.text);
        }
        -> { $leaveVarDefinition::bCleanup }? ID[$varName.token, "unused var"]
        -> ^(VAR type $varName)
    ;

// -----------------------------------------------------------------------------
// flagVarAsUsed
//
// Active during SCAN pass only.
//
// Called for every ID token encountered during the bottomup walk. If we are
// outside a variable definition (bInVarDefinition == false), records this ID
// as a reference in the current scope's usage map.
//
// The predicate {ePassType == CleanupPass.SCAN}? restricts this rule to the
// SCAN pass. During CLEANUP, ID tokens are not individually visited.
//
// Semantic predicate: only active during SCAN pass.
// -----------------------------------------------------------------------------
flagVarAsUsed
    : idToken=ID
        {ePassType == CleanupPass.SCAN}?
    { HandleIDUse($idToken.text); }
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
//   Int      -> matches '.'
//   Int[]    -> matches '. LBRACKET RBRACKET'
//   Actor    -> matches '.'
//   Actor[]  -> matches '. LBRACKET RBRACKET'
//
// Note: the lookahead checks LA(2) == RBRACKET before committing to the
// optional brackets, matching the generated code's two-token lookahead.
// Unchanged from FO4 — only token numbers differ (LBRACKET=89, RBRACKET=123).
// -----------------------------------------------------------------------------
type
    : . (LBRACKET RBRACKET)?
    ;
