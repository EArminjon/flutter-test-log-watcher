#!/bin/bash

# The goal of this script is to read the flutter test output to check if some weird logs are present (like unwanted exceptions, missing mocks, etc.)

# The list of banned words (format = trigger:description)
bannedWords=(
"Exception:Exception detected in the output ! (If you want to test an exception, please use TestException)"
"is not a subtype of type: A missing Mocktail mock has been detected in the output !"
"No method stub was called: A missing Mocktail mock has been detected in the output !"
"is not registered inside GetIt:GetIt missing instance detected in the output !"
"Binding has not yet been initialized: You can't call api in test. Please use a Mocktail mock !"
)

# This script is equivalent to "flutter test", you can pass any arguments to it
commandLine="flutter test $*"

if command -v fvm &> /dev/null; then
  commandLine="fvm $commandLine"
fi

# Final command line
echo "$commandLine"

# Create a named pipe (FIFO) to process command output while running
pipe=$(mktemp -u)
mkfifo "$pipe"

set -o pipefail
# Using tee to display command while capturing it into a fifo pipe
$commandLine 2>&1 |tee "$pipe" &
# Capture PID of the command
command_pid=$!

# Capture all errors from outputs logs
errors=""
index=1
while IFS=$'\r\n\0$' read -r line; do
  for entry in "${bannedWords[@]}"; do
    key="${entry%%:*}"
    value="${entry##*:}"
    if grep -qw "$key" <<< "$line"; then
      prefix="  +$index: "
      spaces=$(printf '%*s' "${#prefix}" '')
      error="$prefix$line"
      errors+="$error\n${spaces}$value\n"
      ((index++))
    fi
  done
done < <(tr '\r' '\n' < "$pipe" | sed 's/[[:space:]]*$//')

# Wait for the command to finish
wait "$command_pid"
# Capture the actual exit status
status="$?"

# Close the FIFO
rm "$pipe"
set +o pipefail

# Determine the final exit status and display errors if any
if [ -n "$errors" ]; then
  echo "Test output log contain some banned words !"
  echo -e "$errors"
  exit 1
elif [ "$status" -ne 0 ]; then
  echo "Command exited with error status: $status"
  exit "$status"
else
  echo "Command succeeded without banned words."
  exit 0
fi
