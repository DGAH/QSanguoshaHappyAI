--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）怀旧包部分
]]--
--[[****************************************************************
	卡牌部分
]]--****************************************************************
--[[****************************************************************
	银月枪（武器）
]]--****************************************************************
sgs.weapon_range.MoonSpear = 3
sgs.card_constituent["MoonSpear"] = {
	use_priority = 2.64,
}
--[[
	内容：注册“银月枪”
]]--
sgs.RegistCard("MoonSpear")
--[[
	功能：使用银月枪
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardMoonSpear(card, use)
	use.card = card
end
--[[
	套路：仅使用“银月枪”
]]--
sgs.ai_series["MoonSpearOnly"] = {
	name = "MoonSpearOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["MoonSpear"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,spear in ipairs(handcards) do
			if spear:isKindOf("MoonSpear") then
				return {spear}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["MoonSpear"], "MoonSpearOnly")
--[[****************************************************************
	武将部分
]]--****************************************************************
--[[****************************************************************
	武将：怀旧·刘备（蜀）
]]--****************************************************************
--[[
	技能：仁德
	描述：出牌阶段，你可以将任意数量的手牌交给一名其他角色，然后当你于此阶段内以此法交给其他角色的手牌首次达到两张或更多时，你回复1点体力 
]]--
--[[
	内容：“仁德技能卡”的卡牌成分
]]--
sgs.card_constituent["NosRendeCard"] = {
	benefit = 2,
	use_value = sgs.card_constituent["RendeCard"]["use_value"],
	use_priority = sgs.card_constituent["RendeCard"]["use_priority"],
}
--[[
	内容：“仁德技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["NosRendeCard"] = sgs.ai_card_intention["RendeCard"]
--[[
	内容：注册“仁德技能卡”
]]--
sgs.RegistCard("NosRendeCard")
--[[
	内容：“仁德”技能信息
]]--
sgs.ai_skills["nosrende"] = {
	name = "nosrende",
	dummyCard = function(self)
		return sgs.Card_Parse("@NosRendeCard=.")
	end,
	enabled = function(self, handcards)
		return not self.player:isKongcheng()
	end,
}
--[[
	内容：“仁德技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["NosRendeCard"] = function(self, card, use)
	if self.player:getMark("nosrende") > 1 then
		if sgs.current_mode:find("04_1v3") then 
			return 
		end
	end
	if self:shouldUseRende() then
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		self:sortByUseValue(cards, true)
		local name = self.player:objectName()
		local c, friend = self:getCardNeedPlayer(cards)
		if c and friend then
			if friend:objectName() == self.player:objectName() then
				return
			elseif not handcards:contains(c) then 
				return 
			end
			local card_str = nil
			if friend:hasSkill("enyuan") then
				if #cards >= 2 then
					if sgs.current_mode ~= "04_1v3" or self.player:getMark("nosrende") ~= 1 then
						self:sortByUseValue(cards, true)
						for i = 1, #cards, 1 do
							if cards[i]:getId() ~= c:getId() then
								card_str = "@NosRendeCard=" .. c:getId() .. "+" .. cards[i]:getId()
								break
							end
						end
					end
				end
			end
			if not card_str then
				card_str = "@NosRendeCard=" .. c:getId()
			end
			use.card = sgs.Card_Parse(card_str)
			if use.to then 
				use.to:append(friend) 
			end
			return
		else
			local PangTong = self.room:findPlayerBySkillName("manjuan")
			if PangTong then 
				if self.player:isWounded() then
					if self.player:getHandcardNum() > 3 then
						local mark = self.player:getMark("nosrende")
						if mark < 2 then
							self:sortByUseValue(cards, true)
							local to_give = {}
							for _, c in ipairs(cards) do
								if not sgs.isCard("Peach", c, self.player) then
									if not sgs.isCard("ExNihilo", c, self.player) then 
										table.insert(to_give, c:getId()) 
									end
								end
								if #to_give == 2 - mark then 
									break 
								end
							end
							if #to_give > 0 then
								local card_str = "@NosRendeCard=" .. table.concat(to_give, "+")
								use.card = sgs.Card_Parse(card_str)
								if use.to then 
									use.to:append(PangTong) 
								end
							end
						end
					end
				end
			end
		end
	end
end
--[[
	套路：仅使用“仁德技能卡”
]]--
sgs.ai_series["NosRendeCardOnly"] = {
	name = "NosRendeCardOnly",
	IQ = 2,
	value = 5,
	priority = 4,
	skills = "nosrende",
	cards = {
		["NosRendeCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local rende_skill = sgs.ai_skills["nosrende"]
		local dummyCard = rende_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["NosRendeCard"], "NosRendeCardOnly")
--[[
	技能：激将（主公技）
	描述：当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。 
]]--
--[[****************************************************************
	武将：怀旧·黄月英（蜀）
]]--****************************************************************
sgs.ai_chaofeng.nos_huangyueying = sgs.ai_chaofeng.huangyueying
--[[
	技能：集智
	描述：每当你使用非延时类锦囊牌选择目标后，你可以摸一张牌。 
]]--
sgs.nosjizhi_keep_value = sgs.jizhi_keep_value
--[[
	内容：“集智”卡牌需求
]]--
sgs.card_need_system["nosjizhi"] = sgs.card_need_system["jizhi"]
--[[
	技能：奇才（锁定技）
	描述：你使用锦囊牌无距离限制。 
]]--
--[[****************************************************************
	武将：怀旧·貂蝉（群）
]]--****************************************************************
--[[
	技能：离间
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名男性角色，令其中一名男性角色视为对另一名男性角色使用一张【决斗】（不能使用【无懈可击】对此【决斗】进行响应）。 
]]--
--[[
	内容：“离间技能卡”的卡牌成分
]]--
sgs.card_constituent["NosLijianCard"] = {
	use_value = sgs.card_constituent["LijianCard"]["use_value"],
	use_priority = sgs.card_constituent["LijianCard"]["use_priority"],
}
--[[
	内容：“离间技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["NosLijianCard"] = sgs.ai_card_intention["LijianCard"]
--[[
	内容：注册“离间技能卡”
]]--
sgs.RegistCard("NosLijianCard")
--[[
	内容：“离间”技能信息
]]--
sgs.ai_skills["noslijian"] = {
	name = "noslijian",
	dummyCard = function(self)
		return sgs.Card_Parse("@NosLijianCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("NosLijianCard") then
			return false
		elseif self.player:isNude() then
			return false
		end
		return true
	end,
}
--[[
	内容：“离间技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["NosLijianCard"] = function(self, card, use)
	local id = self:getLijianCard()
	if id then
		local first, second = self:findLijianTarget("NosLijianCard", use.isDummy)
		if first and second then
			local card_str = "@NosLijianCard=" .. id
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(first)
				use.to:append(second)
			end
		end
	end
end
--[[
	套路：仅使用“离间技能卡”
]]--
sgs.ai_series["NosLijianCardOnly"] = {
	name = "NosLijianCardOnly",
	IQ = 2,
	value = 4,
	priority = 3,
	skills = "noslijian",
	cards = {
		["NosLijianCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lijian_skill = sgs.ai_skills["noslijian"]
		local dummyCard = lijian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["NosLijianCard"], "NosLijianCardOnly")
--[[
	技能：闭月
	描述：结束阶段开始时，你可以摸一张牌。 
]]--
--[[****************************************************************
	武将：怀旧·法正（蜀）
]]--****************************************************************
sgs.ai_chaofeng.nosfazheng = -3
--[[
	技能：恩怨（锁定技）
	描述：每当你回复1点体力后，令你回复体力的角色摸一张牌；每当你受到伤害后，伤害来源选择一项：交给你一张♥手牌，或失去1点体力。 
]]--
sgs.ai_skill_cardask["@enyuanheart"] = function(self, data)
	local damage = data:toDamage()
	if not self:hasSkills(sgs.masochism_skill) then
		if self:needToLoseHp(self.player, damage.to, nil, true) then
			return "." 
		elseif self:needToLoseHp() then
			return "." 
		end
	end
	if self:isPartner(damage.to) then 
		return 
	end
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Heart then
			if not sgs.isCard("Peach", card, self.player) then
				if not sgs.isCard("ExNihilo", card, self.player) then
					return card:getEffectiveId()
				end
			end
		end
	end
	return "."
end
sgs.slash_prohibit_system["nosenyuan"] = {
	name = "nosenyuan",
	reason = "nosenyuan",
	judge_func = function(self, target, source, slash)
		--绝情
		if source:hasSkill("jueqing") then
			return false
		end
		--原版潜袭
		if source:hasSkill("nosqianxi") then
			if source:distanceTo(target) == 1 then 
				return false 
			end
		end
		--原版解烦
		if source:hasFlag("nosjiefanUsed") then 
			return false 
		end
		--卖血触发技
		if not self:hasSkills(sgs.masochism_skill, source) then 
			if self:needToLoseHp(source) then
				return false
			end
		end
		--体力
		if source:getHp() > 3 then 
			return false 
		end
		--恩怨
		local n = 0
		local cards = source:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Heart then
				if not sgs.isCard("Peach", card, source) then
					if not sgs.isCard("ExNihilo", card, source) then
						if not card:isKindOf("Slash") then 
							return false 
						end
						n = n + 1
					end
				end
			end
		end
		if n < 1 then 
			return true 
		elseif n > 1 then 
			return false 
		elseif n == 1 then 
			return slash:getSuit() == sgs.Card_Heart
		end
		--虚弱
		return self:isWeak(source)
	end
}
sgs.damage_avoid_system["nosenyuan"] = {
	reason = "nosenyuan",
	judge_func = function(self, target, damage, source)
		return false
	end
}
sgs.ai_damage_requirement["nosenyuan"] = function(self, source, target)	
	if target:hasSkill("nosenyuan") then
		if self:isOpponent(source, target) then
			if self:isWeak(source) then
				local flag = true
				if self:needToLoseHp(source) then
					if not self:hasSkills(sgs.masochism_skill, source) then
						flag = false
					end
				end
				return flag
			end
		end
	end
	return false
end
--[[
	技能：眩惑
	描述：出牌阶段限一次，你可以将一张♥手牌交给一名其他角色，然后你获得该角色的一张牌，将该牌交给除该角色外的另一名角色。 
]]--
--[[
	内容：“眩惑技能卡”的卡牌成分
]]--
sgs.card_constituent["NosXuanhuoCard"] = {
}
--[[
	内容：注册“眩惑技能卡”
]]--
sgs.RegistCard("NosXuanhuoCard")
--[[
	内容：“眩惑”技能信息
]]--
sgs.ai_skills["nosxuanhuo"] = {
	name = "nosxuanhuo",
	dummyCard = function(self)
		return sgs.Card_Parse("@NosXuanhuoCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("NosXuanhuoCard") then
			for _,heart in ipairs(handcards) do
				if heart:getSuit() == sgs.Card_Heart then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“眩惑技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["NosXuanhuoCard"] = function(self, card, use)
	local handcards = self.player:getHandcards()
	local cards = {}
	for _,heart in sgs.qlist(handcards) do
		if heart:getSuit() == sgs.Card_Heart then
			table.insert(cards, heart)
		end
	end
	if #cards > 0 then
		local target
		for _, friend in ipairs(self.partners_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				if not friend:getEquips():isEmpty() then
					if not friend:hasSkill("manjuan") then
						target = friend
						break
					end
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.opponents) do
				if self:getDangerousCard(enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, friend in ipairs(self.partners_noself) do
				if self:needToThrowArmor(friend) then
					if not friend:hasSkill("manjuan") then
						target = friend
						break
					end
				end
			end
		end
		if not target then
			self:sort(self.opponents, "handcard")
			for _, enemy in ipairs(self.opponents) do
				if self:getValuableCard(enemy) then
					target = enemy
					break
				end
				if not enemy:isKongcheng() and not enemy:hasSkills("tuntian+zaoxian") then
					local enemyhandcards = enemy:getHandcards()
					local flag = string.format("visible_%s_%s", self.player:objectName(), enemy:objectName())
					for _, c in sgs.qlist(enemyhandcards) do
						if c:hasFlag("visible") or c:hasFlag(flag) then
							if sgs.isKindOf("Peach|Analeptic", c) then
								target = enemy
								break
							end
						end
					end
				end
				if target then 
					break 
				end
				if self:getValuableCard(enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, friend in ipairs(self.partners_noself) do
				if friend:hasSkills("tuntian+zaoxian") then
					if not friend:hasSkill("manjuan") then
						target = friend
						break
					end
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude() then
					if enemy:hasSkill("manjuan") then
						target = enemy
						break
					end
				end
			end
		end
		if target then
			self:sortByKeepValue(cards)
			local to_use = nil
			if self:isPartner(target) then
				to_use = cards[1]
			else
				for _, c in ipairs(cards) do
					if not sgs.isCard("Peach", c, target) then
						if not sgs.isCard("Nullification", c, target) then
							to_use = c
							break
						end
					end
				end
			end
			if to_use then
				target:setFlags("AI_NosXuanhuoTarget")
				local card_str = "@NosXuanhuoCard=" .. to_use:getEffectiveId()
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then 
					use.to:append(target)
				end
			end
		end
	end
end
sgs.ai_skill_playerchosen["nosxuanhuo"] = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if player:getHandcardNum() <= 2 or player:getHp() < 2 then
			if self:isPartner(player) then
				if not player:hasFlag("AI_NosXuanhuoTarget") then
					if not self:needKongcheng(player, true) then
						if not player:hasSkill("manjuan") then
							return player
						end
					end
				end
			end
		end
	end
	for _, player in sgs.qlist(targets) do
		if self:isPartner(player) then
			if not player:hasFlag("AI_NosXuanhuoTarget") then
				if not self:needKongcheng(player, true) then
					if not player:hasSkill("manjuan") then
						return player
					end
				end
			end
		end
	end
	for _, player in sgs.qlist(targets) do
		if player:objectName() == self.player:objectName() then
			return player
		end
	end
end
sgs.nosxuanhuo_suit_value = {
	heart = 3.9
}
--[[
	套路：仅使用“眩惑技能卡”
]]--
sgs.ai_series["NosXuanhuoCardOnly"] = {
	name = "NosXuanhuoCardOnly",
	IQ = 2,
	value = 2,
	priority = 2,
	skills = "nosxuanhuo",
	cards = {
		["NosXuanhuoCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xuanhuo_skill = sgs.ai_skills["nosxuanhuo"]
		local dummyCard = xuanhuo_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["NosXuanhuoCard"], "NosXuanhuoCardOnly")
--[[****************************************************************
	武将：怀旧·凌统（吴）
]]--****************************************************************
--[[
	技能：旋风
	描述：每当你失去一次装备区里的牌后，你可以选择一项：视为对一名其他角色使用一张无距离限制的【杀】，或对距离1的一名角色造成1点伤害 
]]--
sgs.ai_playerchosen_intention["nosxuanfeng_damage"] = 80
sgs.ai_playerchosen_intention["nosxuanfeng_slash"] = 80
sgs.ai_skill_choice["nosxuanfeng"] = function(self, choices)
	self:sort(self.opponents, "defenseSlash")
	for _, enemy in ipairs(self.opponents) do
		if self.player:distanceTo(enemy)<=1 then
			return "damage"
		elseif self:willUseSlash(enemy, self.player, sgs.slash) then
			if self:slashIsEffective(sgs.slash, enemy) then
				if sgs.isGoodTarget(self, enemy, self.opponents) then
					return "slash"
				end
			end
		end
	end
	return "nothing"
end
sgs.ai_skill_playerchosen["nosxuanfeng_damage"] = sgs.ai_skill_playerchosen["damage"]
sgs.ai_skill_playerchosen["nosxuanfeng_slash"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
sgs.nosxuanfeng_keep_value = sgs.xiaoji_keep_value
--[[****************************************************************
	武将：怀旧·徐庶（蜀）
]]--****************************************************************
--[[
	技能：无言（锁定技）
	描述：你使用的非延时类锦囊牌对其他角色无效。其他角色使用的非延时类锦囊牌对你无效 
]]--
sgs.trick_invalid_system["noswuyan"] = {
	name = "noswuyan",
	reason = "noswuyan",
	judge_func = function(card, target, source)
		if target:objectName() ~= source:objectName() then
			if card:isNDTrick() then
				if target:hasSkill("noswuyan") then
					return true
				elseif source:hasSkill("noswuyan") then
					return true
				end
			end
		end
		return false
	end,
}
sgs.amazing_grace_invalid_system["noswuyan"] = {
	name = "noswuyan",
	reason = "noswuyan",
	judge_func = function(self, card, target, source)
		if target:hasSkill("noswuyan") then
			return target:objectName() ~= source:objectName()
		end
	end
}
--[[
	技能：举荐
	描述：出牌阶段限一次，你可以弃置至多三张牌并选择一名其他角色，该角色摸等量的牌。若你以此法弃置三张同一类别的牌，你回复1点体力。 
]]--
--[[
	内容：“举荐技能卡”的卡牌信息
]]--
sgs.card_constituent["NosJujianCard"] = {
	benefit = 1,
	use_value = 6.7,
	use_priority = 0,
}
--[[
	内容：“举荐技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["NosJujianCard"] = -100
--[[
	内容：注册“举荐技能卡”
]]--
sgs.RegistCard("NosJujianCard")
--[[
	内容：“举荐”技能信息
]]--
sgs.ai_skills["nosjujian"] = {
	name = "nosjujian",
	dummyCard = function(self)
		return sgs.Card_Parse("@NosJujianCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("NosJujianCard") then
			return #handcards > 0
		end
		return false
	end,
}
--[[
	内容：“举荐技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["NosJujianCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local abandon_card = {}
	local index = 0
	local hasPeach = ( self:getCardsNum("Peach") > 0 )
	local trick_num, basic_num, equip_num = 0, 0, 0
	if not hasPeach then
		if self.player:isWounded() then
			local cards = self.player:getCards("he")
			if cards:length() >=3 then
				cards = sgs.QList2Table(cards)
				self:sortByUseValue(cards, true)
				for _, c in ipairs(cards) do
					local type = c:getTypeId()
					if type == sgs.Card_TypeTrick then
						if not sgs.isCard("ExNihilo", c, self.player) then
							trick_num = trick_num + 1
						end
					elseif type == sgs.Card_TypeBasic then
						basic_num = basic_num + 1
					elseif type == sgs.Card_TypeEquip then
						equip_num = equip_num + 1
					end
				end
				local result_class
				if trick_num >= 3 then 
					result_class = "TrickCard"
				elseif equip_num >= 3 then 
					result_class = "EquipCard"
				elseif basic_num >= 3 then 
					result_class = "BasicCard"
				end
				for _, c in ipairs(cards) do
					if c:isKindOf(result_class) then
						if not sgs.isCard("ExNihilo", c, self.player) then
							table.insert(abandon_card, c:getId())
							index = index + 1
							if index == 3 then 
								break 
							end
						end
					end
				end
				if index == 3 then
					local target = self:findPlayerToDraw(false, 3)
					if target then
						local card_str = "@NosJujianCard=" .. table.concat(abandon_card, "+")
						use.card = sgs.Card_Parse(card_str)
						if use.to then 
							use.to:append(target) 
						end
						return
					end
				end
			end
		end
	end
	abandon_card = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slash_num = self:getCardsNum("Slash")
	local jink_num = self:getCardsNum("Jink")
	index = 0
	for _, c in ipairs(cards) do
		if index >= 3 then 
			break 
		end
		if c:isKindOf("TrickCard") then
			if not c:isKindOf("Nullification") then
				table.insert(abandon_card, c:getId())
				index = index + 1
			end
		elseif c:isKindOf("EquipCard") then
			table.insert(abandon_card, c:getId())
			index = index + 1
		elseif c:isKindOf("Slash") then
			table.insert(abandon_card, c:getId())
			index = index + 1
			slash_num = slash_num - 1
		elseif c:isKindOf("Jink") then
			if jink_num > 1 then
				table.insert(abandon_card, c:getId())
				index = index + 1
				jink_num = jink_num - 1
			end
		end
	end
	if index == 3 then
		local target = self:findPlayerToDraw(false, 3)
		if target then
			local card_str = "@NosJujianCard=" .. table.concat(abandon_card, "+")
			use.card = sgs.Card_Parse(card_str)
			if use.to then 
				use.to:append(target) 
			end
			return
		end
	end
	local overflow = self:getOverflow()
	if overflow > 0 then
		local discard = self:askForDiscard("dummyreason", math.min(overflow, 3), nil, false, true)
		local target = self:findPlayerToDraw(false, math.min(overflow, 3))
		if target then
			local card_str = "@NosJujianCard=" .. table.concat(discard, "+")
			use.card = sgs.Card_Parse(card_str)
			if use.to then 
				use.to:append(target) 
			end
			return
		end
	end
	if index > 0 then
		local target = self:findPlayerToDraw(false, index)
		if target then
			local card_str = "@NosJujianCard=" .. table.concat(abandon_card, "+")
			use.card = sgs.Card_Parse(card_str)
			if use.to then 
				use.to:append(target) 
			end
		end
	end
end
--[[
	套路：仅使用“举荐技能卡”
]]--
sgs.ai_series["NosJujianCardOnly"] = {
	name = "NosJujianCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "nosjujian",
	cards = {
		["NosJujianCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jujian_skill = sgs.ai_skills["nosjujian"]
		local dummyCard = jujian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["NosJujianCard"], "NosJujianCardOnly")
--[[****************************************************************
	武将：怀旧·张春华（魏）
]]--****************************************************************
--[[
	技能：绝情（锁定技）
	描述：你即将造成的伤害视为失去体力。 
]]--
--[[
	技能：伤逝
	描述：弃牌阶段外，每当你的手牌数小于你已损失的体力值时，你可以将手牌数补至等同于你已损失的体力值。 
]]--
sgs.ai_skill_invoke["nosshangshi"] = sgs.ai_skill_invoke["shangshi"]
--[[****************************************************************
	武将：怀旧·关兴张苞（蜀）
]]--****************************************************************
--[[
	技能：父魂
	描述：摸牌阶段开始时，你可以放弃摸牌，展示牌堆顶的两张牌并获得之。若展示的牌不为同一颜色，你获得技能“武圣”、“咆哮”，直到回合结束。 
]]--
sgs.ai_skill_invoke["nosfuhun"] = function(self, data)
	if not self.player:isSkipped(sgs.Player_Play) then
		local target = 0
		local range = self.player:getAttackRange()
		for _, enemy in ipairs(self.opponents) do
			local distance = self.player:distanceTo(enemy)
			if distance <= range then 
				target = target + 1 
				break
			end
		end
		if target > 0 then
			return true
		end
	end
	return false
end
sgs.draw_cards_system["nosfuhun"] = {
	name = "nosfuhun",
	return_func = function(self, player)
		return 2
	end,
}
--[[****************************************************************
	武将：怀旧·韩当（吴）
]]--****************************************************************
--[[
	技能：弓骑
	描述：你可以将一张装备牌当【杀】使用或打出。你以此法使用的【杀】无距离限制。 
]]--
--[[
	内容：注册“弓骑杀”
]]--
sgs.RegistCard("nosgongqi>>Slash")
--[[
	内容：“弓骑”技能信息
]]--
sgs.ai_skills["nosgongqi"] = {
	name = "nosgongqi",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local number = sgs.slash:getNumberString()
		local card_id = sgs.slash:getEffectiveId()
		local card_str = ("slash:nosgongqi[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			local cards = self.player:getCards("he")
			for _,equip in sgs.qlist(cards) do
				if equip:isKindOf("EquipCard") then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“弓骑杀”的具体产生方式
]]--
sgs.ai_view_as_func["nosgongqi>>Slash"] = function(self, card)
	local cards = self.player:getCards("he")
	local equips = {}
	for _,equip in sgs.qlist(cards) do
		if equip:isKindOf("EquipCard") then
			table.insert(equips, equip)
		end
	end
	if #equips > 0 then
		self:sortByUseValue(equips, true)
		local slashValue = sgs.getCardValue("Slash", "use_value")
		for _,equip in ipairs(equips) do
			local name = sgs.getCardName(equip)
			local value = sgs.getCardValue(name, "use_value")
			if value < slashValue then
				local suit = equip:getSuitString()
				local number = equip:getNumberString()
				local card_id = equip:getEffectiveId()
				local card_str = ("slash:nosgongqi[%s:%s]=%d"):format(suit, number, card_id)
				return sgs.Card_Parse(card_str)
			end
		end
	end
end
--[[
	内容：“弓骑”响应方式
	需求：杀
]]--
sgs.ai_view_as["nosgongqi"] = function(card, player, place, class_name)
	if place ~= sgs.Player_PlaceSpecial then
		if card:getTypeId() == sgs.Card_TypeEquip then
			if not card:hasFlag("using") then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				return ("slash:nosgongqi[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end
--[[
	内容：“弓骑”卡牌需求
]]--
sgs.card_need_system["nosgongqi"] = function(self, card, player)
	if card:getTypeId() == sgs.Card_TypeEquip then
		return sgs.getKnownCard(player, "EquipCard", true) == 0
	end
	return false
end
--[[
	内容：“弓骑”统计信息
]]--
sgs.card_count_system["nosgongqi"] = {
	name = "nosgongqi",
	pattern = "Slash",
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("nosgongqi") then
			local count = data["count"]
			count = count + data["EquipCard"] 
			count = count + data["unknown"] * 0.5
			return count
		end
	end
}
--[[
	技能：解烦
	描述：你的回合外，当一名角色处于濒死状态时，你可以对当前回合角色使用一张【杀】。此【杀】造成伤害时你防止此伤害，视为对该濒死角色使用了一张【桃】。 
]]--
--[[
	内容：“解烦技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["NosJiefanCard"] = sgs.ai_card_intention["Peach"]
sgs.ai_skill_cardask["jiefan-slash"] = function(self, data, pattern, target)
	if self:isOpponent(target)then
		if self:canLeiji(target, self.player) then 
			return "." 
		end
	end
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes) do
		if self:slashIsEffective(slash, target) then 
			return slash:toString()
		end 
	end
	return "."
end
sgs.ai_cardsview_valuable["nosjiefan"] = function(self, class_name, player)
	if class_name == "Peach" then
		if not player:hasFlag("Global_NosJiefanFailed") then
			local dying = self.room:getCurrentDyingPlayer()
			if dying then
				local current = self.room:getCurrent()
				if current and current:isAlive() then
					if current:getPhase() ~= sgs.Player_NotActive then
						if current:objectName() ~= player:objectName() then
							local flag = true
							if current:hasSkill("wansha") then
								if player:objectName() ~= dying:objectName() then
									flag = false
								end
							end
							if flag then
								if self:isOpponent(current) then
									if self:canLeiji(current, player) then
										flag = false
									end
								end
							end
							if flag then
								return "@NosJiefanCard=."
							end
						end
					end
				end
			end
		end
	end
end
--[[
	内容：“解烦”卡牌需求
]]--
sgs.card_need_system["nosjiefan"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) == 0
	end
	return false
end
--[[****************************************************************
	武将：怀旧·马岱（蜀）
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：潜袭
	描述：每当你使用【杀】对距离1的目标角色造成伤害时，你可以进行一次判定，若判定结果不为♥，你防止此伤害，该角色减1点体力上限。 
]]--
sgs.ai_skill_invoke["nosqianxi"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isPartner(target) then 
		return false 
	end
	local lost = target:getLostHp()
	local hp = target:getHp()
	if lost >= 2 then
		if hp <= 1 then 
			return false 
		end
	end
	if self:hasSkills(sgs.masochism_skill, target) then
		return true
	elseif self:hasSkills(sgs.recover_skill, target) then
		return true
	elseif self:hasSkills("longhun|buqu|noslonghun", target) then 
		return true 
	end
	if self:hasHeavySlashDamage(self.player, damage.card, target) then 
		return false 
	end
	local maxhp = target:getMaxHp()
	if maxhp - hp < 2 then
		return true
	end
	return false
end
--[[
	内容：“潜袭”卡牌需求
]]--
sgs.card_need_system["qianxi"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) == 0
	end
	return false
end
--[[****************************************************************
	武将：怀旧·王异（魏）
]]--****************************************************************
--[[
	技能：贞烈
	描述：每当你的判定牌生效前，你可以展示牌堆顶的一张牌代替之。 
]]--
sgs.ai_skill_invoke["noszhenlie"] = function(self, data)
	local judge = data:toJudge()
	return not judge:isGood() 
end
--[[
	技能：秘计
	描述：回合开始或结束阶段开始时，若你已受伤，你可以进行一次判定，若判定结果为黑色，你观看牌堆顶的X张牌然后将其交给一名角色。（X为你已损失的体力值） 
]]--
sgs.ai_skill_playerchosen["nosmiji"] = function(self, targets)
	local lost = self.player:getLostHp()
	local phase = self.player:getPhase()
	local num = self.player:getHandcardNum()
	if num - lost < 2 then
		if not self:needKongcheng() then
			if phase == sgs.Player_Start then
				if not self:willSkipPlayPhase() then 
					return self.player 
				end
			elseif phase == sgs.Player_Finish then
				return self.player 
			end
		end
	end
	local target = self:findPlayerToDraw(true, lost)
	return target or self.player
end
--[[
	内容：“秘计”最优体力
]]--
sgs.best_hp_system["nosmiji"] = {
	name = "nosmiji",
	reason = "nosmiji",
	best_hp = function(player, maxhp, isLord)
		if isLord then
			return math.max(3, maxhp-1)
		else
			return math.max(2, maxhp-1)
		end
	end,
}