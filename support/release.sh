#!/bin/bash

# Use colors for errors.
. $(dirname ${0})/colors.sh

test ${#} -eq 2 || \
  { echo "Usage: `basename ${0}` [version] [candidate]"; exit 1; }

# TODO(benh): Figure out a way to get version number and release
# candidate automagically.
VERSION=${1}
CANDIDATE=${2}

echo "${GREEN}Releasing mesos-${VERSION} candidate ${CANDIDATE}${NORMAL}"

read -p "Hit enter to continue ... "

make distcheck || \
  { echo "${RED}Failed to check the distribution${NORMAL}"; exit 1; }

mv mesos-${VERSION}.tar.gz mesos-${VERSION}-incubating.tar.gz || \
  { echo "${RED}Failed to rename the distribution${NORMAL}"; exit 1; }

TARBALL=mesos-${VERSION}-incubating.tar.gz

echo "${GREEN}Now let's sign the distribution ...${NORMAL}"

# Sign the tarball.
gpg --armor --output ${TARBALL}.asc --detach-sig ${TARBALL} || \
  { echo "${RED}Failed to sign the distribution${NORMAL}"; exit 1; }

echo "${GREEN}And let's create an MD5 ...${NORMAL}"

# Create MD5 checksum.
gpg --print-md MD5 ${TARBALL} > ${TARBALL}.md5 || \
  { echo "${RED}Failed to create MD5 for distribution${NORMAL}"; exit 1; }

DIRECTORY=public_html/mesos-${VERSION}-incubating-RC${CANDIDATE}

echo "${GREEN}Now let's upload our artifacts (the distribution," \
  "signature, and MD5) ...${NORMAL}"

ssh people.apache.org "mkdir -p ${DIRECTORY}" || \
  { echo "${RED}Failed to create remote directory${NORMAL}"; exit 1; }

{ scp ${TARBALL} people.apache.org:${DIRECTORY}/ && \
  scp ${TARBALL}.asc people.apache.org:${DIRECTORY}/ && \
  scp ${TARBALL}.md5 people.apache.org:${DIRECTORY}/; } || \
  { echo "${RED}Failed to copy distribution artifacts${NORMAL}"; exit 1; }

echo "${GREEN}Now let's make the artifacts world readable ...${NORMAL}"

{ ssh people.apache.org "chmod a+r ${DIRECTORY}/${TARBALL}" && \
  ssh people.apache.org "chmod a+r ${DIRECTORY}/${TARBALL}.asc" && \
  ssh people.apache.org "chmod a+r ${DIRECTORY}/${TARBALL}.md5"; } || \
  { echo "${RED}Failed to change permissions of artifacts${NORMAL}";
    exit 1; }

echo "${GREEN}Finally, we'll create an SVN tag/branch ...${NORMAL}"

MESSAGE="Tag for release-${VERSION}-incubating-RC${CANDIDATE}."

git svn branch -n --tag -m ${MESSAGE} \
  release-${VERSION}-incubating-RC${CANDIDATE} || \
  { echo "${RED}Failed to create SVN tag/branch${NORMAL}"; exit 1; }

exit 0
