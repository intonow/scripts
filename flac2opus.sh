#!/bin/bash

# this script simply copies every file and folder except for .flac files who are transcoded to opus
# all the metadata and files that were is the original folder are copied as they were
# ( reminder : please do not transcode lossy audio to lossy audio ! )

# TODO :
# using the file utility would be better than the end of the name to detect the file type.
# using a function is kinda useless ?


# please change it to your directory
script_dir=~/Music/0_FLAC

init_dir="$(pwd)"
dest_dir="$1"


navigate() {
	for file_name in *
	do
		file_ext=${file_name: -4}
		file_path="$init_dir"/"$file_name"
		dest_path="$dest_dir"/"$file_name"
		
		if [ "$file_ext" = "flac" ]
		then
			opusenc "$file_path" "${dest_path%.*}.opus"
			echo "file $file_name converted"

		elif [ -d "$file_path" ]
		then
			mkdir "$dest_path"
			echo "entering into the folder $file_name" && cd "$file_path"
			"$script_dir"/flac2opus.sh "$dest_path" 
			cd "$init_dir"

		else
			cp "$file_path" "$dest_path"
			echo "copied $file_name"
		fi

	done
}


navigate
