--
-- PATCHWORK (v2.1)
--
-- Dual sequencer for
-- norns, grid + crow
-- @olivier
-- llllllll.co/t/patchwork/28800
--
-- See full documentation
-- in library post on lines
--
--

local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local pages = {"EDIT", "COMMANDS"}
local pageNum = 1

local scaleGroup = 1
local scale_names = {}
local scaleLength = 8
local activeSeq = 0

local bpm = {a=120,b=120}

local position = {1,1}
local edit = {1,1}
seqStart = {}
seqStart["A"] = 1
seqStart["B"] = 1
seqEnd = {}
seqEnd["A"] = 16
seqEnd["B"] = 16

local length = {16,16}
local noteSel = {1,1}
local direction = {0,0}

local helpKey = 1

local keydown = {0,0,0}
local gridMode = {0,0}

local midi_out_device
local midi_out_channel_A
local midi_out_channel_B

local pattern = {
  {},
  {}
}

active_notes = {
  {},
  {},
}

g = grid.connect()
local music = require 'musicutil'


local offset = {0,0}
local notes = {}

local step = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
}

local rests = {
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
}

local clk_mod = {
  {1, "1/8"},
  {2, "1/4"},
  {4, "1/2"},
  {6, "3/4"},
  {8, "none"},
  {12, "3/2"},
  {16, "2/1"},
  {24, "3/1"},
  {32, "4/1"},
}

function set_outs(target)
  local output_param = params:get(target == 1 and "output_a" or "output_b")
  if output_param == 1 then
    crow.output[2].action = "pulse(.025,5,1)"
  elseif output_param == 2 then
    crow.output[4].action = "pulse(.025,5,1)"
  elseif output_param == 3 or 4 or 5 then
    crow.ii.pullup(true)
    crow.ii.jf.mode(1)
  end
end

-- COMMANDS

function build_scale()
  notes = music.generate_scale_of_length(params:get("root_note")-60, params:get("scale_mode"), scaleLength)
  for i = 1, 7 do
    table.insert(notes, notes[i])
  end
end

-- A SEQUENCE COMMANDS

function newPattern_A(a,b)
  for i = a,b do
    pattern[1][i] = math.random(scaleLength)
  end
end

function sync_A() position[2] = position[1]; direction[2] = direction[1] end

function offsetDec_A()
  if params:get("output_a") ~= 6 then
    offset[1] = util.clamp(offset[1]-1,-1,1)
  else
    offset[1] = -12
  end
end

function offsetInc_A()
  if params:get("output_a") ~= 6 then
    offset[1] = util.clamp(offset[1]+1,-1,1)
  else
    offset[1] = 12
  end
end

function newNote_A() pattern[1][position[1]] = math.random(scaleLength) end
function posRand_A() position[1] = math.random(seqStart["A"],seqEnd["A"]) end
function direction_A() direction[1] = math.random(0,1) end
function rest_A() end

-- B SEQUENCE COMMANDS

function newPattern_B(a,b)
  for i = a,b do
    pattern[2][i] = math.random(scaleLength)
  end
end


function sync_B() position[1] = position[2]; direction[1] = direction[2]  end

function offsetDec_B()
  if params:get("output_b") ~= 6 then
    offset[2] = util.clamp(offset[2]-1,-1,1)
  else
    offset[2] = -12
  end
end

function offsetInc_B()
  if params:get("output_b") ~= 6 then
    offset[2] = util.clamp(offset[2]+1,-1,1)
  else
    offset[2] = 12
  end
end

function newNote_B() pattern[2][position[2]] = math.random(scaleLength) end
function posRand_B() position[2] = math.random(seqStart["B"],seqEnd["B"]) end
function direction_B() direction[2] = math.random(0,1) end
function rest_B() end

commands = 8

act = {
  {offsetDec_A, offsetInc_A, newNote_A, rest_A, direction_A, posRand_A, sync_A, newPattern_A},
  {offsetDec_B, offsetInc_B, newNote_B, rest_B, direction_B, posRand_B, sync_B, newPattern_B}
}

