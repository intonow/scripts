#!/bin/sh
#
# this script aims to compress all images in folders that does not have any subfolders to a .cbz
# NOTHING ELSE. This should be pretty straightforward with the zip utility


# zip syntax :  zip [chapterXX.cbr] [files]
# zip -j ... --- does not record directiory name & path

# make zip read a list of file from stdin :
# zip [output-name] -@ < input.txt
# ( with input.txt having one path per line )

# explore : recursive until it founds a folder without folders inside

explore() {
	no_folder="true"
	for file_name in *
	do
		if [ -d "$file_name" ] ; then
			cd "$file_name"
			explore
			cd ..
			no_folder="false"
		fi
	done
	if [ "$no_folder" = "true" ] ; then
		zip -j "$(pwd).cbz" "$(pwd)"/* # does this work -> yes
	fi
}

explore
