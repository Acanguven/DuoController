local socket = require("socket")
local tcp = socket.tcp()
tcp:settimeout(10)
local ok,err = tcp:connect("127.0.0.1", 5000)
if not ok then
   print('Could not connect Error: ',err)
   return
else
   print("TCP connection succesful with Duo Controller Server")
end
--Connection Done

--Tcp Send

--Tcp Recieve
lastTick = 0

function OnLoad()
	tcp:send("setup,"..createGameId()..","..myHero.charName);

end

function OnTick()
	tcpListen()
end

function tcpListen()
	tcp:settimeout(0)
	local s, status, partial = tcp:receive()
	print(partial)
	--if #partial > 1 then
	--	print(partial)
	--end
end

function createGameId()
	enemyHeroes = GetEnemyHeroes()
	allyHeroes = GetStart()
	local id = ""
	for _, ally in pairs(allyHeroes) do
		print(ally)
	end
	return id
end
