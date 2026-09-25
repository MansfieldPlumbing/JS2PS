# JS2PS repository contract

The goal is for PowerShell's `System.Management.Automation` (SMA) to consume and
execute JavaScript. SMA is the parser, the compiler and the runtime. Keep this
repository narrow and evidence-led.

## The three instruments

Work is done with SMA's own machinery, and only with it:

- **AST.** SMA's `System.Management.Automation.Language` tree: parse results,
  tokens, extents, visitors, and AST nodes built or rebuilt through their public
  constructors.
- **LINQ.** The expression trees SMA's compiler produces from that AST, its
  binders and call sites, and the delegates compiled from them.
- **Mutations.** Runtime changes to SMA's state and extension points, applied
  speculatively, scored, and rolled back exactly when rejected. Examples:
  `DynamicKeyword` registrations with their parse callbacks; the tokenizer's
  keyword, operator and character-trait tables; command vocabulary (functions
  named for JavaScript keywords); extended type data; binder and call-site
  substitution in the lowered LINQ tree.

Be creative within these instruments. Combining them is expected: a mutation can
change how SMA tokenizes, what AST it builds, or how that AST lowers to LINQ, as
long as each change is reversible and its effect is measured.

## Rules

- Never edit the JavaScript source. SMA reads the original text, byte for byte.
- No regular expressions, anywhere.
- No external JavaScript parser or engine. ECMA-262 is the reference for what
  JavaScript means; SMA is the only thing that parses or runs it.
- Every runtime mutation is reversible, and a test proves the restore.
- Search is automated: candidates are generated from what SMA reports (tokens,
  parse errors, AST shape, LINQ shape), tried speculatively, and kept only when
  they measurably improve the score. Do not hand-write per-construct rules.
- A construct is not supported because it parses. Semantic claims need an
  executable conformance case with an expected result.

## Layout

- `tests/` holds the gates; `tests/Verify.ps1` runs them all.
- `experiments/` holds observations of SMA; they are not claims.
- `fixtures/` holds pinned, integrity-checked inputs.
- `results/` is generated output and is never source.

IL emission, persisted assemblies and the Android appliance live in the
`PSPersistence` and `Pwsh` repositories, not here.
