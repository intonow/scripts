#!/bin/bash
#
# VERSION 0.0.2.1 -- 2023-02-08 sss
# a script that manages your saves for you, between PCs and emulators ( linux only )
# relies on metadata for last file modification, be careful not to modify those and to use the same timezones

# this program should be paired with a cron job to be useful
# support flatpak if a $HOME/.var folder is present

# cron job setup example :
# sudo cat /ect/cron.allow [username]
# crontab -e (opens the editor)
# 5 * * * * sh [/path/to/script.sh] ## this exectutes the script automatically every 5 minutes

# it first checks the system and then compare them to the stored saves ( if there are some )
# TODO : detect arguments by content and not by number ?
# TODO : fully POSIX compliant and not reliant on bash
# TODO : complete the save paths, only works for yuzu for the time being

# check the creation date in seconds in unix time : date -r file +%s : useful for compareasons

# WARNING : this script is NOT tested properly yet

# INFO : mkdir -p allows to create the parents even if they don't exist yet
# cp -a allows to keep the metadata of the file, essential for this script
# cp -a "$dir/." "$dest_dir" allows us to copy the contents of $dir, without copying $dir itself


# this may not be the best way of doing it but it should do the job for now

mkdir -p "$HOME/Game/Save_k"
save_dir="$HOME/Game/Save_k"

# safe backup option : idk how to make this properly
# if [ "$1" = "backup" ] || [ "$1" = "true" ] ; then
# backup="true"
# fi

local_dir="$HOME/.local/share"

if [ -d "$HOME/.var"  ] ; then
	flatpak=true
	flatpak_dir="$HOME/.var/app"
else 
	flatpak=false
fi


echo "Flatpak = $flatpak"

backup="false"
mkdir -p "$save_dir/backup"

# order : 
# switch local, switch flatpak, stored switch saves,
# dolphin local, dolphin saves, citra local, citra saves, 
# melonds local

safe_copy() {
	copied_file="$1"
	overwritten_file="$2"
	mv "$overwritten_file" "$save_dir/backup/$(date +%Y-%m-%T)-$overwritten_file"
	cp -a "$copied_file" "$overwritten_file"
}


sync_both() {
	folder_local="$1"
	folder_store="$2"
	if [ ! -d "$folder_local" ] ; then
		echo "no folder_local ..."
		if [ -d "$folder_store" ] ; then
			echo "but a folder_store"
			mkdir -p "$folder_local"
			crawl_compare_copy "$folder_store" "$folder_local"
		else
			echo "and NONE OF $folder_local and $folder_store exist; can't proceed further"
		fi
	elif [ ! -d "$folder_store" ] ; then
		echo "no folder_store but a folder_local"
		mkdir -p "$folder_store"
		crawl_compare_copy "$folder_local" "$folder_store" # i don't understant why but this should work well
	else # means both exist
		echo "sync : both exist ?"
		crawl_compare_copy "$folder_local" "$folder_store"
		crawl_compare_copy "$folder_store" "$folder_local" # a sync should be done by both sides, it everything is okay in the code it should work
	fi
}

crawl_compare_copy() {
	folder_local="$1"
	folder_store="$2"
	for file in "$folder_local"/* ; do
		local_file="$file"
		store_file="$folder_store/${file##*/}" # '##' removes everything that matches the search from the begining ( unlike % and %% who does it from the end )
		# echo "loc_folder= $folder_local ; store_folder= $folder_store"
		echo "loc_file= $local_file ; store_file= $store_file"
		if [ -e "$store_file" ]; then
			if [ -d "$store_file" ] && [ -d "$local_file" ] ; then
				crawl_compare_copy "$local_file" "$store_file"
			elif [ -f "$store_file" ] ; then
				if [ $(date -r "$store_file" +%s) -gt $(date -r "$local_file" +%s) ] ; then # -gt : greater than. -le : less equal
					if [ "$backup" = "true" ] ; then
						safe_copy "$store_file" "$local_file"
					else
						cp -a "$store_file" "$local_file"
					fi
				elif [ $(date -r "$store_file" +%s) -lt $(date -r "$local_file" +%s) ] ; then # -lt : less than. -le : less equal
					if [ "$backup" = "true" ] ; then
						safe_copy "$local_file" "$store_file"
					else
						cp -a "$local_file" "$store_file"
					fi
				else
					echo "the modification date of $local_file and $store_file are identical ; we will consider that they are the same file"
				fi # as else pass will not be of any use, and no need to copy the files if they're the same
			else # store_file doesn't exist, so we copy it
				cp -a "$local_file" "$store_file"
			fi
		elif [ ! -e "$store_file" ] ; then
				cp -a "$local_file" "$store_file"
		fi
	done
}

# experiment to make things more readable ?
short_save_interface() {
	if [ -d "$1" ] ; then
	app_path="$1"
	app_local_path="$2"
	store_save_path="$3"
	sync_both "$app_path/$app_local_path" "$store_save_path/$app_local_path"
	fi
	if [ $flatpak = true ] && [ -d "$4" ] ; then
		echo "$4"
		flatpak_path="$4"
		sync_both "$flatpak_path/$app_local_path" "$local_save_path/$app_local_path"
	else
		echo "flatpak $4 does not exist"
	fi
}


sync_all_saves_main() {
	# short- yuzu
	short_save_interface "$local_dir/yuzu" "nand/user/save" "$save_dir/Switch" "$flatpak_dir/org.yuzu_emu.yuzu/data/yuzu"
	short_save_interface "$local_dir/yuzu" "nand/system/save" "$save_dir/Switch" "$flatpak_dir/org.yuzu_emu.yuzu/data/yuzu"

	# ryujinx


	# short- dolphin -- problem with this one
	short_save_interface "$local_dir/dolphin-emu" "GC" "$save_dir/GC" "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
	short_save_interface "$local_dir/dolphin-emu" "Wii" "$save_dir/Wii" "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
	short_save_interface "$local_dir/dolphin-emu" "SaveStates" "$save_dir/DolphinSaveStates" "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu"

	# nds saves : melonds --name : nds


	# 3ds saves : citra --name : n3ds


	# gb/gba saves : mgba --name : ngb


	# wiiu saves : cemu --name : wiiu


	# psp saves : ppsspp --name : psp


	# psvita saves : vita3k --name : psv


	# ps1/psx saves : duckstation --name : ps1


	# ps2 saves : pcs2x --name : ps2


	# ps3 saves : rpcs3 --name : ps3


	# xbox saves : xemu --name : xbox


	# xbox360 saves : xenia --name : x360


	# nes , snes , sega ?

	# others ? experimental emulators : ps4 , ps5 , xbox_one

}


sync_all_saves_main
