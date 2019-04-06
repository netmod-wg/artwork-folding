#!/bin/bash --posix   # must be `bash` (not `sh`)

print_usage() {
  echo
  echo "Folds the text file, only if needed, at the specified"
  echo "column, according to BCP XX."
  echo
  echo "Usage: $0 [-s <strategy>] [-c <col>] [-r] -i <infile>"
  echo "                                              -o <outfile>"
  echo
  echo "  -s: strategy to use, '1' or '2' (default: try 1, else 2)"
  echo "  -c: column to fold on (default: 69)"
  echo "  -r: reverses the operation"
  echo "  -i: the input filename"
  echo "  -o: the output filename"
  echo "  -d: show debug messages"
  echo "  -h: show this message"
  echo
  echo "Exit status code: zero on success, non-zero otherwise."
  echo
}

# global vars, do not edit
strategy=0 # auto
debug=0
reversed=0
infile=""
outfile=""
maxcol=69  # default, may be overridden by param
hdr_txt_1="NOTE: '\\' line wrapping per BCP XX (RFC XXXX)"
hdr_txt_2="NOTE: '\\\\' line wrapping per BCP XX (RFC XXXX)"
equal_chars="=============================================="
space_chars="                                              "

fold_it_1() {
  # ensure input file doesn't contain the fold-sequence already
  pcregrep -M  "\\\\\n" $infile >> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo
    echo "Error1: infile $infile has a line ending with a '\\'"
    echo "character. This file cannot be folded."
    echo
    return 1
  fi

  # stash some vars
  testcol=`expr "$maxcol" + 1`
  foldcol=`expr "$maxcol" - 1` # for the inserted '\' char

  # ensure input file doesn't contain whitespace on the fold column
  grep "^.\{$foldcol\} " $infile >> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo
    echo "Error: infile has a space character occuring after the"
    echo "folding column. This file cannot be folded."
    echo
    return 1
  fi

  # center header text
  length=`expr ${#hdr_txt_1} + 2`
  left_sp=`expr \( "$maxcol" - "$length" \) / 2`
  right_sp=`expr "$maxcol" - "$length" - "$left_sp"`
  header=`printf "%.*s %s %.*s" "$left_sp" "$equal_chars"\
                   "$hdr_txt_1" "$right_sp" "$equal_chars"`

  # generate outfile
  echo "$header" > $outfile
  echo "" >> $outfile
  gsed "/.\{$testcol\}/s/\(.\{$foldcol\}\)/\1\\\\\n/g"\
          < $infile >> $outfile

  return 0
}

fold_it_2() {
  # ensure input file doesn't contain the fold-sequence already
  pcregrep -M  "\\\\\n[\ ]*\\\\" $infile >> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo
    echo "Error2: infile has a line ending with a '\\' character"
    echo "followed by a '\\' character as the first non-space"
    echo "character on the next line.  This file cannot be folded."
    echo
    return 1
  fi

  # center header text
  length=`expr ${#hdr_txt_2} + 2`
  left_sp=`expr \( "$maxcol" - "$length" \) / 2`
  right_sp=`expr "$maxcol" - "$length" - "$left_sp"`
  header=`printf "%.*s %s %.*s" "$left_sp" "$equal_chars"\
                   "$hdr_txt_2" "$right_sp" "$equal_chars"`

  # fold using recursive passes ('g' used in fold_it_1 didn't work)
  if [ -z "$1" ]; then
    # init recursive env
    cp $infile /tmp/wip
  fi
  testcol=`expr "$maxcol" + 1`
  foldcol=`expr "$maxcol" - 1` # for the inserted '\' char
  gsed "/.\{$testcol\}/s/\(.\{$foldcol\}\)/\1\\\\\n\\\\/" < /tmp/wip\
        >> /tmp/wip2
  diff /tmp/wip /tmp/wip2 > /dev/null 2>&1
  if [ $? -eq 1 ]; then
    mv /tmp/wip2 /tmp/wip
    fold_it_2 "recursing"
  else
    echo "$header" > $outfile
    echo "" >> $outfile
    cat /tmp/wip2 >> $outfile
    rm /tmp/wip*
  fi
  return 0
}

