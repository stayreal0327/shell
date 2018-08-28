# -L, --location      Follow redirects (H)
# -C, --continue-at OFFSET  Resumed transfer offset
# --retry NUM   Retry request NUM times if transient problems occur
# --retry-delay SECONDS When retrying, wait this many seconds between each
# -o, --output FILE   Write output to <file> instead of stdout
# -i, --include       Include protocol headers in the output (H/F)
# -d, --data DATA     HTTP POST data (H)
# -v, --verbose       Make the operation more talkative
# -H, --header LINE   Custom header to pass to server (H)
# -s, --silent        Silent mode. Don't output anything

#download file
curl -L -C - -s --retry 3 --retry-delay 5 -o curl.download http://www.baidu.com

#post request
curl -i -d '{"sysId":"123456","timeStamp":"2018-4-25 14:56:00","siteId":"Koo5","queryType":1,"commandType":"loadQueryReq"}' http://127.0.0.1/commonRouter -H "host:st:1stage.nokiacdnpoc.tw"

#add header
curl -v -H "Host: 2stage.nokiacdnpoc.tw" -H "range: bytes=0-7499191" http://61.220.141.89/1/33/VOD/2304010022_f/26/1/01_0003.ts

#only show headers no content
curl http://www.baidu.com -v -s -o /dev/null
