# Dynamic Music System

A comprehensive dynamic music system for Homigrad that provides immersive, context-aware music that responds to gameplay situations.

## Features

### 1. Ambient to Dynamic Transitions
- Music smoothly transitions between calm ambient tracks and intense combat music
- Transitions are based on player state (adrenaline, damage, fear)
- Configurable transition sensitivity

### 2. Server Mode Synchronization
- Automatically detects game mode and plays appropriate music
- Supported modes:
  - `coop` → Half-Life Coop music
  - `dm` → Mirror's Edge music
  - `tdm` → Mirror's Edge music
  - `combine` → Combine team music
  - `zombie` → Half-Life Coop music
  - `defense` → Splinter Cell music
  - `homicide` → SWAT 4 music
  - `riot` → SWAT 4 music
  - `brawl` → Mirror's Edge music
  - `shooter` → Mirror's Edge music
  - `sfd` → Mirror's Edge music
  - `gwars` → Mirror's Edge music
  - `scugarena` → Mirror's Edge music

### 3. Music Pack Constructor
Easy-to-use functions to create and add music packs:

```lua
-- Create a new pack
DMusic:AddPack("my_pack")

-- Add tracks to a pack
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "path/to/ambient.mp3", 0.3)  -- Level 0: Ambient
musMeta:AddMusic(Music, 1, "path/to/combat.mp3")        -- Level 1: Combat
musMeta:AddMusic(Music, 3, "path/to/intense.mp3")       -- Level 3: Intense
musMeta:AddMusic(Music, 4, "path/to/fear.mp3")          -- Level 4: Fear

-- Add sequence to pack
DMusic:AddSequence("my_pack", "track_01", Music)
```

### 4. Music Control
- Enable/disable music via convar `hg_dmusic`
- Skip current track with `hg_dmusic_skip`
- Stop all music with `hg_dmusic_stop`
- Select music pack via console or menu

### 5. Ambient Volume Control
- Separate ambient volume slider (`hg_dmusic_ambient_vol`)
- Mixes ambient and dynamic tracks based on intensity
- Respects GMod's master music volume

### 6. Fear-Based Music Tracks
- Special tracks play when player experiences high fear
- Fear increases from:
  - Taking damage
  - Witnessing deaths
  - Hearing scary sounds
  - Being in dangerous situations
- Configurable fear threshold and volume

### 7. Adrenaline/Damage-Based Transitions
- Music intensity increases with:
  - Adrenaline levels
  - Noradrenaline levels
  - Berserk state
  - Recent damage taken
- Melee damage causes more intense transitions
- Explosion damage triggers extreme intensity

## Console Commands

| Command | Description |
|---------|-------------|
| `hg_dmusic` | Enable/disable dynamic music (0/1) |
| `hg_dmusic_ambient_vol` | Set ambient volume (0-1) |
| `hg_dmusic_sensitivity` | Set transition sensitivity (0.5-2) |
| `hg_dmusic_default_pack` | Set default music pack |
| `hg_dmusic_fear_threshold` | Set fear threshold for fear tracks (0-10) |
| `hg_dmusic_fear_volume` | Set fear track volume multiplier (0-2) |
| `hg_dmusic_setpack <name>` | Set current music pack |
| `hg_dmusic_setmode <mode>` | Set current game mode |
| `hg_dmusic_skip` | Skip current track |
| `hg_dmusic_stop` | Stop all music |
| `hg_dmusic_fear <amount>` | Add fear level |
| `hg_dmusic_list` | List available packs and settings |
| `hg_dmusic_menu` | Open settings menu |

## Settings Menu

Access the settings menu via:
- Console command: `hg_dmusic_menu`
- Spawn menu: Options → Homigrad → Dynamic Music

### Menu Tabs

1. **General**
   - Enable/disable music
   - Ambient volume slider
   - Sensitivity slider
   - Default pack selection
   - Current status display
   - Skip/Stop buttons

2. **Music Packs**
   - Browse available music packs
   - Select active pack
   - View pack details

3. **Fear Tracks**
   - Configure fear threshold
   - Set fear volume multiplier
   - View current fear level
   - Browse available fear tracks

4. **Mode Mapping**
   - View game mode to music pack mappings
   - Add custom mode mappings
   - Edit existing mappings

## Music Intensity Levels

| Level | Description | When It Plays |
|-------|-------------|---------------|
| 0 | Ambient | Calm situations, no danger |
| 0.5 | Suspense | Minor tension, exploring |
| 1 | Light Combat | Small skirmishes, minor injuries |
| 2 | Medium Combat | Active combat, moderate injuries |
| 3 | Intense Combat | Heavy combat, serious injuries |
| 4 | Fear/Horror | High fear, extreme danger |
| 5 | Extreme | Berserk state, critical situations |

## Integration with Organism System

The music system integrates with the organism system to provide realistic responses:

- **Adrenaline**: Increases music intensity during combat
- **Fear**: Triggers fear-based tracks when witnessing deaths or taking damage
- **Berserk**: Activates extreme intensity music
- **Damage**: Causes immediate intensity spikes
- **Noradrenaline**: Sustains elevated intensity

## Creating Custom Music Packs

1. Create a new Lua file in `lua/homigrad/dynmusic/`
2. Use the pack constructor functions:

```lua
hg = hg or {}
hg.DynaMusic = hg.DynaMusic or {}
local DMusic = hg.DynaMusic

-- Create your pack
DMusic:AddPack("custom_pack")

-- Add tracks with different intensity levels
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "custom/ambient1.mp3", 0.3)
musMeta:AddMusic(Music, 1, "custom/combat1.mp3")
musMeta:AddMusic(Music, 3, "custom/intense1.mp3")
musMeta:AddMusic(Music, 4, "custom/fear1.mp3")
DMusic:AddSequence("custom_pack", "01", Music)

-- Add more sequences as needed
```

3. Place your audio files in `sound/custom/`
4. The pack will be automatically loaded

## File Structure

```
lua/homigrad/dynmusic/
├── cl_init.lua      # Main client-side music system
├── cl_menu.lua      # Settings menu UI
├── sh_packs.lua     # Music pack definitions
└── README.md        # This file
```

## Tips

- Use `hg_dmusic_list` to see all available packs and current settings
- Adjust sensitivity if transitions feel too abrupt or too slow
- Lower fear threshold if you want fear tracks to trigger more often
- Use `hg_dmusic_skip` to skip tracks that don't fit the current situation
- The system automatically syncs with server game modes
