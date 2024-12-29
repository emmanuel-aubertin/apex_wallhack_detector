# Wallhack Detector

This is an experimental test. The idea is to detect wallhacks and visible cheats based on player screenshots.

**Work in progress**  
Currently working on CNN models.

## Available Features

### Dataset Builder

This script builds a dataset from YouTube videos. Be aware that some extracted images might not be suitable for your dataset (for example: post-production effects, extra text, intros, outros, etc.).

Here is how to use it:

```bash
❯ ./build_dataset.sh -h
Revision 1.0 (c) 2025 Aubertin Emmanuel


Usage: build_dataset.sh | [-h | --help] | [-v | --version] | [-V | --verbose] | [-d | --youtube_dl] | [-y | --yt-dlp] | [-k | --keep] | [-o | --output_directory] | [-t | --tmp_directory] 

          -h  Show this help
          -v  Version
          -V  Verbose mode
          -k  Keep MP4 files
          -o  Output directory
          -d  Use youtube-dl (by default)
          -y  Use yt-dlp
          -f  Input file with YouTube links, json/txt only (see documentation)
          -n  Number of images extracted from each video
          -o  Specify the output directory (output/ by default)
          -t  Specify the path to the temporary video directory (tmp_video/ by default)
          -s  Skip video download

Example: ./build_dataset.sh -o dataset/cheater -y -f apex_cheater.json -t tmp_cheater_vids -k
More documentation available at https://github.com/emmanuel-aubertin/apex_wallhack_detector
```

Example of input file (-f):
Json (see [here](apex_cheater.json))
```json
{
    "videolink": [
        {
            "url": "https://www.youtube.com/watch?v=0t2cCSpu-H8"
        },
        ...
       ]
} 
```
Plain text (see [here](apex_player.txt))
```
https://www.youtube.com/watch?v=N50rg1Xx3YE
https://www.youtube.com/watch?v=8nhkf_WdBUA
....
```
