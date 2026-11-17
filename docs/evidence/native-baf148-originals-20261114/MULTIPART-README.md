# Original Native screenshots: lossless multipart transport

The original archive remains exactly 25,465,892 bytes with SHA256
`c527f35148189bdca92aa42288a66f165c6a2ebcbddee16c5b7a87c518129d2c`.
Its unchanged contents are the fifteen original Root-reviewed PNGs, their
original selection catalog and the unchanged Root review.

The first large Git-blob write was not confirmed. A subsequent actual object
read returned 404 and the evidence branch remained at its parent. The exact
transport/tool failure reason was not retained and is not inferred.
The same large request was not retried.

For repository transport only, concatenate parts 001 through 005 in that
order. Their concatenation was read back and compared byte for byte with the
complete original archive. Individual sizes, SHA256 and Git-blob identities
are in image-archive-parts.json.

```sh
cat native-baf148b-root-reviewed-15.tar.gz.part-001 \
    native-baf148b-root-reviewed-15.tar.gz.part-002 \
    native-baf148b-root-reviewed-15.tar.gz.part-003 \
    native-baf148b-root-reviewed-15.tar.gz.part-004 \
    native-baf148b-root-reviewed-15.tar.gz.part-005 > native-baf148b-root-reviewed-15.tar.gz
sha256sum native-baf148b-root-reviewed-15.tar.gz
```

The original source/archival manifests intentionally remain unchanged. This
supplement describes only how their one full image archive is represented in
the repository. It introduces no image edits, new render, test result, source
change, candidate activation, tag or release.
