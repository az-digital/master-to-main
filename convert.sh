#!/bin/zsh

mkdir -p repos

while read -r REPO; do
  echo $REPO
  git clone --depth=1 "git@github.com:az-digital/${REPO}.git" "repos/${REPO/^\./}"
done < repos.txt

(
cd repos
for ROOT in */ ; do
  (
    cd "${ROOT}"
    git checkout master
    git pull
    git checkout -b main
    git branch -d master
    git checkout -b 'issues/311'
  )
done
)
