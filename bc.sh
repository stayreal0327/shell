#!/bin/bash

#bc命令是一种支持任意精度的交互执行的计算器语言。bash内置了对整数四则运算的支持，但是并不支持浮点运算，而bc命令可以很方便的进行浮点运算，当然整数运算也不再话下


echo "1.212*3" | bc 

#设定小数精度（数值范围），参数scale=2是将bc输出结果的小数位设置为2位。
echo "scale=2;3/8" | bc

#这是用bc将十进制转换成二进制
abc=192
echo "obase=2;$abc" | bc

echo "10^10" | bc
echo "sqrt(100)" | bc