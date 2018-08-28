#!/bin/bash  
  
for((i=1;i<=10;i++));  
    do   
    echo $(expr $i \* 3 + 1);  
done  

for i in $(seq 1 10)  
    do   
    echo $(expr $i \* 3 + 1);  
done   

  
for i in {1..10}  
   do  
   echo $(expr $i \* 3 + 1);  
done  
  
awk 'BEGIN{for(i=1; i<=10; i++) print i}'  
  

for i in `ls`;  
    do   
    echo $i is file name\! ;  
done   
  

for i in $* ;  
    do  
    echo $i is input chart\! ;  
done  
  

for i in f1 f2 f3 ;  
    do  
    echo $i is appoint ;  
done  

list="rootfs usr data data2"  
for i in $list;  
    do  
    echo $i is appoint ;  
done  

  
for file in /proc/*;  
    do  
    echo $file is file path \! ;  
done  
  
for file in $(ls *.sh)  
    do  
    echo $file is file path \! ;  
done  
