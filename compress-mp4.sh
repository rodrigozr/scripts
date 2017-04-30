#!/bin/bash

FFMPEG=~/Downloads/ffmpeg

INPUT_FOLDER=$1
OUTPUT_FOLDER=$2

if [[ -z $INPUT_FOLDER ]] || [[ -z $OUTPUT_FOLDER ]]; then
    echo Usage: "$0 <input folder with MP4 files> <output folder>"
    exit 1
fi
if ! [[ -d $INPUT_FOLDER ]]; then
    echo Input folder is not a valid directory: $INPUT_FOLDER
    exit 1
fi
if ! [[ -d $OUTPUT_FOLDER ]]; then
    echo Output folder is not a valid existing directory: $OUTPUT_FOLDER
    exit 1
fi
if ! [[ -e $FFMPEG ]]; then
    echo Could not find ffmpeg executable: $FFMPEG
    exit 1
fi

shopt -s nocaseglob
for f in $INPUT_FOLDER/*.MP4
do
    FNAME=$(basename $f)
    echo "Processing file: $FNAME ..."
    # Get the file bitrate and size
    bitrate=$($FFMPEG -i $f -nostdin 2>&1 | grep -o "bitrate: \d*" | cut -b10-)
    size=$(du -h $f | cut -f1)
    # Check if the video is rotated
    rotated=NO
    resolution=1280x720
    if $FFMPEG -i $f 2>&1 | grep rotate > /dev/null; then
        rotated=YES
        resolution=720x1280
    fi

    # Print source file information
    echo "  CURRENT BITRATE: $bitrate"
    echo "  CURRENT SIZE   : $size"
    echo "  ROTATED        : $rotated"
    if [[ $bitrate -lt 6000 ]]; then
        echo "  (IGNORING FILE - ALREADY AT A LOW BITRATE)"
        echo ""
        continue
    fi

    # Transcode the file
    echo "  Compressing..."
    out=$OUTPUT_FOLDER/$FNAME
    $FFMPEG -i $f -nostdin -preset slow -s $resolution -crf 24 $out 2> $OUTPUT_FOLDER/log.txt
    if ! [[ $? -eq 0 ]]; then
        echo "  ERROR!!! Check log.txt"
        exit 1
    fi

    # Get the new file bitrate and size
    bitrate=$($FFMPEG -i $out -nostdin 2>&1 | grep -o "bitrate: \d*" | cut -b10-)
    size=$(du -h $out | cut -f1)
    echo "  NEW BITRATE    : $bitrate"
    echo "  NEW SIZE       : $size"

    # Copy the file timestamps from the original
    touch -r $f $out
    echo "  Success!!"
    echo ""
done

echo Finished processing all files. Enjoy :P