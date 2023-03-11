#!/bin/bash

original_folder="/media/kiu/storage-m2-500/media/video/non-custom/test"
destination_folder="/media/kiu/storage-m2-500/media/video/test/out"

original_folder="/media/kiu/storage-m2-500/media/video/umaru/umaru-s2-eng"
destination_folder="/media/kiu/storage-m2-500/media/video/umaru/umaru-s2/out"

# this file is only meant to extract the japanese out of releases.
# the goal is not to extract dubs or anything like that
# this other bash script is for recompling files into proper mkvs with jp subs

# original folder have to only contain the mkv files, with no spaces
for file_number in $( seq $(ls $original_folder | wc -l ))
do
    currentfile=$(ls $original_folder | sed -n "$file_number"p )
    echo $currentfile
    cd $destination_folder
    echo $original_folder/$currentfile
    # modifiy this for every release  : you can check a mkv's properties with mkvmerge -i
    mkvextract $original_folder/$currentfile tracks 0:$currentfile.video 1:$currentfile.audio chapters $currentfile.chapters.xml
done

# NOTE : not using tags bc they are useless for my use case and just cause confusion with the dividinf factor in the other file
