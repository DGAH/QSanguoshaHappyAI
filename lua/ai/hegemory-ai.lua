--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）国战专属扩展包部分
]]--
--[[****************************************************************
	武将：国战·乐进（魏）
]]--****************************************************************
sgs.ai_chaofeng.yuejin = 2
--[[
	技能：骁果
	描述：其他角色的结束阶段开始时，你可以弃置一张基本牌，令该角色选择一项：弃置一张装备牌，或受到你对其造成的1点伤害。 
]]--
sgs.ai_skill_cardask["@xiaoguo"] = function(self, data)
	local current = self.room:getCurrent()
	local analeptic, slash, jink
	local handcards = self.player:getHandcards()
	for _, basic in sgs.qlist(handcards) do
		if basic:isKindOf("Analeptic") then 
			analeptic = basic
		elseif basic:isKindOf("Slash") then 
			slash = basic
		elseif basic:isKindOf("Jink") then 
			jink = basic
		end
	end
	local card = nil
	if slash then 
		card = slash
	elseif jink then 
		card = jink
	elseif analeptic then
		if not self:isWeak() then
			card = analeptic
		elseif self:getCardsNum("Analeptic") > 1 then
			card = analeptic
		end
	end
	if card then
		if self:isPartner(current) then
			if self:needToThrowArmor(current) then 
				if card:isKindOf("Slash") then
					return "$" .. card:getEffectiveId()
				elseif card:isKindOf("Jink") then
					if self:getCardsNum("Jink") > 1 then
						return "$" .. card:getEffectiveId()
					end
				end
			end
		elseif self:isOpponent(current) then
			if self:damageIsEffective(current, sgs.DamageStruct_Normal, self.player) then 
				if self:invokeDamagedEffect(current, self.player) then
					return "."
				elseif self:needToLoseHp(current, self.player) then
					return "."
				elseif self:needToThrowArmor(current) then 
					return "." 
				elseif self:hasSkills(sgs.lose_equip_skill, current) then
					local equips = current:getCards("e")
					if equips:length() > 0 then 
						return "." 
					end
				end
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@xiaoguo-discard"] = function(self, data)
	if self:needToThrowArmor() then
		local armor = player:getArmor()
		return "$" .. armor:getEffectiveId()
	end
	local YueJin = self.room:findPlayerBySkillName("xiaoguo")
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, YueJin) then
		return "."
	end
	if self:invokeDamagedEffect(self.player, YueJin) then
		return "."
	end
	if self:needToLoseHp(self.player, YueJin) then
		return "."
	end
	local card_id
	if self:hasSkills(sgs.lose_equip_skill) then
		if self.player:getWeapon() then 
			card_id = self.player:getWeapon():getId()
		elseif self.player:getOffensiveHorse() then 
			card_id = self.player:getOffensiveHorse():getId()
		elseif self.player:getArmor() then 
			card_id = self.player:getArmor():getId()
		elseif self.player:getDefensiveHorse() then 
			card_id = self.player:getDefensiveHorse():getId()	
		end
	end
	if not card_id then
		local handcards = self.player:getCards("h")
		for _, card in sgs.qlist(handcards) do
			if card:isKindOf("EquipCard") then
				card_id = card:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		if self.player:getWeapon() then 
			card_id = self.player:getWeapon():getId()
		elseif self.player:getOffensiveHorse() then 
			card_id = self.player:getOffensiveHorse():getId()
		elseif self:isWeak() then
			if self.player:getArmor() then 
				card_id = self.player:getArmor():getId()
			elseif self.player:getDefensiveHorse() then 
				card_id = self.player:getDefensiveHorse():getId()
			end			
		end
	end
	if card_id then
		return "$" .. card_id
	end
	return "."
end
--[[
	内容：“骁果”卡牌需求
]]--
sgs.card_need_system["xiaoguo"] = function(self, card, player)
	if card:getTypeId() == sgs.Card_Basic then
		return sgs.getKnownCard(player, "BasicCard", true) == 0
	end
	return false
