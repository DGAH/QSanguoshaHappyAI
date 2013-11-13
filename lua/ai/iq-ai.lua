--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）智商水平部分
]]--
sgs.ai_IQ = 4 --AI水平（数值越大，思考层次越深）
sgs.ai_IQ_system_invoked = false --是否已启用AI智商系统
sgs.IQ_translate = { --翻译
	["0"] = "LevelO", --猪一般队友
	["1"] = "LevelA", --菜鸟一只
	["2"] = "LevelB", --围观路人
	["3"] = "LevelC", --一般水平
	["4"] = "LevelD", --学会思考
	["5"] = "LevelE", --高端玩家
	["6"] = "LevelX", --神一般存在
}
sgs.IQ_level = { --智商等级
	["LevelO"] = 0,
	["LevelA"] = 1,
	["LevelB"] = 2,
	["LevelC"] = 3,
	["LevelD"] = 4,
	["LevelE"] = 5,
	["LevelX"] = 6,
}
sgs.IQ_range = { --AI智商水平分布
	0,
	1, 1, 1,
	2, 2, 2, 2, 2, 2, 
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	5, 5, 5, 5, 5,
	6, 6,
}
--[[
	功能：启用AI智商系统
	参数：无
	结果：无
]]--
function sgs.InitIQ()
	if not sgs.ai_IQ_system_invoked then
		local allplayers = global_room:getAllPlayers()
		for _,p in sgs.qlist(allplayers) do
			if p:getState() ~= "robot" then
				local choices = {
					"LevelA", --菜鸟一只
					"LevelB", --围观路人
					"LevelC", --一般水准
					"LevelD", --学会思考
					"LevelE", --高端玩家
					"cancel", --随机智商水平
				}
				choices = table.concat(choices, "+")
				local choice = global_room:askForChoice(p, "StartIQSystem", choices)
				if choice == "cancel" then
					local index = math.random(1, #sgs.IQ_range)
					sgs.ai_IQ = sgs.IQ_range[index] or 3 --随机AI智商
					local key = tostring(sgs.ai_IQ)
					local IQ_text = sgs.IQ_translate[key] 
					local msg = sgs.LogMessage()
					msg.type = "#ForbidIQ"
					msg.from = p
					msg.arg = sgs.ai_IQ 
					msg.arg2 = IQ_text
					global_room:sendLog(msg)
				else
					sgs.ai_IQ = sgs.IQ_level[choice] or 3
					local msg = sgs.LogMessage()
					msg.type = "#ChooseIQ"
					msg.from = p
					msg.arg = sgs.ai_IQ
					msg.arg2 = choice
					global_room:sendLog(msg)
				end
				sgs.ai_IQ_system_invoked = true
				break
			end
		end
	end
end
--[[
	技能：掀桌
	描述：出牌阶段，你可以令所有角色弃置所有手牌和装备并各流失一点体力上限，然后你立即死亡。
]]--
--[[
	功能：判断是否需要使用掀桌神技
	参数：source（ServerPlayer类型，表示当前角色）
	结果：boolean类型，表示是否掀桌
]]--
function sgs.CanXianzhuo(source)
	if sgs.ai_IQ == 0 then
		if source:getState() == "robot" then --电脑玩家掀桌
			local turn = sgs.turncount or 1
			local target = turn * 10
			local percent = math.random(0, 100)
			if percent <= target then
				source:speak("切！不玩了不玩了！掀桌子走人！")
				return true
			end
		else --人类玩家掀桌
			if source:askForSkillInvoke("_Xianzhuo") then
				return true
			end
		end
	end
	return false
end
--[[
	功能：执行掀桌
	参数：source（ServerPlayer类型，表示当前掀桌的角色）
	结果：无
]]--
function sgs.DoXianzhuo(source)
	local room = source:getRoom()
	local msg = sgs.LogMessage()
	msg.type = "#xianzhuo"
	msg.from = source
	msg.arg = "_Xianzhuo"
	room:sendLog(msg)
	local alives = room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		p:throwAllHandCardsAndEquips()
	end
	for _,p in sgs.qlist(alives) do
		room:loseMaxHp(p, 1)
	end
	room:killPlayer(source)
end
--[[
	内容：翻译表（无效）
]]--
sgs.IQ_Translations = {
	["StartIQSystem"] = "请选择AI智商",
	["LevelO"] = "猪一般队友",
	["LevelA"] = "菜鸟一只",
	["LevelB"] = "围观路人",
	["LevelC"] = "一般水准",
	["LevelD"] = "学会思考",
	["LevelE"] = "高端玩家",
	["LevelX"] = "神一般存在",
	["#ForbidIQ"] = "%from 关闭了AI智商系统！本局AI将以智商水平 %arg - %arg2 参与游戏。",
	["#ChooseIQ"] = "%from 选择了本局AI的智商水平为：%arg - %arg2。",
	["#xianzhuo"] = "%from 发动了技能 %arg ！这家伙不玩了！",
	["_Xianzhuo"] = "掀桌",
}