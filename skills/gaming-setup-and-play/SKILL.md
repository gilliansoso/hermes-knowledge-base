---
name: gaming-setup-and-play
description: "Set up and manage gaming servers: Minecraft modded servers and headless Pokemon emulation via PyBoy."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [gaming, minecraft, pokemon, server, emulator, gameboy]
    category: gaming
---

# Gaming Setup & Play

This umbrella covers gaming-related skills: server setup for modded Minecraft and headless Pokemon emulation for gameplay. Both are CLI-driven gaming experiences requiring no GUI.

---

## Minecraft Modpack Server

### When to Use

- User wants to set up a modded Minecraft server from a server pack zip
- User needs help with NeoForge/Forge server configuration
- User asks about Minecraft server performance tuning or backups

### Quick Setup

1. Download and inspect the pack: `mkdir -p ~/minecraft-server && cd ~/minecraft-server && wget -O serverpack.zip "<URL>" && unzip -o serverpack.zip -d server`
2. Install Java (1.21+ → Java 21, 1.18-1.20 → Java 17)
3. Install the mod loader: most packs include `startserver.sh` with an install mode
4. Accept EULA: `echo "eula=true" > server/eula.txt`
5. Configure `server.properties`: set `allow-flight=true` (required for modded), `max-tick-time=180000`, `spawn-protection=0`
6. Tune JVM: scale RAM to mod count (100-200 mods → 6-12GB, 200-350+ → 12-24GB)
7. Open firewall: `sudo ufw allow 25565/tcp`
8. Set up automated backups via cron

### Key Pitfalls

- ALWAYS set `allow-flight=true` for modded — jetpacks will kick players otherwise
- `max-tick-time=180000` or higher — modded servers often have long ticks during worldgen
- First startup is SLOW (several minutes for big packs)
- If `online-mode=false`, set `enforce-secure-profile=false` too

---

## Pokemon Player (Headless Emulator)

### When to Use

- User says "play pokemon", "start pokemon", "pokemon game"
- User wants to watch an AI play Pokemon
- User references a ROM file (.gb, .gbc, .gba)

### Quick Start

1. Clone the repo: `git clone https://github.com/NousResearch/pokemon-agent.git`
2. Set up a Python 3.10+ venv and install with pyboy extra
3. Start the game server: `pokemon-agent serve --rom roms/pokemon_red.gb --port 9876`
4. Set up a live dashboard via SSH reverse tunnel: `ssh -R 80:localhost:9876 nokey@localhost.run`

### Gameplay Loop

1. **OBSERVE**: `GET /state` for position/HP/battle/dialog + `GET /screenshot` for vision
2. **ORIENT**: dialog > battle > heal > objective > training > explore
3. **DECIDE**: 2-4 steps max, then re-check
4. **ACT**: `POST /action` with short action list
5. **VERIFY**: screenshot after every move — vision is critical for navigation
6. **SAVE**: every 15-20 turns, before risky fights

### Key Pitfalls

- NEVER download or provide ROM files — ask the user
- Take a screenshot every 2-4 movement steps — RAM state gives position, NOT what's around you
- Add 2-3 wait_60 actions after door/stair warps (screen fades to black during transitions)
- Always sidestep after exiting buildings before going north — otherwise you walk right back in
- Use `hold_b` + `press_a` for dialog (hold B for 120 frames to speed text, then A to advance)
- Ledge tiles are one-way — can only jump south (down), never climb north

### Save/Load

- `POST /save` with descriptive name (before_brock, route1_start, etc.)
- `POST /load` with save name
- `GET /saves` lists all saves
- Save via `--load-state` flag on server startup (faster than API)