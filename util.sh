function get_media_info()
{
	if [[ ! -f $1 ]]
	then
		echo "$1 not found!"
		return 1
	fi

	local file=$1
	local width
	local height
	local media_info=`ffprobe $1 2>&1`
	echo "********************media info********************"
	echo "file:$file"
	filesize=`du -sh "$file" |awk '{print $1}'`
	echo "filesize:$filesize"
	local container=`echo $media_info | grep "Input" | sed -r 's/.*#0, (.*), from.*/\1/'`
	echo "container:$container"
	local duration=`echo $media_info | grep "Duration" | sed -r 's/.*Duration: (.*), start.*/\1/'`
	echo "duration:$duration"
	videoCodec=`echo $media_info | grep "Video:" | sed -r 's/.*Video: +([^ ]+).*/\1/'`
	echo "videoCodec:$videoCodec"
	videoBitrate=`echo $media_info | sed -r 's/.*bitrate: ([0-9]* kb\/s).*/\1/'`
	echo "videoBitrate:$videoBitrate"
	width=`ffprobe -v quiet -show_streams $file |grep "^width=" |cut -d '=' -f 2`
	echo "width:$width"
	height=`ffprobe -v quiet -show_streams $file |grep "^height=" |cut -d '=' -f 2`
	echo "height:$height"
	resolution="$width"x"$height"
	echo "resolution:$resolution"
	framerate=`echo $media_info | sed -r 's/.*, (.*) fps.*/\1/'`
	echo "framerate:$framerate"
	audiocodec=`echo $media_info | sed -r 's/.*Audio: +([^ ]+).*/\1/'`
	echo "audiocodec:$audiocodec"
	echo "********************media info********************"
	return 0
}

################################################test#####################################################
get_media_info /mnt/hgfs/shell/demon.mp4