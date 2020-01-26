# Patchwork

Patchwork is a dual function sequencer for monome norns, crow and grid. Each sequence has both a note pattern and a command pattern. A command fires when the sequence reaches its position. Commands manipulate the sequences. Think octave and position jumping, direction changes, new notes, sequence syncing, etc. 

The grid has two modes: `NOTES` and `COMMANDS` (you'll see an indication of what mode you're in on norns' screen). Use the former to edit your note pattern, the latter to edit your command pattern. 

To drive the sequences, send triggers into crow's inputs. For output, you have two options (selectable from the `PARAMS` menu): `^^ outs` (2 v/oct + trig pairs) or `jf ii 1+2`. If using the latter, make sure crow is connected to Just Friends via i2c. 

#### Keys & Encoders

- `K2` (short) - toggle between sequences
- `K2` (long) - toggle between grid modes
- `K3` (short) - randomizes commands for selected sequence
- `K3` (long) - clears commands
- `K1` - functions as an `ALT` key:
  - `K1` + `E1` - adjust length of both sequences
  - `K1` + `E2` - adjust length of sequence A
  - `K1` + `E3` - adjust length of sequence B
- `E1` - scroll between `EDIT` and `REFERENCE` pages
- `E2` - navigate to command step for selected sequence
- `E3` - select command at step for selected sequence

#### Commands

- `-`: Jump down an octave 
- `+`: Jump up an octave 
- `N`: New note 
- `M`: Mute 
- `D`: Random direction 
- `?`: Random position 
- `1`: Sync both sequences 
- `P`: New note pattern 


