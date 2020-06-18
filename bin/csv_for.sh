#! /bin/bash

STATS_FILE=$1
TERMS_FILE=$2
PREFIX="data/target/daten_berlin_de.searchterms."
SUFFIX=".csv"
MONTH=${TERMS_FILE#"$PREFIX"}
MONTH=${MONTH%"$SUFFIX"}

cat $STATS_FILE | jq -r '.stats.months."'$MONTH'".terms | to_entries | map_values(.value + { term: .key }) | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' | csvcut -c term,impressions,visits,page_duration_avg,exit_rate > data/target/daten_berlin_de.searchterms.$MONTH.csv
