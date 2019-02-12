
-- packages

local socket = require "socket"
local json = require "json"


local jordanila = {}



-- retourne l'objet serveur
function jordanila.newserver(pPort)
  
  local myserver = {}
  myserver.lstclients = {}
  myserver.socketudp = socket.udp()  -- création de la socket du serveur
  myserver.coroutine = nil
  myserver.hostname = socket.dns.gethostname()
  myserver.ip = nil
  myserver.resolved = nil
  myserver.port = pPort
  myserver.events = {}
  
  
  
  myserver.getclient = function(pIp,pPort)
    
    local self = myserver
     
    for k,v in pairs(self.lstclients) do
      if v.port == pPort and v.ip == pIp then
        return v
      end
    end
    
  
    return nil
    
  end
  
  myserver.isconnected = function(pIp,pPort)
    local self = myserver
    
    return self.getclient(pIp,pPort) ~= nil
  end
  
  
  myserver.newclient = function(pId,pIp,pPort)
  
    local self = myserver
    local myclient = {}

    myclient.id = pId
    myclient.ip = pIp
    myclient.port = pPort
 
   
    table.insert(self.lstclients,myclient)
      
   
  end
  
  myserver.setevent = function(pEvent,pFunc)
    local self = myserver
    
    if not type(pEvent) ~= "string" and not type(pFunc) ~= "function" and self.events[pEvent] == nil then return nil end -- on vérifie les type des arguments
    table.insert(self.events[pEvent],pFunc)
    
  end
  
  myserver.processevents = function(pData)  -- traîtement des événements réseaux
    
       
    local self = myserver
    local pEvent = pData.type
    
    if pEvent == nil or self.events[pEvent] == nil then return nil end -- pas d'évenements
    
    for k1,v1 in pairs(self.events[pEvent]) do -- on parcourt toutes les fonctions à cette événements, puis on les traîte.
      v1(self,pData)
    end
    
  end
  
  
  
  
  myserver.main = function()
    
    local self = myserver
    local udp = self.socketudp
    print("Serveur Jordanila lancé ...")
 
   
  
  
    while true do
      
      data,ip,port = udp:receivefrom()
 
      if data then
        udp:setpeername(ip,port) -- on connecte le client au serveur
       
        print("Server: ",data,ip,port)
        local res,o = pcall(json.decode,data)
       
        if res then self.processevents(o) end
        
        
        udp:setpeername('*') -- puis on n'oublie de le re-deconnecter.
      end
      
      
      
      
      
      coroutine.yield()
      
    end

    
    
  end
  
  myserver.start = function()
    local self = myserver
    local udp = self.socketudp
     -- bind address
     _,self.resolved = socket.dns.toip(self.hostname)
     self.ip = self.resolved.ip[2]
    
    udp:setsockname(self.ip,self.port)
    udp:settimeout(0)
    
    setmetatable(self.events,{__index = function(table,key) return nil end})
    -- listes des événements possible
    self.events["connect"] = {}
    self.events["update"] = {}
    self.events["create"] = {}
  
    
    
    
    self.coroutine = coroutine.create(self.main)
  end
  
  
  myserver.update = function()
    local self = myserver
    if self.coroutine then
      coroutine.resume(self.coroutine)
    end
  end
  
  
  return myserver
  
end

function jordanila.newclient(pIp,pPort)
  
  local myclient = {}
  myclient.remoteip = pIp
  myclient.remoteport = pPort
  myclient.socketudp = socket.udp()  -- création de la socket du serveur
  myclient.coroutine = nil
  myclient.isconnected = false
  myclient.events = {} -- liste des événements
  myclient.actions = {} -- listes des actions
  
  myclient.setevent = function(pEvent,pFunc)
    local self = myclient
   
    if not type(pEvent) ~= "string" and not type(pFunc) ~= "function" and self.events[pEvent] == nil then return nil end -- on vérifie les type des arguments
 
    table.insert(self.events[pEvent],pFunc)
    
  end
  
   myclient.setaction = function(pAction,pFunc)
      
    local self = myclient
    
    if not type(pAction) ~= "string" and not type(pFunc) ~= "function" and self.actions[pAction] == nil then return nil end -- on vérifie les type des arguments
   
    table.insert(self.actions[pAction],pFunc)
    
  end
  
  myclient.processevents = function(pData)
    
    local self = myclient
    local pEvent = pData.type
   
    if pEvent == nil or self.events[pEvent] == nil then return nil end -- pas d'évenements
    
    for k1,v1 in pairs(self.events[pEvent]) do -- on parcourt toutes les fonctions à cette événements, puis on les traîte.
      v1(self,pData)
    end
    
  end
  
  
  myclient.main = function()
    
    local self = myclient
    local udp = self.socketudp
    print("Client Jordanila lancé ...")
 
   
  
  
    while true do
      
      data = udp:receive()
 
      if data then
        print("Client : ",data)
        local res,o = pcall(json.decode,data)
       
        if res then self.processevents(o) end
      end
     
      --udp:send("client")
      
      coroutine.yield()
      
    end

    
    coroutine.yield()
  end
  
  myclient.start = function()
    local self = myclient
    
    local udp = self.socketudp
     -- bind address
     
    self.ip,self.port = udp:getsockname()
     
    udp:setpeername(self.remoteip,self.remoteport) -- connect udp
    udp:settimeout(0) -- ne pas attendre
    
    -- listes des événements possible
      
    -- listes des actions
    
    setmetatable(self.actions,{__call = function(pTable,pAction,pId)
      
      local tfunc = self.actions[pAction]
      local func = tfunc[pId]
      
      if tfunc == nil and func == nil then return nil end
        
      func(self)
      
    end})
    
    
    self.events["connect"] = {}
    self.events["update"] = {}
    self.events["create"] = {}
    self.actions["connect"] = {}
    self.actions["update"] = {}
    
    self.coroutine = coroutine.create(self.main)
  end
  
  myclient.update = function()
    local self = myclient
    if self.coroutine then
      coroutine.resume(self.coroutine)
    end
  end
  
  
  return myclient
end







return jordanila