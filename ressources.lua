

local ressources = {}

ressources.player = {}
for k=1,4 do
  table.insert(ressources.player,love.graphics.newImage("ressources/images/Character/Player/player-tank_base"..k..".png"))
end
ressources.enemy = {}
for k=1,4 do
  table.insert(ressources.enemy,love.graphics.newImage("ressources/images/Character/Enemy/enemy-tank_base"..k..".png"))
end
ressources.player.canons = {}
for k=1,2 do
  table.insert(ressources.player.canons,love.graphics.newImage("ressources/images/Character/Player/player-cannonlv1-"..k..".png"))
end
ressources.enemy.canons = {}
for k=1,2 do
  table.insert(ressources.enemy.canons,love.graphics.newImage("ressources/images/Character/Enemy/enemy-cannon1-"..k..".png"))
end
ressources.player.canons.tirs = {}
for k=1,3 do
  table.insert(ressources.player.canons.tirs,love.graphics.newImage("ressources/images/Character/Player/player-cannonlv"..k.."bullet.png"))
end
ressources.enemy.canons.tirs = {}
for k=1,2 do
  table.insert(ressources.enemy.canons.tirs,love.graphics.newImage("ressources/images/Character/Enemy/enemy-cannon"..k.."bullet.png"))
end





return ressources