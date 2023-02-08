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
# TODO : coplete the save paths, only works for yuzu for the time being

# check the creation date in seconds in unix time : date -r file +%s : useful for compareasons

# WARNING : this script is NOT tested properly yet

# INFO : mkdir -p allows to create the parents even if they don't exist yet
# cp -a allows to keep the metadata of the file, essential for this script
# cp -a "$dir/." "$dest_dir" allows us to copy the contents of $dir, without copying $dir itself


if [ ! -x "./kyub_save" ] ; then
mkdir "./kyub_save"
fi
save_dir="./kyub_save"

echo "save_dir = $save_dir"

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
		echo "no folder_local"
		if [ -d "$folder_store" ] ; then
			echo "but a folder_store"
			mkdir -p "$folder_local"
			cp -a "$folder_store/." "$folder_local"
		else
			echo "NONE OF $folder_local and $folder_store exist; can't proceed further"
		fi
	elif [ ! -d "$folder_store" ] ; then
		echo "no folder_store"
		if [ -d "$folder_local" ] ; then
			echo "but a folder_local"
			mkdir -p "$folder_store/.."
			cp -a "$folder_local/." "$folder_store"
		fi
	else # means both exist
		echo "sync : both exist ?"
		crawl_compare_copy "$folder_local" "$folder_store"
		crawl_compare_copy "$folder_store" "$folder_local" # a sync should be done by both sides, it everything is okay in the code it should work
	fi
}

crawl_compare_copy() {
	folder_local="$1"
	folder_store="$2"
	for file in "$folder_local" ; do
		local_file="$folder_local/$file"
		store_file="$folder_store/$file"
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
				fi # as else pass will not be of any use, and no need to copy the files if they're the same
			else # store_file doesn't exist, so we copy it
				cp -a "$local_file" "$store_file"
			fi
		elif [ ! -e "$store_file" ] ; then
				cp -a "$local_file" "$store_file"
		fi
	done
}


sync_all_saves_main() {
	# switch saves : yuzu and ryujinx --name : switch
	if [ -d "$local_dir/yuzu" ] ; then
		echo "trying local yuzu"
		sync_both "$local_dir/yuzu/nand/user/save" "$save_dir/switch/user/save"
		sync_both "$local_dir/yuzu/nand/system/save" "$save_dir/switch/system/save"
	else
		echo "no local yuzu"
	fi
	if [ $flatpak = true ] ; then
		if [ -d "$flatpak_dir/org.yuzu_emu.yuzu/data/yuzu" ] ; then
			echo "trying flatpak yuzu"
			sync_both "$flatpak_dir/org.yuzu_emu.yuzu/data/yuzu/nand/user/save" "$save_dir/switch/user/save"
			sync_both "$flatpak_dir/org.yuzu_emu.yuzu/data/yuzu/nand/system/save" "$save_dir/switch/system/save"
		else
			echo "no flatpak yuzu"
		fi
	fi
	# ryujinx


	# gc/wii saves : dolphin --name : dolphin ; this manipulates memory cards, be careful ??
	if [ -d "$local_dir/dolphin-emu" ] ; then
		echo "trying local dolphin"
		sync_both "$local_dir/dolphin-emu/GC/" "$save_dir/GC"
		sync_both "$local_dir/dolphin-emu/Wii/" "$save_dir/Wii"
		# save states
		sync_both "$local_dir/dolphin-emu/StateSaves/" "$save_dir/DophinStates"
	else
		echo "no local dolphin"
	fi
	if [ $flatpak = true ] ; then ## neither verified or tested
		if [ -d "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu" ] ; then
			echo "trying flatpak dolphin"
			sync_both "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC/" "$save_dir/GC"
			sync_both "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu/Wii/" "$save_dir/Wii"
			# save states
			sync_both "$flatpak_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu/StateSaves/" "$save_dir/DophinStates"
		else
			echo "no flatpak dolphin"
		fi
	fi

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
