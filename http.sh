#!/bin/bash

function url_encode()
{
    # urlencode <string>
    local length="${#1}"
    local c

    encoded_value=""
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        local tmp=""
        case $c in
            [a-zA-Z0-9.~_-])
                tmp=`printf "$c"`
                encoded_value=$encoded_value$tmp ;;
            *) 
                tmp=`printf '%%%02X' "'$c"` #注意这里必须要"'$c"，加单引号，否则把c当单纯数字
                encoded_value=$encoded_value$tmp
        esac
    done
    echo $encoded_value
}
 

url_encode "http://www.stayrea.com/haha?user=+11& pwd=123U"