label = {"-", "+", "N", "*", "D", "?", "1", "P"}
description = {"Shift down an octave", "Shift up an octave", "New note", "Mute note", "Random direction", "Random step position", "Sync sequences", "Create new pattern"}

function all_notes_off(target)
  for _, a in pairs(active_notes[target]) do
    if target == 1 then
      midi_out_device:note_off(a, nil, params:get("midi_out_channel_A"))
    elseif target == 2 then
      midi_out_device:note_off(a, nil, params:get("midi_out_channel_B"))
    end
  end
  active_notes[target] = {}
end



function init()
  -- crow initialization
  crow.init()
  crow.clear()
  crow.reset()
  crow.output[2].action = "pulse(.025,5,1)"
  crow.output[4].action = "pulse(.025,5,1)"

  -- midi initialization
  midi_out_device = midi.connect(1)

  -- encoder 1 sensitivity
  norns.enc.sens(1,5)

  -- clocks
  seq_clk = {}
  sync_A()

  for i = 1, #music.SCALES do
    table.insert(scale_names, string.lower(music.SCALES[i].name))
  end

  -- params

  params:set("clock_tempo",120)

  params:add_group("PATCHWORK", 16)

  params:add_option("output_a", "output (A)", {"crow 1+2", "crow 3+4", "jf.vox 1", "jf.vox 2", "jf.note", "midi"}, 1)
  params:set_action("output_a", function(x) set_outs(1) end)

  params:add_option("output_b", "output (B)", {"crow 1+2", "crow 3+4", "jf.vox 1", "jf.vox 2", "jf.note", "midi"}, 1)
  params:set_action("output_b", function(x) set_outs(2) end)

  params:add{type = "option", id = "scale_mode", name = "scale",
    options = scale_names, default = 12,
    action = function() build_scale() end}

  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return music.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}

  params:add_separator("Sequence A")

  params:add{type = "number", id = "bpm_a", name = "BPM (A)",
    min = 20, max = 240, default = 120,
    action = function(x) params:set("clock_tempo",x); bpm.a = x; print(bpm.a); params:set("bpm_b",x) end}

  params:add_option("mod_a", "Div/mult (A)", {
    clk_mod[1][2],
    clk_mod[2][2],
    clk_mod[3][2],
    clk_mod[4][2],
    clk_mod[5][2],
    clk_mod[6][2],
    clk_mod[7][2],
    clk_mod[8][2],
    clk_mod[9][2],
  }, 5)

  params:add{type = "number", id = "prob_a", name = "Probability (A)",
    min = 0, max = 100, default = 100,
    action = function(value) end}

  params:add_separator("Sequence B")

  params:add{type = "number", id = "bpm_b", name = "BPM (B)",
    min = 20, max = 240, default = 120,
    action = function(value) end}

  params:add_option("mod_b", "Div/mult (B)", {
    clk_mod[1][2],
    clk_mod[2][2],
    clk_mod[3][2],
    clk_mod[4][2],
    clk_mod[5][2],
    clk_mod[6][2],
    clk_mod[7][2],
    clk_mod[8][2],
    clk_mod[9][2],
  }, 5)

  params:add{type = "number", id = "prob_b", name = "Probability (B)",
    min = 0, max = 100, default = 100,
    action = function(value) end}

  params:add_separator("Midi")

  params:add{type = "number", id = "midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1,
    action = function(value)
      midi_out_device = midi.connect(value)
      for i = 1,127 do
        midi_out_device:note_off(i, nil, midi_out_channel_A)
        midi_out_device:note_off(i, nil, midi_out_channel_B)
      end
    end}

  params:add{type = "number", id = "midi_out_channel_A", name = "midi out channel (A)",
    min = 1, max = 16, default = 1,
    action = function(value)
      all_notes_off(1)
      for i = 1,127 do
        midi_out_device:note_off(i, nil, value-1)
        midi_out_device:note_off(i, nil, value+1)
      end
      midi_out_channel_A = value
    end}
  params:add{type = "number", id = "midi_out_channel_B", name = "midi out channel (B)",
    min = 1, max = 16, default = 2,
    action = function(value)
      all_notes_off(2)
      for i = 1,127 do
        midi_out_device:note_off(i, nil, value-1)
        midi_out_device:note_off(i, nil, value+1)
      end
      midi_out_channel_B = value
    end}


  -- REDRAW CLOCK
  draw_clk = metro.init(intclk, 0.05, -1)
  draw_clk:start()

  -- CREATE NEW PATTERNS
  newPattern_A(seqStart["A"],seqEnd["A"])
  newPattern_B(seqStart["B"],seqEnd["B"])
  build_scale()

  run()
