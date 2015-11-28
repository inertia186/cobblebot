seeds="44477 11615 44563 44688 36775 39080 14310 50190"

for seed in $seeds
do
  TESTOPTS="--verbose --seed $seed" rake test
  # Apprently, rake doesn't bother to deal with return codes.
  # if [ $! -ne 0 ]; then
  #   echo Problem on seed: $seed
  #   exit
  # fi
  echo Done with seed: $seed
done