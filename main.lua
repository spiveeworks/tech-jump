tiles = {}

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


function love.load()
  tiles:load('tileset.png')
end

function love.draw()
  for i = 1,3 do
    for j = 1,3 do
      love.graphics.draw(tiles.img, tiles.quads[1], (10 + i) * 32, (8 + j) * 32)
    end
  end
  love.graphics.draw(tiles.img, tiles.quads[4], 12 * 32, 10 * 32)
end
