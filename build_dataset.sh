#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               | For: Apex WallHack_detect     ****#
#*----- Description :   Script use to build image dataset from youtube vids             ****#
#*******************************************************************************************#

PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2025 Aubertin Emmanuel"
DEBUG=0
VERBOSE=0

downloader="youtube-dl"
keep_mp4=0
links_file="links.json"
tmp_directory="tmp_video"
output_directory="output"
number_img=100
skip_download=0

print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
        echo ""
        echo "$PROGNAME"
        echo ""
        echo "Usage: $PROGNAME | [-h | --help] | [-v | --version] | [-V | --verbose] | [-d | --youtube_dl] | [-y | --yt-dlp] | [-k | --keep] | [-o | --output_directory] | [-t | --tmp_directory] "
        echo ""
        echo "          -h  Show this help"
        echo "          -v  Version"
        echo "          -V  Verbose mode"
        echo "          -k  Keep MP4 files"
        echo "          -o  Output directory"
        echo "          -d  Use youtube-dl (by default)"
        echo "          -y  Use yt-dlp"
        echo "          -f  Input file with youtube links (see PUT LINK TO DOC LATER)" 
        echo "          -n  Number of images extracted from each video"
        echo "          -o  Specify the output directory (output/ by default)"
        echo "          -t  Specify the path to the video temps directory (tmp_video/ by default)"
        echo "          -s  Skip video download"
        echo ""
        echo "Exemple: ./build_dataset.sh -o dataset/cheater -y -f apex_cheater.json -t tmp_cheater_vids -k"
        echo ""
}

print_help() {
        print_release
        echo ""
        print_usage
        echo ""
        exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            ;;
        -v | --version)
            print_release
            exit
            ;;
        -d | --youtube_dl)
            downloader="youtube-dl"
            ;;
        -y | --yt-dlp)
            downloader="yt-dlp"
            ;;
        -k | --keep)
            keep_mp4=1
            ;;
        -f | --file_links)
            links_file=$2
            shift
            ;;
        -o | --output_directory)
            output_directory=$2
            shift
            ;;
        -t | --tmp_directory)
            tmp_directory=$2
            shift
            ;;
        -n | --number_img)
            number_img=$2
            shift
            ;;
        -s | --skip)
            skip_download=1
            ;;
        -V | --verbose)
            VERBOSE=1
            ;;
        *)  echo "Argument inconnu: $1"
            print_usage
            exit 1
            ;;
    esac
    shift
done

# Detect operating system
OS=$(uname -s)

colored_echo() {
    local color_code="$1"
    local text="$2"
    case "$OS" in
        Darwin)
            # macOS uses \033 instead of \e for color codes
            echo "\033[${color_code}${text}\033[0m"
            ;;
        *)
            # Linux and other systems
            echo -e "\e[${color_code}${text}\e[0m"
            ;;
    esac
}

function log_verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo "$1"
    fi
}

function ask_yes_or_no() {
    echo -n "[yes/no] : "
    read -r YESNO
    if [[ $YESNO =~ [yY] ]]; then
        return 0
    fi
    return 1
}
function dl_vids() {
    local video_url="$1"
    local video_title

    if ! command -v $downloader &> /dev/null; then
        colored_echo "1;31m" "Error: $downloader is not installed. Please install it and try again."
        print_help
        exit 1
    fi

    if [ ! -d "$tmp_directory" ]; then
        mkdir -p "$tmp_directory"
    fi

    video_title=$($downloader --get-filename -o "%(title)s.mp4" "$video_url" 2>/dev/null)
    if [ -z "$video_title" ]; then
        colored_echo "1;31m" "Error: Unable to fetch video title. Skipping..."
        return
    fi

    if [ -f "$tmp_directory/$video_title" ]; then
        colored_echo "1;33m" "Video already downloaded: $video_title. Skipping..."
        return
    fi

    log_verbose "Downloading video from $video_url to $tmp_directory using $downloader..."
    $downloader -o "$tmp_directory/%(title)s.mp4" "$video_url" &> /dev/null

    if [ $? -eq 0 ]; then
        colored_echo "1;32m" "Download completed successfully: $video_title."
        log_verbose "Download details: Video URL - $video_url"
    else
        colored_echo "1;31m" "Error: Download failed for $video_url."
        exit 1
    fi
}

function parse_links_file() {
    if [ ! -f "$links_file" ]; then
        colored_echo "1;31m" "Error: Links file $links_file does not exist."
        exit 1
    fi

    case "$links_file" in
        *.json)
            colored_echo "1;32m" "Parsing JSON links file: $links_file"
            jq -r '.videolink[].url' "$links_file" | while read -r url; do
                dl_vids "$url"
            done
            ;;
        *.txt)
            colored_echo "1;32m" "Parsing text links file: $links_file"
            while read -r url; do
                [ -n "$url" ] && dl_vids "$url"
            done < "$links_file"
            ;;
        *)
            colored_echo "1;31m" "Error: Unsupported file format for $links_file. Please use .json or .txt."
            exit 1
            ;;
    esac
}

function extract_images() {
    if [ ! -d "$output_directory" ]; then
        mkdir -p "$output_directory"
    fi

    for file in "$tmp_directory"/*.mp4; do
        if [ ! -e "$file" ]; then
            colored_echo "1;31m" "Error: No video files found in $tmp_directory."
            exit 1
        fi
        filename=$(basename "$file" .mp4)
        total_frames=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$file")
        if [ -z "$total_frames" ] || [ "$total_frames" -eq 0 ]; then
            colored_echo "1;31m" "Error: Unable to determine frame count for $file."
            continue
        fi

        # Ignore Intro and outro (10 seconds)
        video_duration=$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 "$file")
        if [ -z "$video_duration" ] || (( $(echo "$video_duration < 30" | bc -l) )); then
            colored_echo "1;31m" "Error: Video too short to process (less than 30 seconds). Skipping $file."
            continue
        fi

        start_time=15
        end_time=$(echo "$video_duration - 15" | bc)

        frame_interval=$((total_frames / number_img))
        if [ "$frame_interval" -eq 0 ]; then
            frame_interval=1
        fi

        log_verbose "Extracting images from $file with interval $frame_interval, ignoring first 15s and last 15s..."
        ffmpeg -i "$file" -vf "select='between(t,$start_time,$end_time)*not(mod(n\,$frame_interval))'" -vsync vfr "$output_directory/${filename}_%04d.png" &> /dev/null

        if [ $? -eq 0 ]; then
            colored_echo "1;32m" "Images extracted successfully for $file."
        else
            colored_echo "1;31m" "Error: Failed to extract images from $file."
        fi
    done
}


if [ $skip_download -eq 0 ]; then
    parse_links_file
    colored_echo "32m" "Download complete."
else
    colored_echo "32m" "Skipping Download."
fi

extract_images

colored_echo "32m" "Extraction complete."

colored_echo "1;32m" "**************************************************"
colored_echo "1;33m" "*     🎉 Now you can enjoy your dataset! 🎉      *"
colored_echo "1;32m" "**************************************************"
colored_echo "1;32m" "Happy learning! 😊"
