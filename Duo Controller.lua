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
debug = false	
version = "1.0.0"
authList = {}
puppet = nil
validPuppet = nil

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
	if VIP_USER then HookPackets() end
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
	if not VIP_USER and validPuppet then 
		myHero:HoldPosition()
	end
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

	if arr[1] == "selected" then
		print("Controlling puppet")
		validPuppet = puppet
	end

	if arr[1] == "1" then
		local spellTarget = nil
		local dist = 99999999
		for i = 1, heroManager.iCount do
		  	if GetDistance(heroManager:GetHero(i), mousePos) <= dist then
		      	dist = GetDistance(heroManager:GetHero(i), mousePos)
		      	spellTarget = heroManager:GetHero(i)
		    end
		end

		if arr[2] == "Q" then
			CastSpell(_Q, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_Q, spellTarget)
			CastSpell(_Q)
		end
		if arr[2] == "W" then
			CastSpell(_W, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_W, spellTarget)
			CastSpell(_W)
		end
		if arr[2] == "E" then
			CastSpell(_E, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_E, spellTarget)
			CastSpell(_E)
		end
		if arr[2] == "R" then
			CastSpell(_R, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_R, spellTarget)
			CastSpell(_R)
		end
		if arr[2] == "D" then
			CastSpell(_D, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_D, spellTarget)
			CastSpell(_D)
		end
		if arr[2] == "F" then
			CastSpell(_F, tonumber(arr[3]), tonumber(arr[4]))
			CastSpell(_F, spellTarget)
			CastSpell(_F)
		end
	end

	if arr[1] == "2" then
		local attackTarget = nil
		local dist = 99999999
		for i = 1, heroManager.iCount do
		  	if math.sqrt(math.pow(heroManager:GetHero(i).x + tonumber(arr[2]),2) + math.pow(heroManager:GetHero(i).z + tonumber(arr[3]),2)) <= dist then
		      	dist = math.sqrt(math.pow(heroManager:GetHero(i).x + tonumber(arr[2]),2) + math.pow(heroManager:GetHero(i).z + tonumber(arr[3]),2))
		      	attackTarget = heroManager:GetHero(i)
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

function OnWndMsg(msg,key)
	if msg == WM_LBUTTONDOWN then
		local dist = 1000000


		for i = 1, heroManager.iCount do
		  	if GetDistance(heroManager:GetHero(i), mousePos) <= dist then
		      	dist = GetDistance(heroManager:GetHero(i), mousePos)
		      	puppet = heroManager:GetHero(i)
		    end
		end

		if puppet ~= nil then
		  if dist < 250 then
		    puppet = puppet
		    sendTcp("select,"..puppet.charName..puppet.team)
		    return
		  end
		end
		puppet = nil
		validPuppet = nil
	end
	if msg == WM_RBUTTONDOWN then
		if (validPuppet ~= nil) then
			sendTcp("0,"..validPuppet.charName..validPuppet.team..","..mousePos.x..","..mousePos.z)
		end
	end
  	if msg == 257 then
  		if (validPuppet ~= nil) then
  			if key == 81 then
	  			print("Fire Q from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",Q,"..mousePos.x..","..mousePos.z)
			end
			if key == 87 then
	  			print("Fire W  from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",W,"..mousePos.x..","..mousePos.z)
			end
			if key == 69 then
	  			print("Fire E  from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",E,"..mousePos.x..","..mousePos.z)
			end
			if key == 82 then
	  			print("Fire R  from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",R,"..mousePos.x..","..mousePos.z)
			end
			if key == 68 then
	  			print("Fire D  from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",D,"..mousePos.x..","..mousePos.z)
			end
			if key == 70 then
	  			print("Fire F  from Puppet")
				sendTcp("1,"..validPuppet.charName..validPuppet.team..",F,"..mousePos.x..","..mousePos.z)
			end
		end
  	end
end

function OnDraw()
	if (validPuppet) then
		DrawCircle(validPuppet.x, validPuppet.y, validPuppet.z, validPuppet.range, ARGB(255,150, 0 , 0 ))
	end
end

function DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8, Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}
	
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end

function OnSendPacket(p)
	if validPuppet then
		if p.header == 276 then
			p:Block()
		end
		if p.header == 135 then
			p:Block()
		end
		if p.header == 143 then
			p:Block()
			sendTcp("2,"..validPuppet.charName..validPuppet.team..","..mousePos.x..","..mousePos.z)
		end
	end
end

