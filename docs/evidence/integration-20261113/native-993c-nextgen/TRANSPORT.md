# Lossless Git transport

The 558 files of the frozen Native 993c Nextgen compact pack are stored in
`original-evidence.tar.gz`. All member bytes were compared with the originals
after archive creation. `archive-manifest.json` records every stored identity.
The original README, manifest and SHA256SUMS are also directly tracked for
navigation and retain their original hashes.

Extract the transport archive into this directory to restore checkpoint and
artifact-data files, then verify the original SHA256SUMS. Their internal gzip
objects retain complete original metadata and logs without whitespace changes.
The 22 actually reviewed PNGs are separately committed by the existing Host
recorder. Full original ZIP/PNG payloads are not duplicated in this transport.
