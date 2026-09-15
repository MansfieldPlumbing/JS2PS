$ErrorActionPreference='Stop'
$source='jsconst Item { value = 1 }'

function Parse-Shape([string]$Text){
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseInput($Text,[ref]$tokens,[ref]$errors)
    [PSCustomObject]@{Ast=$ast;Tokens=@($tokens);Errors=@($errors);StatementType=$ast.EndBlock.Statements[0].GetType().Name}
}

[Management.Automation.Language.DynamicKeyword]::RemoveKeyword('jsconst')
$before=Parse-Shape $source
$preParseCalled=$false;$postParseCalled=$false;$semanticCheckCalled=$false
$keyword=[Management.Automation.Language.DynamicKeyword]::new()
$keyword.Keyword='jsconst'
$keyword.NameMode=[Management.Automation.Language.DynamicKeywordNameMode]::SimpleNameRequired
$keyword.BodyMode=[Management.Automation.Language.DynamicKeywordBodyMode]::Hashtable
$keyword.DirectCall=$true
$property=[Management.Automation.Language.DynamicKeywordProperty]::new()
$property.Name='value';$property.TypeConstraint='int'
$keyword.Properties.Add('value',$property)
$keyword.PreParse={param($definition)$script:preParseCalled=$true;[Management.Automation.Language.ParseError[]]@()}
$keyword.PostParse={param($statement)$script:postParseCalled=$true;[Management.Automation.Language.ParseError[]]@()}
$keyword.SemanticCheck={param($statement)$script:semanticCheckCalled=$true;[Management.Automation.Language.ParseError[]]@()}
try {
    [Management.Automation.Language.DynamicKeyword]::AddKeyword($keyword)
    if(-not [Management.Automation.Language.DynamicKeyword]::ContainsKeyword('jsconst')){throw 'Keyword registration was not observable.'}
    $registered=Parse-Shape $source
} finally {
    [Management.Automation.Language.DynamicKeyword]::RemoveKeyword('jsconst')
}
$afterRemoval=Parse-Shape $source

if($before.StatementType-ne 'PipelineAst'){throw "Unexpected pre-registration AST: $($before.StatementType)"}
if($registered.StatementType-ne 'DynamicKeywordStatementAst'){throw "Registered AST was $($registered.StatementType)."}
if($registered.Tokens[0].Kind-ne [Management.Automation.Language.TokenKind]::DynamicKeyword){throw 'Tokenizer did not emit DynamicKeyword.'}
if($registered.Errors.Count){throw "Registered source produced $($registered.Errors.Count) parse errors."}
if(-not $preParseCalled-or-not $postParseCalled-or-not $semanticCheckCalled){throw 'One or more parser callbacks were not invoked.'}
if($afterRemoval.StatementType-ne 'PipelineAst'){throw "Keyword remained active after removal: $($afterRemoval.StatementType)"}

[PSCustomObject]@{
    BeforeRegistration=$before.StatementType
    RegisteredTokenKind=$registered.Tokens[0].Kind
    AfterRegistration=$registered.StatementType
    ParseErrors=$registered.Errors.Count
    PreParseCalled=$preParseCalled
    PostParseCalled=$postParseCalled
    SemanticCheckCalled=$semanticCheckCalled
    AfterRemoval=$afterRemoval.StatementType
    Passed=$true
}
