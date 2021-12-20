#!/bin/bash

if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
clear
    cat <<EOF

RUN IN VERBOSE. DO NOT DELETE ANYTHING
./deletePartition.sh "3 years ago" "history"
./deletePartition.sh "180 days ago" "history_uint"
./deletePartition.sh "3 months ago" "history_str"

DELETE PARTITIONS:
./deletePartition.sh "180 days ago" "history_uint" yes
   
EOF
    exit 1
fi


# define inputs
AGO=$1
TABLE=$2

# if 3rd argument is is empty then set delete to 'no'
if [ -z "$3" ]; then
DELETE_NOW="no"
else
DELETE_NOW="$3"
fi


# set unixtime
THRESHOLD=$(date +%s -d "$AGO")
THRESHOLD_HUMAN=$(date -d "$AGO")

echo
echo "                 Threshold: $THRESHOLD"
echo "  Human readable threshold: $THRESHOLD_HUMAN"
echo "Flag to execute the delete: $DELETE_NOW"
echo "         Maintaining table: $TABLE"
echo

# list all partition names per table
# it looks for a table name + another '_' and numbers. This is required because a patern 'history' is a part of 'history_uin', ..
PARTITIONS=$(
psql \
--username=postgres \
--no-align \
--tuples-only \
--dbname=zabbix \
--command="
SELECT table_name FROM information_schema.tables WHERE table_schema = 'partitions'
" | grep "^$(echo $TABLE)_[0-9]\+" | sort | uniq
)

# go through every partition name and
# 1) convert yyyymmdd to unixtimestamp
# 2) compart unixtimestamp with the threshold
echo "$PARTITIONS" | \
while IFS= read -r NAME_OF_PARTITION
do {

# calculate unixtime for partition
YYYYMMDD=$(echo $NAME_OF_PARTITION | sed 's|^.*_||g')
YEAR=$(echo $YYYYMMDD | grep -Eo "^[0-9]{4}")
MONTH=$(echo $YYYYMMDD | sed 's|^....||' | grep -Eo "^[0-9]{2}")
DAY=$(echo $YYYYMMDD | sed 's|^......||' | grep -Eo "^[0-9]{2}")

# calculate the unixtime
# history tables are using pattern 'yyyymmdd', trend tables are using pattern 'yyyymm'
echo "$TABLE" | grep trends > /dev/null
if [ $? -eq 0 ]; then
UNIXTIME_OF_PARTITION=$(date --date="$YEAR-$MONTH-01 00:00:00" +"%s")
else
UNIXTIME_OF_PARTITION=$(date --date="$YEAR-$MONTH-$DAY 00:00:00" +"%s")
fi


if [ $UNIXTIME_OF_PARTITION -lt $THRESHOLD ]; then
echo "partition $NAME_OF_PARTITION will be deleted"

# check if delete=yes
if [ "$DELETE_NOW" = "yes" ]; then
echo executing command

echo psql --username=postgres --dbname=zabbix --command="DROP TABLE IF EXISTS partitions.$NAME_OF_PARTITION"
psql --username=postgres --dbname=zabbix --command="DROP TABLE IF EXISTS partitions.$NAME_OF_PARTITION"

fi

fi

} done

