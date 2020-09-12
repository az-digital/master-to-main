#!/bin/zsh

GH_ORG='az-digital'
GH_API="https://api.github.com/orgs/${GH_ORG}/repos?per_page=200"
ISSUE_BRANCH='issues/311'

mkdir -p repos cache
curl -s "${GH_API}" | jq -r -c '.[] | {name: .name, git_url: .git_url}' > cache/gh_data.ndjson

# Clone all the repos in our org
while read -r REPO_INFO; do
  git clone --depth=1 "$(echo ${REPO_INFO} | jq -r '.git_url')" "repos/$(echo ${REPO_INFO} | jq -r '.name' | sed 's/^\.//g')"
done < cache/gh_data.ndjson

# Set up main and issue branch, delete master
(
cd repos
for ROOT in */ ; do
  (
    cd "${ROOT}"
    git checkout master
    git pull
    git checkout -b main
    git branch -d master
    git checkout -b "${ISSUE_BRANCH}"
  )
done
)