fold_it() {
  # ensure input file doesn't contain a TAB
  grep $'\t' $infile >> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo
    echo "Error: infile contains a TAB character, which is not"
    echo "allowed."
    echo
    return 1
  fi

  # check if file needs folding
  testcol=`expr "$maxcol" + 1`
  grep ".\{$testcol\}" $infile >> /dev/null 2>&1
  if [ $? -ne 0 ]; then
    if [[ $debug -eq 1 ]]; then
      echo "nothing to do"
    fi
    cp $infile $outfile
    return -1
  fi

  if [[ $strategy -eq 1 ]]; then
    fold_it_1
    return $?
  fi
  if [[ $strategy -eq 2 ]]; then
    fold_it_2
    return $?
  fi
  fold_it_1
  if [ $? -ne 0 ]; then
    fold_it_2
    return $?
  fi
  return 0
}

unfold_it_1() {
  # output all but the first two lines (the header) to wip file
  awk "NR>2" $infile > /tmp/wip

  # unfold wip file
  gsed ":x; /.*\\\\$/N; s/\\\\\n[ ]*//; tx" /tmp/wip > $outfile

  # clean up and return
  rm /tmp/wip
  return 0
}

unfold_it_2() {
  # output all but the first two lines (the header) to wip file
  awk "NR>2" $infile > /tmp/wip

  # unfold wip file
  gsed ":x; /.*\\\\$/N; s/\\\\\n[ ]*\\\\//; tx" /tmp/wip > $outfile

  # clean up and return
  rm /tmp/wip
  return 0
}

unfold_it() {
  # check if file needs unfolding
  line=`head -n 1 $infile`
  result=`echo $line | fgrep "$hdr_txt_1"`
  if [ $? -eq 0 ]; then
    unfold_it_1
    return $?
  fi
  result=`echo $line | fgrep "$hdr_txt_2"`
  if [ $? -eq 0 ]; then
    unfold_it_2
    return $?
  fi
  if [[ $debug -eq 1 ]]; then
    echo "nothing to do"
  fi
  cp $infile $outfile
  return -1
}

process_input() {
  while [ "$1" != "" ]; do
    if [ "$1" == "-h" -o "$1" == "--help" ]; then
      print_usage
      exit 1
    fi
    if [ "$1" == "-d" ]; then
      debug=1
    fi
    if [ "$1" == "-s" ]; then
      strategy="$2"
      shift
    fi
    if [ "$1" == "-c" ]; then
      maxcol="$2"
      shift
    fi
    if [ "$1" == "-r" ]; then
      reversed=1
    fi
    if [ "$1" == "-i" ]; then
      infile="$2"
      shift
    fi
    if [ "$1" == "-o" ]; then
      outfile="$2"
      shift
    fi
    shift 
  done

  if [ -z "$infile" ]; then
    echo
    echo "Error: infile parameter missing (use -h for help)"
    echo
    exit 1
  fi

  if [ -z "$outfile" ]; then
    echo
    echo "Error: outfile parameter missing (use -h for help)"
    echo
    exit 1
  fi

  if [ ! -f "$infile" ]; then
    echo
    echo "Error: specified file \"$infile\" is does not exist."
    echo
    exit 1
  fi

  if [[ $strategy -eq 2 ]]; then
    min_supported=`expr ${#hdr_txt_2} + 8`
  else
    min_supported=`expr ${#hdr_txt_1} + 8`
  fi
  if [ $maxcol -lt $min_supported ]; then
    echo
    echo "Error: the folding column cannot be less than"
    echo "$min_supported."
    echo
    exit 1
  fi

  # this is only because the code otherwise runs out of equal_chars
  max_supported=`expr ${#equal_chars} + 1 + ${#hdr_txt_1} + 1\
       + ${#equal_chars}`
  if [ $maxcol -gt $max_supported ]; then
    echo
    echo "Error: the folding column cannot be more than"
    echo "$max_supported."
    echo
    exit 1
  fi
}

main() {
  if [ "$#" == "0" ]; then
     print_usage
     exit 1
  fi

  process_input $@

  if [[ $reversed -eq 0 ]]; then
    fold_it
    code=$?
  else
    unfold_it
    code=$?
  fi
  exit $code
}

main "$@"
