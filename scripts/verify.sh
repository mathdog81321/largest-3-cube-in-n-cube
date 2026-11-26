#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
RUN="verification_runs/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$RUN"
RUN="$(cd "$RUN" && pwd)"
STATUS="$RUN/STATUS.txt"
printf 'STARTED %s\n' "$(date -u +%FT%TZ)" > "$STATUS"
trap 'rc=$?; if [ "$rc" -ne 0 ]; then printf "FAILED exit=%s\n" "$rc" >> "$STATUS"; fi' EXIT
step() {
    local label="$1"; shift
    echo "[$label]"
    if "$@" >"$RUN/$label.log" 2>&1; then
        printf '%s PASS\n' "$label" >> "$STATUS"
    else
        local rc=$?
        printf '%s FAILED exit=%s\n' "$label" "$rc" >> "$STATUS"
        tail -n 50 "$RUN/$label.log" >&2 || true
        exit "$rc"
    fi
}
for bin in git python3 lean lake; do
    command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 127; }
done
# GNU coreutils provides sha256sum; macOS ships shasum instead.
if command -v sha256sum >/dev/null; then
    SHA256_CHECK=(sha256sum -c)
elif command -v shasum >/dev/null; then
    SHA256_CHECK=(shasum -a 256 -c)
else
    echo "Missing sha256sum or shasum" >&2; exit 127
fi
# Fail if a Lean log reports an error, a sorry, or a theorem depending on
# anything other than the three standard axioms.
check_lean_log() {
    local log="$1" bad
    if grep -E ': error|declaration uses .sorry.' "$log"; then return 1; fi
    if ! grep -q 'depends on axioms\|does not depend on any axioms' "$log"; then
        echo "No axiom report found in $log" >&2; return 1
    fi
    # A wrapped (multi-line) axiom list would escape the check below.
    if [ "$(grep -c 'depends on axioms' "$log")" != "$(grep -c 'depends on axioms: \[.*\]' "$log")" ]; then
        echo "Unparsed axiom report in $log" >&2; return 1
    fi
    bad="$(grep -o 'depends on axioms: \[.*\]' "$log" | sed 's/.*\[//; s/\]$//' \
        | tr ',' '\n' | tr -d ' ' | sort -u \
        | grep -vxE 'propext|Classical\.choice|Quot\.sound' || true)"
    if [ -n "$bad" ]; then echo "Disallowed axioms in $log: $bad" >&2; return 1; fi
}
step proof_source_hashes "${SHA256_CHECK[@]}" PINNED_PROOF_SOURCES.sha256
if ! grep -qx 'leanprover/lean4:v4.19.0' lean-toolchain; then echo 'Unexpected Lean toolchain' >&2; exit 2; fi
printf 'source_toolchain=%s\n' "$(cat lean-toolchain)" > "$RUN/TOOLS.txt"
lean --version >> "$RUN/TOOLS.txt" 2>&1
lake --version >> "$RUN/TOOLS.txt" 2>&1
cp lake-manifest.json "$RUN/lake-manifest.before.json"
if [ ! -d .lake/packages/mathlib ]; then
    step dependency_fetch env MATHLIB_NO_CACHE_ON_UPDATE=1 lake update
fi
if ! cmp -s lake-manifest.json "$RUN/lake-manifest.before.json"; then
    echo 'Manifest changed: verification cannot be claimed' >&2; exit 5
fi
expected='c44e0c8ee63ca166450922a373c7409c5d26b00b'
actual="$(git -C .lake/packages/mathlib rev-parse HEAD)"
if [ "$actual" != "$expected" ]; then echo 'Mathlib commit mismatch' >&2; exit 6; fi
printf '%s\n' "$actual" > "$RUN/mathlib_commit.txt"
step mathlib_cache lake exe cache get
step build lake build
step CompleteAudit lake env lean CompleteAudit.lean
step KeyTheorems lake env lean KeyTheorems.lean
step AuxiliaryAudit lake env lean AuxiliaryAudit.lean
step PaperWitnesses lake env lean PaperWitnesses.lean
step audit_report python3 scripts/check_fresh_audit.py "$RUN/CompleteAudit.log"
for audit in Audit GeometryAudit ProductMassAudit VariationalAudit; do
    step "$audit" lake env lean "$audit.lean"
    step "${audit}_axioms" check_lean_log "$RUN/$audit.log"
done
if ! cmp -s lake-manifest.json "$RUN/lake-manifest.before.json"; then
    echo 'Manifest changed during verification' >&2; exit 7
fi
step final_proof_source_hashes "${SHA256_CHECK[@]}" PINNED_PROOF_SOURCES.sha256
printf 'PASSED %s\n' "$(date -u +%FT%TZ)" >> "$STATUS"
echo "Verified successfully. Logs: $RUN"
