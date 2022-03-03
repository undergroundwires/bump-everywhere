#!/usr/bin/env bash

# Globals
readonly ABSOLUTE_SELF_DIRECTORY=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

test_utilities::assert_equals() {
  local -r expected="$1"
  local -r actual="$2"
  local -r error_message="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "[SUCCESS] expected: $expected == actual: $actual"
    return 0
  else
    echo "[FAIL] $error_message (expected: $expected !== actual: $actual)"
    return 1
  fi
}

test_utilities::run_script() {
  local script_path="$1"

  local sut_path

  if ! sut_path=$(__get_absolute_sut_path "$script_path"); then
    echo '😢 Could not locate sut'
    return 1
  fi

  echo "Sut (\"$sut_path\"):"

  bash "$sut_path" | test_utilities::tab_indent_to_right
  local -r exit_code="${PIPESTATUS[0]}"

  if [[ "$exit_code" -ne 0 ]]; then
    echo "$script_path ended with unexpected exit code: $exit_code."
  fi

  return "$exit_code"
}

# Takes test function delegate as argument and then:
#   1. Creates a temporary directory, navigates to it
#   2. Runs the test
#   3. Cleans temporary directory, returns the test result
test_utilities::run_tests() {
  local -ra test_function_references=("$@")
  local -i total_fails=0

  for test_function_reference in "${test_function_references[@]}"; do
    if ! __run_test "$test_function_reference"; then
      ((total_fails++))
    fi
  done

  if [[ "$total_fails" -eq 0 ]]; then
    echo "🟢 All tests passed (total run: ${#test_function_references[@]})."
  else
    echo "🔴 Some tests failed (total failed/run: $total_fails/${#test_function_references[@]})."
  fi

  return "$total_fails"
}

test_utilities::tab_indent_to_right() {
  local -r input=$(</dev/stdin)
  echo "$input" | awk -v prefix='\t' '{print prefix $0}'
}

__run_test(){
  # Begin
  local -r temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'bumpeverywheretmpdir')
  echo "Test dir: \"$temp_dir\""
  if ! cd "$temp_dir"; then
      echo "😢 Could not navigate to $temp_dir"
      return 1
  fi

  # Test
  $1
  local -i -r test_exit_code="$?"
  echo "Test exit code: $test_exit_code"

  # Clean
  rm -rf "$temp_dir"
  echo "Cleaned \"$temp_dir\""
  return "$test_exit_code"
}

__get_absolute_sut_path()
{
  local -r path_from_scripts="$1"
  local -r script_dir="$ABSOLUTE_SELF_DIRECTORY/../scripts"
  local normalized
  if ! normalized=$(cd "${script_dir}" || return 1;pwd; return 0); then
    echo "Dir does not exist: ${script_dir}"
    return 1
  fi
  local -r script_path="$normalized/$path_from_scripts"
  echo "$script_path"
}
