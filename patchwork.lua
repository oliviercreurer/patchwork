--
-- PATCHWORK (v2.0)
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

local position = {1,1}
local edit = {1,1}
local seqStart_A = 1
local seqStart_B = 1
local seqEnd_A = 16
local seqEnd_B = 16
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

function set_out_A(x)
  if x == 1 then
    crow.output[2].action = "pulse(.025,5,1)"
    crow.ii.jf.mode(0)
  elseif x == 2 then
    crow.output[4].action = "pulse(.025,5,1)"
    crow.ii.jf.mode(0)
  elseif x == 3 then
    crow.ii.pullup(true)
    crow.ii.jf.mode(1)
  end
end

function set_out_B(x)
  if x == 1 then
    crow.output[2].action = "pulse(.025,5,1)"
    crow.ii.jf.mode(0)
  elseif x == 2 then
    crow.output[4].action = "pulse(.025,5,1)"
    crow.ii.jf.mode(0)
  elseif x == 3 then
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
function posRand_A() position[1] = math.random(seqStart_A,seqEnd_A) end
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
function posRand_B() position[2] = math.random(seqStart_B,seqEnd_B) end
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

  sync_A()

  for i = 1, #music.SCALES do
    table.insert(scale_names, string.lower(music.SCALES[i].name))
  end

  -- params

  params:add_group("PATCHWORK", 8)

  params:add_option("output_a", "output (A)", {"crow 1+2", "crow 3+4", "jf.vox 1", "jf.vox 2", "jf.note", "midi"}, 1)
  params:set_action("output_a", function(x) set_out_A(x) end)

  params:add_option("output_b", "output (B)", {"crow 1+2", "crow 3+4", "jf.vox 1", "jf.vox 2", "jf.note", "midi"}, 2)
  params:set_action("output_b", function(x) set_out_B(x) end)

  params:add{type = "option", id = "scale_mode", name = "scale",
    options = scale_names, default = 12,
    action = function() build_scale() end}

  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return music.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}

  params:add_separator("Midi")

  params:add{type = "number", id = "midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1,
    action = function(value) midi_out_device = midi.connect(value) end}

  params:add{type = "number", id = "midi_out_channel_A", name = "midi out channel (A)",
    min = 1, max = 16, default = 1,
    action = function(value)
      all_notes_off(1)
      midi_out_channel_A = value
    end}
  params:add{type = "number", id = "midi_out_channel_B", name = "midi out channel (B)",
    min = 1, max = 16, default = 2,
    action = function(value)
      all_notes_off(2)
      midi_out_channel_B = value
    end}


  -- REDRAW CLOCK
  clk = metro.init(intclk, 0.05, -1)
  clk:start()

  -- CREATE NEW PATTERNS
  newPattern_A(seqStart_A,seqEnd_A)
  newPattern_B(seqStart_B,seqEnd_B)
  build_scale()

  -- CROW SETUP
  -- Inputs
  crow.input[1].change = count_A
  crow.input[1].mode("change", 1.0, 0.25, "rising")
  crow.input[2].change = count_B
  crow.input[2].mode("change", 1.0, 0.25, "rising")
end

function count_A()
  if direction[1] == 0 then
    position[1] = (position[1]-seqStart_A+1) % (seqEnd_A-seqStart_A+1) + seqStart_A
  else
    position[1] = (position[1]-seqStart_A-1) % (seqEnd_A-seqStart_A+1) + seqStart_A
  end
  act[1][step[1][position[1]]](seqStart_A,seqEnd_A)
  if act[1][step[1][position[1]]] ~= act[1][4] then
    rests[1][position[1]-1] = 0
    if params:get("output_a") ~= 6 then
      all_notes_off(1)
    end
    if params:get("output_a") == 1 then
      crow.output[1].volts = notes[pattern[1][position[1]]]/12 + offset[1]
      crow.output[2].execute()
    elseif params:get("output_a") == 2 then
      crow.output[3].volts = notes[pattern[1][position[1]]]/12 + offset[1]
      crow.output[4].execute()
    elseif params:get("output_a") == 3 then
      crow.ii.jf.play_voice(1,notes[pattern[1][position[1]]]/12 + offset[1],9)
    elseif params:get("output_a") == 4 then
      crow.ii.jf.play_voice(2,notes[pattern[1][position[1]]]/12 + offset[1],9)
    elseif params:get("output_a") == 5 then
      crow.ii.jf.play_note(notes[pattern[1][position[1]]]/12 + offset[1],9)
    elseif params:get("output_a") == 6 then
      all_notes_off(1)
      --midi_out_device:note_on((notes[pattern[1][position[1]]] + 60) + offset[1],127,midi_out_channel_A)
      midi_out_device:note_on((notes[pattern[1][position[1]]] + 60) + offset[1],127,params:get("midi_out_channel_A"))
      table.insert(active_notes[1], (notes[pattern[1][position[1]]] + 60) + offset[1])
    end
  else
    rests[1][position[1]-1] = 1
  end
  redraw()
