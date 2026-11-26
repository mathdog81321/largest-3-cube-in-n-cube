# Largest three-dimensional cubes in higher-dimensional unit cubes

**K.-C. Chang**  
**Preliminary working manuscript — 25 November 2026. Not peer reviewed.**

This repository contains a mathematical manuscript and a Lean 4 formalization
concerning the maximal side length of a three-dimensional cube contained
isometrically in the unit n-dimensional cube. It studies static containment,
not Prince Rupert's passage problem.

## Main result

Write `f(3,n)` for the maximal side length and `F_3(n) = f(3,n)^2`.
The manuscript gives the following exact values for every integer `n >= 3`:

| Dimension | `F_3(n)` |
| --- | --- |
| `n=3m`, `m>=1` | `m` |
| `n=4` | `1+delta_1` |
| `n=7` | `2+delta_2` |
| `n=3m+1`, `m>=3` | `m+15-4*sqrt(14)` |
| `n=3m+2`, `m>=1` | `m+10-4*sqrt(6)` |

The two exceptional constants are algebraic, with
`delta_1 ~ 0.014925` and `delta_2 ~ 0.030276`: `delta_1` is the smaller
positive root of `4d^4-12d^3-67d^2-66d+1`, and `delta_2` is the smallest
positive root of `d^8-8d^7-12d^6+80d^5+70d^4-200d^3-28d^2-32d+1`.
The formula gives `F_3(n+3) = F_3(n) + 1` for all `n >= 8`.

The cases with `3 | n` and the exact value for `n=4` were proved previously.
The value for `n=5` had been reported (Finch, attributing it to Huber) and
attained by an explicit construction (Firsching), but we are not aware of a
published proof of the matching upper bound; see the manuscript's bibliography.
Research priority for the entire family is not independently established, particularly in relation to unpublished
work by Huber and Ligocki.

## Manuscript

- `paper/manuscript.pdf`: current working draft.
- `paper/manuscript.tex`: LaTeX source; compile from `paper/` with `latexmk -pdf manuscript.tex`.
- `paper/pair_support_graph.pdf`: figure used in the manuscript.

## Lean 4 formalization

The formalization uses Lean 4.19.0 and a pinned Mathlib dependency. From the
repository root, on Linux, macOS, or WSL2 with Lean and Lake installed:

```bash
lake exe cache get
lake build
bash scripts/verify.sh
```

The script checks source hashes, builds the project, runs `CompleteAudit.lean`,
`KeyTheorems.lean`, `AuxiliaryAudit.lean` and `PaperWitnesses.lean`, and checks
1,195 theorem type/axiom records. It also runs `Audit.lean`, `GeometryAudit.lean`,
`ProductMassAudit.lean` and `VariationalAudit.lean` and checks their axiom
reports. It accepts only `propext`, `Classical.choice`, and `Quot.sound` as
theorem dependencies. Reproducibility
logs are saved locally in the ignored `verification_runs/` directory.
`PaperWitnesses.lean` checks the existence and prints types of selected Lean
witness declarations. A successful Lean build does not by itself establish the
fidelity of every natural-language statement to its formal specification.

**macOS notes.** The script uses `shasum -a 256` when `sha256sum` is not
installed. On recent macOS versions, executables linked by the linker bundled
with Lean 4.19 may be rejected at load time (`dyld: __DATA_CONST segment
missing SG_READ_ONLY flag`), which breaks `lake exe cache get`. Relinking the
cache tool with the system compiler works around this:

```bash
cd .lake/packages/mathlib
rm -f .lake/build/bin/cache
LIBRARY_PATH="$(elan which lean | xargs dirname)/../lib" LEAN_CC=/usr/bin/clang lake build cache
cd ../../.. && lake exe cache get
```

### Paper statements and Lean theorems

Each row names the Lean declaration that formalizes a manuscript statement.
The `#check` output of `KeyTheorems.lean` prints their exact types. Checking
that these types say what the manuscript says is the part a build cannot do.

| Manuscript | Lean declaration | Notes |
| --- | --- | --- |
| Theorem 1.1 | `F3.geometricValue_eq_sqrt_formula` | Geometric side length; matrix form is `F3.frameValue_eq_formula`. |
| Theorem 1.1, `n=5` | `F3.geometricValue_five`, `F3.frameValue_five` | |
| Theorem 1.1, `n=7` | `F3.frameValue_seven` | |
| Corollary 1.2 | `F3.geometricValue_squared_recurrence`, `F3.geometricValue_squared_recurrence_iff` | The `iff` form gives the exceptions `n=4,7`. |
| Proposition 2.2 | `F3.geometricSide_iff_feasibleValue`, `F3.General.geometricSide_iff_feasibleValue`, `F3.General.value_trace_equality_iff` | Geometry-to-matrix equivalence; trace equality iff `k` divides `n`. |
| Proposition 2.3 | `F3.General.value_superadditive` | Stacking. |
| Lemma 3.3 | `F3.active_residue_one` | Stated for any feasible frame at level `m+d`, `d>0`. |
| Lemma 3.6 | `F3.strict_second_order_not_local_min` | |
| Proposition 3.7 | `F3.full_support_bound_at_optimum` | `Q+2F<=5`. |
| Lemma 4.1 | `F3.rootOneEquation_unique`, `F3.rootTwoEquation_unique`, `F3.canonical_exceptional_roots` | |
| Lemma 5.7 | `F3.active_residue_two` | Adds the hypothesis `1/5<d`, which holds at the optimum (`Delta>1/5`). |
| Equation (6.1) | `F3.tetrahedronValue_eq_geometricValue` | `T(n)=sqrt(2) f(3,n)`; also `F3.tetrahedronValue_five`. |
| Proposition 6.1 | `F3.General.finite_core_iff_stabilization` | |
| Theorems 4.6 and 5.10 | `F3.canonical_sharp_values` | All residues at once, as `SharpValues`. |

## Status, licensing, and citation

The paper is a preliminary working draft; a full author-side review and peer
review remain outstanding. Its AI-assistance disclosure appears in the paper.

- Lean source, build and verification scripts, and this repository README:
  Apache License 2.0 (`LICENSE`, `NOTICE`).
- Mathematical manuscript, LaTeX, and figure in `paper/`:
  Copyright (c) 2026 K.-C. Chang, all rights reserved (`paper/LICENSE`).
  The repository-level Apache license does not extend to `paper/`.
- Third-party dependencies retain their respective licenses.

For citations, see `CITATION.cff`. No DOI has yet been assigned to this version.
