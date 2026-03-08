# Contributing

Thanks for your interest in contributing! The easiest way to contribute is by creating a new sound theme.

## Creating a Theme

A theme is just two files in `themes/<your-theme-name>/`:

```
themes/
└── your-theme/
    ├── config.sh    ← required: sound mappings and settings
    └── README.md    ← required: where to get sounds + file mapping guide
```

That's it. No code changes to `play.sh` or `install.sh` needed.

### Step 1: Copy the template

```bash
cp -r themes/masterchief themes/your-theme
```

### Step 2: Edit `config.sh`

Open `themes/your-theme/config.sh` and update:

**Theme name** — shown in the terminal title bar:
```bash
THEME_NAME="GLaDOS"
```

**Terminal titles** — text shown per event category:
```bash
TITLE_session_start="Testing initiated"
TITLE_task_complete="Test complete"
# ... etc
```

**Primary and bonus sounds** — filenames that get weighted selection:
```bash
# PRIMARY plays ~40% of the time
# BONUS plays ~10% (or whatever BONUS_PCT you set)
# All other .wav files in the directory split the remaining ~50%

PRIMARY_session_start="hello_and_welcome.wav"
BONUS_session_start="the_cake_is_a_lie.wav"
BONUS_PCT_session_start=10
```

**Flavor sounds** — special trigger filenames (all optional):
```bash
FLAVOR_COMPACT_1="you_are_not_a_good_person.wav"   # context compaction
FLAVOR_COMPACT_2=""                                  # leave empty to skip
FLAVOR_SUBAGENT="there_you_are.wav"                  # subagent spawned
FLAVOR_FIRST_BASH="lets_get_started.wav"             # first Bash of session
FLAVOR_ERROR_RECOVERY="are_you_still_there.wav"      # success after failure
```

Any config value can be left empty or omitted — the engine will fall back to equal-weight random selection from whatever `.wav` files exist in that category directory.

### Step 3: Write `README.md`

Your theme README should include:

1. **Where to get the sound files** — link to a legal source (sound archives, community sites, etc.)
2. **Copyright notice** — remind users the audio is someone else's IP
3. **File mapping** — which `.wav` files go in which directory, with the expected filenames matching your `config.sh`
4. **Tips** — recommended clip lengths, any category-specific notes

See `themes/masterchief/README.md` for a complete example.

### Sound file guidelines

- Use `.wav` format (`.mp3` and `.ogg` are not currently supported by the engine)
- Keep clips short: **0.3s - 1.5s** for frequent events, **1s - 3s** for infrequent ones
- Do NOT include sound files in your PR — the `.gitignore` excludes all audio. Your README should tell users where to download them.

## Directory structure reference

When a user installs your theme, they'll create this structure at `~/.claude/sounds/<theme>/`:

```
~/.claude/sounds/your-theme/
├── config.sh               ← installed from your theme
├── play.sh                 ← installed from repo root
├── session_start/          ← 2-6 .wav files
├── prompt_submit/          ← 2-5 .wav files
├── needs_input/            ← 2-5 .wav files
├── task_complete/          ← 2-6 .wav files
├── error/
│   ├── instant/            ← 2-4 quick error sounds
│   ├── quiet/              ← optional: subtle errors
│   └── violent/            ← optional: dramatic errors (~10% chance)
├── working/                ← 2-5 .wav files
└── flavor/                 ← special trigger sounds
```

Not every directory needs files. The engine gracefully skips empty categories.

## Submitting a PR

1. Fork the repo
2. Create a branch: `git checkout -b theme/your-theme-name`
3. Add your two files: `themes/your-theme/config.sh` and `themes/your-theme/README.md`
4. Test locally:
   ```bash
   ./install.sh your-theme
   # Add your sound files to ~/.claude/sounds/your-theme/
   echo '{"hook_event_name":"SessionStart","session_id":"test"}' | bash ~/.claude/sounds/your-theme/play.sh
   ```
5. Open a PR with:
   - Theme name and what franchise/character it's based on
   - Confirmation that no audio files are included in the PR
   - A note on where you sourced the sounds

## Other contributions

Bug fixes and improvements to `play.sh`, `install.sh`, or docs are also welcome. Please open an issue first to discuss larger changes.

## Code style

- Bash scripts should work on bash 3.2+ (macOS default)
- Use `shellcheck` if available: `shellcheck play.sh`
- Keep it simple — this is a fun side project, not enterprise software
