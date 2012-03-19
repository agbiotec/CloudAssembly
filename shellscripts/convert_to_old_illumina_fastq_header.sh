#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: `basename $0` {input file} {output file}"
    exit 1
fi

#cat $1 | awk '{if (NR % 4 == 1) {split($1, arr, ":"); split($2, arr2, ":"); printf "%s_%s:%s:%s:%s:%s#%s/%s (%s)\n", arr[1], arr[3], arr[4], arr[5], arr[6], arr[7], arr2[4], arr2[1], $0} else if (NR % 4 == 3){print "+"} else {print $0} }' > $2
#cat $1 | awk '{if (NR % 4 == 1) {split($1, arr, ":"); split($2, arr2, ":"); printf "%s_%s:%s:%s:%s:%s#%s/%s\n", arr[1], arr[3], arr[4], arr[5], arr[6], arr[7], arr2[4], arr2[1], $0} else if (NR % 4 == 3){print "+"} else {print $0} }' > $2
cat $1 | awk '{if (NR % 4 == 1) {split($1, arr, ":"); split($2, arr2, ":"); printf "%s_%04d_%s:%s:%s:%s:%s#%s/%s\n", arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7], arr2[4], arr2[1], $0} else if (NR % 4 == 3){print "+"} else {print $0} }' > $2
