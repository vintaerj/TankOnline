
-- **chargement des packages** 

local ressources = require ("ressources")


local gameplay = {}

-- |renvoie la liste de tous les sprites correspondant à l'id|

gameplay.getspritesbyid = function(id)
  
  local sprites = {}
  
  for _,sprite in pairs(game.lstsprites) do
    if sprite.id == id then
        table.insert(sprites,sprite)
    end
  end
  
  return sprites
  
  
end



--[[

|Créer un nouveau sprite avec une position, une image et un id|.

]]--


gameplay.newsprite = function(id,typesprite,nameimage,x,y,r)
  
 
  local mysprite = {}
  mysprite.id = id -- **identifiant d'appartenance**
  mysprite.type = typesprite  -- **type du sprite**
  mysprite.x = x -- **position x**
  mysprite.y = y -- **position y**
  mysprite.r = r or 0 -- **angle de rotation de l'image**
  mysprite.ismoving = false -- **mouvement du sprite**
  mysprite.delete = false -- **si le sprite est à suprrimé**
 
  mysprite.nameimage = nameimage -- **nom de l'image ou du tileset**
  
  
  if type(nameimage) ~= "string" then
    mysprite.images = ressources 
    for k,v in pairs(nameimage) do -- **chargement de l'images**
       mysprite.images =  mysprite.images[v]
    end
  else
     mysprite.images = ressources[nameimage] 
  end
  
  
  
  
  
 
  
   
   
  mysprite.w = mysprite.images[1]:getWidth()
  mysprite.h = mysprite.images[1]:getHeight()

  mysprite.offsetx = mysprite.w/2
  mysprite.offsety = mysprite.h/2
  
  mysprite.nbframes = 4 -- **nombres d'images**
  mysprite.currentframe = 1 -- **image courante**
  
   
  
  
  
  -- |envoie de la table sur le réseau|
   
  mysprite.getsprite = function(self,...)
    
    local t = {}
    t.id = self.id
    t.type = self.type
    t.x = self.x
    t.y = self.y
    t.r = self.r
    t.nameimage = self.nameimage
    t.currentframe = self.currentframe
    
    return t
  
  end
  
  -- |envoie de la table sur le réseau|
   
  mysprite.get = function(self,...)
    return self:getsprite()
  end


  -- |mise à jour des données|
  
   mysprite.setsprite = function(self,t)
     
    if self.id ~= t.id then self.id = t.id end
    if self.type ~= t.type then self.type = t.type end
    if self.x ~= t.x then self.x = t.x end
    if self.y ~= t.y then self.y = t.y end
    if self.r ~= t.r then self.r = t.r end
    if self.nameimage ~= t.nameimage then self.nameimage = t.nameimage end
    if self.currentframe ~= t.currentframe then self.currentframe = t.currentframe end
      
  end

  -- |mise à jour des données|
  
   mysprite.set = function(self,t)
      self:set(t)
  end
  
  -- |traitement de l'affichage du sprite|
  
  mysprite.drawsprite = function(self)
    love.graphics.draw(self.images[math.floor(self.currentframe)],self.x,self.y,math.rad(self.r),1,1,self.offsetx,self.offsety)
  end
  
  -- |traitement des mises à jour du sprite|
  
  mysprite.updatesprite = function(self,dt)
    
    --print(math.floor(self.currentframe))
    if self.ismoving then
      self.currentframe = self.currentframe + 0.2
      if self.currentframe >= self.nbframes + 1 then
        self.currentframe = 1
      end
    end
    
    
    
    
    
  end
  
  -- |affiche le sprite|
  
  mysprite.draw = function(self,...)
    self:drawsprite()
  end
  
  -- |mise à jour du sprite|
  
  mysprite.update = function(self,dt)
    self:updatesprite(dt)
  end
  
   -- |mise à jour clic souris|
  
  mysprite.mousepressed = function(self,x,y,button)
  end
  
  

  table.insert(game.lstsprites,mysprite) -- **ajout du sprites dans la liste de sprites**
 
  return mysprite

  
end

--[[

-- |créer un tank|

]]--

