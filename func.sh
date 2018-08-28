#! /bin/bash

function sum()
{
  returnValue=$(( $1 + $2 ))
  return $returnValue
}

sum 22 4

echo $?

#注意，$10 不能获取第十个参数，获取第十个参数需要${10}。当n>=10时，需要使用${n}来获取参数。
funWithParam(){
    echo "传递到脚本的参数个数$#"	
    echo "以一个单字符串显示所有向脚本传递的参数$*"
    echo "脚本运行的当前进程ID号$$"
    echo "后台运行的最后一个进程的ID号$!"
    echo "与$*相同，但是使用时加引号，并在引号中返回每个参数$@"
    echo "显示Shell使用的当前选项，与set命令功能相同。$-"
    echo "显示最后命令的退出状态。0表示没有错误，其他任何值表明有错误。	$?"


    echo "第一个参数为 $1 !"
    echo "第二个参数为 $2 !"
    echo "第十个参数为 $10 !"
    echo "第十个参数为 ${10} !"
    echo "第十一个参数为 ${11} !"
    echo "参数总数有 $# 个!"
    echo "作为一个字符串输出所有参数 $* !"
}
funWithParam 1 2 3 4 5 6 7 8 9 34 73
