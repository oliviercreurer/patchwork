--
-- PATCHWORK (v1.0)
-- 
-- Dual sequencer for
-- norns, grid + crow
-- @olivier
-- https://llllllll.co/t/patchwork/28800

local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local pages = {"EDIT", "COMMANDS"}
local pageNum = 1

local scaleGroup = 1
local scale_names = {}
local activeSeq = 0

local position = {1,1}
local edit = {1,1}
local length = {16,16}
local noteSel = {1,1}
local direction = {0,0}

local helpKey = 1

local keydown = {0,0}
local gridMode = {0,0}

local pattern = {
  {},
  {}
}

g = grid.connect()
local music = require 'musicutil'

mode = 1
scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)

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

function setOuts(x)
  if x == 1 then
    crow.output[2].action = "pulse(.025,5,1)"
    crow.output[4].action = "pulse(.025,5,1)"
    -- crow.ii.pullup(false)
  elseif x == 2 then
    crow.ii.pullup(true)
    crow.ii.jf.mode(1)
  end
end

-- SEQUENCE LENGTH ------------------------------------------------------

function setn_A(t,n)
  setmetatable(t,{__len=function() return n end})
end

function setn_B(t,n)
  setmetatable(t,{__len=function() return n end})
end

-- COMMANDS -------------------------------------------------------------

function build_scale()
  notes = music.generate_scale_of_length(0, params:get("scale_mode"), 8)
  for i = 1, 8 do
    table.insert(notes, notes[i])
  end
end

function newPattern_A()
  for i = 1,16 do
    table.insert(pattern[1],i,(math.random(8)))
  end
end

-- function offsetFixed_A() offset[1] = 0 end
function sync_A() position[2] = position[1]; direction[2] = direction[1] end
function offsetDec_A() offset[1] = util.clamp(offset[1]-1,-1,1) end
function offsetInc_A() offset[1] = util.clamp(offset[1]+1,-1,1) end
function newNote_A() pattern[1][position[1]] = math.random(8) end
function posRand_A() position[1] = math.random(length[1]) end
function direction_A() direction[1] = math.random(0,1) end
function rest_A() end

-- B SEQUENCE

function newPattern_B()
  for i = 1,16 do
    table.insert(pattern[2],i,(math.random(8)))
  end
end

-- function offsetFixed_B() offset[2] = 0 end
function sync_B() position[1] = position[2]; direction[1] = direction[2]  end
function offsetDec_B() offset[2] = util.clamp(offset[2]-1,-1,1) end
function offsetInc_B() offset[2] = util.clamp(offset[2]+1,-1,1) end
function newNote_B() pattern[2][position[2]] = math.random(8) end
function posRand_B() position[2] = math.random(length[2]) end
function direction_B() direction[2] = math.random(0,1) end
function rest_B() end

commands = 8

act = {
  {offsetDec_A, offsetInc_A, newNote_A, rest_A, direction_A, posRand_A, sync_A, newPattern_A}, --newPattern_A
  {offsetDec_B, offsetInc_B, newNote_B, rest_B, direction_B, posRand_B, sync_B, newPattern_B}  --newPattern_B
}

-- label = {"1", "-", "+", "N", "M", "D", "?", "P"}
-- description = {"Middle octave", "Octave down", "Octave up", "Random note", "Mute note", "Random direction", "Random position", "New pattern"}

label = {"-", "+", "N", "M", "D", "?", "1", "P"}
description = {"Octave -", "Octave +", "Random note", "Mute note", "Random direction", "Random position", "Sync sequences", "New pattern"}

function init()
  crow.init()
  crow.clear()
  crow.reset()
  crow.output[2].action = "pulse(.025,5,1)"
  crow.output[4].action = "pulse(.025,5,1)"

  for i = 1, #music.SCALES do
    table.insert(scale_names, string.lower(music.SCALES[i].name))
  end

  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 12,
    action = function() build_scale() end}

  params:add_option("output", "output", {"^^ outs", "jf ii 1+2"}, 1)
  params:set_action("output", function(x) setOuts(x) end)

  params:add_separator()

  -- REDRAW CLOCK
  clk = metro.init(intclk, 0.05, -1)
  clk:start()

  -- CREATE NEW PATTERNS
  newPattern_A()
  newPattern_B()
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
    position[1] = (position[1] % length[1]) + 1
  else
    position[1] = ((position[1] + (length[1]-2)) % length[1]) + 1
  end
  act[1][step[1][position[1]]]()
  if act[1][step[1][position[1]]] ~= act[1][4] then
    rests[1][position[1]-1] = 0
    if params:get("output") == 1 then
      crow.output[1].volts = notes[pattern[1][position[1]]]/12 + offset[1]
      crow.output[2].execute()
    else
      crow.ii.jf.play_voice(1,notes[pattern[1][position[1]]]/12 + offset[1],9)
    end
  else
    rests[1][position[1]-1] = 1
  end
  redraw()
end

function count_B()
  if direction[2] == 0 then
    position[2] = (position[2] % length[2]) + 1
  else
    position[2] = ((position[2] + (length[2]-2)) % length[2]) + 1
  end
  act[2][step[2][position[2]]]()
  if act[2][step[2][position[2]]] ~= act[2][4] then
    rests[2][position[2]-1] = 0
    if params:get("output") == 1 then
      crow.output[3].volts = notes[pattern[2][position[2]]]/12 + offset[2]
      crow.output[4].execute()
    else
      crow.ii.jf.play_voice(2,notes[pattern[2][position[2]]]/12 + offset[2],9)
    end
  else
    rests[2][position[2]-1] = 1
  end
  redraw()
end

g.key = function(x,y,z)
  if z == 1 then
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
      helpKey = y
      print(helpKey)
    end
  end
