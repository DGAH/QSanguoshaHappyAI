--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）国战·阵扩展包部分
	注：此扩展包在端午序曲版（20130610）中不存在，仅为兼容新版而作
]]--
--[[****************************************************************
	武将：阵·邓艾（魏）
]]--****************************************************************
--[[
	技能：资粮
	描述：每当一名角色受到伤害后，你可以将一张“田”交给该角色。
]]--
sgs.ai_skill_invoke["ziliang"] = function(self, data)
	--Waiting For More Details
	return false
end
sgs.ai_skill_askforag["ziliang"] = function(self, card_ids)
	return self.ziliang_id
end
--[[****************************************************************
	武将：阵·曹洪（魏）
]]--****************************************************************
--[[
	技能：护援
	描述：结束阶段开始时，你可以将一张装备牌置于一名角色装备区内，然后你弃置该角色距离1的一名角色区域内的一张牌。
]]--
--[[
	内容：“护援技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HuyuanCard"] = function(self, card, source, targets)
	local target = targets[1]
	--Waiting For More Details
	sgs.updateIntention(source, target, -50)
end
sgs.ai_skill_use["@@huyuan"] = function(self, prompt)
	--Waiting For More Details
end
sgs.ai_skill_playerchosen["huyuan"] = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if p:hasFlag("AI_HuyuanToChoose") then
			p:setFlags("-AI_HuyuanToChoose")
			return p
		end
	end
	return targets:first()
end
sgs.huyuan_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 4.8,
}
--[[
	技能：鹤翼
	描述："回合结束时，你可以选择包括你在内的至少两名连续的角色，这些角色（除你外）拥有“飞影”，直到你的下个回合结束时。
]]--
--[[
	内容：“鹤翼技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HeyiCard"] = function(self, card, source, targets)
	--Waiting For More Details
end
sgs.ai_skill_use["@@heyi"] = function(self, prompt)
	--Waiting For More Details
	return "."
end
--[[****************************************************************
	武将：阵·姜维（蜀）
]]--****************************************************************
--[[
	技能：天覆
	描述：你或与你相邻的角色的回合开始时，该角色可以令你拥有“看破”，直到回合结束。
]]--
sgs.ai_skill_invoke["tianfu"] = function(self, data)
	local JiangWei = data:toPlayer()
	if JiangWei then
		return self:isPartner(JiangWei)
	end
	return false
end
--[[****************************************************************
	武将：阵·蒋琬费祎（蜀）
]]--****************************************************************
--[[
	技能：生息
	描述：每当你的出牌阶段结束时，若你于此阶段未造成伤害，你可以摸两张牌。
]]--
--[[
	技能：守成
	描述：每当一名角色于其回合外失去最后的手牌后，你可以令该角色选择是否摸一张牌。
]]--
sgs.ai_skill_invoke["shoucheng"] = function(self, data)
	--Waiting For More Details
	return false
end
sgs.ai_skill_choice["shoucheng"] = function(self, choices)
	if self.player:getPhase() == sgs.Player_NotActive then
		if self:needKongcheng(self.player, true) then
			return "reject"
		end
	end
	return "accept"
end
--[[****************************************************************
	武将：阵·蒋钦（吴）
]]--****************************************************************
--[[
	技能：尚义（阶段技）
	描述：你可以令一名其他角色观看你的手牌，然后你选择一项：1.观看其手牌，然后你可以弃置其中一张黑色牌。2.观看其身份牌。
]]--
--[[
	内容：注册“尚义技能卡”
]]--
sgs.RegistCard("ShangyiCard")
--[[
	内容：“尚义”技能信息
]]--
sgs.ai_skills["shangyi"] = {
	name = "shangyi",
	dummyCard = function(self)
		return sgs.Card_Parse("@ShangyiCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("ShangyiCard") then
			return false
		end
		return true
	end,
}
--[[
	内容：“尚义技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["ShangyiCard"] = function(self, card, use)
	--Waiting For More Details
end
sgs.ai_skill_choice["shangyi"] = function(self, choices)
	return "handcards"
end
--[[
	套路：仅使用“尚义技能卡”
]]--
sgs.ai_series["ShangyiCardOnly"] = {
	name = "ShangyiCardOnly",
	IQ = 2,
	value = 3,
	priority = 5,
	skills = "shangyi",
	cards = {
		["ShangyiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local shangyi_skill = sgs.ai_skills["shangyi"]
		local dummyCard = shangyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ShangyiCard"], "ShangyiCardOnly")
--[[
	技能：鸟翔
	描述：每当一名角色被指定为【杀】的目标后，若你与此【杀】使用者均与该角色相邻，你可以令该角色须使用两张【闪】抵消此【杀】
]]--
sgs.ai_skill_invoke["niaoxiang"] = function(self, data)
	--Waiting For More Details
	return false
end
--[[****************************************************************
	武将：阵·徐盛（吴）
]]--****************************************************************
--[[
	技能：疑城
	描述：每当一名角色被指定为【杀】的目标后，你可以令该角色摸一张牌，然后弃置一张牌。
]]--
sgs.ai_skill_invoke["yicheng"] = function(self, data)
	--Waiting For More Details
	return false
end
sgs.ai_skill_discard["yicheng"] = function(self, discard_num, min_num, optional, include_equip)
end
--[[****************************************************************
	武将：阵·于吉（群）
]]--****************************************************************
--[[
	技能：千幻
	描述：每当一名角色受到伤害后，该角色可以将牌堆顶的一张牌置于你的武将牌上。每当一名角色被指定为基本牌或锦囊牌的唯一目标时，若该角色同意，你可以将一张“千幻牌”置入弃牌堆：若如此做，取消该目标。
]]--
sgs.ai_skill_invoke["qianhuan"] = function(self, data)
	--Waiting For More Details
	return false
end
sgs.ai_skill_choice["qianhuan"] = function(self, choices, data)
end
--[[****************************************************************
	武将：阵·何太后（群）
]]--****************************************************************
--[[
	技能：鸩毒
	描述：每当一名其他角色的出牌阶段开始时，你可以弃置一张手牌：若如此做，视为该角色使用一张【酒】（计入限制），然后你对该角色造成1点伤害。
]]--
sgs.ai_skill_cardask["@zhendu-discard"] = function(self, data)
	--Waiting For More Details
	return "."
end
--[[
	技能：戚乱
	描述：每当一名角色的回合结束后，若你于本回合杀死至少一名角色，你可以摸三张牌。
]]--