function gameplay.newtank(id,typesprite,nameimage,x,y,r)
  
  local mytank = gameplay.newsprite(id,typesprite,nameimage,x,y,r)
  
    
  mytank.speedforward = 4
  mytank.speedrotation = 3
  mytank.time = 0
  mytank.xtouret = x
  mytank.ytouret = y
  mytank.rtouret = 0
  mytank.isshooting = false
  mytank.lsttirs = {}
  
  
  mytank.nameimagetouret = "canons"
  mytank.nbframestouret = 2

  mytank.imagestouret = ressources[nameimage][mytank.nameimagetouret]
  mytank.currentframetouret = 1
  
  

  -- |traitement de l'affichage du tank|
 
  mytank.drawtank = function(self,...)
    self:drawsprite()
     love.graphics.draw(self.imagestouret[math.floor(self.currentframetouret)],self.xtouret,self.ytouret,math.rad(self.rtouret),1,1,32,38)
  end
  
  -- |traitement des mise à jour du tank|
  
  mytank.updatetank = function(self,dt)
    self:updatesprite(dt)
    if self.isshooting then
      self.currentframetouret = self.currentframetouret + 0.2
      if self.currentframetouret >= self.nbframestouret + 1 then
      self.isshooting = false
      self.currentframetouret = 1
      end
    end
    
    for k=#self.lsttirs,1,-1 do -- **update lstsprites**
      local tir =self.lsttirs[k] 
      if tir.delete then
        table.remove(self.lsttirs,k)
      end
    end
    
  end
  
  -- |affiche le tank|
  
  mytank.draw = function(self,...)
    self:drawtank()
    love.graphics.print("nombre tirs tank : "..#self.lsttirs,10,0)
  end
  
  -- |mise à jour du tank|
  
  mytank.update = function(self,dt)
   
   
    local x,y,r,rtouret = self.x,self.y,self.r,self.rtouret
   
    self:updatetank(dt)
    
    if self.id == game.player.id then
      self:controls()
      self:collide()
      -- **si la position est modifié**
      if self.x ~= x or self.y ~= y or self.r ~= r  then
        self.ismoving = true
      else
        if self.ismoving then self.ismoving = false end
      end
      
      if self.ismoving or self.rtouret ~= rtouret then
          game.client:request("UPDATE",{player = self:get()})
      end
      
    end
    
  end
  
  -- |gestion des inputs|
  
  mytank.controls = function(self,dt)

    if love.keyboard.isDown("d") then
        self.r = (self.r + self.speedrotation)%360
    elseif love.keyboard.isDown("q") then
        self.r = (self.r - self.speedrotation)%360
    end
    
    if love.keyboard.isDown("z") then
        self.x = self.x + math.sin(math.rad(self.r)) * self.speedforward
        self.y = self.y - math.cos(math.rad(self.r)) * self.speedforward
    elseif love.keyboard.isDown("s") then
        self.x = self.x - math.sin(math.rad(self.r)) * self.speedforward
        self.y = self.y + math.cos(math.rad(self.r)) * self.speedforward
    end
    
    
    
    
    local mx,my = love.mouse.getPosition()
    self.rtouret = math.deg(math.atan2(my - self.y,mx - self.x)) + 90
    
    local offsetx,offsety = -8,-8
    
    self.xtouret = self.x + math.sin(math.rad(self.r)) * offsetx
    self.ytouret = self.y - math.cos(math.rad(self.r)) * offsety
    
  
end

  -- |mise à jour clic souris|
  
  mytank.mousepressed = function(self,x,y,button)
   
    --self:newtir()
    if mytank.isshooting == false then
     --mytank.isshooting = true
    end
   
    
  end
  
  -- |collide tank|
  
  mytank.collide = function(self,...)
    
    local w,h = love.graphics.getWidth(),love.graphics.getHeight()
    
    if self.x < 0 + self.offsetx then
      self.x = 0 + self.offsetx
    end
    if self.x > w - self.w + self.offsetx then
      self.x = w - self.w + self.offsetx
    end
    
    if self.y < 0 + self.offsety then
      self.y = 0 + self.offsety
    end
    
    if self.y > h - self.h + self.offsety then
      self.y = h - self.h + self.offsety
    end
    
  end
  
  -- |création tir|
  
  mytank.newtir = function(self,...)
    local timages = {}
    table.insert(timages,self.nameimage)
    table.insert(timages,"canons")
    table.insert(timages,"tirs")
    local tir = gameplay.newtir(self.id,"tir",timages,self.xtouret,self.ytouret,self.rtouret)
    table.insert(self.lsttirs,tir)
    tir.index = #self.lsttirs
    game.client:request("CREATE",{player = game.player:get()})
  end
  
  

    -- |envoie de la table sur le réseau|

  mytank.get = function(self,...)
    
    local t = mytank:getsprite()
    t.xtouret = self.xtouret
    t.ytouret = self.ytouret
    t.rtouret = self.rtouret
    t.nameimagetouret = self.nameimagetouret
    t.currentframetouret = self.currentframetouret
    
    return t
  
  end

 -- |mise à jour des données|
  
   mytank.set = function(self,t)
     
    mytank:setsprite(t) 
    if self.xtouret ~= t.xtouret then self.xtouret = t.xtouret end
    if self.ytouret ~= t.ytouret then self.ytouret = t.ytouret end
    if self.rtouret ~= t.rtouret then self.rtouret = t.rtouret end
    if self.nameimagetouret ~= t.nameimagetouret then self.nameimagetouret = t.nameimagetouret end
    if self.currentframetouret ~= t.currentframetouret then self.currentframetouret = t.currentframetouret end
    
    
  end
  
  
  
  
  return mytank
  
  
end



--[[

|créer un sprite tir||

]]--

gameplay.newtir = function(id,typesprite,nameimage,x,y,angle)
  
  local mytir = gameplay.newsprite(id,typesprite,nameimage,x,y,angle)
  mytir.angle = angle
  mytir.speed = 10
  
  
  
  -- |traitement de l'affichage du tir|
  
  mytir.drawtir = function(self)
  end
  
  -- |traitement des mises à jour du tir|
  
  mytir.updatetir = function(self,dt)

    self.x = self.x + math.sin(math.rad(self.angle)) * self.speed
    self.y = self.y - math.cos(math.rad(self.angle)) * self.speed
    
  end
  
  
  
  -- |affiche le tir|
  
  mytir.draw = function(self,...)
    self:drawsprite()
    self:drawtir()
  end
  
  -- |mise à jour du tir|
  
  mytir.update = function(self,dt)
    self:updatesprite(dt)
    self:updatetir(dt)
  end
  
  table.insert(game.lsttirs,mytir)
  
  
  return mytir
end





return gameplay

