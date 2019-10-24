#! /bin/bash
MODULE_NAME="geth"
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
MODULE_PATH=$DIR/$MODULE_NAME

PID="$( ps -ef|grep $MODULE_PATH |grep -v grep | awk -F' ' '{print $2}' )"
if [ -z "$PID" ]; then 
    echo "process "$MODULE_PATH" not found!" 
else
    echo "killing "$MODULE_PATH" pid="$PID" ..."
    kill -9 $PID
fi
