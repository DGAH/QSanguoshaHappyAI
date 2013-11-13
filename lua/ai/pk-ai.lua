--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）单挑套路部分
]]--
--[[****************************************************************
	套路：孙权刷寒冰剑单挑小乔、钟会
]]--****************************************************************
sgs.ai_series["PK_Zhiheng_IceSword"] = {
	name = "PK_Zhiheng_IceSword",
	IQ = 4,
	value = 4,
	priority = 3,
	skills = "zhiheng",
	cards = {
		["ZhihengCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		if self.room:alivePlayerCount() == 2 then
			local others = self.room:getOtherPlayers(self.player)
			local enemy = others:first()
			if self:hasSkills("tianxiang|quanji", enemy) then
				if not enemy:isKongcheng() then
					if self:getCardsNum("IceSword", self.player, "he") == 0 then
						if not self:isWeak() then
							sgs.PK_Enemy = enemy
							return true
						end
					end
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		local zhiheng_skill = sgs.ai_skills["zhiheng"]
		local dummyCard = zhiheng_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ZhihengCard"], "PK_Zhiheng_IceSword")
--制衡
sgs.ai_series_use_func["ZhihengCard"]["PK_Zhiheng_IceSword"] = function(self, card, use)
	local keepDist = false
	local horse = nil
	local enemy = sgs.PK_Enemy
	if enemy then
		if enemy:distanceTo(self.player) > 1 then
			horse = self.player:getDefensiveHorse()
			if horse then
				keepDist = true
			end
		end
	end
	local to_discard = {}
	local cards = self.player:getCards("he")
	for _,c in sgs.qlist(cards) do
		if not keepDist then
			table.insert(to_discard, c)
		elseif c:getId() ~= horse:getId() then
			table.insert(to_discard, c)
		end
	end
	if #to_discard > 0 then
		local card_str = "@ZhihengCard="..table.concat(to_discard, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		return 
	end
end
--[[****************************************************************
	套路：
]]--****************************************************************
--[[****************************************************************
	套路：
]]--****************************************************************
--[[****************************************************************
	套路：
]]--****************************************************************