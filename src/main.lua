tiles = {}

function tiles.load(self, path)
  self.img = love.graphics.newImage(path)

  self.width, self.height = 32,32
  self.img_width = self.img:getWidth()
  self.img_height = self.img:getHeight()

end

function tiles.quad(self, x, y)
  return love.graphics.newQuad(
    x * self.width, y * self.height,
    self.width, self.height,
    self.img_width, self.img_height
  )
end


function love.load()
  tiles:load('tileset.png')

  BlockQuad = tiles:quad(0, 0)
  EmptyQuad = tiles:quad(1, 1)

end

function love.draw()
  for i = 1,3 do
    for j = 1,3 do
      love.graphics.draw(tiles.img, BlockQuad, (10 + i) * 32, (8 + j) * 32)
    end
  end
  love.graphics.draw(tiles.img, EmptyQuad, 12 * 32, 10 * 32)
end
