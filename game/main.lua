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
local STANDING_JUMP_SPEED = 3
local JUMP_WARMUP = 10
local JUMP_HEIGHT = -64
local PUNCH_HEIGHT = -128
local PUNCH_SPEED = 3
local PUNCH_THRESHOLD = 10
local BOUNCE_THRESHOLD = 4
local JUMP_TIME = 15
local HOP_DIST = 48
local HOP_THRESHOLD = 3  -- 10 frames
local STAND_FRAMES = 5

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

function is_jump_down()
  return love.keyboard.isDown("z")
end

function modes.falling(body)
  if body.y > FLOOR_HEIGHT then
    body.y = FLOOR_HEIGHT
    if not body.pressed_z then
      body.z_released = nil
      body.mode = "walking"
      if body.is_hopping then
        body.vel_x = 0
      end
      body.vel_y = 0
      body.acc_y = 0
    elseif math.abs(body.vel_x) >= PUNCH_THRESHOLD
        and body.vel_y <= BOUNCE_THRESHOLD then
      if body.vel_x > 0 then
        body.vel_x = PUNCH_SPEED
      else
        body.vel_x = -PUNCH_SPEED
      end
      body.z_released = nil
      start_jump(body, PUNCH_VEL)
    else
      body.prev_vel_x, body.prev_vel_y = body.vel_x, body.vel_y
      if not body.is_hopping then
        body.vel_x = 0
      end
      body.vel_y = 0
      body.acc_y = 0
      body.mode = "redirect"
    end
    body.pressed_z = nil
    body.is_hopping = nil
  elseif not is_jump_down() and not body.z_released then
    body.z_released = true
  elseif is_jump_down() and body.z_released then
    body.pressed_z = true
    body.z_released = false
  end
end

function modes.redirect(body)
  body.stand_frames = (body.stand_frames or -1) + 1
  if body.stand_frames > STAND_FRAMES then
    body.stand_frames = nil
    body.z_released = nil
    perform_redirect(body)
  elseif not is_jump_down() and not body.z_released then
    body.z_released = true
  elseif is_jump_down() and body.z_released then
    body.bounce = true
    body.z_released = false
  end
end

function perform_redirect(body)
  if body.bounce then
    body.bounce = nil
    body.vel_x = body.prev_vel_x
    start_jump(body, -body.prev_vel_y)
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
  if is_jump_down() then
    body.jump_frames = (body.jump_frames or -1) + 1
    if body.jump_frames > JUMP_WARMUP then
      jump_vel = JUMP_VEL
      body.jump_frames = nil
      if math.abs(body.vel_x) < HOP_THRESHOLD then
        body.vel_x = STANDING_JUMP_SPEED * keyboard_walk_direction()
      end
    end
  elseif body.jump_frames then
    local speed = math.abs(body.vel_x)
    body.jump_frames = nil
    if speed >= HOP_THRESHOLD then
      local hop_time = HOP_DIST / speed
      jump_vel = vel_from_acc_time(JUMP_ACC, hop_time)
      body.is_hopping = true
    end
  end
  if jump_vel then
    start_jump(body, jump_vel)
  end
end

function start_jump(body, vel)
  body.vel_y = vel
  body.acc_x = 0
  body.acc_y = JUMP_ACC
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
