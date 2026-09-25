# JS2PS

JS2PS is a research repository whose goal is for PowerShell's
`System.Management.Automation` (SMA) to consume and execute JavaScript. SMA is the
parser, the compiler and the runtime. JS2PS is not a JavaScript runtime, a Node
replacement, or a claim that arbitrary JavaScript already runs.

## Approach

Everything is done with SMA's own machinery:

- **AST**: SMA's parse results, tokens and syntax tree, including nodes built through
  their public constructors.
- **LINQ**: the expression trees SMA's compiler lowers that AST into, with its binders
  and call sites.
- **Mutations**: runtime changes to SMA itself, such as `DynamicKeyword` registrations,
  the tokenizer's keyword, operator and character tables, command vocabulary, extended
  type data, and binder substitution in the lowered tree. Each is tried speculatively,
  scored by what SMA then produces, and rolled back when rejected.

These can be combined freely. The search is automated; per-construct rules are not
written by hand. See `AGENTS.md` for the full contract.

## Rules

- The JavaScript source is never edited. SMA reads the original text.
- SMA is changed only at runtime, through its own extension points and state, and
  every change is reversible.
- No regular expressions, and no external JavaScript parser or engine.

A construct is not considered supported merely because it parses. Semantic claims
require an executable conformance case with an expected result.

## Current proofs

- reversible registration and removal of an SMA `DynamicKeyword` statement form.

## Requirements

- PowerShell 7 for SMA parsing and execution tests.

No test downloads dependencies implicitly or searches machine-wide paths for them.

## Verify

Run the gate set:

```powershell
pwsh -NoProfile -File .\tests\Verify.ps1
```

The default gate verifies the checked-in OGL files against their pinned local
hash manifest and does not require network access. A separate scheduled and
manually runnable provenance check downloads the immutable npm tarball, verifies
its SHA-512 integrity value, and compares the four retained files byte-for-byte:

```powershell
pwsh -NoProfile -File .\tests\Verify-FixtureProvenance.ps1
```

Individual tests:

```powershell
pwsh -NoProfile -File .\tests\Prove-DynamicKeywordParserExtension.ps1
```

## Layout

```text
tests/        repeatable gates and bounded proofs
fixtures/     pinned, integrity-checked corpus inputs; see fixtures/README.md
docs/         generated matrices and bounded claims
experiments/  exploratory probes that are not release gates
results/      local generated output
tools/        matrix-generation utilities
```

## Non-goals

- regenerating JavaScript as new source text;
- embedding a JavaScript engine as the execution model;
- claiming semantic equivalence from parser acceptance.

IL emission, persisted assemblies and the Android appliance belong in the separate
`PSPersistence` and `Pwsh` projects.

## License

JS2PS is available under the MIT License.
