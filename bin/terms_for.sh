#! /bin/bash

STATS_FILE=$1
TERMS_FILE=$2
PREFIX="data/temp/terms_"
SUFFIX=".json"
MONTH=${TERMS_FILE#"$PREFIX"}
MONTH=${MONTH%"$SUFFIX"}

cat $STATS_FILE | jq  '.stats.months."'$MONTH'".terms | keys' > data/temp/terms_$MONTH.json