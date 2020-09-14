#!/bin/zsh

GH_ORG='az-digital'
GH_API="https://api.github.com/orgs/${GH_ORG}/repos?per_page=200"
ISSUE_BRANCH='issues/311'

mkdir -p repos cache
curl -s "${GH_API}" | jq -r -c '.[] | {name: .name, ssh_url: .ssh_url}' > cache/gh_data.ndjson

# Clone all the repos in our org
while read -r REPO_INFO; do
  git clone --depth=1 "$(echo ${REPO_INFO} | jq -r '.ssh_url')" "repos/$(echo ${REPO_INFO} | jq -r '.name' | sed 's/^\.//g')"
done < cache/gh_data.ndjson

# Set up main and issue branch, delete master
(
cd repos
for ROOT in */ ; do
  (
    cd "${ROOT}"
    git checkout master
    git pull
    git branch main
    git checkout main
    # git push --set-upstream origin main
    # git branch -d master
    git branch "${ISSUE_BRANCH}"
    git checkout "${ISSUE_BRANCH}"

    # Update github actions
    find . -type f -path '.github/workflows/*' -exec sed -i '' 's/- master/- main/g' {} \;
    git add .github/workflows
    git commit -m 'update worflows to reference main branch'

    # Update composer.json and composer.lock
    sed -i '' 's/dev-master/dev-main/g' composer.json
    composer update --lock
    git add composer.json composer.lock
    git commit -m 'update composer.json and composer.lock to reference main branch'

    # Update *.md files
    find . -name '*.md' -exec sed -E -i '' 's|(https://github\.com/az-digital/.*)(master)(.*)|\1main\3|g' {} \;
    git add .
    git commit -m 'update md files reference main branch'

    # git push --set-upstream origin "${ISSUE_BRANCH}"
  )
done
)
