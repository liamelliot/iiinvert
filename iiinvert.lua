-- iiinvert
-- 4 Track Live Trig Sequencer
-- see https://llllllll.co/t/iiinvert/74376

--             GRID
--  ----------------------------
-- |                            |
-- |        track 1-4           |
-- |                            |
-- |----------------------------|
-- |              |store invert |
-- |  probability |recall stop/go/reset/random |
-- |              |  length     |
--  ----------------------------

--the diagram above shows the main interface. there are 3 button combos to know
--track button + randomize does just that row
--track button + reset clears that row (otherwise resets to step 1 immediately)(handy for syncing with other musicians)
--track button + play enters note selection screen (bottom left is 0, each row an octave)
--track button + stop enters tempo selection screen with manual or tap entry

--the variables below set script behavior
--setTempo(i) and setVel(i) can be used to change tempo or velocity during playback. i is bpm/velocity

notes = {46,42,39,36} --set initial track notes
vel = 100 -- set average velocity
velVary = 50 --set variation in velocity
ch = 1 --set output channel
tempo = 135 --bpm
div = 4 --subdivide tempo e.g. 4 is 16th notes

visuals = true --turn on/off visualizations (grid zero only)
running = true --begin with playhead active
noteOffs = true --send note off before starting next step and when pausing

--tempo view stuff
nb = 10 --number brightness
start = 0
taps = {0} --set first in array to 0 for tapping
tc = 2 --tap count
tempoView = false


-------------------------------

tempoTime = 60/(tempo*div) --bpm to time
velMax = math.max(0, math.min(127, (vel + (velVary/2)))) --find max velocity
velMin = math.max(0, math.min(127, (vel - (velVary/2)))) --find min velocity

--create and set initial probability
prob = {
  key = {},
  odds = {},
}
for i=1,4 do
  prob.key[i] = 8
  prob.odds[i] = 100
end


invert = {0,0,0,0} --track inversion status
held = {false,false,false,false,true} --key held per row ([5] indicates none held)
noteSet = {false,false,false,false,false} --this one more sensibly has [5] indicate that we're not in the note selection screen
displayScale = {5,1,4,1,4,4,1,4,1,4,1,4}
currentNotes = {}
blinkSet = {false,false,false,false}

--create and populate track sequences
seq = {
  pos = 1,
  length = 16,
  one = {}, two = {}, thr = {}, fou = {},
}
for i=1, 16 do
  seq.one[i] = 0
  seq.two[i] = 0
  seq.thr[i] = 0
  seq.fou[i] = 0
end

for j=1,127 do --array for held notes
  currentNotes[j] = false
end

--create 4 pattern save slots
function createpatterns()
  patterns = {}
  for i=1, 4 do
    table.insert(patterns,
      {id = i,
        stored = 0,
        active = 0,
        length = 16,
        one = {}, two = {}, thr = {}, fou = {},
        })
    for j=1, 16 do
      patterns[i].one[j] = 0
      patterns[i].two[j] = 0
      patterns[i].thr[j] = 0
      patterns[i].fou[j] = 0
    end
  end
end

function storepattern(i)
  patterns[i].stored = 1
  patterns[i].length = seq.length
  for j=1,16 do
    patterns[i].one[j] = seq.one[j]
    patterns[i].two[j] = seq.two[j]
    patterns[i].thr[j] = seq.thr[j]
    patterns[i].fou[j] = seq.fou[j]
  end
end

function recallpattern(i)
  for j=1, 4 do
    patterns[j].active = 0
  end
  patterns[i].active = 1
  for j=1,16 do
    seq.one[j] = patterns[i].one[j]
    seq.two[j] = patterns[i].two[j]
    seq.thr[j] = patterns[i].thr[j]
    seq.fou[j] = patterns[i].fou[j]
  end
end

