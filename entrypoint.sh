#!/bin/sh -l

# The path to the SSH directory
SSHPATH="$HOME/.ssh"

# Create the SSH directory and a known_hosts file for our connection
mkdir $SSHPATH
touch $SSHPATH/known_hosts

# Send the supplied key to the SSH directory in the deploy_key file
echo "$INPUT_KEY" > "$SSHPATH/deploy_key"

# Apply the correct permissions to the SSH directory
chmod 700 "$SSHPATH"
chmod 600 "$SSHPATH/known_hosts"
chmod 600 "$SSHPATH/deploy_key"

# If INPUT_EVENT is closed, we want to delete the sandbox
if [[ $INPUT_EVENT = "closed" ]]; then
  COMMAND="php artisan sandbox:triage $INPUT_APP_NAME $INPUT_PR_NUMBER"
else
  # Construct the sandbox creation command
  COMMAND="php artisan sandbox:create $INPUT_APP_NAME $INPUT_PR_NUMBER --repo=$GITHUB_REPOSITORY --branch=$GITHUB_HEAD_REF"

  # Conditionally add the optional parameters
  [[ ! -z "$INPUT_PHP_VERSION" ]] && COMMAND="${COMMAND} --php=$INPUT_PHP_VERSION"
  [[ ! -z "$INPUT_DOC_ROOT" ]] && COMMAND="${COMMAND} --doc_root=$INPUT_DOC_ROOT"
  [[ -z "$INPUT_DISABLE_SSL" = "true" ]] && COMMAND="${COMMAND} --disable-ssl"

  # Append the aliases
  for domain in $INPUT_ALIASES; do
    COMMAND="${COMMAND} --alias=$domain"
  done
fi

# Create the shell script
cat > $HOME/shell.sh <<- EOM
cd $INPUT_PATH
$COMMAND
exit
EOM

# Display the shell script we're going to run
cat $HOME/shell.sh

# Connect to the server and run the command
sh -c "ssh -tt -i $SSHPATH/deploy_key -o StrictHostKeyChecking=no ${INPUT_USER}@${INPUT_HOST} < $HOME/shell.sh"
