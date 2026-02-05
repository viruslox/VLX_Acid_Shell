#!/bin/bash

# ==============================================================================
#  __      __   __   __      _         _    _   ___ _        _ _ 
#  \ \    / /   \ \ / /     /_\  _ __ (_)__| | / __| |_  ___| | |
#   \ \  / /| |__\ V /     / _ \|/ _| |/ _` | \__ \ ' \/ -_) | |
#    \_\/_/ |____|\_/     /_/ \_\__|_|_\__,_| |___/_||_\___|_|_|
#
#  VLX_Acid_Shell v1.0
#  Algorithmic 8-Bit Drum & Bass Sequencer / Streamer
#  Concept by VirusLox | Code by Gemini
# ==============================================================================

FILE_OUTPUT="Acid_Shell_saves.txt"
declare -a LAYERS
FULL_FORMULA=""

show_help() {
    echo "=============================================================================="
    echo "  __      __   __   __      _         _    _   ___ _        _ _ "
    echo "  \ \    / /   \ \ / /     /_\  _ __ (_)__| | / __| |_  ___| | |"
    echo "   \ \  / /| |__\ V /     / _ \|/ _| |/ _\` | \__ \ ' \/ -_) | |"
    echo "    \_\/_/ |____|\_/     /_/ \_\__|_|_\__,_| |___/_||_\___|_|_|"
    echo ""
    echo "  VLX_Acid_Shell v1.0"
    echo "  Algorithmic 8-Bit Drum & Bass Sequencer / Streamer"
    echo "  Concept by VirusLox | Code by Gemini"
    echo "=============================================================================="
    echo ""
    echo "Usage: $0 [mode] [arguments]"
    echo ""
    echo "Available Modes:"
    echo ""
    echo "  (No arguments)       Start in Local Output mode (uses 'aplay')."
    echo "  <formula>            Start with a manual bytebeat formula (e.g., 't*4')."
    echo ""
    echo "  file [filename]      Record audio to a file."
    echo "                       If [filename] is omitted, saves as 'Acid_Shell_<date>.mp3'."
    echo ""
    echo "  srt <endpoint>       Stream audio via SRT protocol."
    echo "                       Example: $0 srt 127.0.0.1:9000"
    echo ""
    echo "  rtsp <endpoint>      Stream audio via RTSP protocol."
    echo "                       Example: $0 rtsp 192.168.1.10:8554/live"
    echo ""
    echo "  rtsps <endpoint>     Stream audio via RTSPS protocol."
    echo "                       Example: $0 rtsps 192.168.1.10:322/live"
    echo ""
    echo "  --update             Update the script from the official GitHub repository."
    echo "  help, --help         Display this help message."
    echo ""
    exit 0
}

# --- OUTPUT CONFIGURATION ---
MODE_NAME="- Local Output"
# Default: standard output piping to aplay (silence errors)
OUTPUT_CMD=(aplay -r 8000 -f U8 -q)

# Argument Parsing for Modes
if [[ "$1" == "help" || "$1" == "--help" ]]; then
    show_help

elif [[ "$1" == "--update" ]]; then
    echo "- Updating script from GitHub..."
    UPDATE_URL="https://raw.githubusercontent.com/viruslox/VLX_Acid_Shell/main/VLX_Acid_Shell.sh"
    TEMP_FILE=$(mktemp)

    if command -v curl &> /dev/null; then
        curl -fsL "$UPDATE_URL" -o "$TEMP_FILE"
    elif command -v wget &> /dev/null; then
        wget -q "$UPDATE_URL" -O "$TEMP_FILE"
    else
        echo "Error: Neither 'curl' nor 'wget' found. Cannot update."
        rm -f "$TEMP_FILE"
        exit 1
    fi

    if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
        chmod +x "$TEMP_FILE"
        mv "$TEMP_FILE" "$0"
        if [ $? -eq 0 ]; then
            echo "- Update successful. Please restart the script."
            exit 0
        else
            echo "Error: Failed to replace the script (permission denied?)."
            rm -f "$TEMP_FILE"
            exit 1
        fi
    else
        echo "Error: Update failed or downloaded file is empty."
        rm -f "$TEMP_FILE"
        exit 1
    fi