end

function run()
  for i=1,2 do
    seq_clk[i] = clock.run(bang,i)
  end
end

function bang(x)
  while true do
    local chance = math.random(0,100)
    local seq = x == 1 and "a" or "b"
    if x == 1 then
      clock.sync(1/(clk_mod[params:get("mod_a")][1]/8))
    end
    if x == 2 then
    clock.sync(1/ (params:get("bpm_b")/clock.get_tempo()) / (clk_mod[params:get("mod_b")][1]/8) )
    end
    if chance <= params:get("prob_"..seq) then
      count(x)
    end
  end
end

function count(x)
  local Start = seqStart[x == 1 and "A" or "B"]
  local End = seqEnd[x == 1 and "A" or "B"]
  local seq = x == 1 and "a" or "b"
  if direction[x] == 0 then
    position[x] = (position[x]-Start+1) % (End-Start+1) + Start
  else
    position[x] = (position[x]-Start-1) % (End-Start+1) + Start
  end
  act[x][step[x][position[x]]](Start,End)
  if act[x][step[x][position[x]]] ~= act[x][4] then
    rests[x][position[x]-1] = 0
    local output_param = params:get(x == 1 and "output_a" or "output_b")
    if output_param ~= 6 then
      all_notes_off(x)
    end
    if output_param == 1 then
      crow.output[1].volts = notes[pattern[x][position[x]]]/12 + offset[x]
      crow.output[2].execute()
    elseif output_param == 2 then
      crow.output[3].volts = notes[pattern[x][position[x]]]/12 + offset[x]
      crow.output[4].execute()
    elseif output_param == 3 then
      crow.ii.jf.play_voice(1,notes[pattern[x][position[x]]]/12 + offset[x],9)
    elseif output_param == 4 then
      crow.ii.jf.play_voice(2,notes[pattern[x][position[x]]]/12 + offset[x],9)
    elseif output_param == 5 then
      crow.ii.jf.play_note(notes[pattern[x][position[x]]]/12 + offset[x],9)
    elseif output_param == 6 then
      all_notes_off(x)
      midi_out_device:note_on((notes[pattern[x][position[x]]] + 60) + offset[x],127,params:get(x == 1 and "midi_out_channel_A" or "midi_out_channel_B"))
      table.insert(active_notes[x], (notes[pattern[x][position[x]]] + 60) + offset[x])
    end
  else
    rests[x][position[x]-1] = 1
  end
  redraw()
end

-- GRID FUNCTIONS

g.key = function(x,y,z)

  if z == 1 then
    if keydown[1] == 0 then
      if pageNum == 1 then
        if activeSeq == 0 then
          if gridMode[1] == 0 then
            pattern[1][x] = 9-y
          else
            if y > 0 then
              step[1][x] = 9-y
            end
          end
        else
          if gridMode[2] == 0 then
            pattern[2][x] = 9-y
          else
            if y > 0 then
              step[2][x] = 9-y
            end
          end
        end
      else
        helpKey = (1+8) - y
        print(helpKey)
      end
    else
      if activeSeq == 0 then

      end
    end
  end
end

