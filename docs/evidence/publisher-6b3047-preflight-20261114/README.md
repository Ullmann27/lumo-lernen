# Inactive publisher preparation for Host 6b3047b7

This checkpoint prepares a new publisher for the actual Host source
6b3047b7979dfb86d837e74a21b0fd890e4f9e66, tree
8b0c31a26207068c28658e14c6535c39a51cf95b, Native
84789d0c2c6fb4b6ecd2897ce1951b89f958b604. The mandatory complete Host acceptance
is run 43616038272, attempt 1. At preparation time its full verification is still
running. This checkpoint does not approve an APK or execute a release operation.

## Preserved original publication requirements

The existing publisher is rebound to the actual source/run. Reversing only the
documented additions and literal source/run replacements reproduces every byte
of the reviewed 1e22 publisher (SHA256
c090b8631be7f43215fc3b4472bb710348f869eb0ff397b60abbd37a27cc141d).

All original seven-job checks, source/PR/attempt bindings, complete delivery
ZIP and eleven-asset requirements, original APK comparison, independent
apksigner/aapt verification, stable test certificate, new-version/tag vacancy,
new-draft-only operations, and unauthenticated public APK byte verification
remain present. Existing releases are not overwritten.

The verifier-source receipt additionally hashes scripts/package_notices.py and
config/lumo-notices.json, as required by the current source's original-notice
verification. No notice text is changed.

## Additional exact acceptance checks

Before handling the original delivery bundle and again immediately before
publishing, the workflow fetches current Native and Feature run, job and artifact
metadata. The bound verifier requires exact source, repository, branch, event,
workflow, run, attempt, job identity, ordered original step names/numbers, every
step's successful terminal state, complete single-job/artifact catalogs, and
the reviewed artifact ID/name/size/digest/owner. No skipped gate qualifies.

Native: run 43613299144/1, artifact 14122180486, 66,954,397 bytes,
SHA256 af8a7b6f08d59f52dd25c2b061b4119b369f3793845132bb39ef9fca6b0446f0.
[Original Native evidence](https://github.com/Ullmann27/lumo-godot/tree/1a96e90bcbd927e458ccc2c2626d2e4b979a429e/docs/evidence/native-discovery-847-43613299144).

Feature: run 43616035099/1, artifact 14122252221, 1,167,242 bytes,
SHA256 aa3acbb92e89b5e8c3723d35ffb0ea8e07f6405b8dbe7821a6a3ce9b085b9075.
[Original 30/0/0 Feature evidence](https://github.com/Ullmann27/lumo-lernen/tree/debe7026e5c257bf5d8fe26ec57af51e97b41419/docs/evidence/live-integration-20261114/final-6b3047b7/feature30).

This additional check revalidates metadata against previously reviewed immutable
artifacts. It does not rerun Flutter, Godot or image readers. Both publication-time
metadata snapshots and the exact verifier are included in the always-uploaded
publication receipt.

## Actual local preparation verification

- 51 metadata guard tests passed, zero failures or skips: two positive checks use
  actual successful Native/Feature metadata; 49 tests cover missing, duplicate,
  changed, stale, foreign, nonterminal, failed and skipped inputs.
- The verifier CLI ran successfully against those actual saved metadata values,
  the current clean Host6b checkout and exact Native847 pin.
- All eight Bash blocks passed bash -n; all four Python heredocs parsed/compiled
  without execution. The embedded helper equals the tested helper byte for byte.
- Actionlint 1.7.12 exited zero, binary SHA256
  c872d6db8c6bf83a8eaa704fc93999f027d55dffbc63b8a6abdccb47df5f4cd4.

The six files in original-metadata/ contain the actual GitHub API field values
parsed and re-serialized for the local test fixtures. They are not claimed to
preserve HTTP-response formatting or network bytes. The local CLI is an offline
replay of these saved values, not a new publication-time API fetch. The original
CLI/test stdout is unchanged; the word FRESH in the verifier's status label
describes its intended workflow invocation and does not turn this local replay
into a live request.

No workflow command, APK rebuild, tag creation, draft upload, publication or
public download was executed by the static preflight. A complete successful
new-source Host run and independent original delivery review remain mandatory.
The delivery activation branch has not been created by this preparation.
