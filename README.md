# iiinvert
4 track live sequencer for iii grid


Most of iiinvert is one function per key on this single page:

[Probability] sets the chance of each step triggering per track from 0-100% in eight increments

[Store pattern] writes the current pattern to one of four slots

[Recall] pattern loads one of the four stored patterns

[Invert] inverts the on/off pattern with a separate button for each track

[Length] sets the number of steps from 1-16

[Stop] and [play] toggle playback. If the sequencer is playing then stop is lit, if the sequencer is stopped then play is lit.

[Reset] immediately sets the playhead to step 1. It’s useful for (re)synchronizing with folks playing acoustic instruments

[Random] randomizes the entire pattern.

There are 3 button combos. For each one, hold any key on one of the four sequences and then press the combo key.

[sequence key] + [random] randomizes just that row

[sequence key] + [reset] clears just that row

[any sequence key] + [invert 1-4] opens a note selector screen for sequence 1-4. midi note 0 (C-1) is bottom left, which each row being an octave (12 steps) higher. The selected track is brightly lit, with the other tracks’ notes shown dimly.

More options are available in lines 22-30 of the code:

notes = {36,37,38,42}  --set initial track notes
vel = 100  -- set average velocity
velVary = 50  --set variation in velocity (randomly selected each trig)
ch = 1  --set output channel
tempo = 135  --tempo in bpm
div = 4  --subdivide tempo e.g. 4 is 16th notes
visuals = true  --turn on/off visualizations (grid zero only)(it’s kind of a lot)
running = true  --begin with playhead active
noteOffs = true  --send note off before starting next step and when pausing

setTempo(i) and setVel(i) can be used to change tempo or velocity during playback

