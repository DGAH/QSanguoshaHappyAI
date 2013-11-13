--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）内部测试文件
]]--
--[[
	功能：发布服务器信息
	参数：message（string类型，表示待发布的消息）
	结果：无
]]--
function msg(message)
	global_room:writeToConsole(message)
end
--[[
	功能：获取并显示函数调用记录
	参数：title（string类型，表示记录标题）
	结果：无
]]--
function sgs.Debug_traceback(title)
	global_room:writeToConsole("-------- Trace Back START --------")
	global_room:writeToConsole(string.format("INFO:%s", title or ""))
	local current = global_room:getCurrent()
	local debug_str = string.format(
		"current=%s(%s), round=%d", 
		current:getGeneralName(), current:objectName(), sgs.turncount or 0
	)
	global_room:writeToConsole(debug_str)
	global_room:writeToConsole(debug.traceback())
	global_room:writeToConsole("-------- Trace Back END --------")
end
--[[
	功能：获取并显示当前系统判定的各角色阵营信息
	参数：无
	结果：无
]]--
function sgs.Debug_ShowCamps()
	global_room:writeToConsole("======== Camp Information START ========")
	local current = global_room:getCurrent()
	local debug_str = string.format(
		"current=%s(%s), round=%d", 
		current:getGeneralName(), current:objectName(), sgs.turncount or 0
	)
	global_room:writeToConsole(debug_str)
	local alives = global_room:getAlivePlayers()
	for index, player in sgs.qlist(alives) do
		local name = player:objectName()
		local general = player:getGeneralName()
		local role = player:getRole()
		local camp = sgs.ai_camp[name] or "unknown"
		local system = sgs.system_record[name] or ""
		debug_str = string.format(
			"%d - %s(%s): \r\n\trole=%s \tcamp=%s \t(infact=%s)", 
			index, general, name, role, camp, system
		)
		global_room:writeToConsole(debug_str)
	end
	global_room:writeToConsole("======== Camp Information END ========")