elif [[ "$1" == -* ]]; then
    echo "Error: Unknown option $1"
    show_help

elif [[ "$1" == "file" ]]; then
    if [ -n "$2" ]; then
        FILENAME="$2"
    else
        FILENAME="Acid_Shell_$(date +%Y-%m-%d_%H-%M-%S).mp3"
    fi
    MODE_NAME="- Recording to '$FILENAME'"
    OUTPUT_CMD=(ffmpeg -f u8 -ar 8000 -ac 1 -i pipe:0 -y "$FILENAME" -v quiet)

elif [[ "$1" == "srt" ]]; then
    if [ -z "$2" ]; then
        echo "Error: SRT endpoint required."
        show_help
    fi
    ENDPOINT="$2"
    if [[ "$ENDPOINT" != srt://* ]]; then ENDPOINT="srt://$ENDPOINT"; fi
    MODE_NAME="- SRT Stream to $ENDPOINT"
    OUTPUT_CMD=(ffmpeg -re -f u8 -ar 8000 -ac 1 -i pipe:0 -c:a libmp3lame -b:a 128k -f mpegts "$ENDPOINT" -v quiet)

elif [[ "$1" == "rtsp" ]]; then
    if [ -z "$2" ]; then
        echo "Error: RTSP endpoint required."
        show_help
    fi
    ENDPOINT="$2"
    if [[ "$ENDPOINT" != rtsp://* ]]; then ENDPOINT="rtsp://$ENDPOINT"; fi
    MODE_NAME="- RTSP Push to $ENDPOINT"
    OUTPUT_CMD=(ffmpeg -re -f u8 -ar 8000 -ac 1 -i pipe:0 -c:a aac -b:a 128k -f rtsp "$ENDPOINT" -v quiet)

elif [[ "$1" == "rtsps" ]]; then
    if [ -z "$2" ]; then
        echo "Error: RTSPS endpoint required."
        show_help
    fi
    ENDPOINT="$2"
    if [[ "$ENDPOINT" != rtsps://* ]]; then ENDPOINT="rtsps://$ENDPOINT"; fi
    MODE_NAME="- RTSPS Push to $ENDPOINT"
    OUTPUT_CMD=(ffmpeg -re -f u8 -ar 8000 -ac 1 -i pipe:0 -c:a aac -b:a 128k -f rtsp "$ENDPOINT" -v quiet)
fi

# --- CLEANUP HANDLER ---
cleanup() {
    # Disable trap to prevent recursion
    trap - SIGINT SIGTERM EXIT
    
    echo -e "\n\n- [SYSTEM HALT] Terminating processes..."
    
    # Kill process tree
    pkill -P $$ 2>/dev/null
    # Force remove temporary binaries
    pkill -f "$COMPILED_BINARY" 2>/dev/null
    rm -f "$COMPILED_BINARY"
    
    echo "- VLX_Acid_Shell session closed."
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- SYSTEM CHECKS ---
if ! command -v gcc &> /dev/null; then echo "Error: 'gcc' compiler not found."; exit 1; fi

# Check 'aplay' only if in local mode
if [[ "$MODE_NAME" == *"Local"* ]] && ! command -v aplay &> /dev/null; then
    echo "Error: 'aplay' (alsa-utils) not found."
    exit 1
fi

COMPILED_BINARY=$(mktemp)

# --- CORE LOGIC ---

generate_chunk() {
    # Generates random bitwise rhythm pattern
    local p1=$(( (RANDOM % 12) + 4 ))
    local p2=$(( (RANDOM % 22) + 8 ))
    local mask=$(( (RANDOM % 80) + 20 ))
    echo "t*(t>>$p1|t>>$p2)&$mask"
}

get_random_op() {
    # Selects mix operator: OR (Merge), XOR (Distort), ADD (Boost)
    local ops=("|" "|" "^" "+") 
    echo "${ops[$RANDOM % ${#ops[@]}]}"
}

rebuild_and_play() {
    FULL_FORMULA=""
    
    echo -e "\n-  TRACKLIST ($MODE_NAME):"
    echo "------------------------------------------------"
    
    for i in "${!LAYERS[@]}"; do
        RAW_LAYER="${LAYERS[$i]}"
        
        # SMART MIXING: Strip leading operator if layer is at index 0
        if [ "$i" -eq 0 ]; then
            CLEAN_LAYER=$(echo "$RAW_LAYER" | sed -E 's/^[\^|+]\s*//')
            FULL_FORMULA="$CLEAN_LAYER"
            echo "   [$i] $CLEAN_LAYER (Lead)"
        else
            FULL_FORMULA="($FULL_FORMULA) $RAW_LAYER"
            echo "   [$i] $RAW_LAYER"
        fi
    done
    echo "------------------------------------------------"
    
    # C Source Construction
    SOURCE_CODE="#include <stdio.h>
    int main(){
        int t=0;
        for(;;t++){
            putchar($FULL_FORMULA);
        }
        return 0;
    }"

    # Terminate previous audio thread
    if [ ! -z "$PLAYER_PID" ]; then
        kill $PLAYER_PID 2>/dev/null
        wait $PLAYER_PID 2>/dev/null
    fi

    # Compile (-w suppresses warnings)
    printf "%s" "$SOURCE_CODE" | gcc -x c - -o "$COMPILED_BINARY" -w
    
    # Execute directly (replaces eval)
    "$COMPILED_BINARY" | "${OUTPUT_CMD[@]}" 2>/dev/null &
    
    PLAYER_PID=$!
}

# --- UI INITIALIZATION ---
clear
echo "=================================================="
echo " VLX_Acid_Shell v1.0 // 8-Bit Bytebeat Sequencer"
echo "=================================================="
echo "COMMANDS:"
echo " [ENTER]      : Add Random Layer"
echo " a <formula>  : Add Manual Layer (e.g. 'a t>>4')"
echo " d <id>       : Delete Layer (e.g. 'd 0')"
echo " s            : Save Formula to Disk"
echo " r            : Reset All"
echo " q            : Quit"
echo "--------------------------------------------------"

# Handle Argument: Custom Formula vs Mode Keyword
if [ -n "$1" ] && [[ "$1" != "file" && "$1" != "rtsp" && "$1" != "srt" && "$1" != "rtsps" ]]; then
    echo "- Manual Input Detected."
    LAYERS+=("$1")
else
    # Initialize with random seed
    BASE_CHUNK=$(generate_chunk)
    LAYERS+=("$BASE_CHUNK & t>>8")
fi

rebuild_and_play

# --- MAIN EVENT LOOP ---
while true; do
    read -r -p "VLX> " INPUT_STR
    read -r cmd arg <<< "$INPUT_STR"
    
    # Handle spacing for manual add command
    if [ "$cmd" == "a" ]; then arg="${INPUT_STR:2}"; fi

    case "$cmd" in
        q|quit|exit) 
            cleanup 
            ;;
            
        r)
            echo "-  System Reset."
            LAYERS=()
            BASE_CHUNK=$(generate_chunk)
            LAYERS+=("$BASE_CHUNK & t>>8")
            rebuild_and_play
            ;;
            
        d)
            if [[ -n "$arg" && "$arg" =~ ^[0-9]+$ ]] && [ "$arg" -lt "${#LAYERS[@]}" ]; then
                unset 'LAYERS[$arg]'
                LAYERS=("${LAYERS[@]}") # Re-index array
                rebuild_and_play
            fi
            ;;
            
        s)
            echo "--- $(date) ---" >> "$FILE_OUTPUT"
            echo "$FULL_FORMULA" >> "$FILE_OUTPUT"
            echo "- Configuration saved to $FILE_OUTPUT"
            ;;
            
        a)
            if [ -n "$arg" ]; then
                OP=$(get_random_op)
                LAYERS+=("$OP ($arg)")
                rebuild_and_play
            fi
            ;;
            
        "")
            # Empty input -> Generate Random Layer
            OP=$(get_random_op)
            CHUNK=$(generate_chunk)
            SHIFT=$(( (RANDOM % 5) + 6 ))
            LAYERS+=("$OP ($CHUNK & t>>$SHIFT)")
            rebuild_and_play
            ;;
            
        *) 
            ;;
    esac
done
