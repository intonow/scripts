#!/bin/bash

original_folder="/media/kiu/storage-m2-500/media/video/test/out"
destination_folder="/media/kiu/storage-m2-500/media/video/test/"

original_folder="/media/kiu/storage-m2-500/media/video/umaru/umaru-s2/out"
destination_folder="/media/kiu/storage-m2-500/media/video/umaru/umaru-s2/"

filename="umaru-s2"

# this file is pretty much the reversed process of extracting
# it uses the command mkvmerge
# please check everyfile afterwards and fix manually the probelms ! you do not warnt broken releases right ?

# /4 because there are video, audio, sub and chapter
for file_number in $(seq -w $(( $(ls $original_folder | wc -l ) / 4 )))
do
    audio_file=$original_folder/$filename"-"$file_number".mkv.audio"
    video_file=$original_folder/$filename"-"$file_number".mkv.video"
    subt_file=$original_folder/$filename"-"$file_number".srt"
    chap_file=$original_folder/$filename"-"$file_number".mkv.chapters.xml"
    echo $audio_file $video_file $subt_file
    # modifiy this for every release : you can check a mkv's properties with mkvmerge -i
    mkvmerge -o $destination_folder/$filename"-"$file_number".mkv" --default-language ja --chapters $chap_file $video_file $audio_file $subt_file
done

