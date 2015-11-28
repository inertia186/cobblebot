seeds="44477 11615 44563 44688 36775 39080 14310 50190 24858 43509 40788"

for seed in $seeds
do
  N=1 HELL_ENABLED=true TESTOPTS="--seed $seed" rake test
  # Apprently, rake doesn't bother to deal with return codes.
  # if [ $! -ne 0 ]; then
  #   echo Problem on seed: $seed
  #   exit
  # fi
  echo Done with seed: $seed
done
