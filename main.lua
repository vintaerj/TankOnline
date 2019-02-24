

-- **Cette ligne permet d'afficher des traces dans la console pendant l'éxécution**
io.stdout:setvbuf('no')

-- **Empèche Love de filtrer les contours des images quand elles sont redimentionnées**
-- **Indispensable pour du pixel art**
--love.graphics.setDefaultFilter("nearest")

-- **Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio**
if arg[#arg] == "-debug" then require("mobdebug").start() end

-- **Chargement packages** 

local games = require("games")
local json = require("json")
local socket = require("socket")
local jordanilient = require("jordanilient")
local gameplay = require "gameplay"





-- **variable globales**

game = games.newgame(true)


-- |initialisation des variables|

local t
function love.load()
  --t = love.thread.newThread("servertank.lua")
 -- t:start(22222)
  game:load()
end

-- |mise à jour du jeu|

function love.update(dt)
  game:update(dt)
end

-- |affichage graphique|

function love.draw()
   game:draw()
end

-- |mousepressed|

function love.mousepressed(x,y,button)
   game:mousepressed(x,y,button)
end





  