--move through sequence steps
function step()

    if running then

      if noteOffs == true then --optionally turn notes off before doing next step
        for i=1,4 do
          midi_note_off(notes[i],0,ch)
        end

        for j=1,127 do
          if currentNotes[j] == true then
            midi_note_off(j-1,0,ch)
            currentNotes[j] = false
          end
        end
      end

      seq.pos = seq.pos + 1 --advance sequencer
      if seq.pos > seq.length then
        seq.pos = 1
      end

      if (seq.one[seq.pos] - invert[1]) ~= 0 then --an inverted 0 will be -1, and noninverted 1 will be 1
        if math.random(100) <= prob.odds[1] then --roll dice for probability
            midi_note_on(notes[1], math.random(velMin,velMax), ch) --send midi note
            blinkSet[1] = true
            currentNotes[notes[1]+1] = true
        end
      end
      if (seq.two[seq.pos] - invert[2]) ~= 0 then
        if math.random(100) <= prob.odds[2] then
            midi_note_on(notes[2], math.random(velMin,velMax), ch)
            blinkSet[2] = true
            currentNotes[notes[2]+1] = true
        end
      end
      if (seq.thr[seq.pos] - invert[3]) ~= 0 then
        if math.random(100) <= prob.odds[3] then
            midi_note_on(notes[3], math.random(velMin,velMax), ch)
            blinkSet[3] = true
            currentNotes[notes[3]+1] = true
        end
      end
      if (seq.fou[seq.pos] - invert[4]) ~= 0 then
        if math.random(100) <= prob.odds[4] then
            midi_note_on(notes[4], math.random(velMin,velMax), ch)
            blinkSet[4] = true
            currentNotes[notes[4]+1] = true
        end
      end
  end
  redraw()
end

--grid presses
function event_grid(x,y,z)
  if z == 1 and noteSet[5] == false and tempoView == false then --button on
    if y == 1 then
      seq.one[x] = seq.one[x] == 0 and 1 or 0 --flips state for reasons i don't understand
    end
    if y == 2 then
      seq.two[x] = seq.two[x] == 0 and 1 or 0
    end
    if y == 3 then
      seq.thr[x] = seq.thr[x] == 0 and 1 or 0
    end
    if y == 4 then
      seq.fou[x] = seq.fou[x] == 0 and 1 or 0
    end


    if y >= 5 and x <= 8 and x > 1 then --set probability
      prob.key[y-4] = x
      prob.odds[y-4] = math.floor(((x-1) * (100/7))+0.5)
    end

    if y>= 5 and x == 1 then --hold row
      held[y-4] = true
      held[5] = false
    end

    if x > 8 and y == 7 then  --set number of steps in sequence
      seq.length = x-8
    elseif x > 8 and y == 8 then
      seq.length = x
    end

    if y == 5 and x > 8 and x <= 12 then
      storepattern(x-8)
    end

    if y == 6 and x > 8 and x <= 12 then
      recallpattern(x-8)
    end

    if y == 6 and x == 13 then
      if held[5] == true then
        m:stop()
        running = false
        metro.free_all()
        for j=1,127 do
          if currentNotes[j] == true then
            midi_note_off(j-1,0,ch)
            currentNotes[j] = false
          end
        end
      end
      for i=1,4 do --any track key + stop to go to tempo
        if held[i] == true then
          tempoView = true
          tempoToDigits(tempo)
        end
      end
      for j=1,4 do
        held[j] = false
        held[5] = true
      end
    end


    if y == 6 and x == 14 then
      if held[5] == true then --start playback
        running = true
        step()
        metro.free_all()
        m = metro.init(step, tempoTime)
        m:start()
      end
      for i=1,4 do
        if held[i] == true then
          noteDraw() --go to note selector
          noteSet[i] = true
          noteSet[5] = true
        end
      end
    end

    --reset playhead. or if row held then clear that row
    if y == 6 and x == 15 then
      if held[5] == true then --reset playhead
        seq.pos = 0
        step()
        --seq.pos = 1
        m:stop()
        metro.free_all()
        m = metro.init(step, tempoTime)
        m:start()
      end
      if held[1] == true then --clear that row
        for i=1, 16 do
          seq.one[i] = 0
        end
      end
      if held[2] == true then
        for i=1, 16 do
          seq.two[i] = 0
        end
      end
      if held[3] == true then
        for i=1, 16 do
          seq.thr[i] = 0
        end
      end
      if held[4] == true then
        for i=1, 16 do
          seq.fou[i] = 0
        end
      end

    end

    --randomize, hold row to randomize just that row
    if y == 6 and x == 16 then
      for i=1, 16 do
        if held[1] == true then --randomize just that row
          seq.one[i] = (math.random(2) - 1)
        end
        if held[2] == true then
          seq.two[i] = (math.random(2) - 1)
        end
        if held[3] == true then
          seq.thr[i] = (math.random(2) - 1)
        end
        if held[4] == true then
          seq.fou[i] = (math.random(2) - 1)
        end
        if held[5] == true then --randomize all
          seq.one[i] = (math.random(2) - 1)
          seq.two[i] = (math.random(2) - 1)
          seq.thr[i] = (math.random(2) - 1)
          seq.fou[i] = (math.random(2) - 1)
        end
      end
    end

    if y == 5 and x >= 13 then --invert row or go to set note
        invert[x-12] = invert[x-12] == 0 and 1 or 0
    end

  elseif z == 0 and noteSet[5] == false and tempoView == false then --when row released stop marking it as held
    if y >= 5 and x == 1 then
      held[y-4] = false
      if held[1] == false and held[2] == false and held[3] == false and held[4] == false then
        held[5] = true --check in case one row released when another still held
      end
    end

