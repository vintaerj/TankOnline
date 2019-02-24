-- **packages**

local socket = require "socket"
local json = require "json"
local gameplay = require "gameplay"


-- alias

local dns = socket.dns 

local jordanilient = {}
jordanilient.types = {}
jordanilient.types.CONNECT = "CONNECT" -- **type request "CONNECT"**
jordanilient.types.CREATE = "CREATE" -- **type request "CREATE"**
jordanilient.types.INFO = "INFO" -- **type request "INFO"**
jordanilient.types.UPDATE = "UPDATE" -- **type request "UPDATE"**


function jordanilient.newclient(ip,port)
  
  local myclient = {}
  myclient.ipremote = ip
  myclient.portremote = port
  myclient.events = {}

 
  
  -- |envoie un packet au serveur|

  myclient.request = function(self,request,...)
    
    local header = {}
    header.request = request
    header.options = {}
    header.data = ...
    
    local success,jsonmsg = pcall(json.encode,header)
    
    if success then self.udp:send(jsonmsg) else return false end
    return true
    
  end
  
  -- |traitement du message connect|
  
  myclient.connect = function(self,header,...)
   
    if header.code == 0 then
     
      self.id = header.data.id
    
      game.player = gameplay.newtank(self.id,"tank","player",love.graphics.getWidth()/2,love.graphics.getHeight()/2,0)
      
      self:request(jordanilient.types.CREATE,{player = game.player:get()})
    else
      print("ECHEC")
    end
    
  end
  
  -- |traitement du message create|
  
  myclient.create = function(self,header,...)
    
    if header.code >= 0 then
      local p = header.data.player
       local sprite
       if header.data.player.type == "tank" then
        sprite = gameplay.newtank(p.id,p.type,"enemy",p.x,p.y,p.r) -- **tank enemy**
       else
        sprite = gameplay.newsprite(p.id,p.type,p.nameimage,p.x,p.y,p.r)
       end
       
     
      if header.code == 0 then
        self:request(jordanilient.types.INFO,{id = p.id,player = game.player:get()})
      end
    else
     
    end
    
    end
  
  -- |traitement du message update|
  
   myclient.updates = function(self,header,...)
    
   
    if header.code >= 0 then
    
      local sprite = header.data.player
      local sprites = gameplay.getspritesbyid(sprite.id)
      for _,s in pairs(sprites) do
          if s.type == sprite.type then
               s:set(sprite)
          end
      end
     
    else

    end
   
    

    
    end
  
  
  
  -- |traitement des messages json reçu|
  
  myclient.process = function(self,header)
    
    if self.isresponse(header.response) then -- **si l'entête est bien une requête conforme**.
      self.events[header.response](self,header)
    end
    
  end
  
  -- |vérifie si la response est correcte|

  myclient.isresponse = function(response,...)
  
    if type(response) ~= "string" then return false end
  
    local good = false
    for _,v in pairs(jordanilient.types) do
      if v == string.upper(response) then good = true end
    end
  
  
    return good 
  end
  

  -- |boucle principale du serveur|

  myclient.execute = function(self,...)
    
    print "Client lancé ..."
    
    local running = true
    while running do
      
      local data = self.udp:receive() -- **en attente de reçevoir des messages**
      
     
      if data then
        
        --print("Client: ",string.format("data : %s time : %d",data,socket.gettime()))
        local correct,json_data = pcall(json.decode,data) -- **convertie le chaine en json**
        
        if correct then
          self:process(json_data)
        end
      
    end
    
     
      coroutine.yield()
    end
    
    
    
    
  end

  -- |Initialisation|
  
  myclient.load = function(self,...)
    
    -- **initialisation des événements**
    
    self.events[jordanilient.types.CONNECT] = self.connect
    self.events[jordanilient.types.CREATE] = self.create
    self.events[jordanilient.types.UPDATE] = self.updates
    
    self.udp = socket.udp()  -- **création de la socket du serveur**.
    self.hostname = dns.gethostname() -- **récupération du nom de la machine**.
    _,self.resolved = dns.toip(self.hostname) -- **récupération des informations réseaux de la machine hôte**.
    self.ip = self.resolved.ip[2] -- **récupération de l'ip la machine**.
    
    -- **initialisation de la socket**
    
    self.udp:setpeername(self.ipremote,self.portremote)-- **lie l'ip et le port du serveur à la socket udp**.
    self.udp:settimeout(0) -- **initialise le timeout à 0**.
    
    self.coroutine = coroutine.create(self.execute) -- **création de la boucle principale du serveur**
    
    self:request(jordanilient.types.CONNECT)
  
    
    
  end
  
  -- |mise à jour du serveur|
  
  myclient.update = function(self,...)
    local err,err_c = pcall(coroutine.resume,self.coroutine,self,...) 
    if not err_c then  os.exit(1) end -- **s'il y a une erreur dans la coroutine on la fait remonter**
  end
  
  
  return myclient
  
end


return jordanilient