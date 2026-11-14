# Separate C4 2020 publication orchestrator

## Status and source boundary

This is an external source proposal. The two new Python files have not been
executed, imported as executable modules or tested. No API mutation, release,
tag, APK download, Git write, workflow activation or candidate change occurred.
Root must checkpoint this source before the isolated tests run.

The source contract was read in full from Host
`37ec6c6aee67c31ce16550cd59d616c80e80e305`, tree
`6ab0e6cafc9fb37d3b3d95d76805aff4b6810d7a`. Its delivery verifier and release
gate helper are unchanged from the earlier 68f pin checkpoint. The current
candidate's subsequent outer-budget adjustment is not embedded here. Every
actual candidate and publisher identity is a required command-line argument.
The previously reported run 43601673844 is not treated as accepted. No bundle
artifact identity was available during preparation.

Only these proposed repository paths are added:

- `scripts/publish_connect_four_delivery.py`
- `scripts/tests/test_publish_connect_four_delivery.py`

The original candidate workflow and all verifier files remain unchanged. No
new workflow is included with fabricated final identities. The later single
push workflow must bind the genuinely observed final Host/tree, successful
run/attempt and complete delivery artifact ID/digest/size.

## Invocation inputs

Run the new script from its own committed publisher checkout. Supply every
required identity explicitly; there are no defaults for candidate identities.

| Argument | Required binding |
| --- | --- |
| `--candidate-source` | Absolute path to a separate, clean checkout of the accepted Host |
| `--host-sha`, `--host-tree` | Exact accepted candidate commit and tree |
| `--publisher-source` | Absolute path to the clean checkout containing this committed script |
| `--publisher-sha`, `--publisher-tree` | Exact publisher commit and tree, separate from APK identity |
| `--build-run`, `--run-attempt` | Exact completed successful C4 candidate run and attempt |
| `--bundle-artifact-id` | Actual unique `lumo-connect-four-2020-delivery-bundle` artifact |
| `--bundle-artifact-digest` | Exact API value with `sha256:` prefix |
| `--bundle-artifact-size` | Exact full archive size reported by the API |
| `--pull-request` | Exactly 485 |
| `--output` | New absolute directory outside both checkouts; reuse is rejected |
| `--bundle-archive` | Optional already-preserved complete original archive; still checked against fresh API metadata |

The sole credential input is the `GITHUB_TOKEN` environment variable. It is
used only for the fixed repository API and upload endpoints. The read-only
candidate verifier receives an explicit small environment without credentials.
No caller-supplied Python import path or existing ignored bytecode is used by
that verifier.

For the later workflow, default permissions should remain read-only. Only the
publication job needs `contents: write`, plus `actions: read` and
`pull-requests: read`. Both checkouts must use exact SHAs and
`persist-credentials: false`. Keep the accepted candidate checkout outside the
publisher checkout and all outputs outside both. Use a dedicated exact push
branch and concurrency group, with no rerun/resume behavior. Preserve the
script's original stdout, stderr and actual shell exit status even on failure.
Upload the external evidence directory with an always-running artifact step;
never rewrite the delivery directory to insert a publication receipt.

## Sequence and unchanged verifier calls

1. Check both actual Git HEADs, trees, clean status and raw index identities.
   The candidate verifier, its helper, native pin, pubspec and C4 workflow must
   match committed bytes. The two executable verifier/helper hashes are fixed
   to their reviewed originals.
2. Read fresh latest-run and exact-attempt metadata, PR485, all attempt jobs and
   all artifacts. Require the seven successful original jobs, the exact open
   unmoved PR and actual bundle identity. All API page bodies remain separate
   originals; the verifier's aggregate arrays are explicitly derived.
3. Read the complete original archive once from the authenticated artifact
   endpoint or supplied local file. Verify the full size and SHA before parsing.
   Stream every member through ZIP CRC and SHA256 verification; extract only
   canonical regular files into a new directory. Reject duplicates, links,
   traversal, encrypted/special files and oversized payloads.
4. Run unchanged `check-current`. It rechecks every local bundle byte against
   the original archive, mandatory jobs, all original artifacts and exact
   candidate source. Check the prepared request payloads and all 11 assets.
5. Read the complete release and tag catalogs. Release/tag page collection ends
   only after an empty page; the matching-ref response is additionally compared
   with all repository tag names. Run unchanged `check-vacant`.
