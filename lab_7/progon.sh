for i in {1..5}; do
  echo "RUN $i"
  cat sql/bench.sql | docker exec -i db-sec-lab-7 psql -U stan -d lab_7
done
