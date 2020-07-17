# Patchwork

Patchwork is a dual function sequencer for monome norns, crow and grid. Each sequence has both a note pattern and a command pattern. A command fires when the sequence reaches its position. Commands manipulate the sequences. Think octave and position jumping, direction changes, new notes, sequence syncing, etc.

The grid has two modes: `NOTES` and `COMMANDS` (you'll see an indication of what mode you're in the bottom right-hand corner of norns' screen). Use the former to edit your note pattern, the latter to edit your command pattern.

To drive the sequences, send triggers into crow's inputs.

### Output Options

As of 2.0, each sequence has its own dedicated - and configurable - output options:

- `CROW 1+2` (out 1 = v/8, out 2 = trig)
- `CROW 3+4` (out 3 = v/8, out 4 = trig)
- `JF.VOX 1` (make sure to connect jf to crow via ii)
- `JF.VOX 2`
- `JF.NOTE`
- `MIDI` (device + channel selection options are in params)

> With Just Friends' new and improved polyphonic allocator (in firmware [4.0](https://llllllll.co/t/just-friends-v4-0/34554)), it's possible to send both sequences to a single Just Friends for amazingly lush results. To take advantage of the JF output options, make sure your JF is connected to crow via i2c.

#### Keys & Encoders

- `K2` (short) - toggle between sequences
- `K3` (short) - randomizes commands for selected sequence
- `K3` (long) - clears commands
- `K2` + `E2` - adjust start position of selected sequencer
- `K2` + `E3` - adjust end position of selected sequencer
- `K1` (long) - toggle between main page and reference page
- `E1` - switch between grid modes
- `E2` - navigate to command step for selected sequence
- `E3` - select command at step for selected sequence

#### Commands

- `-`: Jump down an octave
- `+`: Jump up an octave
- `N`: New note
- `*`: Mute
- `D`: Random direction
- `?`: Random position
- `1`: Sync both sequences
- `P`: New note pattern

#### Params

Head to the global params menu and scroll down to find the `PATCHWORK` section. From there, you can:

- adjust output options per sequence
- select a scale
- select a root note
- select midi device #
- select midi out channel (per sequence)
