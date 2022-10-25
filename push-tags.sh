#!/bin/bash
set -x

SE_VERSION="4.39"
SE_REVISION="9772"

BASE_TAGS="latest fedora debian alpine ubuntu"

for TAG in ${BASE_TAGS}; do
  docker pull siomiz/softethervpn:${TAG}
  VERSION_TAG=${SE_VERSION}-${TAG}
  REVISION_TAG=${SE_REVISION}-${TAG}
  docker tag siomiz/softethervpn:${TAG} siomiz/softethervpn:${VERSION_TAG%-latest}
  docker tag siomiz/softethervpn:${TAG} siomiz/softethervpn:${REVISION_TAG%-latest}
  docker push siomiz/softethervpn:${VERSION_TAG%-latest}
  docker push siomiz/softethervpn:${REVISION_TAG%-latest}
done
