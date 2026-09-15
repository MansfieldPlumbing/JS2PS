# AST-Guided Hill Climbing

## Purpose

Use small, reversible source edits to reach a PowerShell parse that preserves the input expression's operation and value.

This is not a language-lowering stage. It does not translate the source into an intermediate representation, replace operators, introduce a runtime, or execute JavaScript. The current proof only inserts PowerShell variable sigils at JavaScript identifier-reference coordinates.

## Inputs

- Original JavaScript expression text.
- Identifier-reference coordinates reported by a JavaScript parser.
- The AST and parse errors reported by `System.Management.Automation.Language.Parser` for each candidate.
- An expected result supplied by a conformance case.

Property names in static member access are not candidates. For example, `player` is a reference in `player.x`, while `x` is a property name.

## Search

1. Parse the unchanged expression with SMA.
2. Produce every candidate that adds one unselected `$` insertion.
3. Parse and score every candidate.
4. Accept only the highest candidate whose score strictly improves.
5. Repeat until no improving candidate remains.
6. Parse and execute the result.
7. Compare its value with the case's expected value.

The score rewards PowerShell expression nodes and penalizes command-shaped nodes and parser errors. It is a search heuristic, not a correctness claim.

## Proof gate

A bounded case passes only when all of the following are true:

- the JavaScript parser identifies the expected reference coordinates;
- every accepted mutation improves the SMA score;
- the final source matches the expected minimally edited source;
- SMA reports zero parse errors;
- the scriptblock executes;
- the result matches the expected value;
- the final score equals the best score found by exhaustive enumeration of every candidate subset.

The exhaustive comparison proves the greedy result only for the bounded cases in the test. It does not prove that the heuristic finds a global optimum for arbitrary programs.

## Current verification result

`tests/Prove-AstGuidedHillClimb.ps1` currently proves:

| Expression family | Identifier references | Greedy evaluations | Exhaustive evaluations |
|---|---:|---:|---:|
| Two indexed vector operands | 2 | 4 | 4 |
| Interpolation with repeated identifiers | 4 | 11 | 16 |
| Member and nested computed access | 5 | 16 | 32 |

Every current case reaches the exhaustive best score, parses without errors, executes, and returns the expected value.

## Reproduction

Install or otherwise obtain Esprima.NET 3.0.6, then run:

```powershell
pwsh -NoProfile -File .\tests\Prove-AstGuidedHillClimb.ps1 `
    -AssemblyPath <path-to-Esprima.dll>
```

The assembly path is explicit. The test does not download packages, search machine-wide paths, or add a QuickPS runtime dependency.

## Not proved

The current proof does not cover:

- statements, functions, classes, or modules;
- calls whose JavaScript and PowerShell invocation syntax differ;
- constructors, typed arrays, ternaries, or object literals;
- JavaScript coercion, equality, prototype, `this`, exception, or asynchronous semantics;
- semantic equivalence without an explicit test oracle;
- search optimality outside the bounded exhaustive cases;
- incremental parsing or parallel candidate evaluation.

These remain separate experiments. A construct is not admitted because it renders, parses, or resembles the expected output. It is admitted only after its syntax and behavior gates pass.

## Next experiments

1. Measure candidate scoring with larger graphics expressions.
2. Compare greedy, beam, and exhaustive search on cases small enough to enumerate.
3. Cache candidate parses by edit-set identity.
4. Stop evaluating edits inside subtrees whose SMA shape is already accepted.
5. Test independent subtrees concurrently without changing selection semantics.
6. Add one irreducible syntax family at a time, each with an execution oracle.
