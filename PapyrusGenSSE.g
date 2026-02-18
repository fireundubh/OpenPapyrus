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

tree grammar PapyrusGenSSE;

options {
    tokenVocab = PapyrusParserSSE;
    ASTLabelType = CommonTree;
    language = CSharp3;
    output = template;
}

@header {
using System.Collections;
using PCompiler;
}

@members {
    // Template library for code generation
    protected StringTemplateGroup templateLib =
        new StringTemplateGroup("PapyrusGenTemplates", typeof(AngleBracketTemplateLexer));

    // Known user flags dictionary (set externally)
    private Dictionary<string, PapyrusFlag> kFlagDict;
    internal Dictionary<string, PapyrusFlag> KnownUserFlags { set { kFlagDict = value; } }

    // Script object type information (from type walker)
    private ScriptObjectType kObjType;

    // Variable name mangling suffix counter
    private int iCurMangleSuffix = 0;

    // Label generation counter
    private int iCurLabelSuffix = 0;

    // Error event handler
    internal event InternalErrorEventHandler ErrorHandler;

    // Error handling override
    private void OnError(string asError, int aiLineNumber, int aiColumnNumber)
    {
        if (ErrorHandler != null)
            ErrorHandler(this, new InternalErrorEventArgs(asError, aiLineNumber, aiColumnNumber));
    }

    public override void DisplayRecognitionError(string[] tokenNames, RecognitionException e)
    {
        OnError(GetErrorMessage(e, tokenNames), e.Line, e.CharPositionInLine);
    }

    // Variable name mangling (for scope collision resolution)
    private string MangleVariableName(string asOriginalName)
    {
        string mangledName = string.Format("::mangled_{0}_{1}", asOriginalName, iCurMangleSuffix);
        ++iCurMangleSuffix;
        return mangledName;
    }

    private void MangleFunctionVariables(ScriptFunctionType akFunction)
    {
        Dictionary<string, bool> definedVars = new Dictionary<string, bool>();
        MangleScopeVariables(akFunction.Scope, ref definedVars);
    }

    private void MangleScopeVariables(ScriptScope akCurrentScope, ref Dictionary<string, bool> akAlreadyDefinedVars)
    {
        // Recursive scope variable mangling implementation
        // Renames variables that shadow outer scope variables to "::mangled_<name>_<suffix>"
        foreach (var variable in akCurrentScope.Variables)
        {
            if (akAlreadyDefinedVars.ContainsKey(variable.Name))
            {
                variable.MangledName = MangleVariableName(variable.Name);
            }
            else
            {
                akAlreadyDefinedVars.Add(variable.Name, true);
            }
        }

        // Recurse into child scopes
        foreach (var childScope in akCurrentScope.ChildScopes)
        {
            MangleScopeVariables(childScope, ref akAlreadyDefinedVars);
        }
    }

    // Label generation for control flow
    private string GenerateLabel()
    {
        string label = string.Format("label{0}", iCurLabelSuffix);
        ++iCurLabelSuffix;
        return label;
    }

    // Timestamp tracking for compiled output
    private static DateTime UnixEpoc { get { return new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc); } }

    private static string ToUnixTime(DateTime dt)
    {
        return ((long)(dt - UnixEpoc).TotalSeconds).ToString();
    }

    private string GetFileModTimeUnix(string asSourceFilename)
    {
        return ToUnixTime(File.GetLastWriteTimeUtc(asSourceFilename));
    }

    private string GetCompileTimeUnix()
    {
        return ToUnixTime(DateTime.UtcNow);
    }

    // User flags reference table construction
    private Hashtable ConstructUserFlagRefInfo()
    {
        Hashtable flagTable = new Hashtable();
        foreach (var kvp in kFlagDict)
        {
            flagTable.Add(kvp.Key, kvp.Value.Index);
        }
        return flagTable;
    }
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * SCOPE DECLARATIONS
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Script-level scope (16 fields)
scope script {
    string sobjName;               // Script object name
    string sparentName;            // Parent script name
    IList kobjVarDefinitions;      // Variable definitions
    IList kobjPropDefinitions;     // Property definitions
    string sinitialState;          // Initial state name
    IList kobjEmptyState;          // Empty state event list
    Hashtable kstates;             // State blocks (name -> template)
    bool bhasBeginStateEvent;      // Has BeginState event
    bool bhasEndStateEvent;        // Has EndState event
    string smodTimeUnix;           // File modification time (Unix)
    string scompileTimeUnix;       // Compilation time (Unix)
    string suserName;              // User name (environment)
    string scomputerName;          // Computer name (environment)
    string sobjFlags;              // User flags string
    Hashtable kuserFlagsRef;       // Flag reference table
    string sdocString;             // Documentation string
}

