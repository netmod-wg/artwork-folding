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
  # $1 : strategy: 1, 2  (0 for auto)
  # $2 : is the file to test
  # $3 : expected folding exit code
  # $4 : expected unfolding exit code
  # $5 : null or maxcol for folding

  printf "testing $2..."

  if [ -z "$5" ]; then
    command="../fold-artwork.sh -s $1 -d -i $2 -o $2.folded 2>&1"
  else
    command="../fold-artwork.sh -s $1 -d -c $5 -i $2 -o $2.folded 2>&1"
  fi
  expected_exit_code=$3
  run_cmd "$command" $expected_exit_code
  if [ $expected_exit_code -eq 1 ]; then
    printf "okay.\n"
    return
  fi

  command="../fold-artwork.sh -d -r -i $2.folded -o $2.folded.unfolded 2>&1"
  expected_exit_code=$4
  run_cmd "$command" $expected_exit_code

  command="diff -q $2 $2.folded.unfolded"
  expected_exit_code=0
  run_cmd "$command" $expected_exit_code

  printf "okay.\n"
  rm $2.folded*
}

main() {
  echo
  echo "starting neither tests..."
  test_file 1 neither-can-fold-it-1.txt 1
  test_file 1 neither-can-fold-it-1.txt 1
  test_file 2 neither-can-fold-it-1.txt 1
  test_file 2 neither-can-fold-it-1.txt 1
  echo
  echo "starting only-2 tests..."
  test_file 1 only-2-can-fold-it-1.txt 1
  test_file 2 only-2-can-fold-it-1.txt 0   0
  test_file 1 only-2-can-fold-it-2.txt 1
  test_file 2 only-2-can-fold-it-2.txt 0   0
  test_file 1 only-2-can-fold-it-3.txt 1
  test_file 2 only-2-can-fold-it-3.txt 0   0
  test_file 1 only-2-can-fold-it-4.txt 1
  test_file 2 only-2-can-fold-it-4.txt 0   0
  test_file 1 only-2-can-fold-it-5.txt 1
  test_file 2 only-2-can-fold-it-5.txt 0   0
  test_file 1 only-2-can-fold-it-6.txt 1
  test_file 2 only-2-can-fold-it-6.txt 0  0
  echo
  echo "starting strategy #1 tests..."
  test_file 1 contains-tab.txt         1
  test_file 1 already-exists.txt       1
  test_file 1 folding-needed.txt       0   0
  test_file 1 nofold-needed.txt      255 255
  test_file 1 nofold-needed.txt        1   x  67
  test_file 1 nofold-needed-again.txt  0   0  67
  echo
  echo "starting strategy #2 tests..."
  test_file 2 contains-tab.txt         1
  test_file 2 already-exists.txt       1
  test_file 2 folding-needed.txt       0   0
  test_file 2 nofold-needed.txt      255 255
  test_file 2 nofold-needed.txt        1   x  67
  test_file 2 nofold-needed-again.txt  0   0  67
  echo
}

main "$@"

