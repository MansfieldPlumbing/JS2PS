# JS2PS repository contract

## What JS2PS is

JS2PS makes SMA and CoreCLR the execution substrate for existing TypeScript and
JavaScript software. The original source stays authoritative and unchanged.

JS2PS is not a transpiler, not a syntax-rewrite project, and not a
reimplementation of Node or V8 in PowerShell. The source does not move; SMA's
perception of the source moves.

The larger program: PowerShell replaces C# as the managed implementation language.
SMA is the compiler infrastructure, managed PE/IL is the durable executable
artifact, and RyuJIT is the native code generator. Roslyn is never required.

## Always descend

```text
TS/JS source -> SMA admission -> semantic and binding facts -> LINQ
             -> persisted managed assembly -> RyuJIT
```

- JavaScript is the source contract, not the preferred execution representation.
  Dynamic SMA is a holding tier; typed LINQ is lower; persisted IL is lower;
  RyuJIT is lower; native bindings and specialized hardware are lower still.
- Retain every successful lowering: the source, the learned representation and
  features, the LINQ, and the emitted assembly.
- On the next run, start from the deepest still-valid artifact. Never climb back up
  unless an invalidated assumption forces it, and never discard a proven lowering.

## Closure

- The production closure starts at PowerShell 7. Anything outside it is a donor or
  an oracle only.
- No Roslyn, no generated C#, no Node runtime in the product path, and no external
  compiler or parser as architectural authority. Node is the semantic oracle, not
  a dependency.

## How SMA comes to admit the source

- The source is never edited, rewritten or regenerated to make a parser happy.
- Syntax is not hand-ported construct by construct. Arrow functions, object
  literals, classes, `new`, TypeScript annotations, `===`, template literals and
  the rest are fixtures that exert pressure on the mutation graph, not a backlog
  of rewrite rules.
- The mutation graph searches the legal SMA seams: tokenizer state, parser and
  tokenizer coordination, token identity, type interpretation, binder and operator
  selection, extended type data and type vocabulary, object adapters, and other
  runtime representation choices.
- Every mutation is reversible and replayable, and a test proves the restore.
- If SMA admits and binds the unchanged source, retain the result and lower it
  further. If no reachable mutation can represent the required semantics, report a
  representational gap and extend the mutation vocabulary.

## Search discipline (ChangeModel)

ChangeModel owns the hill climb, contradiction detection, replay and promotion.
Do not build a second search engine in JS2PS.

- If the representation is adequate and the wrong interpretation was chosen,
  change the delta or search parameters.
- If two semantically different cases collapse to the same representation and no
  parameter choice separates them, the result is not even wrong: the
  representation itself must gain a new distinction.

JS2PS owns the immutable source corpus, the SMA mutation surfaces, the binding and
lowering observations, and the semantic oracle.

ChangeModel is used by pinned commit, never copied here. Current pin:
`MansfieldPlumbing/ChangeModel` `1e3d1143d1dd1d5490bbfc72f951185a65f46291`
(branch `claude/js2ps-world-reconstruction`, Gate 7). JS2PS feeds it through
`tools/Export-LexicalEvidence.ps1` and `tools/Observe-SmaPerception.ps1`.

## Types and objects

- TypeScript is preferred where available. A type annotation is lowering leverage:
  if it can become a CLR or SMA type fact that removes binders and yields better
  LINQ and IL, it is not skipped.
- Runtime objects are bound capabilities, not reconstructed JSON. `console`, DOM
  objects, canvas, native Windows and Android objects are bound through SMA.
  Values cross by value; objects cross by opaque identity. SMA is the binding
  fabric, and SMA's threads are available to the host.
- Chrome is not the architecture. It may be a willing peer; Windows and Android are
  first-class peers too. A DOM object, native control, DirectX resource, Binder
  object or browser object can all take part in one logical object universe.

## Corpus and milestone

- Real CDN and npm packages are the corpus; ECMAScript is not "finished"
  abstractly. Each failed package is evidence for the mutation graph; each
  successful admission becomes a regression fixture and a persisted lowering.
- The milestone is not a percentage of syntax. It is: this unmodified TypeScript or
  JavaScript application or library runs under SMA, binds to native Windows,
  Android or browser objects, and persists as a managed assembly, with no Node, V8,
  Roslyn or source rewriting.

## Upstream first

Read the pinned upstream source before probing runtime behavior. A claim about SMA,
TypeScript, JavaScript or the web platform cites the file and line it comes from.

| Reference | Ref | Commit |
| --- | --- | --- |
| PowerShell (SMA), `src/System.Management.Automation` | `v7.7.0-preview.5` | `149ab5cd6cad34869177f86ef9a3da8414f85dc6` |
| TypeScript, `src/compiler`, `src/lib` (including `lib.dom`) | `v7.0.2` | `1e4744d68260a7cb91b62b12edc3f6a2187faaf1` |
| ECMA-262, `spec.html` | `main` | `726ec8a42625509026a6570f1d4649bfa9fe4156` |
| WebIDL (w3c/webref curated), `ed/idl` | `curated` | `89e7d68c6612fbedb740c1632d36e482ca39e999` |

Upstream sources are read from a checkout outside this repository and never
vendored. Match the SMA reference to the PowerShell version under test.

## Rules

- Never edit the source.
- No regular expressions, anywhere.
- A construct is not supported because it parses. Semantic claims need an
  executable case checked against Node.

## Layout

- `tests/` holds the gates; `tests/Verify.ps1` runs them all.
- `experiments/` holds observations of SMA; they are not claims.
- `fixtures/` holds pinned, integrity-checked inputs.
- `results/` is generated output and is never source.

Persisted assemblies and the Android appliance live in `PSPersistence` and `Pwsh`;
native Windows bindings live in `QuickPS`.
