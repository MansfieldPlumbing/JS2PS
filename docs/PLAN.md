# Implementation plan: the lowering corpus

Status: planned, not started. Nothing below is a capability claim until a gate
passes.

## The corpus

The corpus is three records per unit of real software, kept together:

1. the original TypeScript or JavaScript source, immutable, identified by content
   hash and exact offsets, never copied or edited;
2. the LINQ expression tree SMA lowered it to;
3. the managed assembly persisted from that LINQ.

Every record also names the SMA version, the mutation set that was active, the
deepest tier the unit reached, and Node's verdict on it. Lowering fast and deep
builds the corpus; each saved lowering is both a regression fixture and a
starting point for the next run.

## Tiers

```text
T0 source         pinned bytes, content hash
T1 admission      SMA tokens, parse errors and AST under the active mutation set
T2 LINQ           SMA's own lowered expression tree (Compiler._endBlockLambda)
T3 assembly       the LINQ persisted as a managed assembly (PSPersistence route)
T4 native         RyuJIT code for that assembly
```

A unit's record holds every tier it reached. A run resumes each unit from its
deepest still-valid record. A record is invalidated only when something it
depends on changes: the source hash, the SMA version, or the mutation set.

## Steps

1. **Pin the corpus.** Start with `@xterm/headless` 6.0.0 (MIT), pinned by its npm
   SHA-512 integrity value with the existing provenance gate, and its TypeScript
   sources at the matching release tag. Real packages from the CDN and npm follow.
2. **Units come from SMA's own reading.** SMA parses each file; units are the
   statement, function and script-block extents SMA reports, mapped back to
   source offsets. No external parser delimits anything.
3. **Admission (T1).** Record tokens, errors and AST shape for every unit under the
   active mutation set, including units SMA cannot admit yet. Those are evidence.
4. **Lowering (T2).** For every unit SMA admits, compile through SMA's compiler as
   PSPersistence and ChangeModel already do, capture the LINQ tree, and save it
   as its readable text (`DebugView`) plus a structural fingerprint in
   ChangeModel's `ExpressionFeatures` form: binders, constants, node types,
   calls, operand order.
5. **Persistence (T3).** Persist the LINQ as a managed assembly through
   PSPersistence's `PersistedAssemblyBuilder` route wherever its boundary admits
   the shape, and record the assembly bytes and SHA-256. Shapes outside that
   boundary stay at T2 and are reported.
6. **Oracle.** Stock Node runs the same unit or program on the same inputs; the
   verdict is stored next to the lowering. For canvas and DOM programs both sides
   draw into a recording canvas with pinned randomness and a fixed frame clock.
7. **Store.** A content-addressed store outside the repository
   (`../Build/JS2PS/corpus`): a JSON-lines index keyed by source hash, unit
   offsets, SMA version and mutation set, pointing at the LINQ text, the
   fingerprint and the assembly file. Generated output is never committed.
8. **Mutations.** Each reversible mutation of an SMA seam (tokenizer state, parser
   and tokenizer coordination, token identity, type interpretation, binder and
   operator selection, type vocabulary, object adapters) is registered with an
   apply, an exact restore and a replay. Every restore has a test.
9. **Hand-off to ChangeModel.** The records become ChangeModel experience:
   features from the embedding at the unit's deepest tier, and the Node verdict as
   the observed outcome. Contradictions then come from real code instead of
   curated pairs. ChangeModel owns the search; JS2PS does not build one.

## Gates

- Every mutation restores SMA exactly.
- Re-lowering a unit with the same SMA version and mutation set reproduces the same
  LINQ fingerprint.
- A persisted assembly, reloaded, returns the same results as the in-memory
  delegate it came from.
- A unit counts as lowered only when its result matches Node.

## Expected first result

Unmodified TypeScript and JavaScript will mostly stop at T1 under SMA's plain
reading. That is the first real evidence: units whose admission records look
the same while Node's behavior differs are genuine "not even wrong" cases for
ChangeModel. PSPersistence's current boundary (one typed instance method with one
typed parameter) means T3 will lag T2 at first.
