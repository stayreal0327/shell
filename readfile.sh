#!/bin/bash
#for line in `cat brace.sh`
#do
# echo $line
#done

while read -r line
do
 echo $line
done < readfile.sh
