#/bin/bash

run_cmd() {
  # $1 is the cmd to run
  # $2 is the expected error code

  output=`$1`
  exit_code=$?
  if [ $exit_code -ne $2 ]; then
    printf "failed.\n"
    printf "  - exit code: $exit_code (expected $2)\n"
    printf "  - command: $1\n"
    printf "  - output: $output\n\n"
    exit
  fi
}

test_file() {
  # $1 : is the file to test
  # $2 : expected folding exit code
  # $3 : expected unfolding exit code
  # $4 : null or maxcol for folding

  printf "testing $1..."

  if [ -z "$4" ]; then
    command="../fold-artwork.sh -d -i $1 -o $1.folded 2>&1"
  else
    command="../fold-artwork.sh -d -c $4 -i $1 -o $1.folded 2>&1"
  fi
  expected_exit_code=$2
  run_cmd "$command" $expected_exit_code
  if [ $expected_exit_code -eq 1 ]; then
    printf "okay.\n"
    return
  fi

  command="../fold-artwork.sh -d -r -i $1.folded -o $1.folded.unfolded 2>&1"
  expected_exit_code=$3
  run_cmd "$command" $expected_exit_code

  command="diff -q $1 $1.folded.unfolded"
  expected_exit_code=0
  run_cmd "$command" $expected_exit_code

  printf "okay.\n"
  rm $1.folded*
}

main() {
  echo
  test_file contains-tab.txt         1
  test_file already-exists.txt       1
  test_file folding-needed.txt       0   0
  test_file nofold-needed.txt      255 255
  test_file nofold-needed.txt        1   x  67
  test_file nofold-needed-again.txt  0   0  67
  echo
}

main "$@"

