#for line in `cat brace.sh`
#do
# echo $line
#done

aaaabbbbccdd

while read -r line
do
 echo $line
done < readfile.sh
