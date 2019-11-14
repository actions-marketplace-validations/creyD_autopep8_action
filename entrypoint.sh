#!/bin/sh -l

set -eu

# Function for setting up git env in the docker container (copied from https://github.com/stefanzweifel/git-auto-commit-action/blob/master/entrypoint.sh)
git_setup ( ) {
  cat <<- EOF > $HOME/.netrc
        machine github.com
        login $GITHUB_ACTOR
        password $GITHUB_TOKEN
        machine api.github.com
        login $GITHUB_ACTOR
        password $GITHUB_TOKEN
EOF
    chmod 600 $HOME/.netrc

    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Actions"
}

echo "Installing dependencies..."
pip install -q --upgrade pip
# Install dependencies
pip install -q autopep8

# Install custom project dependencies if applicable
pip install -r $INPUT_DEPENDENCIES

# Apply PEP 8
echo "Running autopep8..."
autopep8 --in-place -r .

if ! git diff --quiet
then
  echo "Commiting and pushing changes."
  # Calling method to configure the git environemnt
  git_setup
  # Switch to the actual branch
  git checkout $INPUT_BRANCH

  git add "${INPUT_FILE_PATTERN}"

  git commit -m "$INPUT_COMMIT_MESSAGE" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"}
  git push --set-upstream origin "HEAD:$INPUT_BRANCH"
else
  echo "Nothing to commit. Exiting."
fi
