# VLX_Acid_Shell

**Algorithmic 8-Bit Drum & Bass Sequencer / Streamer**

Welcome to **VLX_Acid_Shell**, a lightweight, bash-based synthesizer that generates procedural 8-bit Drum & Bass entirely from mathematical formulas (bytebeat). Whether you want to jam locally, record your sessions, or stream chaotic noise to the world, this shell script has you covered.

## Features

- **Procedural Audio Generation**: Creates endless, non-repeating 8-bit audio loops using C-style bitwise expressions.
- **Live Mixing**: Layer multiple formulas, distort them, or boost them in real-time.
- **Multi-Mode Output**:
  - **Local Playback**: Listen directly via `aplay`.
  - **Recording**: Save your sessions to `.mp3` files.
  - **Streaming**: Push your audio to SRT, RTSP, or RTSPS endpoints using `ffmpeg`.
- **Zero-Latency(ish)**: Compiles C code on the fly for immediate audio synthesis.

## Prerequisites

Before you drop the bass, ensure you have the following tools installed on your Linux machine:

- **GCC**: To compile the bytebeat formulas (`sudo apt install build-essential`).
- **ALSA Utils (`aplay`)**: For local playback (`sudo apt install alsa-utils`).
- **FFmpeg**: For recording and streaming features (`sudo apt install ffmpeg`).
- **Curl** or **Wget**: For the self-update feature.

## Usage

First, make the script executable:
```bash
chmod +x VLX_Acid_Shell.sh
```

### 1. Local Playback
Start the sequencer and listen on your default audio device:
```bash
./VLX_Acid_Shell.sh
```
Or start with a specific seed formula:
```bash
./VLX_Acid_Shell.sh "t*(t>>10|t>>8)&123"
```

### 2. Recording
Record your session directly to an MP3 file:
```bash
./VLX_Acid_Shell.sh file [filename.mp3]
```
*If no filename is provided, it defaults to a timestamped file (e.g., `Acid_Shell_2023-10-27...mp3`).*

### 3. Streaming
Broadcast your noise to a remote server or media gateway.

**SRT (Secure Reliable Transport):**
```bash
./VLX_Acid_Shell.sh srt 127.0.0.1:9000
```

**RTSP (Real Time Streaming Protocol):**
```bash
./VLX_Acid_Shell.sh rtsp 192.168.1.10:8554/live
```

**RTSPS (Secure RTSP):**
```bash
./VLX_Acid_Shell.sh rtsps 192.168.1.10:322/live
```

## Interactive Commands

Once the shell is running, you are the conductor. Use these commands to manipulate the soundscape:

- **`[ENTER]`**: Add a random layer to the mix.
- **`a <formula>`**: Add a specific bytebeat formula (e.g., `a t>>4`).
- **`d <id>`**: Delete a specific layer by its ID (check the Tracklist).
- **`s`**: Save the current formula configuration to `Acid_Shell_saves.txt`.
- **`r`**: Reset everything to a fresh start.
- **`q`**: Quit the session.

## Updates

Keep your shell fresh with the built-in update command:
```bash
./VLX_Acid_Shell.sh --update
```

---
*Concept by VirusLox | Code by Gemini*
