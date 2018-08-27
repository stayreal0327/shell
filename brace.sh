file_full_name="/data/a/b/c/d/te*st.m3u8"
echo "original fille full path: $file_full_name";

#截断功能

#remove first / from left and its left
echo ${file_full_name#*/};

#remove last / from left and its left
echo ${file_full_name##*/};

#remove first / from right and its right
echo ${file_full_name%/*};

#remove last / from right and its right
echo ${file_full_name%%/*};

#${varible:n1:n2}:截取变量varible从n1开始的n2个字符，组成一个子字符串
echo ${file_full_name:0:5};

#从左边第几个字符开始，一直到结束。
echo ${file_full_name:7};

#从右边第几个字符开始，及字符的个数
#注：（左边的第一个字符是用 0 表示，右边的第一个字符用 0-1 表示）
echo ${file_full_name:0-7:3};

echo ${file_full_name:0-1};
echo "hello haha"

#replace first / with |
echo ${file_full_name/\//|};

#replace all / with |
echo ${file_full_name//\//|};

file=
echo ${file:-my.file.txt}
<<!
${file-my.file.txt}: 若$file没有设定，则使用my.file.txt作返回值。(空值及非空值时不作处理)
${file:-my.file.txt}:若$file没有设定或为空值，则使用my.file.txt作返回值。(非空值时不作处理)
${file+my.file.txt}: 若$file设为空值或非空值，均使用my.file.txt作返回值。(没设定时不作处理)
${file:+my.file.txt}:若$file为非空值，则使用my.file.txt作返回值。(没设定及空值时不作处理)
${file=my.file.txt}: 若$file没设定，则使用my.file.txt作返回值，同时将$file 赋值为 my.file.txt。(空值及非空值时不作处理)
${file:=my.file.txt}:若$file没设定或为空值，则使用my.file.txt作返回值，同时将 $file 赋值为 my.file.txt。(非空值时不作处理)
${file?my.file.txt}: 若$file没设定，则将my.file.txt输出至 STDERR。(空值及非空值时不作处理)
${file:?my.file.txt}:若$file没设定或为空值，则将my.file.txt输出至STDERR。(非空值时不作处理)
!

#长度
echo ${#file_full_name}

#数组运算
A=(a b c def)

echo ${A[*]}
echo ${A[@]}
echo ${A[3]}
echo ${#A[*]}
echo ${#A[3]}
