# JS2PS

JS2PS is a research repository whose goal is for PowerShell's
`System.Management.Automation` (SMA) to consume and execute TypeScript and
JavaScript. SMA is the parser, the compiler and the runtime. JS2PS contains no
JavaScript engine, and nothing here claims that arbitrary programs already run.

## Approach

The telos is SMA as a drop-in replacement for Node: TypeScript and JavaScript run on
CoreCLR through SMA, with no embedded JavaScript engine. TypeScript is preferred.

SMA reads the original source text. The one permitted change is runtime mutation of
SMA's tokenizer; SMA's own AST, LINQ lowering and execution are observed and scored,
never rewritten. Mutations form a graph that an automated search explores with
speculation, hill climbing and exact rollback. See `AGENTS.md` for the full contract
and the pinned upstream references.

## Rules

- The JavaScript source is never edited. SMA reads the original text.
- SMA is changed only by runtime mutation of its tokenizer, and every change is
  reversible.
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
