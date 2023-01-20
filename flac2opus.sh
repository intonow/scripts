#!/bin/bash

# this script simply copies every file and folder except for .flac files who are transcoded to opus
# all the metadata and files that were is the original folder are copied as they were
# ( reminder : please do not transcode lossy audio to lossy audio ! )

# TODO :
# using the file utility would be better than the end of the name to detect the file type.
# using a function is kinda useless ?

# be extremely wary of spaces with square/test brackets 

if [ -e "~/.flac2opus.temp" ] ; then
	script=$(cat ~/.flac2opus.temp)
else
	[ -f "~/.flac2opus.temp" ] 
	script="$0"
	echo "$script" > ~/.flac2opus.temp
fi

init_dir="$(pwd)"
dest_dir="$1"


navigate() {
	for file_name in *
	do
		dest_path="$dest_dir"/"$file_name"

		if [ -f "$dest_path" ] || [ -f "${dest_path%.*}.opus" ]; then
			echo "$dest_path already exists"
		else
			file_ext=${file_name: -4}
			file_path="$init_dir"/"$file_name"
			copy_transcode
		fi
	done
}

copy_transcode() {
	if [ -f "$file_path" ] && [ "$file_ext" = "flac" ]
	then
		opusenc "$file_path" "${dest_path%.*}.opus"
		echo "file $file_name converted"
		echo " "

	elif [ -d "$file_path" ]
	then
		[ -d "$dest_path" ] || mkdir "$dest_path"
		echo "〜〜〜〜〜〜"
		echo "entering into the folder $file_name" && cd "$file_path"
		echo " "
		"$script" "$dest_path" 
		cd "$init_dir"

	else
		cp "$file_path" "$dest_path"
		echo "〜〜〜〜〜〜"
		echo "copied $file_name"
		echo " "
	fi
}

navigate
