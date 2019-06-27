#/bin/bash

../rfcfold -s 1 -i example-1.txt -o example-1.1.txt.folded
../rfcfold -s 2 -i example-1.txt -o example-1.2.txt.folded

../rfcfold -s 1 -i example-2.txt -o example-2.1.txt.folded
../rfcfold -s 2 -i example-2.txt -o example-2.2.txt.folded

../rfcfold -r -i example-3.1.txt.folded.smart -o example-3.1.txt.folded.smart.unfolded
../rfcfold -r -i example-3.2.txt.folded.smart -o example-3.2.txt.folded.smart.unfolded
../rfcfold -s 2 -i example-3.2.txt.folded.smart.unfolded -o example-3.2.txt.folded.smart.unfolded.folded


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

command="diff -q example-3.1.txt.folded.smart.unfolded example-3.2.txt.folded.smart.unfolded"
expected_exit_code=0
run_cmd "$command" $expected_exit_code
