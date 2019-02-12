
-- chargement packages 

local ressources = require ("ressources")


local gameplay = {}


gameplay.newsprite = function(pX,pY,pNameImage,pUuid)
  
  local mysprite = {}
  mysprite.uuid = pUuid
  mysprite.x = pX
  mysprite.y = pY
  mysprite.r = 0
 
  mysprite.nameimage = pNameImage
  mysprite.images = ressources[pNameImage]
  
 
  mysprite.nbframes = 1
  mysprite.currentframe = 1
  
  mysprite.drawsprite = function()
    local self = mysprite
    love.graphics.draw(self.images[self.currentframe],self.x,self.y,math.rad(self.r),1,1,32,32)
  end
  
  mysprite.updatesprite = function(dt)
    local self = mysprite
  end
  
  mysprite.draw = function()
    local self = mysprite
    self.drawsprite()
  end
  
  mysprite.update = function(dt)
    local self = mysprite
    self.updatesprite(dt)
  end
  
  mysprite.sendnetwork = function() -- données du sprite à envoyer sur le réseau
  
    local self = mysprite
    local t = {}
    t.uuid = self.uuid
    t.x = self.x
    t.y = self.y
    t.r = self.r
    t.nameimage = self.nameimage
    
    return t
  
  end

  mysprite.getnetwork = function(t)
  
    
  
    local self = mysprite
    self.uuid = t.uuid
    self.x = t.x
    self.y = t.y
    self.r = t.r
    self.nameimage = t.nameimage
  
  end


  
  
  table.insert(lstsprites,mysprite)
  
  return mysprite

  
end



function gameplay.newtank(pX,pY,pImages,pUuid)
  
  local mytank = gameplay.newsprite(pX,pY,pImages,pUuid)
  mytank.speedforward = 2
  mytank.speedrotation = 2
 
  
  mytank.drawtank = function()
    local self = mytank
    self.drawsprite()
  end
  
  mytank.updatetank = function(dt)
    local self = mytank
    self.updatesprite()
    
    
   
  end
  
  mytank.draw = function()
    local self = mytank
    self.drawtank()
  end
  
  
  mytank.update = function(dt)
    local self = mytank
    
    local x,y,r = self.x,self.y,self.r
    
    self.updatetank(dt)
    self.controls()
    
    
    -- si les valeurs ont changé
    if x ~= self.x or y ~= self.y or  r ~= self.r then
      
    end
    
  
  end
  
  mytank.controls = function(dt)
    local self = mytank
    
    if love.keyboard.isDown("d") then
        self.r = (self.r + self.speedrotation)%360
    elseif love.keyboard.isDown("q") then
        self.r = (self.r - self.speedrotation)%360
    end
    
    if love.keyboard.isDown("z") then
        self.x = self.x + math.sin(math.rad(self.r)) * self.speedforward
        self.y = self.y - math.cos(math.rad(self.r)) * self.speedforward
    end
  
  end
  
  
  
  return mytank
  
  
end


return gameplay

