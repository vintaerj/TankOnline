



-- **packages**

local socket = require "socket"
local json = require "json"
local math = require("love.math")



-- **alias**

local dns = socket.dns 

local jordaniler = {}
jordaniler.types = {}
jordaniler.types.CONNECT = "CONNECT" -- **type request "CONNECT"**
jordaniler.types.CREATE = "CREATE" -- **type request "CONNECT"**
jordaniler.types.INFO = "INFO" -- **type request "INFO"**
jordaniler.types.UPDATE = "UPDATE" -- **type request "UPDATE"**

--[[ 

|Retourne un objet serveur|.

]]--

function jordaniler.newserver(port)
  
  local myserver = {}
  myserver.lstclients = {}
  myserver.port = port or 22222
  myserver.events = {}

  -- |Retourne le client correspondant à l'ip et le port|.
  
  myserver.getclient = function(self,ip,port)
    
   
    for _,client in pairs(self.lstclients) do
      if client.ip == ip and client.port == port then  return client end -- **si le client est trouvé**
    end
    
     
    
    return nil 
    
  end
  
  
  -- |créer un nouveau client|.
  
  myserver.newclient = function(self,id,ip,port)
  
    local myclient = {}
    myclient.id = id
    myclient.ip = ip
    myclient.port = port
    
    table.insert(self.lstclients,myclient)
    
    return myclient
    
  end
  
  
  -- |Retourne le client correspondant à l'id|.
  
  myserver.getclientbyid = function(self,id)
    
    for _,client in pairs(self.lstclients) do
      if client.id == id then return client end -- **si le client est trouvé**
    end
    
    return nil 
    
  end
  
  -- |Retourne un id unique pour un nouveau client|
  
  myserver.createid = function(self,...)
      
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    local unique = true
    local id
   
    while unique do
      unique = false
      
      id =  string.gsub(template, '[xy]', function (c)
                  local v = (c == 'x') and love.math.random(0, 0xf) or love.math.random(8, 0xb)
                  
                  return string.format('%x', v)
      end)
      
      if #self.lstclients == 0 then unique = false end
      for _,client in pairs(self.lstclients) do
        if client.id == id then unique = true end
      end
      
      
      
    end
    
    return id
  
  end

  -- |envoie un packet à l'ip et port destinataire|

  myserver.sendto = function(self,ip,port,...)
    
    local success,jsonmsg = pcall(json.encode,...)
    
    if success then self.udp:sendto(jsonmsg,ip,port) else return false end
    return true
    
  end
  
  -- |envoie du réponse|
  
  myserver.sendresponse = function(self,ip,port,response,code,...)
    
    local header = {}
    header.response = response
    header.code = code
    header.data = ...
    
    return self:sendto(ip,port,header)
  end
  
  -- |traitement message connect|
  
  myserver.connect = function(self,packet,ip,port)
   
    local client = self:getclient(ip,port)
   
  
    if client ~= nil then -- **client déja connecté**
      
      self:sendresponse(ip,port,jordaniler.types.CONNECT,-1,{id = client.id})
    else
     
      client = self:newclient(self:createid(),ip,port) -- **nouveau client**
         
      self:sendresponse(ip,port,jordaniler.types.CONNECT,0,{id = client.id})
    end
    
   
  
  
  end

  -- |traitement message create|
  
  myserver.create = function(self,packet,ip,port)
  
    local client = self:getclientbyid(packet.data.player.id)
   
    if client ~= nil then -- **client déja connecté**
      for _,v in pairs(self.lstclients) do
        if v.id ~= packet.data.player.id then
          self:sendresponse(v.ip,v.port,jordaniler.types.CREATE,0,packet.data)
        end
      end
    else
      self:sendresponse(ip,port,jordaniler.types.CREATE,-1)
    end
  
  
end

  -- |traitement message info|
  
  myserver.info = function(self,packet,ip,port)
  
    local client = self:getclientbyid(packet.data.id)
   
    if client ~= nil then -- **client déja connecté**
       self:sendresponse(client.ip,client.port,jordaniler.types.CREATE,1,{player = packet.data.player})
         
    else
     
    end
  
  
end

-- |traitement message update|
  
  myserver.updates = function(self,packet,ip,port)
     
   
    
     
    local client = self:getclientbyid(packet.data.player.id)
  
    if client ~= nil then -- **client déja connecté**
      for _,v in pairs(self.lstclients) do
        if v.id ~= client.id then
          self:sendresponse(v.ip,v.port,jordaniler.types.UPDATE,0,packet.data)
        end
      end
       --self:sendresponse(client.ip,client.port,jordaniler.types.CREATE,1,{player = packet.data.player})
    else
     
    end
  
  
  end

  -- |vérifie si la requête est correcte|

  myserver.isrequest = function(request,...)
  
    if type(request) ~= "string" then return false end
  
    local good = false
    for _,v in pairs(jordaniler.types) do
      if v == string.upper(request) then good = true end
    end
  
  
    return good 
  end
  
  
  -- |traitement des messages json reçu|
  
  myserver.process = function(self,header,ip,port)
    
    if self.isrequest(header.request) then -- **si l'entête est bien une requête conforme**.
      self.events[header.request](self,header,ip,port)
    end
    
  end
  

  

  -- |boucle principale du serveur|

  myserver.execute = function(self,...)
    
    print "Serveur lancé ..."
    
    local running = true
    while running do
      
      local data,ip,port = self.udp:receivefrom() -- **en attente de reçevoir des messages**
      if data then
        
        --print("Serveur : ",string.format("data : %s ip : %s port : %s time : %d",data,ip,port,socket.gettime()))
        local correct,json_data = pcall(json.decode,data) -- **convertie le chaine en json**
        
        if correct then
          self:process(json_data,ip,port)
        else
          self:sendresponse(ip,port,"UNDEFINED",-1,"structure data incorrecte, required json ")
        end
      
      end
      
      socket.sleep(0.01)
      coroutine.yield()
    end
    
    
    
    
  end

  -- |Initialisation|
  
  myserver.load = function(self,...)
    
    -- **initialisation des événements**
    self.events[jordaniler.types.CONNECT] = self.connect
    self.events[jordaniler.types.CREATE] = self.create
    self.events[jordaniler.types.INFO] = self.info
    self.events[jordaniler.types.UPDATE] = self.updates
    
   
   
   
   
    self.udp = socket.udp()  -- **création de la socket du serveur**.
    self.hostname = dns.gethostname() -- **récupération du nom de la machine**.
    _,self.resolved = dns.toip(self.hostname) -- **récupération des informations réseaux de la machine hôte**.
    self.ip = self.resolved.ip[2] -- **récupération de l'ip la machine**.
    
    -- **initialisation de la socket**
    
    self.udp:setsockname(self.ip,self.port) -- **lie l'ip de la machine et le port à la socket udp**.
    self.udp:settimeout(0) -- **initialise le timeout à 0**.
    
    self.coroutine = coroutine.create(self.execute) -- **création de la boucle principale du serveur**
   
    
    
  end
  
  -- |mise à jour du serveur|
  
  myserver.update = function(self,...)
    local err,err_c = pcall(coroutine.resume,self.coroutine,self,...) 
    if not err_c then  os.exit(1) end -- **s'il y a une erreur dans la coroutine on la fait remonter**
    
  end
  
  
  return myserver
  
end

return jordaniler