// Field definition scope (1 field)
scope fieldDefinition {
    string sinitialValue;          // Initial value expression
}

// Function scope (12 fields)
scope function {
    string sstate;                 // State name (empty for script-level)
    string sfuncName;              // Function name
    string spropertyName;          // Property name (for property functions)
    string sreturnType;            // Return type name
    bool bisNative;                // Is native function
    bool bisGlobal;                // Is global function
    IList kfuncParams;             // Parameter templates
    IList kfuncVarDefinitions;     // Local variable definitions
    IList kstatements;             // Statement templates
    string suserFlags;             // User flags string
    string sdocString;             // Documentation string
    ScriptFunctionType kfuncType;  // Function type metadata (from type walker)
}

// Event scope (11 fields)
scope eventFunc {
    string sstate;                 // State name (empty for script-level)
    string sfuncName;              // Event name
    string sreturnType;            // Return type (always "None" for events)
    bool bisNative;                // Is native event
    bool bisGlobal;                // Is global event (always false)
    IList kfuncParams;             // Parameter templates
    IList kfuncVarDefinitions;     // Local variable definitions
    IList kstatements;             // Statement templates
    string suserFlags;             // User flags string
    string sdocString;             // Documentation string
    ScriptFunctionType kfuncType;  // Event type metadata (from type walker)
}

// Property scope (4 fields)
scope propertyBlock {
    string spropName;              // Property name
    string spropType;              // Property type
    string suserFlags;             // User flags string
    string sdocString;             // Documentation string
}

// Code block scope (3 fields)
scope codeBlock {
    IList kvarDefs;                // Local variable definitions
    ScriptScope kcurrentScope;     // Current variable scope (from type walker)
    int inextScopeChild;           // Next child scope index
}

// Statement scope (1 field)
scope statement {
    string smangledName;           // Mangled variable name (for locals)
}

// L-value scope (2 fields)
scope l_value {
    string ssourceName;            // Source expression variable
    string sselfName;              // Self reference variable
}

// Basic l-value scope (2 fields)
scope basic_l_value {
    string ssourceName;            // Source expression variable
    string sselfName;              // Self reference variable
}

// Array atom scope (1 field)
scope array_atom {
    string sselfName;              // Self reference variable
}

// Array/func/id scope (1 field)
scope array_func_or_id {
    string sselfName;              // Self reference variable
}

// Func/id scope (1 field)
scope func_or_id {
    string sselfName;              // Self reference variable
}

// Property set scope (2 fields)
scope property_set {
    string sselfName;              // Self reference variable
    string sparamName;             // Parameter variable name
}

// If block scope (3 fields)
scope ifBlock {
    IList kBlockStatements;        // Block statements
    string sEndLabel;              // End label for jumps
    ScriptScope kchildScope;       // Child scope (from type walker)
}

// ElseIf block scope (2 fields)
scope elseIfBlock {
    IList kBlockStatements;        // Block statements
    ScriptScope kchildScope;       // Child scope (from type walker)
}

// Else block scope (2 fields)
scope elseBlock {
    IList kBlockStatements;        // Block statements
    ScriptScope kchildScope;       // Child scope (from type walker)
}

