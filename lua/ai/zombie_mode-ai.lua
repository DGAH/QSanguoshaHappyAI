--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）僵尸模式部分
]]--
--[[
	技能：互助
	描述：你可以弃一张桃，令一名与你距离为1以内的角色回复一点体力。
]]--
--[[
	内容：注册“互助技能卡”
]]--
sgs.RegistCard("PeachingCard")
--[[
	内容：“互助”技能信息
]]--
sgs.ai_skills["peaching"] = {
	name = "peaching",
	dummyCard = function(self)
		return sgs.Card_Parse("@PeachingCard=.")
	end,
	enabled = function(self, handcards)
		return not self.player:isNude()
	end,
}
--[[
	内容：“互助技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["PeachingCard"] = function(self, card, use)
	local peach = self:getCardId("Peach")
	if type(peach) == "number" then
		local card_str = "@PeachingCard=" .. peach
		self:sort(self.friends, "hp")
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() then
				if self.player:distanceTo(friend) <= 1 then
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
	end
end
--[[
	套路：仅使用“互助技能卡”
]]--
sgs.ai_series["PeachingCardOnly"] = {
	name = "PeachingCardOnly",
	IQ = 2,
	value = 3,
	priority = 2,
	skills = "peaching",
	cards = {
		["PeachingCard"] = 1,
		["Peach"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local peaching_skill = sgs.ai_skills["peaching"]
		local dummyCard = peaching_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["PeachingCard"], "PeachingCardOnly")
--[[****************************************************************
	武将：僵尸模式·僵尸（尸）<隐藏武将>
]]--****************************************************************
--[[
	技能：迅猛（锁定技）
	描述：你的杀造成的伤害+1。你的杀造成伤害时若你体力大于1，你流失1点体力。 
]]--
--[[
	技能：感染（锁定技）
	描述：你的装备牌都视为铁锁连环。 
]]--
--[[
	内容：注册“感染铁索连环”
]]--
sgs.RegistCard("ganran>>IronChain")
--[[
	内容：“感染”技能信息
]]--
sgs.ai_skills["ganran"] = {
	name = "ganran",
	dummyCard = function(self)
		local suit = sgs.iron_chain:getSuitString()
		local point = sgs.iron_chain:getNumberString()
		local id = sgs.iron_chain:getEffectiveId()
		local card_str = string.format("iron_chain:ganran[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local cards = self.player:getCards("he")
		for _,card in sgs.qlist(cards) do
			if card:getTypeId() == sgs.Card_TypeEquip then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“感染铁索连环”的具体产生方式
]]--
sgs.ai_view_as_func["ganran>>IronChain"] = function(self, card)
	local cards = self.player:getCards("he")
	for _,equip in sgs.qlist(cards) do
		if sgs.isKindOf("EquipCard|GanranEquip", equip) then
			local suit = equip:getSuitString()
			local point = equip:getNumberString()
			local id = equip:getEffectiveId()
			local card_str = string.format("iron_chain:ganran[%s:%s]=%d", suit, point, id)
			local acard = sgs.Card_Parse(card_str)
			return acard
		end
	end
end
sgs.ai_filterskill_filter["ganran"] = function(card, player, place)
	if card:getTypeId() == sgs.Card_TypeEquip then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("iron_chain:ganran[%s:%s]=%d"):format(suit, number, card_id) 
	end
end
--[[
	套路：仅使用“感染铁索连环”
]]--
sgs.ai_series["ganran>>IronChainOnly"] = {
	name = "ganran>>IronChainOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "ganran",
	cards = {
		["ganran>>IronChain"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local ganran_skill = sgs.ai_skills["ganran"]
		local iron_chain = ganran_skill["dummyCard"](self)
		iron_chain:setFlags("isDummy")
		return {iron_chain}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ganran>>IronChain"], "ganran>>IronChainOnly")
--[[
	技能：灾变（锁定技）
	描述：你的出牌阶段开始时，若人类玩家数-僵尸玩家数+1大于0，你多摸该数目的牌。 
]]--
--[[
	技能：咆哮（锁定技）
	描述：你于出牌阶段内使用【杀】无数量限制。 
]]--
--[[
	技能：完杀（锁定技）
	描述：你的回合内，除濒死角色外的其他角色不能使用【桃】。 
]]--