--------noteset screen
  elseif z == 1 and noteSet[5] == true and tempoView == false then
    if x >= 5 and y <= 8 then
      for n=1,4 do
        if noteSet[n] == true then
          notes[n] = keyToNote(x,y)
        end
      end
    end
    if x == 1 and y >= 5 and y <= 8 then

      if noteSet[y-4] == true then
        for m=1,5 do
          noteSet[m] = false
          for j=1,4 do --reset held state when returning to main screen
            held[j] = false
          end
          held[5] = true
        end
    elseif noteSet[y-4] == false then
        for m=1,5 do
          noteSet[m] = false
        end
        noteSet[y-4] = true
        noteSet[5] = true
      end
    end

-----tempo screen
  elseif z == 1 and tempoView == true then
    if y == 6 and x <=3 then
      hundreds = x-1
    end
    if y == 7 and x <=10 then
      tens = x-1
    end
    if y == 8 and x <=10 then
      ones = x-1
    end

    if x == 16 then
      div = 9-y  --set div number
      setTempo(tempo) --update tempo/div
    end

    tempo = digitsToTempo(hundreds,tens,ones)--update tempo from digits
    drawTempo() --draw the tempo screen generally

    if y == 8 and x == 13 then --tap tempo here
      tapTempo()
    end
    if y == 8 and x == 14 then --1 faster
      tempo = tempo + 1
      tempoToDigits(tempo)
      setTempo(tempo)
      drawTempo()
    end
    if y == 8 and x == 12 then --1 slower
      tempo = tempo - 1
      tempoToDigits(tempo)
      setTempo(tempo)
      drawTempo()
    end
    if y == 7 and x == 13 then --exit tempo screen
      tempoView = false
      for j=1,4 do
        held[j] = false
      end
      held[5] = true
      redraw()
    end

    setTempo(tempo)

  end
  redraw()
end

function redraw() --grid lighting
  grid_led_all(0)
  if noteSet[5] == false and tempoView == false then
    for i=1, seq.length do --will = 1(normal) or -1(invert) if step is on
      if (seq.one[i] - invert[1]) ~= 0 then
        grid_led(i, 1, 10)
      end
      if (seq.two[i] - invert[2]) ~= 0 then
        grid_led(i, 2, 10)
      end
      if (seq.thr[i] - invert[3]) ~= 0 then
        grid_led(i, 3, 10)
      end
      if (seq.fou[i] - invert[4]) ~= 0 then
        grid_led(i, 4, 10)
      end
    end
    for i=(seq.length+1), 16 do --copy of above but dimmer for inactive portion
      if (seq.one[i] - invert[1]) ~= 0 then
        grid_led(i, 1, 1)
      end
      if (seq.two[i] - invert[2]) ~= 0 then
        grid_led(i, 2, 1)
      end
      if (seq.thr[i] - invert[3]) ~= 0 then
        grid_led(i, 3, 1)
      end
      if (seq.fou[i] - invert[4]) ~= 0 then
        grid_led(i, 4, 1)
      end
    end

    if seq.pos > 0 then --protects against reset errors when paused
      for j=1,4 do --playhead
        grid_led(seq.pos, j, 5, true)
      end

      --call visuals
      if (seq.one[seq.pos] - invert[1]) ~= 0 then
        blink(1)
      end
      if (seq.two[seq.pos] - invert[2]) ~= 0 then
        blink(2)
      end
      if (seq.thr[seq.pos] - invert[3]) ~= 0 then
        blink(3)
      end
      if (seq.fou[seq.pos] - invert[4]) ~= 0 then
        blink(4)
      end
    end
    if seq.pos == 0 then--playhead edge case when reset to step 1 while paused
      for j=1,4 do
        grid_led(1, j, 5, true)
      end
    end

    --probabilities
    for j=2, 8 do
      for k=5, 8 do
        grid_led(j,k,j)
      end
    end
    for k=1,4 do
      grid_led(prob.key[k], (k+4), 13)
    end

    --row select
    for l=5,8 do
      grid_led(1,l,13)
    end

    --length
    for j=9, 16 do
      for k=7, 8 do
        grid_led(j,k,2)
      end
    end
    if seq.length <= 8 then
      grid_led((seq.length+8), 7, 13)
    elseif seq.length > 8 then
      grid_led(seq.length, 8, 13)
    end

    --patterns stored and selected
    for k=9, 12 do
      grid_led(k,5, (patterns[k-8].stored * 5))
    end
    for k=9, 12 do
      grid_led(k,6, (patterns[k-8].active * 15))
    end

    if running == true then
      grid_led(13,6,10) --stop button
      if seq.pos%div == 1 then
        grid_led(14,6,15) --go button blink on
      else
        grid_led(14,6,12) --go button blink off
      end
    else
      grid_led(14,6,15) -- brighter go button when stopped
    end
    grid_led(15,6,6) -- reset button
    grid_led(16,6,(math.random(3)+3)) --random button

    --inverts
    for l=1,4 do
      grid_led((l+12),5,((invert[l]*9)+6))
    end
  end

  if noteSet[5] == true then
    noteDraw()
  end

  if tempoView == true then
    drawTempo()
  end

  grid_refresh()
