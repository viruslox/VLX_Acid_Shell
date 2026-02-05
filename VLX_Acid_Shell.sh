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

# --- OUTPUT CONFIGURATION ---
MODE_NAME="? Local Output"
# Default: standard output piping to aplay (silence errors)
OUTPUT_CMD="aplay -r 8000 -f U8 -q 2>/dev/null"

# Argument Parsing for Modes
if [[ "$1" == "stream" ]]; then
    MODE_NAME="? SRT Stream (Port 9998)"
    # Low latency MPEG-TS stream via SRT
    OUTPUT_CMD="ffmpeg -re -f u8 -ar 8000 -ac 1 -i pipe:0 -c:a libmp3lame -b:a 128k -f mpegts srt://0.0.0.0:9998?mode=listener -v quiet"
    
elif [[ "$1" == "save" ]]; then
    MODE_NAME="? Recording to 'vlx_set.mp3'"
    OUTPUT_CMD="ffmpeg -f u8 -ar 8000 -ac 1 -i pipe:0 -y vlx_set.mp3 -v quiet"

elif [[ "$1" == "rtsp" ]]; then
    MODE_NAME="? RTSP Push"
    OUTPUT_CMD="ffmpeg -re -f u8 -ar 8000 -ac 1 -i pipe:0 -c:a aac -b:a 128k -f rtsp rtsp://localhost:8554/dnb -v quiet"
fi

# --- CLEANUP HANDLER ---
cleanup() {
    # Disable trap to prevent recursion
    trap - SIGINT SIGTERM EXIT
    
    echo -e "\n\n? [SYSTEM HALT] Terminating processes..."
    
    # Kill process tree
    pkill -P $$ 2>/dev/null
    # Force remove temporary binaries
    pkill -f "vlx_temp" 2>/dev/null
    
    echo "? VLX_Acid_Shell session closed."
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
    
    echo -e "\n?  TRACKLIST ($MODE_NAME):"
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
    printf "%s" "$SOURCE_CODE" | gcc -x c - -o /tmp/vlx_temp -w
    
    # Execute via eval to handle pipe/redirection in OUTPUT_CMD
    eval "/tmp/vlx_temp | $OUTPUT_CMD &"
    
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
if [ -n "$1" ] && [[ "$1" != "stream" && "$1" != "save" && "$1" != "rtsp" ]]; then
    echo "? Manual Input Detected."
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
            echo "?  System Reset."
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
            echo "? Configuration saved to $FILE_OUTPUT"
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