end
--[[****************************************************************
	武将：国战·甘夫人（蜀）
]]--****************************************************************
--[[
	技能：淑慎
	描述：每当你回复1点体力后，你可以令一名其他角色摸一张牌。 
]]--
--[[
	内容：“淑慎技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShushenCard"] = -80
sgs.ai_skill_playerchosen["shushen"] = function(self, targets)
	if #self.partners_noself > 0 then 
		local to = self:findPlayerToDraw(false)
		if to then 
			return ("@ShushenCard=.->%s"):format(to:objectName()) 
		end
	end
end
--[[
	技能：神智
	描述：准备阶段开始时，你可以弃置所有手牌。若你以此法弃置的牌不少于X张，你回复1点体力。（X为你当前的体力值） 
]]--
sgs.ai_skill_invoke["shenzhi"] = function(self, data)
	if self:getCardsNum("Peach") > 0 then 
		return false 
	end
	local num = self.player:getHandcardNum()
	if num >= 3 then 
		return false 
	end
	if num >= self.player:getHp() then
		if self.player:isWounded() then 
			return true 
		end
	end
	if num == 1 then
		if self.player:hasSkill("beifa") then
			if self:needKongcheng() then
				return true
			end
		end
		if self.player:hasSkill("sijian") then
			return true
		end
	end
	return false
end
--[[
	内容：“神智”卡牌需求
]]--
sgs.card_need_system["shenzhi"] = function(self, card, player)
	return player:getHandcardNum() < player:getHp()
end
--[[****************************************************************
	武将：国战·陆逊（吴）
]]--****************************************************************
--[[
	技能：谦逊（锁定技）
	描述：你不能被选择为【顺手牵羊】与【乐不思蜀】的目标。
]]--
--[[
	技能：度势
	描述：出牌阶段限四次，你可以弃置一张红色手牌并选择任意数量的其他角色，你与这些角色各摸两张牌并弃置两张牌。 
]]--
--[[
	内容：“度势技能卡”的卡牌成分
]]--
sgs.card_constituent["DuoshiCard"] = {
	use_value = 3,
	use_priority = 2.2,
}
--[[
	内容：“度势技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["DuoshiCard"] = function(self, card, source, targets)
	for _,target in ipairs(targets) do
		if target:hasSkill("manjuan") then
			sgs.updateIntention(source, target, 50)
		else
			sgs.updateIntention(source, target, -50)
		end
	end
end
--[[
	内容：注册“度势技能卡”
]]--
sgs.RegistCard("DuoshiCard")
--[[
	内容：“度势”技能信息
]]--
sgs.ai_skills["duoshi"] = {
	name = "duoshi",
	dummyCard = function(self)
		local card_str = "@DuoshiCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:usedTimes("DuoshiCard") < 4 then
			for _,red in ipairs(handcards) do
				if red:isRed() then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“度势技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DuoshiCard"] = function(self, card, use)
	if sgs.turncount <= 1 then
		if #self.friends_noself == 0 then
			if not self:isWeak() then 
				return 
			end
		end
	end
	if self:needBear() then 
		return 
	end
	if self.player:getCardCount(false) <= 2 then 
		return 
	end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards) 
	self:sortByUseValue(cards, true)
	local value = sgs.getCardValue("DuoshiCard", "use_value")
	for _,c in ipairs(cards) do
		if c:isRed() then
			local should_use = true
			if c:isKindOf("Slash") then
				local dummy_use = { 
					isDummy = true, 
				}
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(c, dummy_use)
					if dummy_use.card then 
						shouldUse = false 
					end
				end
			elseif c:isKindOf("TrickCard") then 
				local name = sgs.getCardName(c)
				if sgs.getCardValue(name, "use_value") > value then 
					local dummy_use = { 
						isDummy = true, 
					}
					self:useTrickCard(c, dummy_use)
					if dummy_use.card then 
						shouldUse = false 
					end
				end
			end
			if shouldUse then
				if not c:isKindOf("Peach") then
					local card_id = c:getEffectiveId()
					local card_str = "@DuoshiCard=" .. card_id
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then 
						use.to:append(self.player) 
						for _,friend in ipairs(self.partners_noself) do
							if not friend:hasSkill("manjuan") then
								use.to:append(friend)
							end
						end
						for _,enemy in ipairs(self.opponents) do
							if enemy:hasSkill("manjuan") then
								use.to:append(enemy)
							end
						end
					end
					return 
				end
			end
		end
	end
end
--[[
	套路：仅使用“度势技能卡”
]]--
sgs.ai_series["DuoshiCardOnly"] = {
	name = "DuoshiCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "duoshi",
	cards = {
		["DuoshiCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local duoshi_skill = sgs.ai_skills["duoshi"]
		local dummyCard = duoshi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DuoshiCard"], "DuoshiCardOnly")
--[[****************************************************************
	武将：国战·丁奉（吴）
]]--****************************************************************
--[[
	技能：短兵（锁定技）
	描述：你使用【杀】可以额外选择一名距离1的目标。 
]]--
--[[
	技能：奋迅
	描述：出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，你获得以下锁定技：本回合你无视与该角色的距离。 
]]--
--[[
	内容：“奋迅技能卡”的卡牌成分
]]--
sgs.card_constituent["FenxunCard"] = {
	use_value = 5.5,
	use_priority = 4.1,
}
--[[
	内容：“奋迅技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["FenxunCard"] = 50
--[[
	内容：注册“奋迅技能卡”
]]--
sgs.RegistCard("FenxunCard")
--[[
	内容：“奋迅”技能信息
]]--
sgs.ai_skills["fenxun"] = {
	name = "fenxun",
	dummyCard = function(self)
		return sgs.Card_Parse("@FenxunCard=.")
	end,
	enabled = function(self, handcards) 
		if self.player:hasUsed("FenxunCard") then 
			return false
		elseif self.player:isNude() then
			return false
		end
		return true
	end,
}
--[[
	内容：“奋迅技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["FenxunCard"] = function(self, card, use)
	if #self.opponents == 0 then
		return 
	elseif self:needBear() then
		return 
	end
	local acard = nil
	local slashCount = self:getCardsNum("Slash")
	if self:needToThrowArmor() then
		local armor = self.player:getArmor()
		local card_str = "@FenxunCard=" .. armor:getId()
		acard = sgs.Card_Parse(card_str)
	else
		local card_id = nil
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		if self.player:getHandcardNum() > 0 then
			local jinkCount = self:getCardsNum("Jink")
			local lightning = self:getCard("Lightning")
			if lightning then
				if not self:willUseLightning(lightning) then
					card_id = lightning:getEffectiveId()
				end
			end
			if not card_id then
				for _, c in ipairs(cards) do
					if sgs.isKindOf("AmazingGrace|EquipCard", c) then
						card_id = c:getEffectiveId()
						break
					end
				end
			end
			if not card_id then
				if jinkCount > 1 then
					for _, c in ipairs(cards) do
						if c:isKindOf("Jink") then
							card_id = c:getEffectiveId()
							break
						end
					end
				end
			end
			if not card_id then
				if slashCount > 1 then
					for _, c in ipairs(cards) do
						if c:isKindOf("Slash") then
							slashCount = slashCount - 1
							card_id = c:getEffectiveId()
							break
						end
					end
				end
			end
		end
		if not card_id then
			local weapon = self.player:getWeapon()
			if weapon then
				card_id = weapon:getEffectiveId()
			end
		end
		if not card_id then
			for _, c in ipairs(cards) do
				if sgs.isKindOf("AmazingGrace|EquipCard|BasicCard", c) then
					if not sgs.isCard("Peach", c, self.player) then
						if not sgs.isCard("Slash", c, self.player) then
							card_id = c:getEffectiveId()
							break
						end
					end
				end
			end
		end
		if slashCount > 0 then
			if card_id then
				local card_str = "@FenxunCard=" .. card_id
				acard = sgs.Card_Parse(card_str)
			end
		end
	end
	if acard then
		self:sort(self.opponents, "defense")
		local target = nil
		local slashes = self:getCards("Slash")
		for _,slash in ipairs(slashes) do
			if not acard:getSubcards() or slash:getEffectiveId() ~= acard:getSubcards():at(0) then
				local target_num, hasTarget = 0
				for _, enemy in ipairs(self.opponents) do
					if self:willUseSlash(enemy, self.player, slash) then
						if self.player:canSlash(enemy, slash, false) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								local distance = self.player:distanceTo(enemy)
								if distance > 1 then
									if not target then
										target = enemy
									end
								elseif distance == 1 then
									hasTarget = true
								end
								if self.player:inMyAttackRange(enemy) then
									target_num = target_num + 1
								end
							end
						end
					end
				end
				if hasTarget and target_num >= 2 then 
					return 
				end
			end
		end
		if target then
			if slashCount > 0 then
				use.card = acard
				if use.to then
					use.to:append(target)
				end
			end
		end
	end
end
--[[
	套路：仅使用“奋迅技能卡”
]]--
sgs.ai_series["FenxunCardOnly"] = {
	name = "FenxunCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "fenxun",
	cards = {
		["FenxunCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local fenxun_skill = sgs.ai_skills["fenxun"]
		local dummyCard = fenxun_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["FenxunCard"], "FenxunCardOnly")
--[[****************************************************************
	武将：国战·马腾（群）
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：雄异（限定技）
	描述：出牌阶段，你可以令你与任意数量的其他角色各摸三张牌。若以此法摸牌的角色数不大于全场角色数的一半，你回复1点体力。 
]]--
--[[
	内容：“雄异技能卡”的卡牌成分
]]--
sgs.card_constituent["XiongyiCard"] = {
	use_priority = 9.31,
}
--[[
	内容：“雄异技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["XiongyiCard"] = -80
--[[
	内容：注册“雄异技能卡”
]]--
sgs.RegistCard("XiongyiCard")
--[[
	内容：“雄异”技能信息
]]--
sgs.ai_skills["xiongyi"] = {
	name = "xiongyi",
	dummyCard = function(self)
		return sgs.Card_Parse("@XiongyiCard=.") 
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@arise") > 0 then
			return true
		end
		return false
	end,
}
--[[
	内容：“雄异技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["XiongyiCard"] = function(self, card, use)
	local can_use = false
	if sgs.turncount > 1 then
		if self:isWeak() then
			can_use = true
		end
	end
	if not can_use then
		if sgs.turncount > 2 then
			if self.player:getLostHp() > 0 then
				if #self.partners <= #self.opponents then
					can_use = true
				end
			end
		end
	end
	if can_use then
		use.card = card
		for i = 1, #self.partners, 1 do
			if use.to then 
				use.to:append(self.partners[i]) 
			end
		end
	end
end
--[[
	套路：仅使用“雄异技能卡”
]]--
sgs.ai_series["XiongyiCardOnly"] = {
	name = "XiongyiCardOnly",
	IQ = 2,
	value = 5,
	priority = 4,
	skills = "xiongyi",
	cards = {
		["XiongyiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xiongyi_skill = sgs.ai_skills["xiongyi"]
		local dummyCard = xiongyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XiongyiCard"], "XiongyiCardOnly")
--[[****************************************************************
	武将：国战·孔融（群）
]]--****************************************************************
--[[
	技能：名士（锁定技）
	描述：每当你受到伤害时，若伤害来源装备区的牌数不大于你的装备区的牌数，此伤害-1。
]]--
--[[
	技能：礼让
	描述：当你的牌因弃置而置入弃牌堆时，你可以将其中任意数量的牌以任意分配方式交给任意数量的其他角色。 
]]--
sgs.ai_skill_invoke["lirang"] = function(self, data)
	return #self.partners_noself > 0
end
sgs.ai_skill_askforyiji["lirang"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, card)
	end
	local Shenfen_user = nil
	local alives = self.room:getAlivePlayers()
	for _, player in sgs.qlist(alives) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	local card, target = self:getCardNeedPlayer(cards)
	local friends = {}
	local Dimeng_friend, Dimeng_another
	for _, friend in ipairs(self.partners_noself) do
		local flag = true
		if friend:hasSkill("manjuan") then
			if friend:getPhase() == sgs.Player_NotActive then
				flag = false
			end
		end
		if flag then
			flag = false
			if not self:needKongcheng(friend, true) then
				flag = true
			elseif #self.partners_noself == 1 then
				flag = true
			elseif #card_ids >= 3 then
				flag = true
			end
		end
		if flag then
			flag = not self:isLihunTarget(friend) 
		end
		if flag then
			flag = false
			if not Shenfen_user then
				flag = true
			elseif self:isPartner(Shenfen_user) then
				flag = true
			elseif friend:objectName() ~= Shenfen_user:objectName() then
				if friend:getHandcardNum() >= 4 then
					flag = true
				end
			end
		end
		if flag then
			if friend:hasFlag("DimengTarget") then
				local others = self.room:getOtherPlayers(friend)
				for _, p in sgs.qlist(others) do
					if p:hasFlag("DimengTarget") then
						if self:isOpponent(p) then
							Dimeng_friend = friend
							Dimeng_another = p
							break
						end
					end
				end
			end
			table.insert(friends, friend)
		end
	end
	if #friends > 0 then
		local card, target = self:getCardNeedPlayer(cards)
		if card and target then
			for _, friend in ipairs(friends) do
				if friend:objectName() == target:objectName() then
					if Dimeng_friend and Dimeng_another and friend:objectName() == Dimeng_friend:objectName() then
						return Dimeng_another, card:getEffectiveId()
					else
						return friend, card:getEffectiveId()
					end
				end
			end
		end
		if Shenfen_user and self:isPartner(Shenfen_user) then
			return Shenfen_user, cards[1]:getEffectiveId()
		end
		self:sort(friends, "defense")
		self:sortByKeepValue(cards, true)
		if Dimeng_friend and Dimeng_another and friends[1]:objectName() == Dimeng_friend:objectName() then
			return Dimeng_another, cards[1]:getEffectiveId()
		else
			return friends[1], cards[1]:getEffectiveId()
		end
	end
end
--[[****************************************************************
	武将：国战·纪灵（群）
]]--****************************************************************
sgs.ai_chaofeng.jiling = 2
--[[
	技能：双刃
	描述：出牌阶段开始时，你可以与其他角色拼点：若你赢，视为你对一名其他角色使用一张无距离限制的【杀】；若你没赢，你结束出牌阶段。 
]]--
--[[
	内容：“双刃技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShuangrenCard"] = sgs.ai_card_intention["TianyiCard"]
sgs.ai_skill_use["@@shuangren"] = function(self, prompt)
	if self.player:isKongcheng() then 
		return "." 
	end
	self:sort(self.opponents, "handcard")
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	local dummy_use = { 
		isDummy = true, 
	}
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(sgs.slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")
	if dummy_use.card then
		for _, enemy in ipairs(self.opponents) do
			if not enemy:isKongcheng() then
				if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() > 1 then
					local max_card = self:getMaxPointCard(enemy)
					local max_point = 100
					if max_card then
						max_point = max_card:getNumber()
					end
					if my_max_point > max_point then
						self.shuangren_card = my_max_card:getEffectiveId()
						return "@ShuangrenCard=.->" .. enemy:objectName()
					end
				end
			end
		end
		for _, enemy in ipairs(self.opponents) do
			if not enemy:isKongcheng() then
				if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() > 1 then
					if my_max_point >= 10 then
						self.shuangren_card = my_max_card:getEffectiveId()
						return "@ShuangrenCard=.->" .. enemy:objectName()
					end
				end
			end
		end
		if #self.opponents < 1 then 
			return 
		end
		self:sort(self.partners_noself, "handcard")
		for index = #self.partners_noself, 1, -1 do
			local friend = self.partners_noself[index]
			if not friend:isKongcheng() then
				local min_card = self:getMinPointCard(friend)
				local min_point = 100
				if min_card then
					min_point = min_card:getNumber()
				end
				if my_max_point > min_point then
					self.shuangren_card = my_max_card:getEffectiveId()
					return "@ShuangrenCard=.->" .. friend:objectName()
				end
			end
		end
		local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
		if ZhuGeLiang then
			if self:isPartner(ZhuGeLiang) then
				if ZhuGeLiang:getHandcardNum() == 1 then
					if ZhuGeLiang:objectName() ~= self.player:objectName() then
						if my_max_point >= 7 then
							self.shuangren_card = my_max_card:getEffectiveId()
							return "@ShuangrenCard=.->" .. ZhuGeLiang:objectName()
						end
					end
				end
			end
		end
		for index = #self.partners_noself, 1, -1 do
			local friend = self.partners_noself[index]
			if not friend:isKongcheng() then
				if my_max_point >= 7 then
					self.shuangren_card = my_max_card:getEffectiveId()
					return "@ShuangrenCard=.->" .. friend:objectName()
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_pindian["shuangren"] = function(self, requestor, maxcard, mincard)
	local max_card = self:getMaxPointCard()
	if self:isPartner(requestor) then
		return self:getMinPointCard()
	elseif max_card:getNumber() < 6 then
		return mincard
	else
		return max_card
	end
end
sgs.ai_skill_playerchosen["shuangren"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
--[[
	内容：“双刃”卡牌需求
]]--
sgs.card_need_system["shuangren"] = sgs.card_need_system["bignumber"]
--[[****************************************************************
	武将：国战·田丰（群）
]]--****************************************************************
--[[
	技能：死谏
	描述：每当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。 
]]--
sgs.ai_playerchosen_intention["sijian"] = function(self, source, target)
	local intention = 80
	if self:needToThrowArmor(target) then
		intention = 0
	elseif target:hasSkill("kongcheng") then
		if target:getHandcardNum() == 1 then
			intention = 0
		end
	end
	sgs.updateIntention(source, target, intention)
end
sgs.ai_skill_playerchosen["sijian"] = function(self, targets)
	return self:findPlayerToDiscard()
end
--[[
	技能：随势
	描述：每当其他角色进入濒死状态时，伤害来源可以令你摸一张牌；每当其他角色死亡时，伤害来源可以令你失去1点体力。 
]]--
sgs.ai_skill_invoke["suishi"] = function(self, data)
	local promptlist = data:toString():split(":")
	local effect = promptlist[1]
	local TianFeng = findPlayerByObjectName(self.room, promptlist[2])
	if effect == "draw" then
		return TianFeng and self:isPartner(TianFeng)
	elseif effect == "losehp" then
		return TianFeng and self:isOpponent(TianFeng)
	end
	return false
end
--[[****************************************************************
	武将：国战·潘凤（群）
]]--****************************************************************
--[[
	技能：狂斧
	描述：每当你使用的【杀】对一名角色造成伤害后，你可以将其装备区里的一张牌弃置或置入你的装备区。 
]]--
sgs.ai_skill_invoke["kuangfu"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:hasSkills(sgs.lose_equip_skill, target) then
		if self:isPartner(target) then
			if not self:isWeak(target) then
				return true
			end
		end
		return false
	end
	local benefit = false
	local equips = target:getCards("e")
	if equips:length() == 1 then
		if target:getArmor() then
			if self:needToThrowArmor(target) then
				benefit = false
			end
		end
	end
	if self:isPartner(target) then 
		return benefit 
	end
	return not benefit
end
sgs.ai_skill_choice["kuangfu_equip"] = function(self, choices, data)
	local who = data:toPlayer()
	if self:isFriend(who) then
		if choices:match("1") then
			if self:needToThrowArmor(who) then 
				return "1" 
			elseif self:evaluateArmor(who:getArmor(), who) < -5 then 
				return "1" 
			end
		end
		if self:hasSkills(sgs.lose_equip_skill, who) then
			if self:isWeak(who) then
				if choices:match("0") then 
					return "0" 
				elseif choices:match("3") then 
					return "3" 
				end
			end
		end
	else
		local dangerous = self:getDangerousCard(who)
		if dangerous then
			local card = sgs.Sanguosha:getCard(dangerous)
			if card:isKindOf("Weapon") then
				if choices:match("0") then 
					return "0"
				end
			elseif card:isKindOf("Armor") then
				if choices:match("1") then 
					return "1"
				end
			elseif card:isKindOf("DefensiveHorse") then
				if choices:match("2") then 
					return "2"
				end
			elseif card:isKindOf("OffensiveHorse") then
				if choices:match("3") then 
					return "3"
				end
			end
		end
		if choices:match("1") then
			if who:hasArmorEffect("EightDiagram") then
				if not self:needToThrowArmor(who) then 
					return "1" 
				end
			end
		end
		if self:hasSkills("jijiu|beige|mingce|weimu|qingcheng", who) then
			if not self:doNotDiscard(who, "e", false, 1, reason) then
				if choices:match("2") then 
					return "2" 
				elseif choices:match("1") then
					if who:getArmor() then
						if not self:needToThrowArmor(who) then 
							return "1" 
						end
					end
				elseif choices:match("3") then
					if not who:hasSkill("jijiu") then
						return "3" 
					elseif who:getOffensiveHorse():isRed() then 
						return "3" 
					end
				elseif choices:match("0") then
					if not who:hasSkill("jijiu") then
						return "0" 
					elseif who:getWeapon():isRed() then 
						return "0" 
					end
				end
			end
		end
		local valuable = self:getValuableCard(who)
		if valuable then
			local card = sgs.Sanguosha:getCard(valuable)
			if card:isKindOf("Weapon") then
				if choices:match("0") then 
					return "0"
				end
			elseif card:isKindOf("Armor") then
				if choices:match("1") then 
					return "1"
				end
			elseif card:isKindOf("DefensiveHorse") then
				if choices:match("2") then 
					return "2"
				end
			elseif card:isKindOf("OffensiveHorse") then
				if choices:match("3") then 
					return "3"
				end
			end
		end
		if not self:doNotDiscard(who, "e") then
			if choices:match("3") then 
				return "3" 
			elseif choices:match("1") then 
				return "1" 
			elseif choices:match("2") then 
				return "2" 
			elseif choices:match("0") then 
				return "0" 
			end
		end
	end
end
sgs.ai_skill_choice["kuangfu"] = function(self, choices)
	return "move"
end
--[[****************************************************************
	武将：国战·邹氏（群）
]]--****************************************************************
sgs.ai_chaofeng.zoushi = 3
--[[
	技能：祸水（锁定技）
	描述：你的回合内，体力值不少于体力上限一半的其他角色所有武将技能无效。 
]]--
--[[
	技能：倾城
	描述：出牌阶段，你可以弃置一张装备牌，令一名其他角色的一项武将技能无效，直到其下回合开始。 
]]--
--[[
	内容：“倾城技能卡”的卡牌成分
]]--
sgs.card_constituent["QingchengCard"] = {
	use_value = 2,
	use_priority = 7.2,
}
--[[
	内容：“倾城技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["QingchengCard"] = 0
--[[
	内容：注册“倾城技能卡”
]]--
sgs.RegistCard("QingchengCard")
--[[
	内容：“倾城”技能信息
]]--
sgs.ai_skills["qingcheng"] = {
	name = "qingcheng",
	dummyCard = function(self)
		local card_str = "@QingchengCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local cards = self.player:getCards("he")
		for _,equip in sgs.qlist(cards) do
			if equip:isKindOf("EquipCard") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“倾城技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["QingchengCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	if self.room:alivePlayerCount() == 2 then
		local others = self.room:getOtherPlayers(self.player)
		local only_enemy = others:first()
		if only_enemy:getLostHp() < 3 then 
			return 
		end
	end
	local equip_card = nil
	if self:needToThrowArmor() then
		equip_card = self.player:getArmor()
	else
		local cards = self.player:getCards("h")
		for _, c in sgs.qlist(handcards) do
			if c:isKindOf("EquipCard") then
				equip_card = c
				break
			end
		end
		if not equip_card then
			cards = self.player:getCards("he")
			for _, c in sgs.qlist(cards) do
				if c:isKindOf("EquipCard") then
					if not c:isKindOf("Armor") then
						if not c:isKindOf("DefensiveHorse") then
							equip_card = c
							break
						end
					end
				end
			end
		end
	end
	if equip_card then
		local target = nil
		for _,enemy in ipairs(self.opponents) do
			if self:getPartnerNumBySeat(self.player, enemy) > 1 then
				if enemy:getHp() < 1 then
					if enemy:hasSkill("buqu", true) then
						if enemy:getMark("Qingchengbuqu") == 0 then
							target = enemy
							break
						end
					end
				end
				if self:isWeak(enemy) then
					local skills = sgs.exclusive_skill .. "|" .. sgs.save_skill
					skills = skills:split("|")
					for _, skill in ipairs(skills) do
						if enemy:hasSkill(skill, true) then
							if enemy:getMark("Qingcheng" .. askill) == 0 then
								target = enemy
								break
							end
						end
					end
					if target then 
						break 
					end
				end
				local skills = ("noswuyan|weimu|wuyan|guixin|fenyong|liuli|yiji|jieming|neoganglie|fankui|" ..
				"fangzhu|enyuan|nosenyuan|ganglie|langgu|qingguo|luoying|guzheng|jianxiong|longdan|" ..
				"xiangle|huangen|tianming|yizhong|bazhen|jijiu|beige|longhun|gushou|buyi|" ..
				"mingzhe|danlao|qianxun|jiang|yanzheng|juxiang|huoshou|anxian|zhichi|feiying|" ..
				"tianxiang|xiaoji|xuanfeng|nosxuanfeng|xiaoguo|guhuo|guidao|guicai|nosshangshi|lianying|" ..
				"sijian|mingshi|yicong|zhiyu|lirang|xingshang|shushen|shangshi|leiji|wusheng|" ..
				"wushuang|tuntian|quanji|kongcheng|jieyuan|jilve|wuhun|kuangbao|tongxin|shenjun|" ..
				"ytchengxiang|sizhan|toudu|xiliang|tanlan|shien"):split("|")
				for _, skill in ipairs(skills) do
					if enemy:hasSkill(skill, true) then
						if enemy:getMark("Qingcheng" .. skill) == 0 then
							target = enemy
							break
						end
					end
				end
				if target then 
					break 
				end
			end
		end
		if not target then
			for _, friend in ipairs(self.partners_noself) do
				if friend:hasSkill("shiyong", true) then
					if friend:getMark("Qingchengshiyong") == 0 then
						target = friend
						break
					end
				end
			end
		end
		if target then
			local card_str = "@QingchengCard=" .. equip_card:getEffectiveId()
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
sgs.ai_skill_choice["qingcheng"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isPartner(target) then
		if target:hasSkill("shiyong", true) then
			if target:getMark("Qingchengshiyong") == 0 then 
				return "shiyong" 
			end
		end
	end
	if target:getHp() < 1 then
		if target:hasSkill("buqu", true) then
			if target:getMark("Qingchengbuqu") == 0 then 
				return "buqu" 
			end
		end
	end
	if self:isWeak(target) then
		local skills = sgs.exclusive_skill .. "|" .. sgs.save_skill
		skills = skills:split("|")
		for _, skill in ipairs(skills) do
			if target:hasSkill(skill, true) then
				if target:getMark("Qingcheng" .. skill) == 0 then
					return skill
				end
			end
		end
	end
	local skills = ("noswuyan|weimu|wuyan|guixin|fenyong|liuli|yiji|jieming|neoganglie|fankui|" ..
				"fangzhu|enyuan|nosenyuan|ganglie|langgu|qingguo|luoying|guzheng|jianxiong|longdan|" ..
				"xiangle|huangen|tianming|yizhong|bazhen|jijiu|beige|longhun|gushou|buyi|" ..
				"mingzhe|danlao|qianxun|jiang|yanzheng|juxiang|huoshou|anxian|zhichi|feiying|" ..
				"tianxiang|xiaoji|xuanfeng|nosxuanfeng|xiaoguo|guhuo|guidao|guicai|nosshangshi|lianying|" ..
				"sijian|mingshi|yicong|zhiyu|lirang|xingshang|shushen|shangshi|leiji|wusheng|" ..
				"wushuang|tuntian|quanji|kongcheng|jieyuan|jilve|wuhun|kuangbao|tongxin|shenjun|" ..
				"ytchengxiang|sizhan|toudu|xiliang|tanlan|shien"):split("|")
	for _, skill in ipairs(skills) do
		if target:hasSkill(skill, true) then
			if target:getMark("Qingcheng" .. skill) == 0 then
				return skill
			end
		end
	end
end
sgs.ai_choicemade_filter.skillChoice["qingcheng"] = function(player, promptlist)
	local choice = promptlist[#promptlist]
	local target = nil
	local others = self.room:getOtherPlayers(player)
	for _, p in sgs.qlist(others) do
		if p:hasSkill(choice, true) then
			target = p
			break
		end
	end
	if target then
		if choice == "shiyong" then 
			sgs.updateIntention(player, target, -10) 
		else 
			sgs.updateIntention(player, target, 10) 
		end
	end
end
--[[
	套路：仅使用“倾城技能卡”
]]--
sgs.ai_series["QingchengCardOnly"] = {
	name = "QingchengCardOnly",
	IQ = 2,
	value = 3,
	priority = 2,
	skills = "qingcheng",
	cards = {
		["QingchengCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local qingcheng_skill = sgs.ai_skills["qingcheng"]
		local dummyCard = qingcheng_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["QingchengCard"], "QingchengCardOnly")