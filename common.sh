#!/bin/bash

#calculate md5
md5sum ./*

#caculate total size of path in bytes
du -sb

#变量声明成十进制，在变量前面加上`10#`即可
hour="10"
min="3"
ec="1"
duration=$[10#$hour*3600 + 10#$min*60 + 10#$sec]
echo duration