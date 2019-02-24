

local jordanilient = require("jordanilient")

local game = {}


--[[

|Créer un nouvelle partie de jeu|

]]--

game.newgame = function(isserver)
  
  local mygame = {}
  mygame.lstsprites = {}
  mygame.lsttirs = {}
  mygame.isserver = isserver
 
  
  
  
  mygame.newclient = function(self,ip,port)
    self.client = jordanilient.newclient(ip,port)
    self.client:load()
  end
  
  mygame.update = function(self,dt,...)
    
    if self.client ~= nil then -- **update client**
      self.client:update(dt)
    end
    
    for k=#self.lsttirs,1,-1 do -- **update lsttirs**
      local tir =self.lsttirs[k] 
      if tir.x < 0 or tir.x > love.graphics.getWidth() or tir.y < 0 or tir.y > love.graphics.getHeight() then
          tir.delete = true
          table.remove(self.lsttirs,k)
      end
    end
    
    for k=#self.lstsprites,1,-1 do -- **update lstsprites**
      local sprite =self.lstsprites[k] 
      if sprite ~= nil then  sprite:update(dt) end
      if sprite.delete then
        table.remove(self.lstsprites,k)
      end
    end
    
  
  end

  mygame.draw = function(self,...)
    
    for _,sprite in pairs(self.lstsprites) do
      if sprite ~= nil then  sprite:draw() end
    end
  
  end

  mygame.mousepressed = function(self,x,y,button)
      
      for _,sprite in pairs(self.lstsprites) do
        if sprite ~= nil then  sprite:mousepressed(x,y,button) end
      end
    
  end



  
  
  
  mygame.load = function(self,...)
    
    if self.isserver then
      local server = love.thread.newThread("servertank.lua")
     server:start(33333)
    end
    
    self.player = nil
    self:newclient("176.165.49.100",33333)
  end
  
  
  
  return mygame
  
  
end

return game