function intclk()
  if bpm.a ~= clock.get_tempo() then
    params:set("bpm_a", math.floor(clock.get_tempo()))
    params:set("bpm_b", math.floor(clock.get_tempo()))
    --params:set("bpm_b", string.format("%.0f",clock.get_tempo()))
  end
  for i=1,2 do
    if act[i][step[i][position[i]]] == act[i][7] then
      position[1] = position[2]
    end
  end
  if pageNum == 1 then
    if activeSeq == 0 then
      for i=1,16 do
        if gridMode[1] == 0 then
          g:led(i,9-pattern[1][i],2)
          for i=seqStart["A"],seqEnd["A"] do
            g:led(i,9-pattern[1][i],i==position[1] and 15 or 8)
          end
        else
          g:led(i,9-step[1][i],i==position[1] and 15 or 8)
        end
      end
      g:refresh()
    else
      g:all(0)
    end
    if activeSeq == 1 then
      for i=1,16 do
        if gridMode[2] == 0 then
          g:led(i,9-pattern[2][i],2)
          for i=seqStart["B"],seqEnd["B"] do
            g:led(i,9-pattern[2][i],i==position[2] and 15 or 8)
          end
        else
          g:led(i,9-step[2][i],i==position[2] and 15 or 8)
        end
      end
      g:refresh()
    else
      g:all(0)
    end
  elseif pageNum == 2 then
    g:all(0)
    for i=1,8 do
      g:led(((1+8)-i)+4,i,i==(1+8)-helpKey and 15 or 4)
    end
    g:refresh()
  end
  g:all(0)
  redraw()
end

-- SCREEN

function redraw()
  screen.clear()
  if pageNum == 1 then
    draw_info()
    draw_comm_rows()
    draw_seq()
  else
    drawHelp()
  end
  screen.update()
end

function drawHelp()
  for i=1,#label do
    if helpKey == i then
      screen.level(15)
    else
      screen.level(4)
    end
    screen.move(i*8+25,25)
    screen.text(label[i])
  end
  screen.level(2)
  screen.move(33,32)
  screen.line(93,32)
  screen.stroke()
  for i=1,#description do
    screen.level(2)
    screen.move(64,45)
    screen.text_center(description[helpKey])
  end
end


function draw_info()
  if activeSeq == 0 then
    screen.move(11,57)
    screen.level(15)
    screen.text("A")
    screen.level(2)
    screen.move(23,57)
    screen.text(params:string("output_a").." / "..params:get("bpm_a").."BPM")
    screen.rect(18,54,2,2)
    screen.fill()
  else
    screen.move(11,57)
    screen.level(15)
    screen.text("B")
    screen.level(2)
    screen.move(23,57)
    screen.text(params:string("output_b").." / "..params:get("bpm_b").."BPM")
    screen.rect(18,54,2,2)
    screen.fill()
  end
  --
  screen.level(2)
  screen.move(110,60)
  screen.rect(108,52,2,2)
  screen.rect(111,52,2,2)
  screen.rect(108,55,2,2)
  screen.rect(111,55,2,2)
  screen.fill()
  screen.move(120,57)
  screen.level(5)
  if gridMode[1] and gridMode[2] == 0 then
    screen.text_right("N")
  elseif gridMode[1] and gridMode[2] == 1 then
    screen.text_right("C")
  end
end

function draw_comm_rows()
  -- SEQUENCE A
  if activeSeq == 0 then
    screen.level(15)
  else
    screen.level(0)
  end
  screen.move(4,20)
  screen.text(">")
  for i=1,#step[1] do
    if activeSeq == 0 then
      screen.level((i == edit[1]) and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*7+4,20)
    screen.text(label[step[1][i]])
  end
  -- SEQUENCE B
  if activeSeq == 1 then
    screen.level(15)
  else
    screen.level(0)
  end
  screen.move(4,42)
  screen.text(">")
  for i=1,#step[2] do
    if activeSeq == 1 then
      screen.level((i == edit[2]) and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*7+4,42)
    screen.text(label[step[2][i]])
  end
  screen.level(2)
  screen.move(10,47)
  screen.line(120,47)
  screen.stroke()
