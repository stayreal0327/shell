#!/bin/bash

#sed [options] 'command' file(s)
#sed [options] -f scriptfile file(s)

#-n, --quiet, --silent                     suppress automatic printing of pattern space
#-i[SUFFIX], --in-place[=SUFFIX]           edit files in place (makes backup if SUFFIX supplied)
#-r, --regexp-extended

#替换文本中的字符串
sed 's/book/books/' sed.test

#替换所有匹配
sed 's/book/books/g' sed.test

#-n选项和p命令一起使用表示只打印那些发生替换的行
sed -n 's/test/TEST/p' sed.test

#直接编辑文件选项-i
sed -i 's/book/books/g' sed.test

#当需要从第N处匹配开始替换时，可以使用 /Ng
echo sksksksksksk | sed 's/sk/SK/2g'

#以上命令中字符 / 在sed中作为定界符使用，也可以使用任意的定界符, 定界符出现在样式内部时，需要进行转义
sed 's|test|TEXT|g'

#删除空白行
sed '/^$/d' set.test

#删除文件的第2行
sed '2d' file

删除文件的第2行到末尾所有行
sed '2,$d' file

删除文件最后一行
sed '$d' file

#删除文件中所有开头是test的行：
sed '/^test/d' file

#正则表达式 \w\+ 匹配每一个单词，使用 [&] 替换它，& 对应于之前所匹配到的单词
echo this is a test line | sed 's/\w\+/[&]/g'
#和这个效果一样
echo this is a test line | sed 's/\(\w\+\)/[\1]/g' sed.test

#sed表达式可以使用单引号来引用，但是如果表达式内部包含变量字符串，就需要使用双引号。
test=hello
echo hello WORLD | sed "s/$test/HELLO/"

#所有在模板test和check所确定的范围内的行都被打印
sed -n '/test/,/check/p' file

#打印从5行开始到第一个包含以test开始的行之间的所有行
sed -n '5,/^test/p' file

#对于模板test和west之间的行，每行的末尾用字符串aaa bbb替换
sed '/test/,/west/s/$/aaa bbb/' file

#第2到3行每行的末尾用字符串aaa bbb替换
sed '2,3s/$/aaa bbb/' file

#上面sed表达式的第一条命令删除1至5行，第二条命令用check替换test。命令的执行顺序对结果有影响
sed -e '1,5d' -e 's/test/check/' file

#file里的内容被读进来，显示在与test匹配的行后面，如果匹配多行，则file的内容将显示在所有匹配行的下面
sed '/test/r file' filename

#在example中所有包含test的行都被写入file里
sed -n '/test/w file' example

#将 this is a test line 追加到 以test 开头的行后面
sed '/^test/a\this is a test line' file

#在 test.conf 文件第2行之后插入 this is a test line
sed -i '2a\this is a test line' test.conf

#将 this is a test line 追加到以test开头的行前面：
sed '/^test/i\this is a test line' file

#如果test被匹配，则移动到匹配行的下一行，替换这一行的aa，变为bb，并打印该行，然后继续
sed '/test/{ n; s/aa/bb/; }' file

#把1~10行内所有abcde转变为大写，注意，正则表达式元字符不能使用这个命令
sed '1,10y/abcde/ABCDE/' file

#打印完第10行后，退出sed
sed '10q' file

#在这个例子中就是追加到最后一行。简单来说，任何包含test的行都被复制并追加到该文件的末尾。
sed -e '/test/h' -e '$G' file

#表示互换模板块中的文本和缓冲区中的文本
sed -e '/test/h' -e '/check/x' file


sed -n 'p;n' test.txt  #奇数行
sed -n 'n;p' test.txt  #偶数行
sed -n '1~2p' test.txt  #奇数行
sed -n '2~2p' test.txt  #偶数行

#打印匹配字符串的下一行
grep -A 1 SCC URFILE
sed -n '/SCC/{n;p}' URFILE
awk '/SCC/{getline; print}' URFILE