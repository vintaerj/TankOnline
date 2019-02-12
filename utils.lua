
-- packages

local json = require("json")
local socket = require("socket")
local jordanila = require("jordanila")
local ressources = require ("ressources")
local gameplay = require("gameplay")
local mime = require("mime")


local utils = {}

-- créer une boite à outil

utils.newutils = function()
  
  local myutils = {}
  myutils.actions = {}
  myutils.events = {}
  
  myutils.setevent = function(pName,pFunc)
    local self = myutils
    self.events[pName] = pFunc
  end
  
  myutils.setaction = function(pName,pFunc)
    local self = myutils
    self.actions[pName] = pFunc
  end
  
  myutils.getevent = function(pName)
    local self = myutils
    return self.events[pName]
  end
  
  myutils.getaction = function(pName)
    local self = myutils
    return self.actions[pName]
  end
  
  return myutils
  
end

-- créer une boite à outil pour les serveurs

utils.newserver = function()
  local myserver = utils.newutils()
  
  myserver.sendpacket = function(pSocket,pType,pStatus,pCode,...)
    
    local tanswer = {}
    tanswer.type = pType
    tanswer.status = pStatus
    tanswer.code = pCode
    tanswer.data = ...
  
    pSocket.socketudp:send(json.encode(tanswer))
  
  end
    
 
  
  
  myserver.genuuid = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and love.math.random(0, 0xf) or love.math.random(8, 0xb)
        return string.format('%x', v)
    end)
  end
  
  return myserver
end
  


-- créer une boite à outil pour les clients

utils.newclient = function()
  local myclient = utils.newutils()
  
  myclient.sendpacket = function(pSocket,pType,...)
    
    local trequest = {}
    trequest.type = pType
    trequest.data = ...
  
    pSocket.socketudp:send(json.encode(trequest))
    
    
  end
  
  
  
  
  return myclient
end


--[[ CREATION BOITE OUTILS ]]--


utils.server = utils.newserver() -- création boite outils
utils.client = utils.newclient() -- création boite outils



--[[ FONCTIONS SERVEUR ]]--

local s_traceback = function(pServer)
  
  for k,v in pairs(pServer.lstclients) do
    love.graphics.print("client n°"..k.." : "..v.ip..":"..v.port,0,(k-1)*10)
  end
  
end

--[[ 

Le serveur reçoit un packet de type "connect".
Il regarde dans sa liste client si le client existe avec l'ip et le port. S'il existe il lui répond avec type "connect" et un message d'erreur.
S'il il n'existe pas, il crée un nouveau client avec son ip et son port et lui crée un uuid et le mets dans lstclients. Puis le répond avec 
un type "connect", son uuid et un status.

]]--

local s_connect_response = function(pServer,pInfo) 


  local self = utils
  local ip,port = pServer.socketudp:getpeername()
 
 
  if pServer.isconnected(ip,port) then -- si le client est déja connecté
    utils.server.sendpacket(pServer,"connect","Bad request",-1,{err = "Vous êtes déja connecté"}) -- envoie de la réponse
  else
     
    local uuid = utils.server.genuuid()
    pServer.newclient(uuid,ip,port) -- création du nouveau client dans la liste client
    utils.server.sendpacket(pServer,"connect","Ok",0,{uuid = uuid}) -- envoie de la réponse
    
  end
  
 
end

--[[

Le serveur reçoit un message de type "create". Cela signifie qu'un client veut créer un joueur ( tank ).
Si le client est connecté au serveur alors le serveur répond par un message de type "create" est un status "Ok" avec un code de 0.
Si le client n'est pas connecté au serveur alors le serveur répond un message de type "create" est un status "Forbidden" avec un code de -1

]]--

local s_create_response = function(pServer,pData) 
  
  local self = utils
 
  if pServer.isconnected(ip,port) then -- si le client est déja connecté, il peut créer
     self.server.sendpacket(pServer,"create","Ok",0) -- envoie de la réponse
  else  -- le client n'est pas connecté il ne peut pas créer
     self.server.sendpacket(pServer,"create","Forbidden",-1,{err = "Vous n'êtes pas connecter, vous ne pouvez pas créer de joueur"}) -- envoie de la réponse
  end
  
  
 
end



local s_update = function(pServer,pInfo) -- les serveur à reçu des mise à jour d'un joueur
  

  -- il doit envoyer à tous les joueurs la mise à jour
  local sprite = {}
  sprite.type = "update"
  sprite.sprite = pInfo.sprite
  local ip,port = pServer.socketudp:getpeername()
  pServer.socketudp:setpeername('*') -- puis on n'oublie de le re-deconnecter.
  for k,v in pairs(pServer.lstclients) do
      if  port ~= v.port then
       
        pServer.socketudp:sendto(json.encode(sprite),v.ip,v.port)
      end
  end
  
    
  
end


--[[ FONCTIONS CLIENTS ]]--

--[[ 

Le client envoyer un message de type "connect" pour se connecter au serveur.

]]--
local c_connect_request = function(pClient,pInfo)
  utils.client.sendpacket(pClient,"connect") -- envoie de la requête pour se connecter
end

--[[

Le client reçoit un message de type "connect", s'il le code de retour est 0 , il peut créer son joueur et le dire au serveur.
sinon il ne fait rien.

]]--
local c_connect_response = function(pClient,pData)
 
  local self = utils
 
  if pData.code == 0 then -- le client est connecté au serveur
    pClient.isconnected = true -- le client est connecté au serveur
    pClient.uuid = pData.data.uuid
    self.client.sendpacket(pClient,"create")   -- envoie de son sprite pour le serveur 
  else
    print("c_connect_response : impossible de se connecter au serveur",pData.status) -- on fait rien
  end
  
end

--[[

Le client reçoit un message de type "create". Cela signifie que le client a demander de pouvoir créer un joueur ( tank ) et que le serveur l'a répondu.
S'il le code est 0, alors le client peut créer un joueur, sinon il ne peut pas.


]]--

local c_create_response = function(pClient,pData)
  
  local self = utils
  
  
   if pData.code == 0 then -- le client peut créer un joueur ( tank )
    player = gameplay.newtank(0,0,"player",pClient.uuid)  -- création du tank , ajout dans lstsprites
  else -- le client ne peut pas créer de joueur
    print("c_create_response : impossible de créer un joueur",pData.status) -- on fait rien
  end
  
  
end



local c_update = function(pClient,pInfo) -- reçois update du serveur
  
  
 
   local sprite = pInfo.sprite
   local found = false
  
  
   
   for k,v in pairs(lstsprites) do
    
     if sprite.uuid == v.uuid then
       
       v.getnetwork(sprite)
       found = true
       break
     end
   end
   
  if not found then
    gameplay.newsprite(sprite.x,sprite.y,sprite.nameimage,sprite.uuid)
  end
  
  
end


local c_update_action = function(pClient,pInfo)
  
  
  
  local tnetwork = {}
  tnetwork.type = "update"
  if player ~= nil then
    tnetwork.sprite = player.sendnetwork()
  end
  
 
  pClient.socketudp:send(json.encode(tnetwork)) -- envoie de son sprite pour le serveur 
   
end



-- Stockage des fonctions  dans les boites à outils

utils.server.setaction("traceback",s_traceback)
  
utils.server.setevent("connect",s_connect_response)
utils.server.setevent("create",s_create_response)
utils.server.setevent("update",s_update)


utils.client.setaction("connect",c_connect_request)
utils.client.setaction("update",c_update_action)
utils.client.setevent("create",c_create_response)
utils.client.setevent("connect",c_connect_response)
utils.client.setevent("update",c_update)



return utils