end



function draw_seq()
  -- SEQUENCE A
  for i=seqStart["A"],seqEnd["A"] do
    if i == position[1] then
      screen.level(15)
    else
      if rests[1][i-1] == 1 then
        screen.level(0)
      else
        screen.level(4)
      end
    end
    screen.rect(i*7+4,8,3,3)
    screen.fill()
  end
  -- SEQUENCE B
  for i=seqStart["B"],seqEnd["B"] do
    if i == position[2] then
      screen.level(15)
    else
      if rests[2][i-1] == 1 then
        screen.level(0)
      else
        screen.level(4)
      end
    end
    screen.rect(i*7+4,30,3,3)
    screen.fill()
  end
  screen.level(2)
  screen.move(10,25)
  screen.line(120,25)
  screen.stroke()
end

local gmode = 1

function enc(n,d)
  if n == 1 then
    if keydown[1] == 0 then
      gmode = util.clamp(gmode+d,0,1)
      for i=1,2 do
        gridMode[i] = gmode
      end
      print(gmode)
    end
  elseif n == 2 then
    if activeSeq == 0 then
      if keydown[2] == 0 then
        edit[1] = util.clamp(edit[1]+d,1,length[1])
      else
        seqStart["A"] = util.clamp(seqStart["A"]+d,1,seqEnd["A"]-1)
      end
    else
      if keydown[2] == 0 then
        edit[2] = util.clamp(edit[2]+d,1,length[2])
      else
        seqStart["B"] = util.clamp(seqStart["B"]+d,1,seqEnd["B"]-1)
      end
    end
  elseif n == 3 then
    if activeSeq == 0 then
      if keydown[2] == 0 then
        step[1][edit[1]] = util.clamp(step[1][edit[1]]+d, 1, commands)
      else
        seqEnd["A"] = util.clamp(seqEnd["A"]+d,seqStart["A"]+1,16)
      end
    else
      if keydown[2] == 0 then
        step[2][edit[2]] = util.clamp(step[2][edit[2]]+d, 1, commands)
      else
        seqEnd["B"] = util.clamp(seqEnd["B"]+d,seqStart["B"]+1,16)
      end
    end
  end
  redraw()
end

down_time = 0

function key(n,z)
  if n == 1 then
    keydown[1] = z
    if z == 1 then
      down_time = util.time()
    else
      hold_time = util.time() - down_time
      if hold_time > 1 then
        pageNum = (pageNum % 2) + 1
        print(pageNum)
      end
    end
  elseif n == 2 then
    keydown[2] = z
    if z == 1 then
      down_time = util.time()
    else
      hold_time = util.time() - down_time
      if hold_time < 1 then
        activeSeq = 1 - activeSeq
      else
        -- nothing for now
      end
    end
  elseif n == 3 then
    keydown[3] = z
    if z == 1 then
      down_time = util.time()
    else
      hold_time = util.time() - down_time
      if activeSeq == 0 then
        if hold_time < 1 then
          randomize_A()
        else
          for i=1,#step[1] do
          step[1][i] = 1
          end
        end
      else
        if hold_time < 1 then
          randomize_B()
        else
          for i=1,#step[2] do
          step[2][i] = 1
          end
        end
      end
    end
  end
  redraw()
end

function randomize_A()
  for i=seqStart["A"],seqEnd["A"] do
    step[1][i] = math.random(commands)
  end
end

function randomize_B()
  for i=seqStart["B"],seqEnd["B"] do
    step[2][i] = math.random(commands)
  end
end

function fuck_up_the_midi()
  for i = 1,127 do
    midi_out_device:note_off(i, nil, params:get("midi_out_channel_A"))
    midi_out_device:note_off(i, nil, params:get("midi_out_channel_B"))
  end
end

function cleanup()
  crow.clear()
  crow.reset()
  if params:get("output") == 2 or 3 then
    crow.ii.jf.mode(0)
  end
  fuck_up_the_midi()
end