end
--[[
	功能：获取并显示角色立场
	参数：无
	结果：无
]]--
function SmartAI:Debug_ShowMyAttitude()
	global_room:writeToConsole("******** Attitude Table START ********")
	local alives = global_room:getAlivePlayers()
	local current = global_room:getCurrent()
	local general = self.player:getGeneralName()
	local name = self.player:objectName()
	local msg = string.format(
		"myself=%s(%s), current=%s(%s), round=%d", 
		general, name, current:getGeneralName(), current:objectName(), sgs.turncount or 0
	)
	global_room:writeToConsole(msg)
	msg = "self.friends:"
	global_room:writeToConsole(msg)
	for _,friend in ipairs(self.friends) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			friend:getGeneralName(), friend:objectName(), sgs.getCamp(friend), sgs.system_record[friend:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	msg = "self.unknowns:"
	global_room:writeToConsole(msg)
	for _,p in ipairs(self.unknowns) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			p:getGeneralName(), p:objectName(), sgs.getCamp(p), sgs.system_record[p:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	msg = "self.enemies:"
	global_room:writeToConsole(msg)
	for _,enemy in ipairs(self.enemies) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			enemy:getGeneralName(), enemy:objectName(), sgs.getCamp(enemy), sgs.system_record[enemy:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	msg = "self.partners:"
	global_room:writeToConsole(msg)
	for _,friend in ipairs(self.partners) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			friend:getGeneralName(), friend:objectName(), sgs.getCamp(friend), sgs.system_record[friend:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	msg = "self.neutrals:"
	global_room:writeToConsole(msg)
	for _,p in ipairs(self.neutrals) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			p:getGeneralName(), p:objectName(), sgs.getCamp(p), sgs.system_record[p:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	msg = "self.opponents:"
	global_room:writeToConsole(msg)
	for _,enemy in ipairs(self.opponents) do
		msg = string.format(
			"\t%s(%s) - camp=%s - (infact=%s)", 
			enemy:getGeneralName(), enemy:objectName(), sgs.getCamp(enemy), sgs.system_record[enemy:objectName()]
		)
		global_room:writeToConsole(msg)
	end
	global_room:writeToConsole("******** Attitude Table END ********")
end
--[[
	功能：获取并显示角色间态度
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有待查的目标角色）
	结果：无
]]--
function sgs.Debug_ShowRelationship(players)
	local alives = global_room:getAlivePlayers()
	players = players or alives
	global_room:writeToConsole("******** Relationship Table START ********")
	local current = global_room:getCurrent()
	local debug_str = string.format(
		"current=%s(%s), round=%d",
		current:getGeneralName(), current:objectName(), sgs.turncount or 0
	)
	global_room:writeToConsole(debug_str)
	for index, player in sgs.qlist(players) do
		local myname = player:objectName()
		local mygeneral = player:getGeneralName()
		local mycamp = sgs.system_record[myname] or ""
		local partners = {}
		local opponents = {}
		local neutrals = {}
		for _,target in sgs.qlist(alives) do
			local name = target:objectName()
			local relationship = sgs.ai_relationship[myname][name] or "neutral"
			if relationship == "partner" then
				table.insert(partners, target)
			elseif relationship == "opponent" then
				table.insert(opponents, target)
			else
				table.insert(neutrals, target)
			end
		end
		debug_str = string.format("%d - %s(%s)<%s>:", index, mygeneral, myname, mycamp)
		global_room:writeToConsole(debug_str)
		debug_str = "\tpartners:"
		global_room:writeToConsole(debug_str)
		for _,partner in ipairs(partners) do
			local general = partner:getGeneralName()
			local name = partner:objectName()
			local camp = sgs.ai_camp[name] or "unknown"
			debug_str = string.format("\t\t%s(%s)<%s> ", general, name, camp)
			global_room:writeToConsole(debug_str)
		end
		debug_str = "\tneutrals:"
		global_room:writeToConsole(debug_str)
		for _,neutral in ipairs(neutrals) do
			local general = neutral:getGeneralName()
			local name = neutral:objectName()
			local camp = sgs.ai_camp[name] or "unknown"
			debug_str = string.format("\t\t%s(%s)<%s> ", general, name, camp)
			global_room:writeToConsole(debug_str)
		end
		debug_str = "\topponents:"
		global_room:writeToConsole(debug_str)
		for _,opponent in ipairs(opponents) do
			local general = opponent:getGeneralName()
			local name = opponent:objectName()
			local camp = sgs.ai_camp[name] or "unknown"
			debug_str = string.format("\t\t%s(%s)<%s> ", general, name, camp)
			global_room:writeToConsole(debug_str)
		end
	end
	global_room:writeToConsole("******** Relationship Table END ********")
end
--[[
	功能：获取并显示一名角色的立场转换历史
	参数：player（ServerPlayer类型，表示目标角色）
	结果：无
]]--
function sgs.Debug_ShowCampHistory(player)
	global_room:writeToConsole("~~~~~~~~ Camp History START ~~~~~~~~")
	local current = global_room:getCurrent()
	player = player or current
	local name = player:objectName()
	local msg = string.format("player:%s(%s), current:%s(%s), round=%d", 
		player:getGeneralName(), name, current:getGeneralName(), current:objectName(), sgs.turncount or 0
	)
	global_room:writeToConsole(msg)
	local history = sgs.ai_camp_history[name]
	for index, item in pairs(history) do
		msg = string.format("(%d) %s", index, item)
		global_room:writeToConsole(msg)
	end
	msg = string.format("result=%s (infact=%s)", sgs.getCamp(player), sgs.system_record[name])
	global_room:writeToConsole(msg)
	global_room:writeToConsole("~~~~~~~~ Camp History END ~~~~~~~~")
end
--[[
	功能：获取并显示当前角色的出牌记录
	参数：无
	结果：无
]]--
function sgs.Debug_ShowCardUseHistory()
	global_room:writeToConsole("######## Card History START ########")
	local current = global_room:getCurrent()
	local name = current:objectName()
	local general = current:getGeneralName()
	local msg = string.format("current:%s(%s), round=%d", 
		general, name, sgs.turncount or 0
	)
	global_room:writeToConsole(msg)
	local history = sgs.ai_card_history
	for index, item in pairs(history) do
		msg = string.format("(%d):%s", index, item)
		global_room:writeToConsole(msg)
	end
	global_room:writeToConsole("######## Card History END ########")
end