end

function keyToNote(x,y)
  return ((8-y)*12) + (x-5)
end

function noteToKey(i)
  x = (i%12)+5
  y = 8 - (math.floor(i/12))
  return x, y
end

function noteDraw()

  for i=5,16 do
    for j=1,8 do
      grid_led(i,j,displayScale[i-4])
    end
  end
  for k=1,4 do
    if noteSet[k] == true then
      local l, m = noteToKey(notes[k])
      grid_led(l,m,15)
      grid_led(1,(k+4),15)
    elseif noteSet[k] == false then
      local l, m = noteToKey(notes[k])
      grid_led(l,m,10)
      grid_led(1,(k+4),8)
    end
  end
end

function blink(i) --visualizer
  if grid_size_x() == 16 and grid_size_y() == 16 and visuals then --check if 16x16 grid and visuals on
    if i == 1 then --left
      if blinkSet[i] == true then
        for j=1,8 do
          for k=9,16 do
            grid_led(j,k,(9-j),true)
          end
        end
        blinkSet[i] = false
      end
    end
    if i == 2 then --top
      if blinkSet[i] == true then
        for j=1,16 do
          for k=9,16 do
            grid_led(j,k,(16-k),true)
          end
        end
        blinkSet[i] = false
      end
    end
    if i == 3 then --bottom
      if blinkSet[i] == true then
        for j=1,16 do
          for k=9,16 do
            grid_led(j,k,(k-8),true)
          end
        end
        blinkSet[i] = false
      end
    end
    if i == 4 then --right
      if blinkSet[i] == true then
        for j=9,16 do
          for k=9,16 do
            grid_led(j,k,(j-8),true)
          end
        end
        blinkSet[i] = false
      end
    end
  end
end

function setTempo(i)
  tempo = i
  tempoTime = 60/(tempo*div)
  m.time = tempoTime
end

function setVel(i)
  vel = i
  velMax = math.max(0, math.min(127, (vel + (velVary/2)))) --find max velocity
  velMin = math.max(0, math.min(127, (vel - (velVary/2)))) --find min velocity
end

function tempoToDigits(i)
  hundreds = math.floor(i/100)
  tens = math.floor(i/10) % 10
  ones = math.floor(i % 10)
end

function digitsToTempo(a,b,c)
  return (a*100) + (b*10) + c
end

