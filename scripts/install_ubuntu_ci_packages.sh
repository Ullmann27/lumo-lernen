#!/usr/bin/env bash
set -euo pipefail
# The hosted Ubuntu runner's third-party feeds are unrelated to these
# official Ubuntu packages. Restrict APT to the signed Ubuntu sources.
source /etc/os-release
test "$ID" = ubuntu
test "$VERSION_ID" = 24.04
sources=/etc/apt/sources.list.d/ubuntu.sources
test -s "$sources"
test "$#" -gt 0
options=(-o "Dir::Etc::sourcelist=$sources" -o Dir::Etc::sourceparts=- -o Acquire::Retries=3 -o APT::Get::List-Cleanup=0)
sudo apt-get "${options[@]}" update -qq
sudo env DEBIAN_FRONTEND=noninteractive apt-get "${options[@]}" install -y "$@"
