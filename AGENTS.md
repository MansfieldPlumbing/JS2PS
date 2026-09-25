# JS2PS repository contract

## Telos

`System.Management.Automation` (SMA) becomes a drop-in replacement for Node.
TypeScript and JavaScript programs run on CoreCLR through SMA, in the same process
and runspace as PowerShell, with no V8, browser engine, WebView or embedded
JavaScript engine.

What follows from that is the reason for this repository:

- Every pure TypeScript or JavaScript library, the whole CDN and npm registry,
  becomes something a PowerShell runspace can load and run.
- pwsh becomes a native binding for the web platform, the role Chrome's bindings
  play for Blink: a minimal HTML container with TypeScript is an application,
  and its DOM and canvas are bound to native surfaces (QuickPS on Windows, Pwsh on
  Android).
- TypeScript is preferred over JavaScript. Its types are richer, and typed code
  lowers to LINQ with fewer dynamic binders (PSPersistence's
  `probes/Test-SmaCompilation.ps1`: typed parameters remove the binders untyped
  ones need), which is the shape PSPersistence can persist.

Conformance is judged program by program: the same program in Node and in SMA
must produce the same observable result.

## How SMA consumes the source

- SMA is the parser, the compiler and the runtime.
- The source is the floor and is read-only. The TypeScript or JavaScript text is
  never edited, rewritten, or regenerated.
- The one permitted change is runtime mutation of SMA's tokenizer, applied while
  SMA reads the original text. Nothing below the source is written, and SMA's AST
  and LINQ are not rewritten by hand.
- SMA's AST, its LINQ lowering and the execution result are observed and scored.
  They are the judges.
- Mutations form a graph: each mutation is a node, with edges for what it enables,
  what it conflicts with and what must precede it. The search does not simply
  stream the source through: it speculates, hill-climbs, rolls back exactly, and
  discards readings that are not even wrong. Do not hand-write per-construct
  rules.
- Be creative inside these limits.

## Upstream first

Read the pinned upstream source before probing runtime behavior. A claim about SMA,
TypeScript, JavaScript or the web platform cites the file and line it comes from;
experiments confirm what the source says, they do not replace reading it.

| Reference | Ref | Commit |
| --- | --- | --- |
| PowerShell (SMA), `src/System.Management.Automation` | `v7.7.0-preview.5` | `149ab5cd6cad34869177f86ef9a3da8414f85dc6` |
| TypeScript, `src/compiler`, `src/lib` (including `lib.dom`) | `v7.0.2` | `1e4744d68260a7cb91b62b12edc3f6a2187faaf1` |
| ECMA-262, `spec.html` | `main` | `726ec8a42625509026a6570f1d4649bfa9fe4156` |
| WebIDL (w3c/webref curated), `ed/idl` | `curated` | `89e7d68c6612fbedb740c1632d36e482ca39e999` |

Upstream sources are read from a checkout outside this repository and are never
vendored here. Match the SMA reference to the PowerShell version under test.

## Rules

- Never edit the source.
- No regular expressions, anywhere.
- No external JavaScript or TypeScript parser or engine.
- Every runtime mutation is reversible, and a test proves the restore.
- A construct is not supported because it parses. Semantic claims need an
  executable conformance case with an expected result, checked against Node.

## Layout

- `tests/` holds the gates; `tests/Verify.ps1` runs them all.
- `experiments/` holds observations of SMA; they are not claims.
- `fixtures/` holds pinned, integrity-checked inputs.
- `results/` is generated output and is never source.

IL emission, persisted assemblies and the Android appliance live in the
`PSPersistence` and `Pwsh` repositories, not here.