end

function intclk()
  -- g:all(0)
  setn_A(step[1],length[1])
  setn_B(step[2],length[2])
  for i=1,2 do
    if act[i][step[i][position[i]]] == act[i][7] then
      position[1] = position[2]
      -- direction[2] = direction[1]
    end
  end
  if pageNum == 1 then
    if activeSeq == 0 then
      for i=1,length[1] do
        if gridMode[1] == 0 then
          g:led(i,9-pattern[1][i],i==position[1] and 15 or 4)
        else
          g:led(i,9-step[1][i],i==position[1] and 15 or 3)
        end
      end
      g:refresh()
    else
      g:all(0)
    end
    if activeSeq == 1 then
      for i=1,length[2] do
        if gridMode[2] == 0 then
          g:led(i,9-pattern[2][i],i==position[2] and 15 or 4)
        else
          g:led(i,9-step[2][i],i==position[2] and 15 or 3)
        end
      end
      g:refresh()
    else
      g:all(0)
    end
  elseif pageNum == 2 then
    g:all(0)
    for i=1,8 do
      g:led(16,i,i==helpKey and 15 or 4)
    end
    g:refresh()
  end
  g:all(0)
  redraw()
end


function redraw()
  screen.clear()
  drawMenu()
  if pageNum == 1 then
    drawSeq_A()
    drawSeq_B()
  else
    drawHelp()
  end
  screen.update()
end

function drawHelp()
  for i=1,8 do
    if helpKey == i then
      screen.level(5)
      screen.rect(122,helpKey*7-1,4,4)
    end
  end
  screen.stroke()
  screen.level(10)
  for i=#label,1,-1 do
    screen.move(2,66-i*7)
    screen.text(label[i])
  end
  screen.level(3)
  for i=#description,1,-1 do
    screen.move(13,66-i*7)
    if i == (1+8)-helpKey then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.text(description[i])
  end
end

function drawMenu()

end

function drawSeq_A()
  if activeSeq == 0 then
    screen.level(15)
  else
    screen.level(2)
  end
  screen.move(2,10)
  screen.text("A")
  if activeSeq == 0 then
    screen.level(2)
  else
    screen.level(2)
  end
  -- screen.move(11,10)
  -- screen.text("- G:")
  screen.move(126,10)
  if gridMode[1] == 0 then
    screen.text_right("NOTES")
  else
    screen.text_right("COMMANDS")
  end
    for i=1,#step[1] do
      screen.move(i*8-4,16)
      -- screen.move(i*8-8+1,45)
      if i == position[1] then
        screen.level(15)
        screen.line_rel(0,0)
      else
        if rests[1][i-1] == 1 then
          screen.level(0)
        else
          screen.level(2)
        end
      end
      screen.line_rel(0,2)
      screen.stroke()
    end
      for i=1,#step[1] do
        if activeSeq == 0 then
          screen.level((i == edit[1]) and 15 or 2)
        else
          screen.level(2)
        end
        screen.move(i*8-6,28)
        screen.text(label[step[1][i]])
      end
end

function drawSeq_B()
  if activeSeq == 1 then
    screen.level(15)
  else
    screen.level(2)
  end
  screen.move(2,42)
  screen.text("B")
  if activeSeq == 0 then
    screen.level(2)
  else
    screen.level(2)
  end
  screen.move(11,42)
  for i=1,#step[2] do
    screen.move(i*8-4,48)
    if i == position[2] then
      screen.level(15)
    else
      if rests[2][i-1] == 1 then
        screen.level(0)
      else
        screen.level(2)
      end
    end
    screen.line_rel(0,2)
    screen.stroke()
  end
  for i=1,#step[2] do
    if activeSeq == 1 then
      screen.level((i == edit[2]) and 15 or 2)
    else
      screen.level(2)
    end
    screen.move(i*8-6,60)
    screen.text(label[step[2][i]])
  end
end

local gmode = 1

function enc(n,d)
  if n == 1 then
    if keydown[1] == 0 then
      pageNum = util.clamp(pageNum+d,1,#pages)
    end
    if keydown[1] == 1 then
      for i=1,2 do
        length[i] = util.clamp(length[i]+d,2,16)
        if edit[i] > length[i] then
          edit[i] = length[i]
        end
      end
    end
  elseif n == 2 then
    if keydown[1] == 0 then
      if activeSeq == 0 then
        edit[1] = util.clamp(edit[1]+d,1,length[1])
      else
        edit[2] = util.clamp(edit[2]+d,1,length[2])
      end
    else
      length[1] = util.clamp(length[1]+d,2,16)
      if edit[1] > length[1] then
        edit[1] = length[1]
      end
    end
  elseif n == 3 then
    if keydown[1] == 0 then
      if activeSeq == 0 then
        step[1][edit[1]] = util.clamp(step[1][edit[1]]+d, 1, commands)
      else
        step[2][edit[2]] = util.clamp(step[2][edit[2]]+d, 1, commands)
      end
    else
      length[2] = util.clamp(length[2]+d,2,16)
      if edit[2] > length[2] then
        edit[2] = length[2]
      end
    end
  end
  redraw()
end

down_time = 0
down_time1 = 0

function key(n,z)
  if n == 1 then
    keydown[1] = z
  elseif n == 2 and z == 1 then
    if keydown[1] == 0 then
      activeSeq = 1 - activeSeq
    else
      gmode = 1 - gmode
      for i=1,2 do
        gridMode[i] = gmode
      end
    end
  elseif n == 3 then
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

function patternReset()
  rests = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  newPattern()
end

function randomize_A()
  for i=1,16 do
    step[1][i] = math.random(commands)
  end
end

function randomize_B()
  for i=1,16 do
    step[2][i] = math.random(commands)
  end
end