// While block scope (4 fields)
scope whileBlock {
    IList kBlockStatements;        // Block statements
    string sStartLabel;            // Start label for loop
    string sEndLabel;              // End label for break
    ScriptScope kchildScope;       // Child scope (from type walker)
}

// Function call scope (1 field)
scope function_call {
    string sselfName;              // Self reference variable
}

// Auto-cast scope (1 field)
scope autoCast {
    string ssource;                // Source variable for auto-cast
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * TREE WALKING RULES
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Script-Level Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Main entry point: script object
// Semantic parameters: asSourceFilename (source file path), akObj (script object type)
script[string asSourceFilename, ScriptObjectType akObj]
    scope { script; }
    : ^(OBJECT header definitionOrBlock*)
      // Template: object(objName, parent, variableDefs, propDefs, initialState, emptyState, states, ...)
    ;

// Script header: name, parent, flags, docstring
header
    : ID USER_FLAGS? ID? DOCSTRING?
      // Extracts script name, parent name, user flags, and documentation
    ;

// Top-level definition dispatcher
definitionOrBlock
    : fieldDefinition
    | function
    | eventFunc
    | stateBlock
    | propertyBlock
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Definition Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Variable/field definition
fieldDefinition
    scope { fieldDefinition; }
    : ^(VAR type ID USER_FLAGS constant?)
      // Template: variableDef(name, type, flags, initialValue, lineNo)
    ;

// Function definition
// Semantic parameters: asState (state name, empty for script-level), asPropertyName (property name, empty for non-property)
function[string asState, string asPropertyName]
    scope { function; }
    : ^(FUNCTION functionHeader codeBlock?)
      // Template: functionDef(state, name, returnType, params, varDefs, statements, native, global, flags, docString)
    ;

// Function header: return type, name, parameters, modifiers
functionHeader
    : ^(HEADER (type | NONE) ID USER_FLAGS? callParameters? functionModifier* DOCSTRING?)
      // Extracts function signature
    ;

// Function modifier: NATIVE or GLOBAL
functionModifier
    : NATIVE
    | GLOBAL
    ;

// Event definition
// Semantic parameters: asState (state name, empty for script-level)
eventFunc[string asState]
    scope { eventFunc; }
    : ^(EVENT eventHeader codeBlock?)
      // Template: functionDef(state, name, returnType="None", params, varDefs, statements, native, flags, docString)
    ;

// Event header: name, parameters
eventHeader
    : ^(HEADER NONE ID USER_FLAGS? callParameters? NATIVE? DOCSTRING?)
      // Extracts event signature
    ;

// Function/event parameter list
callParameters returns [IList kParams]
    : callParameter+
      // Returns list of parameter templates
    ;

// Single parameter
callParameter
    : ^(PARAM type ID? constant?)
      // Template: funcParam(name, type, defaultValue)
    ;

// State block definition
stateBlock
    : ^(STATE ID AUTO? stateFuncOrEvent*)
      // Template: state block with functions/events
    ;

// Function or event within a state
stateFuncOrEvent[string asStateName]
    : function[asStateName, ""]
    | eventFunc[asStateName]
    ;

// Property block definition
propertyBlock
    scope { propertyBlock; }
    : ^(PROPERTY propertyHeader propertyFunc propertyFunc?)
      // Template: fullProp(name, type, flags, docString, getFunc, setFunc)
    | ^(AUTOPROP propertyHeader ID)
      // Template: autoProp(name, type, flags, docString, autoVarName)
    ;

// Property header: type, name, flags
propertyHeader
    : ^(HEADER type ID USER_FLAGS? DOCSTRING?)
      // Extracts property signature
    ;

// Property getter/setter function
// Semantic parameters: asPropName (property name)
propertyFunc[string asPropName]
    : ^(PROPFUNC function[, asPropName])
    | PROPFUNC
      // Empty property function (no body)
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Code Block and Statement Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Function/event body
// Semantic parameters: akStatements (output accumulator), akVarDefinitions (output accumulator), akCurrentScope (variable scope)
codeBlock[IList akStatements, IList akVarDefinitions, ScriptScope akCurrentScope]
    scope { codeBlock; }
    : ^(BLOCK statement*)
      // Accumulates variable definitions and statements
    ;

// Statement dispatcher
statement
    scope { statement; }
    : localDefinition
      // Template: localDef(name, type, initialValue, lineNo)
    | ^(EQUALS ID autoCast? l_value expression)
      // Template: assign(target, source, autoCast, lineNo)
    | expression
      // Expression statement (e.g., function call)
    | return_stat
      // Template: return(value, lineNo)
    | ifBlock
      // Template: ifBlock(condition, statements, elseIfs, else, lineNo)
    | whileBlock
      // Template: whileBlock(condition, statements, lineNo)
    ;

// Local variable definition
localDefinition returns [string sVarName, string sExprVar, int iLineNo, StringTemplate kExprST, StringTemplate kAutoCastST]
    : ^(VAR type ID autoCast? expression?)
      // Template: localDef(name, type, initialValue, autoCast, expressions, lineNo)
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * L-Value Rules (Assignment Targets)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// L-value: assignment target
l_value
    scope { l_value; }
    : ^(DOT ^(PAREXPR expression) property_set)
      // Template: propSet(self, propName, value, lineNo)
    | ^(ARRAYSET ID ID autoCast? ^(PAREXPR expression) expression)
      // Template: arraySet(array, index, value, autoCast, lineNo)
    | basic_l_value
      // Delegate to basic l-value
    ;

// Basic l-value: simple assignment target
basic_l_value
    scope { basic_l_value; }
    : ^(DOT array_func_or_id basic_l_value)
      // Dot operator l-value
    | function_call
      // Function call l-value (not actually assignable, but parsed)
    | property_set
      // Property setter
    | ^(ARRAYSET ID ID autoCast? func_or_id expression)
      // Array element assignment
    | ID
      // Simple identifier
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Expression Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Logical OR expression
expression returns [string sRetValue]
    : ^(OR ID expression expression and_expression)
      // Template: orExpression(target, left, right, lineNo)
    | and_expression
      // Delegate to AND expression
    ;

// Logical AND expression
and_expression returns [string sRetValue]
    : ^(AND ID and_expression and_expression bool_expression)
      // Template: andExpression(target, left, right, lineNo)
    | bool_expression
      // Delegate to boolean expression
    ;

// Boolean/comparison expression
bool_expression returns [string sRetValue]
    : ^(EQ ID autoCast? autoCast? bool_expression add_expression)
      // Template: twoOpCommand(command="CMPEQ", target, left, right, autoCast, lineNo)
    | ^(NE ID autoCast? autoCast? bool_expression add_expression)
      // Template: notEqual(target, left, right, autoCast, lineNo)
    | ^(GT ID autoCast? autoCast? bool_expression add_expression)
      // Template: twoOpCommand(command="CMPGT", ...)
    | ^(LT ID autoCast? autoCast? bool_expression add_expression)
      // Template: twoOpCommand(command="CMPLT", ...)
    | ^(GTE ID autoCast? autoCast? bool_expression add_expression)
      // Template: twoOpCommand(command="CMPGE", ...)
    | ^(LTE ID autoCast? autoCast? bool_expression add_expression)
      // Template: twoOpCommand(command="CMPLE", ...)
    | add_expression
      // Delegate to addition expression
    ;

// Addition/subtraction expression
add_expression returns [string sRetValue]
    : ^(IADD ID autoCast? autoCast? add_expression mult_expression)
      // Template: twoOpCommand(command="IADD", target, left, right, autoCast, lineNo)
    | ^(FADD ID autoCast? autoCast? add_expression mult_expression)
      // Template: twoOpCommand(command="FADD", ...)
    | ^(ISUBTRACT ID autoCast? autoCast? add_expression mult_expression)
      // Template: twoOpCommand(command="ISUBTRACT", ...)
    | ^(FSUBTRACT ID autoCast? autoCast? add_expression mult_expression)
      // Template: twoOpCommand(command="FSUBTRACT", ...)
    | ^(STRCAT ID autoCast? autoCast? add_expression mult_expression)
      // Template: twoOpCommand(command="STRCAT", ...)
    | mult_expression
      // Delegate to multiplication expression
    ;

// Multiplication/division/modulus expression
mult_expression returns [string sRetValue]
    : ^(IMULTIPLY ID autoCast? autoCast? mult_expression unary_expression)
      // Template: twoOpCommand(command="IMULTIPLY", target, left, right, autoCast, lineNo)
    | ^(FMULTIPLY ID autoCast? autoCast? mult_expression unary_expression)
      // Template: twoOpCommand(command="FMULTIPLY", ...)
    | ^(IDIVIDE ID autoCast? autoCast? mult_expression unary_expression)
      // Template: twoOpCommand(command="IDIVIDE", ...)
    | ^(FDIVIDE ID autoCast? autoCast? mult_expression unary_expression)
      // Template: twoOpCommand(command="FDIVIDE", ...)
    | ^(MOD ID autoCast? autoCast? mult_expression unary_expression)
      // Template: twoOpCommand(command="MOD", ...)
    | unary_expression
      // Delegate to unary expression
    ;

// Unary expression (negation, NOT)
unary_expression returns [string sRetValue]
    : ^(INEGATE ID cast_atom)
      // Template: singleOpCommand(command="INEGATE", target, source, lineNo)
    | ^(FNEGATE ID cast_atom)
      // Template: singleOpCommand(command="FNEGATE", ...)
    | ^(NOT ID cast_atom)
      // Template: singleOpCommand(command="NOT", ...)
    | cast_atom
      // Delegate to cast expression
    ;

// Type cast expression (AS operator)
cast_atom returns [string sRetValue]
    : ^(AS ID dot_atom type)
      // Template: cast(target, source, type, lineNo)
    | dot_atom
      // Delegate to dot expression
    ;

// Dot operator expression (member access)
dot_atom returns [string sRetValue]
    : ^(DOT array_func_or_id dot_atom)
      // Template: dot(target, object, member, lineNo)
    | array_atom
      // Delegate to array expression
    ;

// Array access expression
array_atom returns [string sRetValue]
    scope { array_atom; }
    : ^(ARRAYGET ID array_func_or_id ^(PAREXPR expression))
      // Template: arrayGet(target, array, index, lineNo)
    | ^(LENGTH ID array_func_or_id)
      // Template: arrayLength(target, array, lineNo)
    | ^(ARRAYFIND ID array_func_or_id ^(PAREXPR expression) ^(PAREXPR expression)?)
      // Template: arrayFind(target, array, element, startIndex, lineNo)
    | ^(ARRAYRFIND ID array_func_or_id ^(PAREXPR expression) ^(PAREXPR expression)?)
      // Template: arrayRFind(target, array, element, startIndex, lineNo)
    | atom
      // Delegate to atom
    ;

// Terminal atom (literals, identifiers, function calls, parenthesized expressions)
atom returns [string sRetValue]
    : array_func_or_id
      // Array, function, or identifier
    | ^(NEW ID type ^(PAREXPR expression))
      // Template: newArray(target, type, size, lineNo)
    | ^(PAREXPR expression)
      // Parenthesized expression
    | constant
      // Constant literal
    ;

// Array, function call, or identifier
array_func_or_id returns [string sRetValue]
    scope { array_func_or_id; }
    : ^(ARRAYGET ID ID ^(PAREXPR expression))
      // Template: arrayGet(target, array, index, lineNo)
    | ^(LENGTH ID ID)
      // Template: arrayLength(target, array, lineNo)
    | ^(ARRAYFIND ID ID ^(PAREXPR expression) ^(PAREXPR expression)?)
      // Template: arrayFind(target, array, element, startIndex, lineNo)
    | ^(ARRAYRFIND ID ID ^(PAREXPR expression) ^(PAREXPR expression)?)
      // Template: arrayRFind(target, array, element, startIndex, lineNo)
    | func_or_id
      // Function call or identifier
    ;

// Function call or identifier
func_or_id returns [string sRetValue]
    scope { func_or_id; }
    : ^(CALL ID ID parameters)
      // Template: callLocal(target, funcName, params, lineNo)
    | ^(CALLPARENT ID ID parameters)
      // Template: callParent(target, funcName, params, lineNo)
    | ^(CALLGLOBAL ID ID ID parameters)
      // Template: callGlobal(target, scriptName, funcName, params, lineNo)
    | ^(PROPGET ID ID ID)
      // Template: propGet(target, object, propName, lineNo)
    | ID
      // Simple identifier
    ;

// Property setter call
property_set
    scope { property_set; }
    : ^(PROPSET ID autoCast? ID expression)
      // Template: propSet(object, propName, value, autoCast, lineNo)
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Control Flow Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Return statement
return_stat
    : ^(RETURN expression?)
      // Template: return(value, lineNo)
    ;

// If statement
ifBlock
    scope { ifBlock; }
    : ^(IF expression statement* elseIfBlock* elseBlock?)
      // Template: ifBlock(condition, statements, elseIfs, else, endLabel, lineNo)
    ;

// ElseIf block
elseIfBlock
    scope { elseIfBlock; }
    : ^(ELSEIF expression statement*)
      // Template: elseIfBlock(condition, statements, lineNo)
    ;

// Else block
elseBlock
    scope { elseBlock; }
    : ^(ELSE statement*)
      // Template: elseBlock(statements, lineNo)
    ;

// While loop
whileBlock
    scope { whileBlock; }
    : ^(WHILE expression statement*)
      // Template: whileBlock(condition, statements, startLabel, endLabel, lineNo)
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Function Call and Parameter Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Function call (used within expressions)
function_call returns [string sRetValue]
    scope { function_call; }
    : ^(CALL ID ID ID ^(CALLPARAMS parameters?))
      // Template: callLocal(target, funcName, retValue, params, lineNo)
    | ^(CALLPARENT ID ID ID ^(CALLPARAMS parameters?))
      // Template: callParent(target, funcName, retValue, params, lineNo)
    | ^(CALLGLOBAL ID ID ID ^(CALLPARAMS parameters?))
      // Template: callGlobal(target, scriptName, funcName, params, lineNo)
    | ^(ARRAYFIND ID ID ^(CALLPARAMS parameters?))
      // Template: arrayFind(target, retValue, params, lineNo)
    | ^(ARRAYRFIND ID ID ^(CALLPARAMS parameters?))
      // Template: arrayRFind(target, retValue, params, lineNo)
    ;

// Call parameters
parameters returns [IList sParamVars, IList kAutoCastST]
    : parameter*
      // Template: parameterExpressions(params)
    ;

// Single call parameter
parameter returns [string sVarName, StringTemplate kAutoCastST]
    : autoCast? expression
      // Returns parameter variable name and auto-cast template
    ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Utility Rules
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Automatic type cast
autoCast returns [string sRetValue]
    scope { autoCast; }
    : ^(AS ID expression type)
      // Template: cast(target, source, type, lineNo)
    ;

// Constant value
constant
    : INTEGER
    | FLOAT
    | STRING
    | BOOL
    | NONE
    ;

// Number literal
number
    : INTEGER
    | FLOAT
    ;

// Type specification
type
    : ID LBRACKET RBRACKET
      // Array type: ID[]
    | ID
      // Simple type: ID
    ;
