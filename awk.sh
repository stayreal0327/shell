#!/bin/bash

#awk [-F|-f|-v] ‘BEGIN{} //{command1; command2} END{}’ file
awk '{print $1}'  /etc/passwd;
awk -F":" '{print $1}'  /etc/passwd 

awk  -F: '{print $1,$3,$6}' OFS="\t" /etc/passwd 
awk 'BEGIN{X=0} /^$/{ X+=1 } END{print "I find",X,"blank lines."}' awk.sh
ls -l|awk 'BEGIN{sum=0} !/^d/{sum+=$5} END{print "total size is",sum}' 
awk -F":" '{print $1}'  /etc/passwd
awk -F":" '{print $1 $3}'  /etc/passwd                      # //$1与$3相连输出，不分隔
awk -F":" '{print $1,$3}'  /etc/passwd                      # //多了一个逗号，$1与$3使用空格分隔
awk -F":" '{print "Username:" $1 "\t\t Uid:" $3 }' /etc/passwd       //自定义输出
awk -F: '{print NF}' /etc/passwd                                //显示每行有多少字段
awk -F: '{print $NF}' /etc/passwd                              //将每行第NF个字段的值打印出来
 awk -F: 'NF==4 {print }' /etc/passwd                       //显示只有4个字段的行
awk -F: 'NF>2{print $0}' /etc/passwd                       //显示每行字段数量大于2的行
awk '{print NR,$0}' /etc/passwd                                 //输出每行的行号
awk -F: '{print NR,NF,$NF,"\t",$0}' /etc/passwd      //依次打印行号，字段数，最后字段值，制表符，每行内容

#打印匹配到joke的下一行
awk '/joke/{getline; print}' sed.test