end

function count_B()
  if direction[2] == 0 then
    position[2] = (position[2]-seqStart_B+1) % (seqEnd_B-seqStart_B+1) + seqStart_B
  else
    position[2] = (position[2]-seqStart_B-1) % (seqEnd_B-seqStart_B+1) + seqStart_B
  end
  act[2][step[2][position[2]]](seqStart_B,seqEnd_B)
  if act[2][step[2][position[2]]] ~= act[2][4] then
    rests[2][position[2]-1] = 0
    if params:get("output_b") ~= 6 then
      all_notes_off(2)
    end
    if params:get("output_b") == 1 then
      crow.output[1].volts = notes[pattern[2][position[2]]]/12 + offset[2]
      crow.output[2].execute()
    elseif params:get("output_b") == 2 then
      crow.output[3].volts = notes[pattern[2][position[2]]]/12 + offset[2]
      crow.output[4].execute()
    elseif params:get("output_b") == 3 then
      crow.ii.jf.play_voice(1,notes[pattern[2][position[2]]]/12 + offset[2],9)
    elseif params:get("output_b") == 4 then
      crow.ii.jf.play_voice(2,notes[pattern[2][position[2]]]/12 + offset[2],9)
    elseif params:get("output_b") == 5 then
      crow.ii.jf.play_note(notes[pattern[2][position[2]]]/12 + offset[2],9)
    elseif params:get("output_b") == 6 then
      all_notes_off(2)
      --midi_out_device:note_on((notes[pattern[2][position[2]]] + 60) + offset[2],127,midi_out_channel_B)
      midi_out_device:note_on((notes[pattern[2][position[2]]] + 60) + offset[2],127,params:get("midi_out_channel_B"))
      table.insert(active_notes[2], (notes[pattern[2][position[2]]] + 60) + offset[2])
    end
  else
    rests[2][position[2]-1] = 1
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
          for i=seqStart_A,seqEnd_A do
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
          for i=seqStart_B,seqEnd_B do
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
    screen.text(params:string("output_a"))
    screen.rect(18,54,2,2)
    screen.fill()
  else
    screen.move(11,57)
    screen.level(15)
    screen.text("B")
    screen.level(2)
    screen.move(23,57)
    screen.text(params:string("output_b"))
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
  for i=seqStart_A,seqEnd_A do
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
  for i=seqStart_B,seqEnd_B do
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
        seqStart_A = util.clamp(seqStart_A+d,1,seqEnd_A-1)
      end
    else
      if keydown[2] == 0 then
        edit[2] = util.clamp(edit[2]+d,1,length[2])
      else
        seqStart_B = util.clamp(seqStart_B+d,1,seqEnd_B-1)
      end
    end
  elseif n == 3 then
    if activeSeq == 0 then
      if keydown[2] == 0 then
        step[1][edit[1]] = util.clamp(step[1][edit[1]]+d, 1, commands)
      else
        seqEnd_A = util.clamp(seqEnd_A+d,seqStart_A+1,16)
      end
    else
      if keydown[2] == 0 then
        step[2][edit[2]] = util.clamp(step[2][edit[2]]+d, 1, commands)
      else
        seqEnd_B = util.clamp(seqEnd_B+d,seqStart_B+1,16)
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
  for i=seqStart_A,seqEnd_A do
    step[1][i] = math.random(commands)
  end
end

function randomize_B()
  for i=seqStart_B,seqEnd_B do
    step[2][i] = math.random(commands)
  end
end

function cleanup()
  crow.clear()
  crow.reset()
  if params:get("output") == 2 or 3 then
    crow.ii.jf.mode(0)
  end
end
