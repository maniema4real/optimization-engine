#!/bin/bash
set -euxo pipefail

# This script generates and publishes the sphinx API documentation
# of opengen

# Firstly, get the current branch and the current commit message
current_branch=$(git rev-parse --abbrev-ref HEAD)
commit_message=$(git log -1 --pretty=format:"%s")
commit_hash=$(git rev-parse --short HEAD)

echo "CURRENT BRANCH:" $current_branch
echo "COMMIT MESSAGE:" $commit_message
echo "COMMIT HASH   :" $commit_hash

# If the current branch is not master and the current commit
# message does not contain [docit], then stop
if ! (grep -q "[docit]" <<< "$commit_message"); then 
echo "The commit message does not contain [docit] /exiting! bye :)";
exit 0;
fi

# Install sphinx and the RTD theme
cd $GITHUB_WORKSPACE/
pip install sphinx
pip install sphinx-rtd-theme

# Install opengen
cd open-codegen
pip install .
cd ..

# Set git username and email
git config --global user.name "github-actions"
git config --global user.email "actions@github.com"

# Checkout gh-pages and delete the folder api-dox (don't push yet)
# At the end, return to the current branch
git fetch origin gh-pages:gh-pages || :
git checkout gh-pages
git rm -r api-dox/
git commit -m "remove old api-dox files"
git checkout $current_branch

# Build the docs
rm -rf sphinx
mkdir -p sphinx
cd sphinx-dox
sphinx-apidoc -o ./source/ ../open-codegen/opengen ../open-codegen/opengen/test/
make html || :
cp -r build/html/ ../sphinx

# Push to gh-pages
cd $GITHUB_WORKSPACE/
rm -rf api-dox/
mv sphinx/ api-dox/
git checkout gh-pages
git add api-dox/
git commit -m "documentation for $commit_hash"
git push origin gh-pages || :