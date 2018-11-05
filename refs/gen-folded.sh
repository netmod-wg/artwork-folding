#/bin/bash

../fold-artwork.sh -i example-1.txt -o example-1.txt.folded
../fold-artwork.sh -i example-2.txt -o example-2.txt.folded
../fold-artwork.sh -i example-3.txt -o example-3.txt.folded
../fold-artwork.sh -i example-4.txt -o example-4.txt.folded

../fold-artwork.sh -r -i example-5.txt.prefolded -o example-5.txt.prefolded.unfolded

