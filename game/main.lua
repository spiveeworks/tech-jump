local tiles = {}
local level = {}
local bodies = {}

function tiles.load(self, path)
  self.img = love.graphics.newImage(path)

  self.width, self.height = 32,32
  self.img_width = self.img:getWidth()
  self.img_height = self.img:getHeight()

  tiles.quads = {}
  for j = 0, 1 do
    for i = 0, 1 do
      tiles.quads[j * 2 + i + 1] = love.graphics.newQuad(
        i * self.width, j * self.height,
        self.width, self.height,
        self.img_width, self.img_height
      )
    end
  end
end

function level.generate(self)
  self.width, self.height = 25, 19
  for x = 1, self.width do
    self[x] = {}
    self[x][self.height - 1] = 1
    self[x][self.height] = 1
  end
end

function bodies.generate(self)
  local player = {}
  player.mode = "falling"
  player.next_mode = "walking"
  player.x, player.y = 600, 350
  player.vel_x, player.vel_y = 0, 0
  player.acc_x, player.acc_y = 0, 1
  self[1] = player
end

function love.load()
  tiles:load('tileset.png')
  level:generate()
  bodies:generate()
end

local modes = {}
local FLOOR_HEIGHT = 16*32
local RUN_SPEED = 10
local RUN_ACC = 0.3
local JUMP_WARMUP = 10
local JUMP_HEIGHT = -100
local JUMP_TIME = 15
local ABSORB_DIST = 16
local MAX_ABSORB_TIME = 15

-- s(t) = 1/2 at^2 + ut
-- s(2*_t) = 0 => u = -a*_t
--             => s = at(t/2 - _t)
-- s(_t) = _s => a = -2*_s/(_t^2)
function acc_from_arc(height, time)
  return -2 * height / (time * time)
end

function vel_from_acc(acc, time)
  return -acc * time
end

function from_arc(height, time)
  local acc = acc_from_arc(height, time)
  local vel = vel_from_acc(acc, time)
  return acc, vel
end

local JUMP_ACC, JUMP_VEL = from_arc(JUMP_HEIGHT, JUMP_TIME)

function modes.update(body)
  modes[body.mode](body)
end

function modes.falling(body)
  if body.y > FLOOR_HEIGHT then
    body.mode = "walking"
    body.next_mode = nil
    body.y = FLOOR_HEIGHT
    body.vel_x = 0
    body.vel_y = 0
    body.acc_y = 0
  end
end

function modes.walking(body)
  update_walk_direction(body)
  update_jump_input(body)
end

function update_walk_direction(body)
  local l = love.keyboard.isDown("left")
  local r = love.keyboard.isDown("right")

  local dir = 0
  if l and not r then
    dir = -1
  elseif r and not l then
    dir = 1
  elseif body.vel_x < -RUN_ACC then
    dir = 1
  elseif RUN_ACC < body.vel_x then
    dir = -1
  else
    body.vel_x = 0
  end
  if dir * body.vel_x > RUN_SPEED then
    body.vel_x = RUN_SPEED * dir
    dir = 0
  end
  body.acc_x = dir * RUN_ACC
end

function update_jump_input(body)
  local jump_vel = nil
  if love.keyboard.isDown("z") then
    body.jump_frames = (body.jump_frames or -1) + 1
    if body.jump_frames > JUMP_WARMUP then
      jump_vel = JUMP_VEL
    end
  elseif body.jump_frames then
    local absorb_time = ABSORB_DIST / body.vel_x
    if absorb_time < 0 then
      absorb_time = -absorb_time
    end
    if absorb_time > MAX_ABSORB_TIME then
      absorb_time = MAX_ABSORB_TIME
    end
    jump_vel = vel_from_acc(JUMP_ACC, absorb_time)
  end
  if jump_vel then
    body.vel_y = jump_vel
    body.acc_x = 0
    body.acc_y = JUMP_ACC
    body.jump_frames = nil
    body.mode = "falling"
  end
end

function love.update()
  for _, body in ipairs(bodies) do
    body.x = body.x + body.vel_x
    body.y = body.y + body.vel_y
    body.vel_x = body.vel_x + body.acc_x
    body.vel_y = body.vel_y + body.acc_y

    modes.update(body)
  end
end

function love.draw()
  for x = 1, level.width do
    for y = 1, level.height do
      local id = level[x][y]
      if id then
        love.graphics.draw(tiles.img, tiles.quads[id], (x - 1) * 32, (y - 1) * 32)
      end
    end
  end

  for _, body in ipairs(bodies) do
    love.graphics.setColor(255, 255, 255)
    love.graphics.ellipse("fill", body.x, body.y, 16, 32)
  end
end
