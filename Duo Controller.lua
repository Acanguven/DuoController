local socket = require("socket")
local tcp = socket.tcp()
tcp:settimeout(10)
local ok,err = tcp:connect("acanguven.koding.io", 44444)
if not ok then
   print("Could not connect to Duo Controller server, maybe he is updating?")
   return
else
   print("Connection succesful with Duo Controller Server")
end
--Connection Done
tcp:setoption("keepalive" , false)
gameId = false
myHeroId = false
debug = true	
version = "1.0.0"
authList = {}

for i = 1, heroManager.iCount do
	authList[heroManager:GetHero(i).charName..heroManager:GetHero(i).team] = false
end
for i = 1, heroManager.iCount do
	if myHero == heroManager:GetHero(i) then
		myHeroId = heroManager:GetHero(i).charName..heroManager:GetHero(i).team
	end
end

function sendTcp(data)
	if data ~= nil then
		tcp:send(data .. "||");
	end
end

function OnLoad()
	duocontroller = scriptConfig("Duo Controller", "duocontroller")
	duocontroller:addSubMenu("Allow Players to Controll Me", "allowedPlayers")
	for i = 1, heroManager.iCount do
		if heroManager:GetHero(i) ~= myHero then
			duocontroller.allowedPlayers:addParam(heroManager:GetHero(i).charName..heroManager:GetHero(i).team, heroManager:GetHero(i).name, SCRIPT_PARAM_ONOFF, false)
	    end
    end

	duocontroller:addSubMenu("Script info", "info")
	duocontroller.info:addParam("info", "Name: Duo Controller", SCRIPT_PARAM_INFO, "")
	duocontroller.info:addParam("info", "Author: The Law", SCRIPT_PARAM_INFO, "")
	duocontroller.info:addParam("info", "Version: "..version.."", SCRIPT_PARAM_INFO, "")
end

function OnTick()
	tcpListen()
	if gameId == false then
		sendTcp("setup,"..createGameId()..","..myHeroId);
	end
	for i = 1, heroManager.iCount do
		if heroManager:GetHero(i) ~= myHero then
			if duocontroller.allowedPlayers[heroManager:GetHero(i).charName..heroManager:GetHero(i).team] ~= authList[heroManager:GetHero(i).charName..heroManager:GetHero(i).team] then
				if gameId ~= false then
				 	auth(heroManager:GetHero(i).charName..heroManager:GetHero(i).team)
				end
			end
		end
	end
	
end

function tcpListen()
	tcp:settimeout(0)
	local s, status, partial = tcp:receive("*l")
	if #partial > 1 then
		local responseArray = partial:split(",")
		processAnswer(responseArray)
	end
end

function createGameId()
	usernames = {}
	for i = 1, heroManager.iCount do
        table.insert(usernames,heroManager:GetHero(i).name)
    end
    table.sort(usernames)
    id = ""
    for i = 1, #usernames do
        id = id .. usernames[i]:sub(1,3)
    end
    --return id
    return 5
end


function processAnswer(arr)
	if arr[1] == "setuptrue" then
		gameId = arr[2]
		if debug then
			print("Setup done, your game id:"..gameId)
		end
	end
	if arr[1] == "0" then
		if debug then
			print("Move command recieved: x->"..arr[2].." z->"..arr[3])
		end
		myHero:MoveTo(tonumber(arr[2]),tonumber(arr[3]))
	end

	if arr[1] == "puppetmaster" then
		for i = 1, heroManager.iCount do
			if arr[2] == heroManager:GetHero(i).charName..heroManager:GetHero(i).team then
				print(heroManager:GetHero(i).charName.. " is now controlling your hero")
			end
		end
	end
	if arr[1] == "auth" then
		if string.format("%s", tostring(authList[arr[2]])) ~= arr[3] then
			authList[arr[2]] = not authList[arr[2]]
			if debug then
				for i = 1, heroManager.iCount do
					if arr[2] == heroManager:GetHero(i).charName..heroManager:GetHero(i).team then
						print("Authed:"..heroManager:GetHero(i).name.." | ".. arr[3])
					end
				end
			end
		end
	end
end

function auth(id)
	sendTcp("auth,"..id..","..string.format("%s", tostring(duocontroller.allowedPlayers[id])))
end
