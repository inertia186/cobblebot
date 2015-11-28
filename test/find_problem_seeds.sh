while :
do
  HELL_ENABLED=tru rake test
  if [ $! -eq 0 ]; then
    echo Problem on last seed \($!\).
    exit
  else
    echo No problem on last seed \($!\).
  fi
done