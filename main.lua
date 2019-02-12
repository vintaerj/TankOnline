

-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')

-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
--love.graphics.setDefaultFilter("nearest")

-- Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio
if arg[#arg] == "-debug" then require("mobdebug").start() end


-- variables globales
lstsprites = {} -- listes des sprites

-- chargement packages 

local json = require("json")
local socket = require("socket")
local jordanila = require("jordanila")
local ressources = require ("ressources")
local gameplay = require("gameplay")
local utils = require("utils")


-- variables locales

local server
client = nil 



function love.load()
  
  largeur = love.graphics.getWidth()
  hauteur = love.graphics.getHeight()
  
  
  server = jordanila.newserver(22222)
  client = jordanila.newclient("192.168.1.51",22222)
  server.start()
  client.start()
  

  -- events serveur
  server.setevent("connect",utils.server.getevent("connect"))
  server.setevent("create",utils.server.getevent("create"))
  --server.setevent("update",utils.server.getevent("update"))
  -- actions serveur
  
  -- events client
  client.setevent("connect",utils.client.getevent("connect"))
  client.setevent("create",utils.client.getevent("create"))
  --client.setevent("update",utils.client.getevent("update"))
  -- actions clients
  client.setaction("connect",utils.client.getaction("connect"))
  --client.setaction("update",utils.client.getaction("update"))
  
  client.actions("connect",1)

  


  
end

function love.update(dt)
  server.update()
  client.update()
  for k,v in pairs(lstsprites) do
    v.update(dt)
  end
   
 
end

function love.draw()
  for k,v in pairs(lstsprites) do
    v.draw()
  end
  utils.server.getaction("traceback")(server)

end

function love.keypressed(key)
  
end


  