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
local RUN_SPEED = 12
local RUN_ACC = 0.3
local JUMP_WARMUP = 10
local JUMP_HEIGHT = -64
local PUNCH_HEIGHT = -128
local PUNCH_COEFF = 0.3  -- reduces horizontal speed during punch :)
local JUMP_TIME = 15
local ABSORB_DIST = 48
local MAX_ABSORB_TIME = JUMP_TIME
local STAND_FRAMES = 5
local REDIRECT_SPEED = RUN_SPEED / 4

-- s(t) = 1/2 at^2 + ut
-- s(2*_t) = 0 => u = -a*_t
--             => s = at(t/2 - _t)
function vel_from_acc_time(acc, time)
  return -acc * time
end

-- s(_t) = _s => a = -2*_s/(_t^2)
function acc_from_arc(height, time)
  return -2 * height / (time * time)
end

-- _t = -u / a, s(_t) = _s
-- => _s = 1/2 a (-u/a)^2 + u (-u/a)
--       = (u^2/a)(1/2 - 1)
-- => u = sqrt(-2*_s*a)
function vel_from_acc_height(acc, height)
  return -math.sqrt(-2*height*acc)
end

function from_arc(height, time)
  local acc = acc_from_arc(height, time)
  local vel = vel_from_acc_time(acc, time)
  return acc, vel
end

local JUMP_ACC, JUMP_VEL = from_arc(JUMP_HEIGHT, JUMP_TIME)
local PUNCH_VEL = vel_from_acc_height(JUMP_ACC, PUNCH_HEIGHT)

function modes.update(body)
  modes[body.mode](body)
end

function modes.falling(body)
  if body.y > FLOOR_HEIGHT then
    body.mode = "redirect"
    body.y = FLOOR_HEIGHT
    body.prev_vel_x, body.prev_vel_y = body.vel_x, body.vel_y
    body.vel_x, body.vel_y = 0, 0
    body.acc_y = 0
    body.stand_frames = 0
  end
end

function modes.redirect(body)
  if body.stand_frames > STAND_FRAMES then
    body.stand_frames = nil
    perform_redirect(body)
  else
    body.stand_frames = body.stand_frames + 1
  end
end

function perform_redirect(body)
  local dir = keyboard_walk_direction()
  if dir * body.prev_vel_x > 0 then
    body.vel_x = body.prev_vel_x
  else
    body.vel_x = REDIRECT_SPEED * dir
  end
  if love.keyboard.isDown("z") then
    start_jump(body, PUNCH_VEL)
    body.vel_x = body.vel_x * PUNCH_COEFF
  else
    body.mode = "walking"
  end
  body.prev_vel_x, body.prev_vel_y = nil, nil
end

function modes.walking(body)
  update_walk_direction(body)
  update_jump_input(body)
end

function keyboard_walk_direction()
  local l = love.keyboard.isDown("left")
  local r = love.keyboard.isDown("right")

  if l and not r then
    return -1
  elseif r and not l then
    return 1
  else
    return 0
  end
end

function update_walk_direction(body)
  local dir = keyboard_walk_direction()

  if dir == 0 then
    if body.vel_x < -RUN_ACC then
      dir = 1
    elseif RUN_ACC < body.vel_x then
      dir = -1
    else
      body.vel_x = 0
    end
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
    jump_vel = vel_from_acc_time(JUMP_ACC, absorb_time)
  end
  if jump_vel then
    start_jump(body, jump_vel)
  end
end

function start_jump(body, vel)
  body.vel_y = vel
  body.acc_x = 0
  body.acc_y = JUMP_ACC
  body.jump_frames = nil
  body.mode = "falling"
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