6. Send the original `audit/create-tag.json` exactly once. Read back the new
   lightweight tag and run unchanged `check-tag`. Recheck catalog identity.
7. Send the original `audit/create-release.json` exactly once. Read back the
   fresh empty prerelease draft and run unchanged `check-release empty-draft`.
8. Upload precisely the 11 original assets once each. Check each returned ID,
   name, size, SHA256 digest and exact public URL. Duplicate names are never
   deleted or overwritten. PR/run/source freshness is checked before every
   mutation.
9. Refresh all current metadata and run unchanged `check-current` again. Read
   full catalogs, the tag, release and all release-asset pages. Only our newly
   created tag and draft may have appeared. Require the same upload IDs and run
   unchanged `check-release uploaded-draft`.
10. Send only the original `audit/publish-release.json` once. Read back the
    published prerelease and run unchanged `check-release published`.
11. Download the exact canonical APK URL completely without authorization on
    any hop. Verify bytes/size/SHA, refresh current candidate and release data,
    then run unchanged `verify-public` to a new receipt outside the delivery.
    Recheck source/index and the entire unchanged delivery/ZIP before success.

## Evidence and failure behavior

Original JSON response bodies, HTTP status, request body hashes, complete
verifier stdout/stderr and return codes are preserved outside the delivery.
Source and explicit-input records distinguish publisher and APK identities.
Original archive/member hashes and the public download are retained.

Authenticated redirects are never followed automatically. The artifact
redirect and public APK redirects use ordinary verified HTTPS; authorization
is never forwarded to download hosts. Signed locations, tokens, cookies and
authorization headers are not logged. An unexpected credential-bearing JSON
response stops the operation; only its byte count, hash and explicit omission
reason are retained. It is not called a preserved complete response.

There are no mutation retries, existing-release resume, asset replacement,
ref updates, deletions or automatic cleanup. An unknown transport outcome can
leave a new tag, partial draft, uploaded draft or even an already published
release. Failure does not turn that outcome into success and does not repair
it. Root must inspect the original receipts before deciding any further work.
The output directory cannot be reused, and existing remote tags/releases make
a new invocation fail vacancy checks.

The maximum archive is 2 GiB, uncompressed member total 3 GiB, member count 512,
JSON response 16 MiB and catalog 100 pages. File data is streamed, not kept as
one large RAM buffer. HTTP socket waits are bounded; responses/downloads are
rejected after their 600-second acceptance budget. A 3600-second budget guards
publication decisions. These guards are not a hard overall process-runtime
claim; the eventual workflow also needs an outer timeout. Verifier calls have
their own 900-second subprocess timeout. All deadlines fail without retry.

Fresh reads do not create a distributed lock against another repository
writer. New tag creation is atomic, and all later observed identity/catalog
changes fail closed. A concurrent change after the last read remains an API
race, not a proven invariant. The separate workflow must have one publisher,
and Root keeps PR485 and accepted candidate refs fixed during publication.

## Planned isolated validation

After Root's source checkpoint, run only:

```sh
python3 -m unittest -v scripts.tests.test_publish_connect_four_delivery
```

The written tests use synthetic bytes and isolated API/Git boundaries. They
exercise the existing delivery CLI dispatcher and verification functions, not
a copied alternative verifier. They deny live socket connections. Negative
cases include changed source/index, PR/run/attempt, skipped required steps,
incomplete catalogs, occupied version, archive CRC/path/type/size errors,
changed asset IDs/bytes, unknown mutation outcomes, redirects/credentials and
public-download corruption. A synthetic successful sequence is not proof of
a real workflow, upload, Android run or release.

## Official API references consulted

- https://docs.github.com/en/rest/about-the-rest-api/api-versions
- https://docs.github.com/en/rest/releases/releases?apiVersion=2026-03-10
- https://docs.github.com/en/rest/releases/assets?apiVersion=2026-03-10
- https://docs.github.com/en/rest/git/refs?apiVersion=2026-03-10
- https://docs.github.com/en/rest/actions/artifacts?apiVersion=2026-03-10
- https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10
- https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10

These references establish the endpoint/method, pagination, status, API
version and redirect contracts used here. They do not establish a real
publication result for this candidate.
