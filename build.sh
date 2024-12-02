#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Modifications
# TODO
# this installs a package from fedora repos
#rpm-ostree install screen

#### Example for enabling a System Unit File

#systemctl enable podman.socket