function numberDraw(n,p) --n is number, p is x position
  if n == 0 then
    for i=1,5 do--sides of 8
      grid_led(0+p,i,nb)
      grid_led(3+p,i,nb)
    end
    for i=1,2 do --acrosses of 8
      grid_led(i+p,1,nb)
      grid_led(i+p,5,nb)
    end
  elseif n == 1 then
    for i=1,5 do
      grid_led(2+p,i,nb)
    end
  elseif n == 2 then
    for i=0,3 do
      grid_led(i+p,1,nb)--horiz lines
      grid_led(i+p,3,nb)
      grid_led(i+p,5,nb)
    end
    grid_led(3+p,2,nb)--connections
    grid_led(p,4,nb)
  elseif n == 3 then
    for i=0,3 do
      grid_led(i+p,1,nb)--horiz lines
      grid_led(i+p,3,nb)
      grid_led(i+p,5,nb)
    end
    grid_led(3+p,2,nb)
    grid_led(3+p,4,nb)
  elseif n == 4 then
    for i=1,5 do
      grid_led(3+p,i,nb)
    end
    for j=0,2 do
      grid_led(j+p,3,nb)
      grid_led(p,1+j,nb)
    end
  elseif n == 5 then
    for i=0,3 do
      grid_led(i+p,1,nb)
      grid_led(i+p,3,nb)
      grid_led(i+p,5,nb)
    end
    grid_led(3+p,4,nb)
    grid_led(p,2,nb)
  elseif n == 6 then
    for i=0,3 do
      grid_led(i+p,1,nb)
      grid_led(i+p,3,nb)
      grid_led(i+p,5,nb)
    end
    grid_led(p,2,nb)
    grid_led(p,4,nb)
    grid_led(p+3,4,nb)
  elseif n == 7 then
    for i=0,3 do
      grid_led(i+p,1,nb)
    end
    grid_led(p+3,2,nb)
    grid_led(p+2,3,nb)
    grid_led(p+2,4,nb)
    grid_led(p+2,5,nb)
  elseif n == 8 then
    for i=1,5 do
      grid_led(0+p,i,nb)
      grid_led(3+p,i,nb)
    end
    for i=1,2 do
      grid_led(i+p,1,nb)
      grid_led(i+p,3,nb)
      grid_led(i+p,5,nb)
    end
  elseif n == 9 then
    for i=1,5 do
      grid_led(3+p,i,nb)
    end
    for i=0,3 do
      grid_led(i+p,1,nb)
      grid_led(i+p,3,nb)
    end
    grid_led(p,2,nb)
  end
end

function drawTempo()
  grid_led_all(0)
  if tempo >= 100 then
    numberDraw(hundreds,1) --numberDraw does the digits
  end
  if tempo >= 10 then
    numberDraw(tens,6)
  end
  numberDraw(ones,11)
  for i=1,3 do --hundreds background
    grid_led(i,6,i)
  end
  for i=1,10 do --tens and ones background
    grid_led(i,7,i)
    grid_led(i,8,i)
  end
  for i=6,8 do
    grid_led(1,i,1)--zero dimmer to help remember these are 0-9
  end
  grid_led(hundreds+1,6,15) --show the selected digits
  grid_led(tens+1,7,15)
  grid_led(ones+1,8,15)

  for i=1,8 do
    grid_led(16,i,2) --div background
  end
  grid_led(16,9-div,15) --show current div
  grid_led(13,8,15) --tap tempo button
  if seq.pos%div == 1 then
    grid_led(13,8,15) --tap button blink on
  else
    grid_led(13,8,12) --tap button blink off
  end
  grid_led(12,8,5) --slower
  grid_led(14,8,5) --faster
  grid_led(13,7,12) --confirm

end

function tapTempo()

  taps[tc] = get_time()

  if (taps[tc] - taps[tc-1]) < 2 then --resets after 2 seconds no tap

    if tc >= 4 then --if we have enough samples (4)
      timeSum = 0
      for i=2,tc do --add up all the inter tap times
        timeSum = timeSum + (taps[i]-taps[i-1])
      end
      tapAvg = timeSum/(tc-1) --divide by number of taps
      tempo = 60 * (1/tapAvg) -- convert times to bpm
      tempoToDigits(tempo) --update the individual digits
      setTempo(tempo) --update the metro time/tempoTime from bpm
      drawTempo() --draw the tempo screen
    end
    tc = tc + 1
  else --if it's been 2s
    for i=1,tc do
      taps[tc] = 0 --erase the values
    end
    taps[1] = get_time() --get new reference time
    tc = 2 --set the count so the next tap can reference the reference time
  end
end


--initialization
createpatterns()
tempoToDigits(tempo)
m = metro.init(step, tempoTime)
m:start()
