#!/bin/sh
path_root=$1
path_tmp=$2
down_url=$3
response_url=$4
program_id=$5
file_type=$6
is_origin=$7
need_aes_dec=$8
key_file=$9
md5=${10}
picture=${11}

if [ $# -lt 8 ];then
	echo "warning:Usage: cmd <root_path> <cache_path> <down_url> <response_url> <proid> <type> <is_origin> <is_aes_decode> <aes_key_path>" 
fi

logdir=/home/otvcloud/hls/
start_time=`date -d today +%Y%m%d%H%M%S`
log=${logdir}${start_time}_${program_id}.log

if [ ! -e $logdir ] ;then
	mkdir -p $logdir
elif [ ! -d $logdir ];then
	rm -f $logdir
	mkdir -p $logdir
fi

echo "***********************************************">>$log
echo " " >>$log
echo "path_root:$path_root" >>$log
echo "path:$path_tmp" >>$log
echo "down_url:$down_url" >>$log
echo "response_url:$response_url" >>$log
echo "program_id:$program_id" >>$log
echo "file_type:$file_type" >>$log
echo "is_origin:$is_origin" >>$log
echo "need_aes_dec:$need_aes_dec" >> $log
echo "key_file:$key_file" >> $log
echo "md5:$md5" >> $log
echo "picture:$picture" >> $log
echo " "
echo "***********************************************">>$log

function get_file_name()
{
    local c

    for((i=1; i<=${#1}; i++))
    do  
        #ith character count backwards
        c=${1:((-$i)):1}
        if [[ $c == '/' || $c == '\' ]]; then
            break
        fi  
    done

    #ith charater count backwards is / or \. find the characters after it. 
    c=${1:(( -(i-1) ))}
    echo $c
}

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
                tmp=`printf '%%%02X' "'$c"`
                encoded_value=$encoded_value$tmp
        esac
    done
    echo $encoded_value
}

function get_uri_and_pre_uri()
{
    arg=$1
    j=0 
    for((i=0; i<${#arg}; i++))
    do  
        character=${arg:i:1}
        if [ $character == '/' ]; then
            ((j++))
            if [ $j -eq 3 ]; then
                break
            fi  

            continue
        fi  
    done

    ((i++))
    ori_uri_pre=${arg:0:i}
    ori_uri=${arg:i}
}


function get_dec_key_and_value()
{
	while read line; do
		key=`echo $line | awk -F ';' '{print $1}'`
		iv=`echo $line | awk -F ';' '{print $2}'`
		export keyvalue=`echo $key | awk -F '=' '{print $2}'`
		export ivvalue=`echo $iv | awk -F '=' '{print $2}'`
		echo "key is: $keyvalue"
		echo "iv is: $ivvalue" 
    done < $key_file
}

has_download=0
firsttime=0
download_ts_datat=''
hlsmediadata=''
whole_stream_info=''

function down_ts()
{
	
	for i in $seglist
	do 
		echo "ts:$i"
		
		full=`echo $i |grep "http"|wc -l`
		
		if [ $full -eq 0 ] ; then			
			
			dst_t=$1/$i			
			dst=${dst_t%.*}.ts
			echo "$dst"
			echo $sub_url_head - $5 - $i
			ts_url_t=${sub_url_head}/$5/$i	
			ts_url=`echo $ts_url_t | tr -d '\n'`
			ts_url=`echo $ts_url | tr -d '\r'`
			
			subpath=${dst%/*}
			echo "subpath: $subpath"

			if [ ! -e $subpath ]; then
			    echo "mkdir -p $subpath"
				mkdir -p $subpath
			elif [ ! -d $subpath ]; then
			    echo "$subpath is not a dir,delete"
				echo "rm -f $subpath"
				rm -f $subpath
				echo "mkdir -p $subpath"
				mkdir -p $subpath
			fi
			
			if [ -e $dst ]; then			   
				if [ -d $dst ]; then
					echo "$dst is a dir,remove it"
					echo "rm -f $dst"
					rm -rf $dst
				else 
					echo "$dst exist,clear old cache"
				    rm -f $dst
				fi
			fi		


			for ((j = 0; j < 3; j++))	
			do
				ts_time=`date -d today +%Y%m%d%H%M%S`
				echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $dst $ts_url"
				
				if [ "$is_origin" == "1" ];then 
					curl -L -C - -s --retry 3 --retry-delay 5 -o $dst "$ts_url"
					
					if [ $? -eq 0 ] ; then
						if [ ! -e $dst ];then 
							 echo "$ts_time $dst [retry][$j]" >>$log
                                                         continue
						fi
						ts_szie=`du -lk $dst |awk '{print $1}'`
						echo "ts_szie:$ts_szie"
						if [ $ts_szie -le 8 ];then
							err_page=`cat $dst|grep "<html>"|wc -l`
							if [ $err_page -ne 0 ];then
							    echo "$ts_time $dst [retry][$j]" >>$log
							    continue
							fi
							if [ $ts_szie -eq 0 ]; then
							    echo "$ts_time $dst [retry][$j]" >>$log
							    continue
							fi 
						fi					
						
						if [ $has_download -eq 0 ];then
							echo "+++++++++++stream bitrate to get_mediainfo is  $2 --$3 --$4 --$5 --$6++++++++++">>$log
							hlsmediadata=`get_meida_file_info $dst $2 $3 $4 $5`						   		
							echo "=====$hlsmediadata======$6" >> $log
							has_download=$[has_download + 1]
						fi
						echo "$ts_time $dst [success]" >>$log
						break
					 else 
							echo "$ts_time $dst [retry][$j]" >>$log
							continue
					 fi
				    
				else 
					curl -o /dev/null -C - -s --retry 3 --retry-delay 5 "$ts_url"
					if [ $? -eq 0 ] ; then
						break
					else 
						continue
					fi
				fi
			done
			
			if [ $j -eq 3 ]; then
				echo "$ts_time $dst [faild][quit]" >>$log
				return 2;
			fi
		else 
			full_subpath=`echo $i|cut -d '/' -f 4-`
			dst_t=$1/$full_subpath
			
			dst=${dst_t%.*}.ts
			echo "$dst"
			
			ts_url=`echo $i | tr -d '\n'`
			ts_url=`echo $ts_url | tr -d '\r'`
			echo "ts_url:$ts_url"
			
			subpath=${dst%/*}
			echo "subpath: $subpath"
					
			if [ ! -e $subpath ]; then
			    echo "mkdir -p $subpath"
				mkdir -p $subpath
			elif [ ! -d $subpath ]; then
			    echo "$subpath is not a dir,delete"
				echo "rm -f $subpath"
				rm -f $subpath
				echo "mkdir -p $subpath"
				mkdir -p $subpath
			fi
			
            if [ -e $dst ]; then			   
				if [ -d $dst ]; then
					echo "$dst is a dir,remove it"
					echo "rm -f $dst"
					rm -rf $dst
				else 
					echo "$dst exist,clear old cache"
				    rm -f $dst
				fi
			fi		

			for ((j = 0; j < 3; j++))	
			do
				ts_time=`date -d today +%Y%m%d%H%M%S`
			    echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $dst $ts_url"
				
				if [ "$is_origin" == "1" ];then 		
					curl -L -C - -s --retry 3 --retry-delay 5 -o $dst "$ts_url"
					
					if [ $? -eq 0 ] ; then 
					        if [ ! -e $dst ];then 
                                                         echo "$ts_time $dst [retry][$j]" >>$log
                                                         continue
                                                fi
						ts_size=`du -lk $dst |awk '{print $1}'`
						echo "ts size :$ts_size"
						if [ $ts_szie -le 8 ];then
							err_page=`cat $dst|grep "<html>"|wc -l`
							if [ $err_page -ne 0 ];then
							    echo "$ts_time $dst [retry][$j]" >>$log
							    continue
							fi
							if [ $ts_szie -eq 0 ]; then
							    echo "$ts_time $dst [retry][$j]" >>$log
							    continue
							fi 
						fi					
						
						if [ $has_download -eq 0 ];then
							
							hlsmediadata=`get_meida_file_info $dst $2 $3`
							
							echo "=====$hlsmediadata======" >> $log
							has_download=$[has_download + 1]
						fi	
						echo "$ts_time $dst [success]" >>$log
						break
						
					else
						echo "$ts_time $dst [retry][$j]" >>$log
						continue
					fi
				else
					curl -o /dev/null -C - -s --retry 3 --retry-delay 5 "$ts_url"
					if [ $? -eq 0 ] ; then
						break
					else 
						continue
					fi
				fi
			done
			
			if [ $j -eq 3 ]; then
				echo "$ts_time $dst [faild][quit]" >>$log
				return 2;
			fi
		fi
	done
	if [ "$need_aes_dec" == "1" ]
	then
		echo "need file aes dec iv:$ivvalue $keyvalue" >> $log
		aes_dec $subpath
		if [ ! $? -eq 0 ]
		then
			return 1
		fi
	fi
}

function save_full_index_m3u8()
{
	tmp=$1.tmp
	
	for line in `cat $1`
	do
		echo $line
		full=`echo $line|grep "http://"|wc -l`

		if [ $full -eq 0 ] ;then
			newline_t=${line%\?*}
			echo $newline_t >>$tmp
		else
			newline_t=${line#*//}
			newline=${newline_t#*/}
			echo "newline:$newline"
			echo $newline>>$tmp
		fi
	done
	
	rm -f $1
	
	if [ ! $? -eq 0 ];then
	   echo "remove $1 [faild]" >>$log
	else
	   echo "remove $1 [success]" >>$log
	fi

	mv $tmp $1
	
	if [ ! $? -eq 0 ];then
	   echo "mv $tmp $1 [faild]" >>$log
	else
	   echo "mv $tmp $1 [success]" >>$log
	fi

}

function down_index_m3u8()
{
	if [ -e $tm3u8dst ];then 
		if [ -d $tm3u8dst ];then
			rm -rf $tm3u8dst
		else
			rm -f $tm3u8dst
		fi
	fi

	for ((i=0;i<3;i++))
	do   
		index_time=`date -d today +%Y%m%d%H%M%S`
		
		echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $tm3u8dst ${down_url}"
		
		curl -L -C - -s --retry 3 --retry-delay 5 -o $tm3u8dst "${down_url}"
			
		if [ $? -eq 0 ] ; then
			toptype=`cat $tm3u8dst|grep "#EXT-X-STREAM-INF" |wc -l`
			secondtype=`cat $tm3u8dst|grep "#EXTINF" |wc -l`
			full=`cat $tm3u8dst |grep "http"|wc -l` 
			
			if [ $toptype -eq 0 ] && [ $secondtype -eq 0 ] ; then
				echo "$index_time $tm3u8dst [retry] [$i]" >>$log
				continue
			elif [ $toptype -gt 0 ] ;then
				echo "$index_time $tm3u8dst [success]" >>$log
				streamlist=`cat $tm3u8dst|grep ".m3u8"`
				if [ "$is_origin" == "1" ]; then
					if [ ! $full -eq 0 ]; then
						save_full_index_m3u8 $tm3u8dst
					fi
				else 
					rm -f $tm3u8dst
				fi
				return 0
			elif [ $secondtype -gt 0 ] ;then 
				echo "$index_time $tm3u8dst [success]" >>$log
				seglist=`cat $tm3u8dst|grep ".ts"`
				if [ "$is_origin" == "1" ]; then
					if [ ! $full -eq 0 ]; then
						save_full_index_m3u8 $tm3u8dst
					fi
				else
					rm -f $tm3u8dst
				fi
				return 1;
			fi
		else
			echo "$index_time $tm3u8dst [retry] [$i]" >>$log
			continue;   
		fi
	done
	if [ $i -eq 3 ]
	then
		echo "$index_time $tm3u8dst [faild] [quit]" >>$log
		return 2;
	fi	    
}

function save_full_stream_m3u8()
{
	tmp=$1.tmp
	
	for line in `cat $1`
	do
		echo $line
		full=`echo $line|grep "http://"|wc -l`

		if [ $full -eq 0 ] ;then
			echo $line >>$tmp
		else
			newline_t=${line#*//}
			newline=${newline_t#*/}
			echo "newline:$newline"
			echo $newline>>$tmp
		fi
	done
	
	rm -f $1
	
	if [ ! $? -eq 0 ];then
	   echo "remove $1 [faild]" >>$log
	else
	   echo "remove $1 [success]" >>$log
	fi

	mv $tmp $1
	
	if [ ! $? -eq 0 ];then
	   echo "mv $tmp $1 [faild]" >>$log
	else
	   echo "mv $tmp $1 [success]" >>$log
	fi

}

function down_stream_m3u8()
{
	for i in $streamlist
	do
		i=`echo $i |tr -d '\r\n'`
		tag=`echo $i | grep "#" | wc -l`
		if [ $tag -ne 0 ];then
			continue
		fi
		echo "second m3u8 name:$i"
		full=`echo $i |grep "http"|wc -l` 
		
		if [ $full -eq 0 ] ; then
			stream_url_t=$sub_url_head/$i	
		
			have_sub=`echo $i|grep '/'|wc -l`
			if [ $have_sub -eq 0 ];then
				stream_dir=""	
			else	
			    stream_dir=${i%/*}
	    	fi	

			dst_t=${path}$i
			
			echo "dst:$dst stream_url:$stream_url"
				
			stream_url=`echo $stream_url_t | tr -d '\r'`
			stream_url=`echo $stream_url | tr -d '\n'`
		    dst=${dst_t%.*}.m3u8
			echo "changed dst:$dst stream_url:$stream_url" >>$log
			
			subpath=${dst%/*}

			
			echo "subpath: $subpath" >>$log
			
			if [ ! -e $subpath ]; then
			    echo "mkdir -p $subpath"
				mkdir -p $subpath
			else 			
			    if [ ! -d $subpath ]; then
				    echo "$subpath is not a dir,delete it"
					rm -f $subpath
					echo "mkdir -p $subpath"
					mkdir -p $subpath
				fi
			fi 
			
			for ((j = 0; j < 3; j++))	
			do	
				stream_time=`date -d today +%Y%m%d%H%M%S`
			    echo "loop start:$i"
				
				echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $dst"
				echo "${sub_url_head}/$i"
				echo "url:${sub_url_head}/$i"
				
				curl -L -C - -s --retry 3 --retry-delay 5 -o $dst "$stream_url"
				
				if [ $? -eq 0 ] ; then 
					echo "dst:$dst"
					fileduration=`cat t.txt | grep "#EXT-X-STREAM-DURATION:" | head -n 1| cut -d ':' -f 2 | cut -d ',' -f 1`
					echo "cat $dst |grep #EXTINF |wc -l"
					contain_ts=`cat $dst | grep "#EXTINF" |wc -l`
					
					echo "contain_ts:$contain_ts"
					
					if [ $contain_ts -gt 0 ]; then 
						echo "second m3u8"
						seglist=`cat $dst|grep ".ts"` 
						echo "$stream_time $dst [success]" >>$log

						if [ "$is_origin" == "1" ]; then
							full_path_ts=`cat $dst|grep "http"|wc -l` 
							if [ ! $full_path_ts -eq 0 ]; then
								save_full_stream_m3u8 $dst
							fi 
						else
							rm -f $dst
						fi
						has_download=0
						alltsduration=0
						for LINE in `cat $dst|grep "#EXTINF"`
						do
						        everysegemnt_duration=`echo $LINE |cut -d ':' -f 2 | cut -d ',' -f 1`
						        alltsduration=$(echo "$alltsduration+$everysegemnt_duration"|bc)
						       
						done
						echo "stream whole duration is $alltsduration">>$log

						echo "sub path is $subpath">>$log
						
						streamfilesize=0
					    echo "+++$subpath +++$contain_ts +++$alltsduration   ++++$streamfilesize  ++++$stream_dir" >>$log
						down_ts $subpath  $contain_ts $alltsduration $streamfilesize $stream_dir 
						if [ ! $? -eq 0 ]; then
							return 2
						else
							#重新计算下这个stream的整体的filesize大小
							streamfilesize=`du -shk $subpath | awk '{print $1}'`
							echo "stream file size is $streamfilesize">>$log
							hlsmediadata=`echo $hlsmediadata | sed  's/streamfilesize/'$streamfilesize'/g'`
							hlsmediadata=`echo $hlsmediadata | tr -d ' '`
							if [ ! $firsttime -eq 0 ]; then
								hlsmediadata=`echo "$hlsmediadata" | sed -r 's/.*<stream>(.*)<\/stream>.*/\1/'`
								whole_stream_info="$whole_stream_info<stream>$hlsmediadata</stream>"
							else
								whole_stream_info="$whole_stream_info$hlsmediadata"
								firsttime=$[firsttime + 1]
							fi
							
							echo "=========whole_stream_info======="
							echo $whole_stream_info
							echo "================================="
							break
						fi
					else 
					   echo "$stream_time $dst [retry][$j]" >>$log
					   continue
					fi
				else 
					echo "$stream_time $dst [retry][$j]" >>$log
					continue
				fi
			done
			
			if [ $j -eq 3 ] && [ $contain_ts -eq 0 ]; then
				echo "$stream_time $dst [faild][quit]" >>$log
				return 2;
			fi

		else 
			full_subpath=`echo $i|cut -d '/' -f 4-`
			dst_t=${path}${full_subpath}
			stream_url=`echo $i | tr -d '\r'`
			stream_url=`echo $stream_url | tr -d '\n'`			
		    dst=${dst_t%.*}.m3u8
			
			subpath=${dst%/*}
			echo "subpath: $subpath"

			if [ ! -e $subpath ]; then
				mkdir -p $subpath
			else 			
			    if [ ! -d $subpath ]; then
					rm -f $subpath
					mkdir -p $subpath
				fi
			fi 
			
			for ((j = 0; j < 3; j++))	
			do	
				stream_time=`date -d today +%Y%m%d%H%M%S`
			    echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $dst $stream_url"
				curl -L -C - -s --retry 3 --retry-delay 5 -o $dst "$stream_url"
				
				if [ $? -eq 0 ] ; then 
					contain_ts=`cat $dst | grep "#EXTINF" |wc -l`
					
					if [ $contain_ts -gt 0 ]; then 
						$seglist=`cat $dst|grep ".ts"` 
						echo "$stream_time $dst [success]" >>$log

						if [ "$is_origin" == "1" ]; then
						   full_path_ts=`cat $dst|grep "http"|wc-l` 
						   
						   if [ ! $full_path_ts -eq 0 ]; then
								save_full_stream_m3u8 $dst
						   fi 
						else 
							rm -f $dst
						fi
						
						has_download=0
						down_ts $subpath ""
						downloadtsdatat=`echo $downloadtsdatat | tr -d ' '`
						if [ ! $firsttime -eq 0 ]; then
							downloadtsdatat=`echo "$downloadtsdatat" | sed -r 's/.*<stream>(.*)<\/stream>.*/\1/'`
							whole_stream_info="$whole_stream_info<stream>$downloadtsdatat</stream>"
						else
							whole_stream_info="$whole_stream_info$downloadtsdatat"
							firsttime=$[firsttime + 1]
						fi
						
						echo "=======whole_stream_info=========="
						echo $whole_stream_info
						echo "==================================" 
						 
												 
						if [ $? -eq 0 ]; then
							break
						else 
							return 2
						fi
						break
					else 
						echo "$stream_time $dst [retry][$j]" >>$log
						continue
					fi
				else   
					echo "$stream_time $dst [retry][$j]" >>$log
					continue
				fi
			done
			
			if [ $j -eq 3 ] && [ $contain_ts -eq 0 ]; then
				echo "$stream_time $dst [faild][quit]" >>$log
				return 2;
			fi
			fi
	done          		
}


function response_cms()
{
  for ((j = 0; j < 3; j++))	
  do
  	response_time=`date -d today +%Y%m%d%H%M%S`
	curl --retry 3 --retry-delay 5 -d "{\"id\":\"$1\", \"result\":\"$2\",\"mediainfo\":\"$3\",\"picture\":\"$4\",\"errno\":\"$5\"}"    "http://$response_url"

	if [ $? -eq 0 ] ; then 
		echo "$response_time response cms [success]" >>$log
		exit 0
	else 
		echo "$response_time response cms [retry] [$j]" >>$log
		continue
	fi
  done
  
  if [ $j -eq 3 ] && [ $? -ne 0 ]; then
	echo "$response_time response cms [faild] [quit]" >>$log
	exit 1;
  fi	

}


function hls_download()
{			
	local tmp_url

	tmp_url=`echo $down_url |tr -d ' '`
	top_m3u8_name=`get_file_name "$tmp_url"`
	top_m3u8_name=${top_m3u8_name%\?*}

	echo "top_m3u8_name:$top_m3u8_name"

	sub_url_head=${down_url%/*}
	echo "sub_url_head:$sub_url_head"

	tm3u8dst=${path}${top_m3u8_name}
	echo "top m3u8 dst:$tm3u8dst" >> log

	#pre_uri:http://ip:port/, uri:a/b/c/d.mp4
	get_uri_and_pre_uri "$down_url"
	url_encode "$ori_uri"
	down_url="$ori_uri_pre""$encoded_value"

	down_index_m3u8
	result=$?
	if [ $result -eq 0 ]; then
		down_stream_m3u8
		if [ $? -eq 0 ]; then
			hlsmediadata=`echo $hlsmediadata | tr -d ' '`
			echo "hlsmediadata is $hlsmediadata" >>$log
			whole_stream_info="<info>$whole_stream_info</info>"
			echo $whole_stream_info >>$log
			response_cms $program_id 1 $whole_stream_info
		else 
			response_cms $program_id 0
		fi
	elif [ $result -eq 1 ] ;then
		num_in_playlist=`cat $tm3u8dst | grep "#EXTINF" |wc -l`
		segment_duration=0
		for LINE in `cat $tm3u8dst | grep "#EXTINF"`
		do
			duration_t=`echo $LINE|cut -d ':' -f 2 | cut -d ',' -f 1`				
			segment_duration=$(echo "$segment_duration + $duration_t"|bc)	   			
		done
		
		down_ts $path  $num_in_playlist $segment_duration 
		result=$?
		if [ $result -eq 0 ]; then
			hlsmediadata="<info>$hlsmediadata</info>"
			hlsmediadata=`echo $hlsmediadata | tr -d ' '`			
			#重新计算下这个stream的整体的filesize大小
			streamfilesize=`du -shk $path | awk '{print $1}'`
			hlsmediadata=`echo $hlsmediadata | sed  's/streamfilesize/'$streamfilesize'/g'`		
			echo "$whole_stream_info" >>$log

			response_cms $program_id 1 $hlsmediadata
		else 
			 response_cms $program_id 0
		fi
	else 
		response_cms $program_id 0
	fi	
	
}
function get_zip_meidainfo()
{
		local stream_btr
        first_stream=1
        zipwholesize=`du -shk .|awk '{print $1}'`
        echo "zip whole size is $zipwholesize">>$log
      
		cur_m3u8=`ls ./*.m3u8`
		if [ "a$cur_m3u8" == "a" ];then
			zipfiletotalsize=$zipwholesize
			return
		fi
		
		top=`cat $cur_m3u8|grep "#EXT-X-STREAM-INF" |wc -l`
		second=`cat $cur_m3u8|grep "#EXTINF" |wc -l`
		
		if [ $top -gt 0 ];then 
			second_m3u8=`cat $cur_m3u8|grep ".m3u8"`				
		else
			second_m3u8=`ls ./*.m3u8`	
		fi


		for m3u8 in $second_m3u8
		do
				m3u8=`echo $m3u8 |tr -d '\r\n'`
				second_dir=${m3u8%%/*}
				if [[ "$second_dir" == "$m3u8" || "$second_dir" == "" ]];then
					second_dir="./"
				else
					stream_btr=$second_dir
				fi

				echo "seconde m3u8 dir is $second_dir" >> $log
			   
				ts_path=`cat $m3u8|grep ".ts"|head -n 1`
				ts_dir=${ts_path%/*}
				if [[ "$ts_path" == "$ts_dir" || "$ts_dir" == "" ]];then
					ts_dir=$second_dir
				else 
					ts_dir=$second_dir/$ts_dir
				fi
				
			
				echo "dir m3u8 is $m3u8" >> $log
				filesize=`du -lk --max-depth=0 $second_dir  |awk '{print $1}'`
				echo "file size is $filesize" >> $log
				 
				#计算hls文件的总大小 
				fileduration=0
				array=`cat $m3u8 | grep "#EXTINF:"`
				for ele in ${array[@]};do
						tmp=${ele##*:}
						tmp=${tmp%%,*}
						fileduration=$(echo "$fileduration+$tmp"|bc)
				done
				fileduration=$(echo "$fileduration*1000"|bc)
				fileduration=${fileduration%%.*}
				#######################################
			  
				#fileduration=`cat $m3u8 | grep "#EXT-X-STREAM-DURATION:" | head -n 1| cut -d ':' -f 2 | cut -d ',' -f 1`
				echo "fileduration is $fileduration" >> $log
				n=`cat $m3u8|grep  "#EXTINF"| wc -l`
				duration=`grep "#EXT-X-TARGETDURATION:" $m3u8`
				duration=${duration:22}
				duration=`expr $duration \* $n`
				file=`ls $ts_dir/*.ts |grep -m1 '.'`
				echo $file

				info=`get_zip_meida_file_info $file $duration $n $fileduration $filesize $first_stream $stream_btr`
				let   first_stream=first_stream+1;
			   
				zip_response=$zip_response$info

		done
        
        zip_response="<info>$zip_response</info>"
}


function get_zip_meida_file_info()
{
	local width
	local height
        stream=`ffprobe $1 2>&1 | grep "Input"`
        #echo $stream
        stream_number=0
        for single in $stream
        do
                stream_number=${stream_number+1}
        done

        #echo "stream number is $stream_number"
        file=$1
        #filesize=`du -s $1 | awk '{print $1}'`
        #filesize=`expr $filesize \* $3`
        filesize=$5
        echo "file size in zip_media_file_info is $filesize" >> $log
        #echo $filesize
        
		first_time=$6 
		
        #duration=`ffprobe $1 2>&1 | grep "Duration"`
        #duration=`echo "$duration" | sed -r 's/.*Duration:(.*), start.*/\1/'`
        duration=$(echo "$4/1000"|bc)
        echo "arg 5 is $5 ------ duration is $duration" >> $log
        
        #echo $duration
        container=`ffprobe $1 2>&1 | grep "Input"`
        container=`echo "$container" | sed -r 's/.*#0, (.*), from.*/\1/'`
        #echo $container
        videocodec=`ffprobe $1 2>&1 | grep "Video:"`
        videocodec=`echo "$videocodec" | sed -r 's/.*Video: (.*), yuv.*/\1/'`
        #echo $videocodec
        videobitrate=`ffprobe $1 2>&1 | grep "bitrate"`
        videobitrate=`echo "$videobitrate" | sed -r 's/.*bitrate: (.*) kb.*/\1/'`
        #echo $videobitrate

	width=`ffprobe -v quiet -show_streams $1 |grep "^width=" |cut -d '=' -f 2`
	height=`ffprobe -v quiet -show_streams $1 |grep "^height=" |cut -d '=' -f 2`
	resolution="$width"x"$height"
        #echo $resolution
        framerate=`ffprobe $1 2>&1 | grep "Video:"`
        framerate=`echo "$framerate" | sed -r 's/.*, (.*) fps.*/\1/'`
        #echo $framerate
        audiocodec=`ffprobe $1 2>&1 | grep "Audio:"`
        audiocodec=`echo "$audiocodec" | sed -r 's/.*Audio: (.*) \(.*/\1/'`
        #echo $audiocodec
        audiobitrate=`ffprobe $1 2>&1 | grep "Audio:"`
        audiobitrate=`echo "$audiobitrate" | sed -r 's/.*, (.*) kb.*/\1/'`
        #echo $audiobitrate
			
		total_duration="<duration>$duration</duration>
                  <container>$container</container>"
        zip_meida_file_response="<stream>
				  <stream_bitrate>$7</stream_bitrate>
                  <filesize>$filesize</filesize>
                  <vcodec>$videocodec</vcodec>
                  <acodec>$audiocodec</acodec>
                  <bitrate>$videobitrate</bitrate>
                  <resolution>$resolution</resolution>
                  <framerate>$framerate</framerate>
                  </stream>
                  "
		if [ $first_time -eq 1 ];then
			zip_meida_file_response=$total_duration$zip_meida_file_response
		fi
        echo $zip_meida_file_response
}

function get_stream_media_info()
{
	local width
	local height
        stream=`ffprobe $1 2>&1 | grep "Input"`
        #echo $stream
        stream_number=0
        for single in $stream
        do
                stream_number=${stream_number+1}
        done

        #echo "stream number is $stream_number"
        file=$1
        #filesize=`du -sh $1 | awk '{print $1}'`
        filesize=`du -s $1 | awk '{print $1}'`
        filesize=`expr $filesize \* $2`
        
        #echo $filesize
        
        duration=`ffprobe $1 2>&1 | grep "Duration"`
        duration=`echo "$duration" | sed -r 's/.*Duration:(.*), start.*/\1/'`
        
        
        #echo $duration
        container=`ffprobe $1 2>&1 | grep "Input"`
        container=`echo "$container" | sed -r 's/.*#0, (.*), from.*/\1/'`
        #echo $container
        videocodec=`ffprobe $1 2>&1 | grep "Video:"`
        videocodec=`echo "$videocodec" | sed -r 's/.*Video: (.*), yuv.*/\1/'`
        #echo $videocodec
        videobitrate=`ffprobe $1 2>&1 | grep "bitrate"`
        videobitrate=`echo "$videobitrate" | sed -r 's/.*bitrate: (.*) kb.*/\1/'`
        #echo $videobitrate

	width=`ffprobe -v quiet -show_streams $1 |grep "^width=" |cut -d '=' -f 2`
	height=`ffprobe -v quiet -show_streams $1 |grep "^height=" |cut -d '=' -f 2`
	resolution="$width"x"$height"
        #echo $resolution
        framerate=`ffprobe $1 2>&1 | grep "Video:"`
        framerate=`echo "$framerate" | sed -r 's/.*, (.*) fps.*/\1/'`
        #echo $framerate
        audiocodec=`ffprobe $1 2>&1 | grep "Audio:"`
        audiocodec=`echo "$audiocodec" | sed -r 's/.*Audio: (.*) \(.*/\1/'`
        #echo $audiocodec
        audiobitrate=`ffprobe $1 2>&1 | grep "Audio:"`
        audiobitrate=`echo "$audiobitrate" | sed -r 's/.*, (.*) kb.*/\1/'`
        #echo $audiobitrate
        stream_media_response="<stream>
				  <stream_bitrate>$4</stream_bitrate>
        		  <filesize>$filesize</filesize>
                  <vcodec>$videocodec</vcodec>
                  <acodec>$audiocodec</acodec>
                  <bitrate>$videobitrate</bitrate>
                  <resolution>$resolution</resolution>
                  <framerate>$framerate</framerate>
                  </stream>
                  "
        echo $stream_media_response
}





function zip_download()
{

	zip_name=${down_url##*/}
	echo "zip_name:$zip_name"

	zip_dst=$path$zip_name
	echo "zip_dst:$zip_dst"
	
	echo "begin to down zip"
	
	for ((i=0;i<3;i++))
	do   
		echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $zip_dst ${down_url}"
		zip_time=`date -d today +%Y%m%d%H%M%S`
		
		if [ "$is_origin" == "1" ];then 
			curl -L -C - -s --retry 3 --retry-delay 5 -o $zip_dst "${down_url}"
			
			if [ $? -eq 0 ] ; then
				if [ ! "$md5" == "0" ];then
						curmd5=`md5sum $zip_dst| awk -F " " '{print $1}'`
						if [ ! "$curmd5" == "$md5" ];then
							download_ts_datat="0"
							
							response_cms $program_id 0 $download_ts_datat 4
						fi
				fi
				if [ ! -e $zip_dst ];then 
                                         echo "$zip_time $zip_dst [retry][$i]" >>$log
                                         continue
                                fi
				zip_szie=`du -lk $zip_dst |awk '{print $1}'`
				echo "zip_szie:$zip_szie"
				if [ $zip_szie -eq 0 ];then
					download_ts_datat="0"
					response_cms $program_id 0 $download_ts_datat 5
					return 1
				fi
				if [ "$need_aes_dec" -eq "1" ] ; then
					echo "need zip file in $path aes dec"
					aes_dec $path
					if [ ! $? -eq 0 ];then
						response_cms $program_id 0
						return 1
					fi
				fi
				
				unzip -o -d $path $zip_dst
				if [ $? -eq 0 ] ; then
					rm -f $zip_dst
					cd $path
					get_zip_meidainfo
					zip_response=`echo $zip_response | tr -d ' '`
					echo "$zip_time $zip_dst [success]" >>$log
					response_cms $program_id 1 $zip_response
				else
					rm -f $zip_dst
					echo "$zip_time $zip_dst [retry] [$i]" >>$log
					continue
				fi
				return					
			else
				echo "$zip_time $zip_dst [retry] [$i]" >>$log
				continue;   
			fi
		else
			curl -o /dev/null -C - -s --retry 3 --retry-delay 5 "${down_url}"
			if [ $? -eq 0 ] ; then
				response_cms $program_id 1
				return
			else 
				continue
			fi
		fi
	done
	
	if [ $i -eq 3 ];then
		echo "$zip_time $zip_dst [faild] [quit]" >>$log
		download_ts_datat="0"
		response_cms $program_id 0 $download_ts_datat 1
		return;
	fi	
}



function get_meida_file_info()
{
	local width
	local height
	stream=`ffprobe $1 2>&1 | grep "Input"`
	#echo $stream
	stream_number=0
	for single in $stream
    do
        stream_number=$[stream_number + 1]
		#echo $single
    done
    #echo "stream number is $stream_number">>$log
	file=$1
	filesize=$4
	
	duration=`echo $3 | awk -F "." '{print $1}'`
	stream_bitrate=$5
	
	echo $2>>$log
	echo $duration>>$log
	container=`ffprobe $1 2>&1 | grep "Input"`
	container=`echo "$container" | sed -r 's/.*#0, (.*), from.*/\1/'`
	#echo $container
	videocodec=`ffprobe $1 2>&1 | grep "Video:"`
	videocodec=`echo "$videocodec" | sed -r 's/.*Video: (.*), yuv.*/\1/'`
	#echo $videocodec
	videobitrate=`ffprobe $1 2>&1 | grep "bitrate"`
	videobitrate=`echo "$videobitrate" | sed -r 's/.*bitrate: (.*) kb.*/\1/'`
	#echo $videobitrate

	width=`ffprobe -v quiet -show_streams $1 |grep "^width=" |cut -d '=' -f 2`
	height=`ffprobe -v quiet -show_streams $1 |grep "^height=" |cut -d '=' -f 2`
	resolution="$width"x"$height"
	#echo $resolution
	framerate=`ffprobe $1 2>&1 | grep "Video:"`
	framerate=`echo "$framerate" | sed -r 's/.*, (.*) fps.*/\1/'`
	#echo $framerate
	audiocodec=`ffprobe $1 2>&1 | grep "Audio:"`
	audiocodec=`echo "$audiocodec" | sed -r 's/.*Audio: (.*) \(.*/\1/'`
	#echo $audiocodec
	response="<duration>$duration</duration>
		  <container>$container</container>
		  <stream>
			  <stream_bitrate>$stream_bitrate</stream_bitrate>
		  	  <filesize>streamfilesize</filesize>	
    		  <vcodec>$videocodec</vcodec>
                  <acodec>$audiocodec</acodec>
                  <bitrate>$videobitrate</bitrate>
                  <resolution>$resolution</resolution>
                  <framerate>$framerate</framerate>
                  </stream>
		  "
	echo $response
}

function get_tar_picture()
{
	picture=`tar -tvf  $1 | grep "jpg" | awk -F ' ' '{print $6}'`
	echo $picture|sed 's/[ ]\{1,\}/,/g'
}

function tar_download()
{
	local ts_line
	local ts_num
	local tar_m3u8
	local everysegemnt_duration
	local alltsduration=0 
	local streamfilesize=0

	other_file_name=${down_url##*/}
        other_file_name=${other_file_name%\?*}
	echo "other_file_name:$other_file_name"

	other_dst=$path$other_file_name
	echo "other_dst:$other_dst"
	
	echo "begin to down tar file"
	
	for ((i=0;i<3;i++))
	do   
		echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $other_dst ${down_url}"
		other_time=`date -d today +%Y%m%d%H%M%S`
		
		if [ "$is_origin" == "1" ];then 
			curl -L -C - -s --retry 3 --retry-delay 5 -o $other_dst "${down_url}"
			
			if [ $? -eq 0 ] ; then
				if [ ! "$md5" == "0" ];then
						curmd5=`md5sum $other_dst| awk -F " " '{print $1}'`
						if [ ! "$curmd5" == "$md5" ];then
							download_ts_datat="0"
							response_cms $program_id 0 $download_ts_datat 4
						fi
				fi
				if [ ! -e $other_dst ];then 
                                        echo "$other_time $other_dst [retry][$i]" >>$log
                                        continue
                                fi
				other_szie=`du -lk $other_dst |awk '{print $1}'`
				if [ $other_szie -gt 4 ]; then

					tar -xvf $other_dst -C $path
					ts_line=`ls $path |grep ts |head -n 1 |tr -d '\r\n'`
					ts_line=$path$ts_line

					tar_m3u8=`ls $path |grep m3u8`
					tar_m3u8=$path$tar_m3u8

					ts_num=`cat $tar_m3u8 |grep "#EXTINF" |wc -l`

					if [ $ts_num -gt 0 ]; then
						for LINE in `cat $tar_m3u8 |grep "#EXTINF"`
						do
							everysegemnt_duration=`echo $LINE |cut -d ':' -f 2 | cut -d ',' -f 1`
							alltsduration=$(echo "$alltsduration+$everysegemnt_duration"|bc)
						done
						
						streamfilesize=`du -shk $path |awk '{print $1}'`
					fi

					download_ts_datat=`get_meida_file_info $ts_line $ts_num $alltsduration $streamfilesize`
					download_ts_datat=`echo $download_ts_datat |sed 's/streamfilesize/'$streamfilesize'/g'`

					echo "$other_time $other_dst [success]" >>$log					
					if [ "$need_aes_dec" == "1" ] ; then
						echo "need other file in $path aes dec"
						aes_dec $path
						if [ ! $? -eq 0 ];then
							response_cms $program_id 0
							return 1
						fi
					fi
					pictureinfo=`get_tar_picture $other_dst`
					rm -f $other_dst
					download_ts_datat="<info>$download_ts_datat</info>"
					download_ts_datat=`echo $download_ts_datat | tr -d ' '`	
					response_cms $program_id 1 $download_ts_datat $pictureinfo  				
					return
				else 
					err_page=`cat $other_dst|grep "<html>"|wc -l`
					if [ $err_page -eq 0 ];then
						if [ $other_szie -eq 0 ];then
						    echo "$other_time $other_dst [retry][$i]" >>$log
						    continue
						else
							data=`cat $other_dst | grep "404"`
							if [ "$data" != " " ];then
							 	response_cms $program_id 0
							 	return 
							fi
						    echo "$other_time $other_dst [success]" >>$log
						    response_cms $program_id 1
						    return
						fi
					else
						echo "$other_time $other_dst [retry][$i]" >>$log
						continue
					fi
				fi
			else
				echo "$other_time $other_dst [retry] [$i]" >>$log
				continue;   
			fi
		else
			curl -o /dev/null -C - -s --retry 3 --retry-delay 5 "${down_url}"
			if [ $? -eq 0 ] ; then
				response_cms $program_id 1
				return
			else
				continue
			fi
		fi
	done
	
	if [ $i -eq 3 ];then
		echo "$other_time $other_dst [faild] [quit]" >>$log
		download_ts_datat="0"
		response_cms $program_id 0 $download_ts_datat 1
		return;
	fi	
}

function other_file_download()
{
	local filename
	local duration
	local stream_btr
	local hour
	local min
	local sec
	local tmp_url

	tmp_url=`echo $down_url |tr -d ' '`
	other_file_name=`get_file_name "$tmp_url"`
	other_file_name=${other_file_name%\?*}

	echo "other_file_name:$other_file_name"

	other_dst="$path$other_file_name"
	echo "other_dst:$other_dst"
	
	echo "begin to down other file"
	
	#pre_uri:http://ip:port/, uri:a/b/c/d.mp4
	get_uri_and_pre_uri "$down_url"
	url_encode "$ori_uri"
	down_url="$ori_uri_pre""$encoded_value"

	for ((i=0;i<3;i++))
	do   
		echo "curl -L -C - -s --retry 3 --retry-delay 5 -o $other_dst ${down_url}"
		other_time=`date -d today +%Y%m%d%H%M%S`
		
		if [ "$is_origin" == "1" ];then 
			curl -L -C - -s --retry 3 --retry-delay 5 -o "$other_dst" "${down_url}"
			
			if [ $? -eq 0 ] ; then
				if [ ! "$md5" == "0" ];then
						curmd5=`md5sum "$other_dst"| awk -F " " '{print $1}'`
						if [ ! "$curmd5" == "$md5" ];then
							download_ts_datat="0"
							response_cms $program_id 0 $download_ts_datat 4
						fi
				fi
				if [ ! -e "$other_dst" ];then
                                        echo "$other_time $other_dst [retry][$i]" >>$log
                                        continue
                                fi
				other_szie=`du -lk "$other_dst" |awk '{print $1}'`
				if [ $other_szie -gt 4 ]; then
					#get duration
					duration=`ffprobe "$other_dst" 2>&1 |grep "Duration"`
					duration=`echo $duration |sed -r 's/.*Duration: (.*)\.(.*), start.*/\1/'`
					hour=`echo $duration |cut -d ':' -f 1`
					min=`echo $duration |cut -d ':' -f 2`
					sec=`echo $duration |cut -d ':' -f 3`
					duration=$[10#$hour*3600 + 10#$min*60 + 10#$sec]

					#get stream bitrate
					filename=${other_dst##*/}

					stream_btr=`echo $filename |sed -r 's/.*_(.*)k_.*/\1/'`
					if [ $stream_btr == $filename ]; then
						#the file is not transcoded
						stream_btr=""
					fi

					#get file size
					filesize=`du -shk "$other_dst" |awk '{print $1}'`

					download_ts_datat=`get_meida_file_info "$other_dst" null $duration null $stream_btr`
					download_ts_datat=`echo $download_ts_datat |sed 's/streamfilesize/'$filesize'/g'`
					echo "$other_time $other_dst [success]" >>$log					
					if [ "$need_aes_dec" == "1" ] ; then
						echo "need other file in $path aes dec"
						aes_dec $path
						if [ ! $? -eq 0 ];then
							response_cms $program_id 0
							return 1
						fi
					fi
					download_ts_datat="<info>$download_ts_datat</info>"
					download_ts_datat=`echo $download_ts_datat | tr -d ' '`	
					response_cms $program_id 1 $download_ts_datat				
					return
				else 
					err_page=`cat "$other_dst"|grep "<html>"|wc -l`
					if [ $err_page -eq 0 ];then
						if [ $other_szie -eq 0 ];then
						    echo "$other_time $other_dst [retry][$i]" >>$log
						    continue
						else
							data=`cat "$other_dst" | grep "404"`
							if [ "$data" != " " ];then
							 	response_cms $program_id 0
							 	return 
							fi
						    echo "$other_time $other_dst [success]" >>$log
						    response_cms $program_id 1
						    return
						fi
					else
						echo "$other_time $other_dst [retry][$i]" >>$log
						continue
					fi
				fi
			else
				echo "$other_time $other_dst [retry] [$i]" >>$log
				continue;   
			fi
		else
			curl -o /dev/null -C - -s --retry 3 --retry-delay 5 "${down_url}"
			if [ $? -eq 0 ] ; then
				download_ts_datat="0"
				response_cms $program_id 0 $download_ts_datat 1
				return
			else
				continue
			fi
		fi
	done
	
	if [ $i -eq 3 ];then
		echo "$other_time $other_dst [faild] [quit]" >>$log
		download_ts_datat="0"
		response_cms $program_id 0 $download_ts_datat 1
		return;
	fi	
}

function aes_dec()
{
        rootpath=$1/     #?a?¨¹???t?¡¤??
        echo "DecFolder:$rootpath"
        for file in $1/*
        do
	        if test -f $file
	        then
	                echo $file ¨º????t
	                dec_file $file
	                if [ ! $? -eq 0 ]
	                then
	                	return 1
	                fi
	        fi
	        if test -d $file
	        then
	                echo $file ¨º?????
	        fi
        done
}

function dec_file()
{
        tmpoutfilename=$1_tmp
        echo "dec tmpfile name:$tmpoutfilename"
        echo "openssl aes-128-cbc -d -iv $ivvalue -K $keyvalue -in $1 -out $tmpoutfil
ename"
        openssl aes-128-cbc -d -iv $ivvalue -K $keyvalue -in $1 -out $tmpoutfilename
        if [ ! $? -eq 0 ]
        then
                echo "dec file:$1 error" >>$log
        else
                rm -rf $1
                if [ ! $? -eq 0 ]
                then
                        echo "delte origin file $1 error" >>$log
                        return 1
                fi
                mv $tmpoutfilename ${tmpoutfilename%_tmp}
                if [ ! $? -eq 0 ]
                then
                        echo "rename tmp file $tmpoutfilename error" >>$log
                        return 1
                fi

        fi
}



echo "**********************begin***********************"

root_last=${path_root:0-1}
echo $root_last

if [ "$root_last" == "/" ]; then
	root_path=${path_root%/*}
else 
    root_path=$path_root
fi

path_last=${path_tmp:0-1}
echo $path_last

if [ "$path_last" != "/" ]; then
	path=$root_path$path_tmp/
else
	path=$root_path$path_tmp
fi

if [ ! -e $path ] ; then
    mkdir -p $path
	if [ ! -d $path ] ; then
		rm -f $path
	    mkdir -p $path
	fi
fi

if [ "$need_aes_dec" == "1" ] ;then
	get_dec_key_and_value
fi				

if [ "$file_type" == "m3u8" ];then 
	hls_download
elif [ "$file_type" == "zip" ];then 
    zip_download
elif [ "$file_type" == "tar" ];then
	tar_download
elif [ "$file_type" == "other" ];then 
    other_file_download
fi

echo "---------------------end-----------------------"

