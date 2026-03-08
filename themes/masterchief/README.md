# Master Chief Theme — Sound Mapping

Halo Master Chief voice lines mapped to Claude Code hook events.

## Getting the Sound Files

Master Chief voice lines can be found at community sound archives:

- **Halo: Combat Evolved sounds**: [The Sounds Resource](https://www.sounds-resource.com/xbox/halocombatevolved/sound/41357/)

Download the Master Chief dialogue files, then organize them into the directory structure below.

> **Note:** Sound files are property of Bungie/343 Industries/Microsoft. This project does not distribute any copyrighted audio — you must source your own files.

## Directory Structure

Place your `.wav` files in `~/.claude/sounds/masterchief/` using this structure:

```
~/.claude/sounds/masterchief/
├── config.sh                           ← theme config (installed automatically)
├── play.sh                             ← playback engine (installed automatically)
│
├── session_start/                      ← Claude starts up
│   ├── I need a weapon.wav             ← PRIMARY (~40%) — the iconic line
│   ├── captain keys.wav                ← rotation
│   ├── permission to leave the station.wav
│   ├── H3_I Understand.wav
│   ├── H3_Well make it.wav
│   └── this is spartan 117.wav         ← BONUS (~10%) — dramatic opener
│
├── prompt_submit/                      ← you send a message
│   ├── Yes Sir.wav                     ← PRIMARY (~40%)
│   ├── sir.wav                         ← rotation
│   ├── Understood.wav
│   ├── H3_Enough.wav
│   └── Punch it.wav                    ← BONUS (~10%)
│
├── needs_input/                        ← Claude needs your attention
│   ├── are you sure.wav                ← PRIMARY (~40%)
│   ├── can anyone hear me, over.wav    ← rotation
│   ├── commander, weve got a problem.wav
│   ├── how much time was left.wav
│   └── your pal, wheres he going.wav   ← BONUS (~10%)
│
├── task_complete/                      ← Claude finishes responding
│   ├── sir, finishing this fight.wav   ← PRIMARY (~40%) — the iconic closer
│   ├── after im thru with truth.wav    ← rotation
│   ├── tell that to the covenant.wav
│   ├── Thanks.wav
│   ├── i wont.wav
│   └── boo.wav                         ← BONUS (~5%) — the legendary "Boo."
│
├── error/                              ← tool failures
│   ├── instant/                        ← main rotation (~90%)
│   │   ├── death_grunt_instant_1.wav
│   │   ├── death_grunt_instant_2.wav
│   │   ├── death_grunt_instant_3.wav
│   │   └── death_grunt_instant_4.wav
│   ├── quiet/                          ← subtle errors (optional)
│   │   ├── death_grunt_quiet_1.wav
│   │   └── ...
│   └── violent/                        ← dramatic errors (~10%)
│       ├── death_grunt_violent_1.wav
│       └── death_grunt_violent_2.wav
│
├── working/                            ← Claude uses Bash/Write/Edit
│   ├── Do it.wav                       ← PRIMARY (~40%)
│   ├── Here we go.wav                  ← rotation
│   ├── We'll be fine.wav
│   ├── Where it is.wav
│   └── No, I think were just getting started.wav  ← BONUS (~10%)
│
└── flavor/                             ← special triggers
    ├── so what sort of weapon.wav      → first Bash command of session
    ├── lets stay focused.wav           → context compaction (PreCompact)
    ├── slow down youre losing me.wav   → context compaction (alternate)
    ├── so, stay here.wav               → subagent spawned
    ├── you all right.wav               → after error recovery
    ├── Relax id rather not piss this thing off.wav  → (reserved)
    ├── something tells me im not gonna like this.wav → (reserved)
    ├── thats not going to happen.wav   → (reserved)
    ├── you have a better idea.wav      → (reserved)
    ├── H3_No Nothing.wav               → (reserved)
    └── I dont understand.wav           → (reserved)
```

Files marked **(reserved)** are included for future use or custom hook extensions. They are not wired up by default but you can reference them in a custom `config.sh`.

## Sound Selection Logic

| Category | PRIMARY | Rotation | BONUS |
|---|---|---|---|
| `session_start` | "I need a weapon" (40%) | 4 others (~50%) | "This is Spartan 117" (10%) |
| `prompt_submit` | "Yes Sir" (40%) | 3 others (~50%) | "Punch it" (10%) |
| `needs_input` | "Are you sure" (40%) | 3 others (~50%) | "Your pal, where's he going" (10%) |
| `task_complete` | "Sir, finishing this fight" (40%) | 4 others (~55%) | "Boo." (5%) |
| `error` | instant grunts (90%) | — | violent grunts (10%) |
| `working` | "Do it" (40%) | 3 others (~50%) | "No, I think we're just getting started" (10%) |

## Tips

- Keep sound clips short: **0.3s - 1.5s** for frequent events (prompt_submit, working), **1s - 3s** for infrequent events (session_start, task_complete)
- The `boo.wav` easter egg is set to 5% instead of 10% — adjust `BONUS_PCT_task_complete` in `config.sh` if you want it more or less often
- If working sounds are too frequent, bump `DEBOUNCE_WORKING` in `config.sh` or disable the category: `export CLAUDE_SOUND_DISABLE=working`
