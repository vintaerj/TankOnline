
-- **package serveur**
local jordaniler = require("jordaniler")


local port = ...

local server = jordaniler.newserver(port)
server:load()

local running = true
while running do
    server:update()
end