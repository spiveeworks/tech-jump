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
local WALK_SPEED = 10
local JUMP_HEIGHT = -100
local JUMP_TIME = 15

-- s(t) = 1/2 at^2 + ut
-- s(2*_t) = 0 => a = -u/_t
--             => s = ut(1 - t/(2*_t))
-- s(_t) = _s  => u = 2*_s/_t
local JUMP_SPEED = 2 * JUMP_HEIGHT / JUMP_TIME
local JUMP_ACC = - JUMP_SPEED / JUMP_TIME

function modes.update(body)
  modes[body.mode](body)
end

function modes.falling(body)
  if body.y > FLOOR_HEIGHT then
    body.mode = "walking"
    body.y = FLOOR_HEIGHT
    body.vel_y = 0
    body.acc_y = 0
  end
end

function modes.walking(body)
  body.vel_x = 0
  if love.keyboard.isDown("left") then
    body.vel_x = -WALK_SPEED
  end
  if love.keyboard.isDown("right") then
    body.vel_x = body.vel_x + WALK_SPEED
  end
  if love.keyboard.isDown("space") then
    body.mode = "falling"
    body.vel_y = JUMP_SPEED
    body.acc_y = JUMP_ACC
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
