#!/bin/sh

echo "Waiting for shairport-sync to settle." >&2
sleep 5
echo "Starting up Shairport-Sync-2-MP3." >&2
echo "MP3 files will be placed in /mp3out. Make sure to have a volume bind-mounted there!" >&2
echo "Listening for Shairport-Sync Metadata." >&2
shairport-sync-metadata-reader < /tmp/shairport-sync-metadata  | while read l
do
  case "$l" in
    "Play Session Begin"*)
      track=1
      lasttitle=""
    ;;
    "Play Session End"*)
      killall -INT ffmpeg >/dev/null 2>&1
      lasttitle=""
    ;;
    "Title"*)
      x=$(echo "$l" | sed 's/[^"]*"\([^"]*\)".*/\1/g')
      title=${x:="notitle"}
    ;;
    "Artist"*)
      x=$(echo "$l" | sed 's/[^"]*"\([^"]*\)".*/\1/g')
      artist=${x:="noartist"}
    ;;
    "Album"*)
      x=$(echo "$l" | sed 's/[^"]*"\([^"]*\)".*/\1/g')
      album=${x:="noalbum"}
    ;;
    *)
    ;;
  esac
  [ "$DEBUG" == "true" ] &&  echo "SS2MP3 DBG: $l" >&2
  [ "$title" == "$lasttitle" ] && continue # if title didn't change, wait for next title
  lasttitle="$title"
  killall -INT ffmpeg >/dev/null 2>&1
  echo "Grabbing track: $artist - $album - $track - $title" >&2
  ffmpeg -sample_rate 44100 -ac 2 -f s16le -i /tmp/shairport-sync-audio -codec:a libmp3lame -qscale:a 2 -metadata title="$title" -metadata artist="$artist" -metadata album="$album" -metadata track="$track" "/mp3out/${artist}__${album}__$track - $title.mp3" &>/dev/null &
  let track++
done
