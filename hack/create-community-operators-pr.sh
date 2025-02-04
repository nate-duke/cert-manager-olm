#!/usr/bin/env bash
#
# Create a PR at one of the operator-hub repos containing the current cert-manager bundle
#
#  BUNDLE_VERSION=1.6.2 UPSTREAM=k8s-operatorhub FORK=wallrj REPO=community-operators ./hack/create-community-operators-pr.sh
#  BUNDLE_VERSION=1.6.2 UPSTREAM=redhat-openshift-ecosystem FORK=wallrj REPO=community-operators-prod ./hack/create-community-operators-pr.sh
#
# But it's easier to call this from the Makefile with:
#
#  make update-community-operators
#  make update-community-operators-prod

set -o errexit
set -o nounset
set -o pipefail

: ${BUNDLE_VERSION?}
: ${UPSTREAM?}
: ${FORK?}
: ${REPO?}

# Clone the repo
test -d "build/operatorhub-repos/${REPO}/.git" || \
    git clone "git@github.com:${FORK}/${REPO}.git" "build/operatorhub-repos/${REPO}" \
        --origin origin

pushd "build/operatorhub-repos/${REPO}"

# Add upstream as remote
git remote get-url upstream ||
    git remote add upstream "https://github.com/${UPSTREAM}/${REPO}.git"
git remote set-url upstream "https://github.com/${UPSTREAM}/${REPO}.git"

# Get latest remote content
git fetch --all --prune

# Create or reset the local branch
git checkout -B "cert-manager-${BUNDLE_VERSION}" upstream/main

# Copy all the files to the workspace
rm -rf "operators/cert-manager/${BUNDLE_VERSION}"
cp -a ../../../bundle "operators/cert-manager/${BUNDLE_VERSION}"

# Commit the files
git add "operators/cert-manager/${BUNDLE_VERSION}"
git commit --message "Release cert-manager-${BUNDLE_VERSION}" --signoff

# Push to the fork
git push origin --force-with-lease --set-upstream

# Create a PR if one does not exist
gh pr view < /dev/null || \
    gh pr create --fill </dev/null
