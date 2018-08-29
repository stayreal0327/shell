#!/bin/bash

#通过使用tr，您可以非常容易地实现 sed 的许多最基本功能。您可以将 tr 看作为 sed的（极其）简化的变体：它可以用一个字符来替换另一个字符，或者可以完全除去一些字符。您也可以用它来除去重复字符。这就是所有 tr所能够做的。 

cat file | tr "abc" "xyz" > new_file #【注意】这里，凡是在file中出现的"a"字母，都替换成"x"字母，"b"字母替换为"y"字母，"c"字母替换为"z"字母。而不是将字符串"abc"替换为字符串"xyz"。

cat file | tr [a-z] [A-Z] > new_file # 小写 --> 大写）

cat file | tr -d "Snail" > new_file #【注意】这里，凡是在file文件中出现的'S','n','a','i','l'字符都会被删除！而不是紧紧删除出现的"Snail”字符串。

cat file | tr -s "\n" > new_file #删除空行

#删除Windows文件“造成”的'^M'字符
cat file | tr -s "\r" "\n" > new_file #注意】这里-s后面是两个参数"\r"和"\n"，用后者替换前者
#or
cat file | tr -d "\r" > new_file

