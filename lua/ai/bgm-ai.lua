--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）☆SP扩展包部分
]]--
sgs.YanxiaoCard = sgs.Sanguosha:cloneCard("YanxiaoCard", sgs.Card_NoSuit, 0)
--[[****************************************************************
	武将：☆SP·赵云（群）
]]--****************************************************************
--[[
	技能：龙胆
	描述：你可以将一张【杀】当【闪】使用或打出，或将一张【闪】当【杀】使用或打出。 
]]--
--[[
	技能：冲阵
	描述：每当你发动“龙胆”使用一张手牌指定目标后，或打出一张手牌时，你可以获得对方的一张手牌。
]]--
sgs.ai_skill_invoke["chongzhen"] = function(self, data)
	local target = data:toPlayer()
	if self:isPartner(target) then
		if self.player:hasSkill("manjuan") then
			if self.player:getPhase() == sgs.Player_NotActive then 
				return false 
			end
		end
		if not self:hasLoseHandcardEffective(target) then 
			return true 
		end
		if self:needKongcheng(target) then
			if target:getHandcardNum() == 1 then 
				return true 
			end
		end
		if self:getOverflow(target) > 2 then 
			return true 
		end
		return false
	else
		if target:hasSkill("kongcheng") then
			if target:getHandcardNum() == 1 then
				return false
			end
		end
		return true
	end
end
sgs.slash_prohibit_system["chongzhen"] = {
	name = "chongzhen",
	reason = "chongzhen+longdan",
	judge_func = function(self, target, source, slash)
		--友方角色
		if self:isPartner(target) then 
			return false 
		end
		--铁骑
		if source:hasSkill("tieji") then 
			return false
		end
		--烈弓
		if self:canLiegong(target, source) then
			return false
		end
		--龙胆
		if target:getHandcardNum() >= 3 then
			if source:getHandcardNum() > 1 then 
				return true 
			end
		end
		return false	
	end
}
--[[****************************************************************
	武将：☆SP·貂蝉（群）
]]--****************************************************************
--[[
	技能：离魂
	描述：出牌阶段限一次，你可以弃置一张牌将武将牌翻面，然后获得一名男性角色的所有手牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值） 
]]--
--[[
	内容：“离魂技能卡”的卡牌成分
]]--
sgs.card_constituent["LihunCard"] = {
	use_value = 8.5,
	use_priority = 6,
}
--[[
	内容：“离魂技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["LihunCard"] = 80
--[[
	内容：注册“离魂技能卡”
]]--
sgs.RegistCard("LihunCard")
--[[
	内容：“离魂”技能信息
]]--
sgs.ai_skills["lihun"] = {
	name = "lihun",
	dummyCard = function(self)
		local card_str = "@LihunCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:isNude() then
			return false
		elseif self.player:hasUsed("LihunCard") then
			return false
		end
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:isMale() then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“离魂技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["LihunCard"] = function(self, card, use)
	if not self.player:hasUsed("LihunCard") then
		local targets = {}
		for _,enemy in ipairs(self.opponents) do
			if enemy:isMale() then
				if not enemy:isKongcheng() then
					table.insert(targets, enemy)
				end
			end
		end
		if #targets > 0 then
			local cards = self.player:getHandcards()
			cards = sgs.QList2Table(cards)
			self:sort(targets, "handcard")
			targets = sgs.reverse(targets)
			local target = nil
			for _,enemy in ipairs(targets) do
				local num = enemy:getHandcardNum()
				local hp = enemy:getHp()
				if num - hp >= 2 then
					target = enemy
					break
				end
			end
			if not target then
				if not self.player:faceUp() then
					for _,enemy in ipairs(targets) do
						local num = enemy:getHandcardNum()
						local hp = enemy:getHp()
						if num - hp >= -1 then
							target = enemy
							break
						end
					end
				end
			end
			if not target then
				local hasCrossbow = false
				if self:isEquip("Crossbow") then
					hasCrossbow = true
				elseif self:getCardsNum("Crossbow") > 0 then
					hasCrossbow = true
				end
				if hasCrossbow then
					local skills = "fenyong|zhichi|fankui|neoganglie|ganglie|enyuan|nosenyuan|langgu|guixin|kongcheng"
					local slashCount = self:getCardsNum("Slash")
					for _,enemy in ipairs(targets) do
						if self:slashIsEffective(sgs.slash, enemy) then
							if self.player:distanceTo(enemy) == 1 then
								if not self:hasSkills(skills, enemy) then
									local knownCount = sgs.getKnownCard(enemy, "Slash")
									if slashCount + knownCard >= 3 then
										target = enemy
										break
									end
								end
							end
						end
					end
				end
			end
			if target then
				use.card = card
				if use.to then 
					use.to:append(target) 
				end
				return 
			end
		end
	end
end
sgs.ai_skill_discard["lihun"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card_ids = {}
	for _,card in ipairs(cards) do
		table.insert(card_ids, card:getEffectiveId())
	end
	local temp = table.copyFrom(card_ids)
	for i = 1, #temp, 1 do
		local card = sgs.Sanguosha:getCard(temp[i])
		if card:isKindOf("SilverLion") then
			if self.player:hasArmorEffect("SilverLion") then
				if self.player:isWounded() then
					table.insert(to_discard, temp[i])
					table.removeOne(card_ids, temp[i])
					if #to_discard == discard_num then
						return to_discard
					end
				end
			end
		end
	end
	temp = table.copyFrom(card_ids)
	for i = 1, #card_ids, 1 do
		local card = sgs.Sanguosha:getCard(card_ids[i])
		table.insert(to_discard, card_ids[i])
		if #to_discard == discard_num then
			return to_discard
		end
	end
	if #to_discard < discard_num then 
		return {} 
	end
end
--[[
	套路：仅使用“离魂技能卡”
]]--
sgs.ai_series["LihunCardOnly"] = {
	name = "LihunCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "lihun",
	cards = {
		["LihunCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lihun_skill = sgs.ai_skills["lihun"]
		local dummyCard = lihun_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LihunCard"], "LihunCardOnly")
--[[
	技能：闭月
	描述：结束阶段开始时，你可以摸一张牌。 
]]--
--[[****************************************************************
	武将：☆SP·曹仁（魏）
]]--****************************************************************
--[[
	技能：溃围
	描述：结束阶段开始时，你可以摸X+2张牌，然后将你的武将牌翻面，且你的下个摸牌阶段开始时，你弃置X张牌。（X为当前场上武器牌的数量） 
]]--
sgs.ai_skill_invoke["kuiwei"] = function(self, data)
	local DiaoChan = self.room:findPlayerBySkillName("lihun")
	if DiaoChan then
		if DiaoChan:faceUp() then
			if not self:willSkipPlayPhase(DiaoChan) then
				if self:isOpponent(DiaoChan) then
					return false
				elseif sgs.turncount <= 1 then
					if sgs.getCamp(DiaoChan) == "unknown" then
						return false
					end
				end
			end
		end
	end
	if self.player:faceUp() then
		for _, friend in ipairs(self.partners_noself) do
			if friend:hasSkills("fangzhu|jilve") then 
				return true 
			end
			if friend:hasSkill("junxing") then
				if friend:faceUp() then
					if not self:willSkipPlayPhase(friend) then
						if not friend:isKongcheng() then
							return true
						elseif not self:willSkipDrawPhase(friend) then
							return true
						end
					end
				end
			end
		end
		local weaponCount = 0
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:getWeapon() then 
				weaponCount = weaponCount + 1 
			end
		end
		if weaponCount > 1 then 
			return true 
		end
		return self:isWeak()
	else
		return true
	end
end
sgs.draw_cards_system["kuiwei"] = {
	name = "kuiwei",
	correct_func = function(self, player)
		local count = 0
		if player:getMark("@kuiwei") > 0 then
			local alives = self.room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				if p:getWeapon() then
					count = count - 1
				end
			end
		end
		return count
	end,
}
--[[
	技能：严整
	描述：若你的手牌数大于你的体力值，你可以将一张装备区的装备牌当【无懈可击】使用。 
]]--
sgs.ai_view_as["yanzheng"] = function(card, player, place, class_name)
	if place == sgs.Player_PlaceEquip then
		if player:getHandcardNum() > player:getHp() then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			return ("nullification:yanzheng[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
--[[
	内容：“严整”统计信息
]]--
sgs.card_count_system["yanzheng"] = {
	name = "yanzheng",
	pattern = "Nullification",
	ratio = 1,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("yanzheng") then
			local count = data["count"]
			local equips = player:getCards("e")
			count = count + equips:length()
			return count
		end
	end
}
--[[****************************************************************
	武将：☆SP·庞统（群）
]]--****************************************************************
sgs.ai_chaofeng.bgm_pangtong = 10
--[[
	技能：漫卷
	描述：每当你将获得一张手牌时，你将之置入弃牌堆。若你的回合内你发动“漫卷”，你可以获得弃牌堆中一张与该牌同点数的牌（不能发动“漫卷”）。 
]]--
sgs.ai_skill_invoke["manjuan"] = true
sgs.ai_skill_askforag["manjuan"] = function(self, card_ids)
	local cards = {}
	for _,card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, card)
	end
	for _,card in ipairs(cards) do
		if card:isKindOf("ExNihilo") then 
			return card:getEffectiveId() 
		elseif card:isKindOf("IronChain") then 
			return card:getEffectiveId() 
		end
	end
	local need_snatch = false
	if #self.opponents > 0 then
		self:sort(self.opponents, "defense")
		local enemy = self.opponents[1]
		if sgs.getDefense(enemy) >= 8 then 
			self:sort(self.opponents, "threat") 
		end
		need_snatch = true
	end
	for _,card in ipairs(cards) do
		if card:isKindOf("Snatch") then
			if need_snatch then
				local enemies = self:exclude(self.opponents, card)
				for _,enemy in ipairs(enemies) do
					if self:trickIsEffective(card, enemy) then
						return card:getEffectiveId()
					end
				end
			end
		end
	end
	local need_peach = false
	if self.player:isWounded() then
		local peachCount = self:getCardsNum("Peach")
		local lost = self.player:getLostHp() 
		if peachCount < lost then
			need_peach = true
		end
	end
	for _,card in ipairs(cards) do
		if card:isKindOf("Peach") then
			if need_peach then
				return card:getEffectiveId() 
			end
		end
	end
	for _,card in ipairs(cards) do
		if card:isKindOf("AOE") then
			if self:getAoeValue(card) > 0 then 
				return card:getEffectiveId() 
			end
		end
	end
	self:sortByCardNeed(cards)
	local index = #cards
	local card = cards[index]
	return card:getEffectiveId()
end
sgs.amazing_grace_invalid_system["manjuan"] = {
	name = "manjuan",
	reason = "manjuan",
	judge_func = function(self, card, target, source)
		if target:hasSkill("manjuan") then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end
}
--[[
	技能：醉乡（限定技）
	描述：准备阶段开始时，你可以将牌堆顶的三张牌置于你的武将牌上。此后每个准备阶段开始时，你重复此流程，直到你的武将牌上出现同点数的“醉乡牌”，然后你获得所有“醉乡牌”（不能发动“漫卷”）。你不能使用或打出“醉乡牌”中存在的类别的牌，且这些类别的牌对你无效。 
]]--
sgs.ai_skill_invoke["zuixiang"] = true
sgs.trick_invalid_system["zuixiang"] = {
	name = "zuixiang",
	reason = "zuixiang",
	judge_func = function(card, target, source)
		local dreams = target:getPile("dream")
		if dreams:length() > 0 then
			if target:isLocked(card) then
				return true
			end
		end
		return false
	end,
}
sgs.slash_invalid_system["zuixiang"] = {
	name = "zuixiang",
	reason = "zuixiang",
	judge_func = function(slash, target, source, ignore_armor)
		if target:hasSkill("zuixiang") then
			if target:isLocked(slash) then
				return true
			end
		end
		return false
	end,
}
--[[****************************************************************
	武将：☆SP·张飞（蜀）
]]--****************************************************************
--[[
	技能：嫉恶（锁定技）
	描述：你使用红色【杀】对目标角色造成伤害时，此伤害+1。 
]]--
--[[
	内容：“嫉恶”卡牌需求
]]--
sgs.card_need_system["jie"] = function(self, card, player)
	if card:isRed() then
		return sgs.isCard("Slash", card, player)
	end
	return false
end
sgs.heavy_slash_system["jie"] = {
	name = "jie",
	reason = "jie",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if slash then
			if slash:isRed() then
				if source:hasSkill("jie") then
					return 1
				end
			end
		end
		return 0
	end,
}
--[[
	技能：大喝
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你可以将该角色的拼点牌交给一名体力值不多于你的角色，本回合该角色使用的非♥【闪】无效；若你没赢，你展示所有手牌，然后弃置一张手牌。 
]]--
--[[
	内容：“大喝技能卡”的卡牌成分
]]--
sgs.card_constituent["DaheCard"] = {
	control = 2,
	use_value = 8.5,
	use_priority = 8,
}
--[[
	内容：“大喝技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["DaheCard"] = 60
--[[
	内容：注册“大喝技能卡”
]]--
sgs.RegistCard("DaheCard")
--[[
	内容：“大喝”技能信息
]]--
sgs.ai_skills["dahe"] = {
	name = "dahe",
	dummyCard = function(self)
		return sgs.Card_Parse("@DaheCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("DaheCard") then
			if not self.player:isKongcheng() then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“大喝技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DaheCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	self:sort(self.opponents, "handcard")
	local my_max_card = self:getMaxPointCard(self.player)
	local my_max_point = my_max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if my_max_card:isKindOf("Slash") then 
		slashcount = slashcount - 1 
	end
	if self.player:hasSkill("kongcheng") then
		if self.player:getHandcardNum() == 1 then
			for _, enemy in ipairs(self.opponents) do
				if not enemy:isKongcheng() then
					self.dahe_card = my_max_card:getId()
					use.card = card
					if use.to then 
						use.to:append(enemy) 
					end
					return
				end
			end
		end
	end
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = {
			isDummy = true,
		}
		self:useBasicCard(slash, dummy_use)
		for _, enemy in ipairs(self.opponents) do
			local flag = true
			if enemy:hasSkill("kongcheng") then
				if enemy:getHandcardNum() == 1 then
					if enemy:getHp() > self.player:getHp() then
						flag = false
					end
				end
			end
			if flag then 
				if not enemy:isKongcheng() then
					if self.player:canSlash(enemy, nil, true) then
						local max_card = self:getMaxPointCard(enemy)
						local allknown = 0
						if self:getKnownNum(enemy) == enemy:getHandcardNum() then
							allknown = allknown + 1
						end
						local can_use = false
						if max_card then
							local max_point = max_card:getNumber()
							if my_max_point > max_point then
								if allknown > 0 then
									can_use = true
								end
							end
							if not can_use then
								if my_max_point > max_point then
									if allknown < 1 then
										if my_max_point > 10 then
											can_use = true
										end
									end
								end
							end
						else
							if my_max_point > 10 then
								can_use = true
							end
						end
						if can_use then
							self.dahe_card = my_max_card:getId()
							use.card = card
							if use.to then 
								use.to:append(enemy) 
							end
							return
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_pindian["dahe"] = function(self, requestor, maxcard, mincard)
	if self:isPartner(requestor) then 
		return mincard:getId() 
	end
	local max_card = self:getMaxPointCard(self.player)
	if max_card then
		return max_card:getId()
	end
	return maxcard:getId()
end
sgs.ai_skill_playerchosen["dahe"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,target in ipairs(targets) do
		if target:hasSkill("kongcheng") then
			if target:isKongcheng() then
				if target:hasFlag("dahe") then 
					return target 
				end
			end
		end 
	end
	for _,target in ipairs(targets) do
		if self:isPartner(target) then
			if not self:needKongcheng(target, true) then 
				return target 
			end
		end
	end
	return nil
end
--[[
	内容：“大喝”卡牌需求
]]--
sgs.card_need_system["dahe"] = sgs.card_need_system["bignumber"]
--[[
	套路：仅使用“大喝技能卡”
]]--
sgs.ai_series["DaheCardOnly"] = {
	name = "DaheCardOnly",
	IQ = 2,
	value = 3,
	priority = 4,
	skills = "dahe",
	cards = {
		["DaheCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local dahe_skill = sgs.ai_skills["dahe"]
		local dummyCard = dahe_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DaheCard"], "DaheCardOnly")
--[[****************************************************************
	武将：☆SP·吕蒙（吴）
]]--****************************************************************
--[[
	技能：探虎
	描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，你拥有以下锁定技：你无视与该角色的距离，你使用的非延时类锦囊牌对该角色结算时不能被【无懈可击】响应，直到回合结束。 
]]--
--[[
	内容：“探虎技能卡”的卡牌成分
]]--
sgs.card_constituent["TanhuCard"] = {
	control = 2,
	use_priority = 8,
}
--[[
	内容：“探虎技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TanhuCard"] = 30
--[[
	内容：注册“探虎技能卡”
]]--
sgs.RegistCard("TanhuCard")
--[[
	内容：“探虎”技能信息
]]--
sgs.ai_skills["tanhu"] = {
	name = "tanhu",
	dummyCard = function(self)
		return sgs.Card_Parse("@TanhuCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("TanhuCard") then
			if #handcards > 0 then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“探虎技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["TanhuCard"] = function(self, card, use)
	if #self.opponents > 0 then
		local my_max_card = self:getMaxPointCard()
		local my_max_point = my_max_card:getNumber()
		local slashCount = self:getCardsNum("Slash")
		if my_max_card:isKindOf("Slash") then 
			slashCount = slashCount - 1 
		end
		self:sort(self.opponents, "defense")
		local target = self.opponents[1]
		if not target:isKongcheng() then
			if slashCount > 0 then
				if self.player:canSlash(target, nil, false) then
					if not target:hasSkill("kongcheng") or target:getHandcardNum() > 1 then
						self.tanhu_card = my_max_card:getEffectiveId()
						use.card = card
						if use.to then 
							use.to:append(target) 
						end
						return
					end
				end
			end
		end
		for _, enemy in ipairs(self.opponents) do
			if not enemy:isKongcheng() then
				if self:getCardsNum("Snatch") > 0 then
					local max_card = self:getMaxPointCard(enemy)
					local allknown = 0
					if self:getKnownNum(enemy) == enemy:getHandcardNum() then
						allknown = allknown + 1
					end
					local flag = false
					if max_card then
						if my_max_point < max_card:getNumber() then
							if allknown > 0 then
								flag = true
							elseif allknown < 1 then
								if my_max_point > 10 then
									flag = true
								end
							end
						end
					else
						if my_max_point > 10 then
							flag = true
						end
					end
					if flag then
						flag = false
						if self:getDangerousCard(enemy) then
							flag = true
						elseif self:getValuableCard(enemy) then
							flag = true
						end
						if flag then
							self.tanhu_card = my_max_card:getEffectiveId()
							use.card = card
							if use.to then 
								use.to:append(enemy) 
							end
							return
						end
					end
				end
			end
		end
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		self:sortByUseValue(cards, true)
		local usecard = cards[1]
		if sgs.getUseValue(usecard, self.player) >= 6 then
			return 
		elseif sgs.getKeepValue(usecard, self.player) >= 6 then
			return 
		end
		if self:getOverflow() > 0 then
			if not target:isKongcheng() then
				self.tanhu_card = my_max_card:getEffectiveId()
				use.card = card
				if use.to then 
					use.to:append(target) 
				end
				return
			end
			for _, enemy in ipairs(self.opponents) do
				if not enemy:isKongcheng() then
					if not enemy:hasSkills("tuntian+zaoxian") then
						if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() > 1 then
							self.tanhu_card = use_card:getId()
							use.card = card
							if use.to then 
								use.to:append(enemy) 
							end
							return
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_pindian["tanhu"] = function(self, requestor, maxcard, mincard)
	if requestor:getHandcardNum() == 1 then
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		self:sortByKeepValue(cards)
		return cards[1]
	end
end
--[[
	内容：“探虎”卡牌需求
]]--
sgs.card_need_system["tanhu"] = sgs.card_need_system["bignumber"]
--[[
	套路：仅使用“探虎技能卡”
]]--
sgs.ai_series["TanhuCardOnly"] = {
	name = "TanhuCardOnly",
	IQ = 2,
	value = 3.5,
	priority = 4,
	skills = "tanhu",
	cards = {
		["TanhuCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local tanhu_skill = sgs.ai_skills["tanhu"]
		local dummyCard = tanhu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["TanhuCard"], "TanhuCardOnly")
--[[
	技能：谋断
	描述：游戏开始时，你获得一枚“文/武”标记（“武”朝上）。若你的手牌数小于或等于2，你的标记为“文”朝上。其他角色的回合开始时，若“文”朝上，你可以弃置一张牌将标记翻至“武”朝上。若“武”朝上，你视为拥有技能“谦逊”和“激昂”；若“文”朝上，你视为拥有技能“英姿”和“克己”。 
]]--
sgs.ai_skill_cardask["@mouduan"] = function(self, data)
	local function needMouduan(self)
		local num = self.player:getHandcardNum()
		if num > 3 then
			local current = self.room:getCurrent()
			if current:objectName() == self.player:objectName() then
				if self:getCardsNum("Slash") >= 3 then
					if self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0 then
						if not self:willSkipPlayPhase() or self.player:hasSkill("dangxian") then
							for _, enemy in ipairs(self.opponents) do
								if self:willUseSlash(enemy, self.player, sgs.slash) then
									if self:slashIsEffective(slash, enemy) then
										if sgs.isGoodTarget(self, enemy, self.opponents) then
											return true
										end
									end
								end
							end
						end
					end
				end
			elseif #self.opponents > 1 then
				if num == 4 or num == 5 then
					return true
				end
			end
		end
		return false
	end
	if needMouduan(self) then
		local to_discard = self:askForDiscard("mouduan", 1, 1, false, true)
		if #to_discard > 0 then 
			return "$" .. to_discard[1] 
		end
	end
	return "."
end
--[[****************************************************************
	武将：☆SP·刘备（蜀）
]]--****************************************************************
--[[
	技能：昭烈
	描述：摸牌阶段，你可以少摸一张牌，令你攻击范围内的一名其他角色展示牌堆顶的三张牌，将其中的非基本牌和【桃】置入弃牌堆，然后选择一项：1.令你对其造成X点伤害，然后该角色获得其余的牌；2.该角色弃置X张牌，然后你获得其余的牌。（X为其中非基本牌的数量） 
]]--
--[[
	功能：判断是否昭烈弃牌
	参数：nobasic（number类型，表示非基本牌的数目）
	结果：boolean类型，表示是否弃牌
]]--
function SmartAI:willZhaolieDiscard(nobasic)
	local LiuBei = self.room:getCurrent()
	if LiuBei and LiuBei:isAlive() then
		if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, LiuBei) then
			local damageCount = nobasic
			if nobasic > 0 then
				if not LiuBei:hasSkill("jueqing") then
					if self.player:hasSkill("tianxiang") then
						local damage_str = {
							damage = damageCount,
							nature = sgs.DamageStruct_Normal,
						}
						local callback = sgs.ai_skill_use["@@tianxiang"]
						local willTianxiang = callback(self, damage_str, sgs.Card_MethodDiscard)
						if willTianxiang ~= "." then
							damageCount = 0
						end
					end
					if damageCount > 0 then
						if self.player:hasSkill("mingshi") then
							if LiuBei:getEquips():length() <= self.player:getEquips():length() then
								damageCount = damageCount - 1
							end
						end
					end
					if damageCount > 1 then
						if self.player:hasArmorEffect("SilverLion") then
							damageCount = 1
						end
					end
				end
			end
			if self.player:hasSkill("wuhun") then
				if not LiuBei:hasSkill("jueqing") then
					if self:amRebel() then
						local mark = 0
						local liubei_mark = 0
						if self:mayLord(LiuBei) then
							liubei_mark = LiuBei:getMark("@nightmare")
						end
						local others = self.room:getOtherPlayers(LiuBei)
						for _,p in sgs.qlist(others) do
							local p_mark = p:getMark("@nightmare")
							if p_mark > mark then
								mark = p_mark
							end
						end
						if mark == 0 then
							if self:mayLord(LiuBei) then
								return false
							end
						end
						if mark < damageCount + liubei_mark then
							return false
						end
					end
				end
			end
			if self.player:hasSkill("manjuan") then
				if self:isPartner(LiuBei) then 
					return true
				else
					if damageCount > 0 then
						local hp = self.player:getHp()
						local besthp = sgs.getBestHp(self.player)
						if hp - damageCount < besthp then
							return true
						end
					end
					return false
				end
			end
			if damageCount == 0 then
				return false
			end
			if damageCount < 2 then
				if self.player:getHp() > 1 then
					return false
				end
			end
			return true
		end
		return false
	end
	return true
end
sgs.ai_skill_playerchosen["zhaolie"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _,target in ipairs(targets) do
		if self:isOpponent(target) then
			if self:damageIsEffective(target) then
				if sgs.isGoodTarget(self, target, targets) then
					return target
				end
			end
		end
	end
	return nil
end
sgs.ai_skill_discard.zhaolie = function(self, discard_num, min_num, optional, include_equip)
	if self:willZhaolieDiscard(discard_num) then
		local to_discard = {}
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		local index = 0
		self:sortByKeepValue(cards, true)
		for i=#cards, 1, -1 do
			local card = cards[i]
			if not self.player:isJilei(card) then
				table.insert(to_discard, card:getEffectiveId())
				table.remove(cards, i)
				index = index + 1
				if index == discard_num then 
					break 
				end
			end
		end
		if #to_discard >= min_num then 
			return to_discard 
		end
	end
	return {}
end
sgs.ai_skill_invoke["zhaolie_obtain"] = function(self, data)
	return self:willZhaolieDiscard(0)
end
sgs.draw_cards_system["zhaolie"] = {
	name = "zhaolie",
	correct_func = function(self, player)
		return -1
	end,
}
--[[
	技能：誓仇（主公技，限定技）
	描述：准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数） 
]]--
--[[
	功能：判断是否应发动誓仇
	参数：无
	结果：boolean类型，表示是否应发动
]]--
function SmartAI:willInvokeShichou()
	local GuanYu = self.room:findPlayerBySkillName("wuhun")
	if GuanYu then
		if GuanYu:getKingdom() == "shu" then
			return true
		end
	end
	if self:amRebel() then
		local lord = self.room:getLord()
		if lord:getKingdom() == "shu" then
			return true
		end
	end
	local first_round = self.player:hasFlag("Global_FirstRound")
	local others = self.room:getOtherPlayers(self.player)
	local shu_count = 0
	local enemy_count = 0
	for _,p in sgs.qlist(others) do
		if p:getKingdom() == "shu" then
			shu_count = shu_count + 1
			if self:isEnemy(p) then
				enemy_count = enemy_count + 1
			end
		end
	end
	if shu_count > 0 then
		if shu_count == 1 then
			return true
		elseif enemy_count > 0 then
			return true
		end
		if first_round then
			if shu_count > 1 then
				if not self:isWeak() then
					return false
				end
			end
		end
		if self:isWeak() then
			return true
		end
	end
	return false
end
--[[
	功能：获取誓仇目标
	参数：targets（sgs.QList<ServerPlayer*>类型，表示备选名单）
	结果：ServerPlayer类型，表示誓仇目标
]]--
function SmartAI:getShichouTarget(targets)
	if self:amRebel() then
		local lord = self.room:getLord()
		if lord and lord:getKingdom() == "shu" then
			return lord
		end
	end
	for _,target in sgs.qlist(targets) do
		if target:hasSkill("wuhun") then
			return target
		end
	end
	local players = sgs.QList2Table(targets) 
	self:sort(players, "hp")
	players = sgs.reverse(players)
	for _,target in ipairs(players) do
		if self:isEnemy(target) then
			return target
		end
	end
	for _,target in ipairs(players) do
		if self:hasSkills("zaiqi|enyuan|nosenyuan|kuanggu", target) then
			if target:getHp() >= 2 then
				return target
			end
		end
	end
	return players[1]
end
--[[
	内容：“誓仇技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShichouCard"] = function(self, card, source, targets)
	if source:hasSkill("weidi") then
		local target = targets[1]
		if self:mayLord(target) then
			sgs.updateIntention(source, target, 80)
		end
	end
end
sgs.ai_skill_use["@@shichou"] = function(self, prompt)
	if self:willInvokeShichou() then
		local to_discard = self:askForDiscard("shichou", 2, 2, false, true)
		if #to_discard == 2 then
			local shu_generals = sgs.SPlayerList()
			local others = self.room:getOtherPlayers(self.player)
			for _, p in sgs.qlist(others) do
				if p:getKingdom() == "shu" then 
					shu_generals:append(p) 
				end
			end
			if shu_generals:length() > 0 then
				local target = self:getShichouTarget(shu_generals)
				if target then
					return ("@ShichouCard=%d+%d->%s"):format(to_discard[1], to_discard[2], target:objectName())
				end
			end
		end
	end
	return "."
end
sgs.ai_damage_requirement["shichou"] = function(self, source, target)
	if target:hasLordSkill("shichou") then
		local victim
		local others = self.room:getOtherPlayers(target)
		for _, p in sgs.qlist(others) do
			if p:getMark("hate_" .. target:objectName()) > 0 then
				if p:getMark("@hate_to") > 0 then
					victim = p
					break
				end
			end
		end
		if victim ~= nil then
			if victim:isAlive() then
				local need_damage = false
				if self:mayLord(target) then
					if self:mayRebel(victim) then
						need_damage = true
					end
				elseif self:mayLoyalist(target) then
					if self:mayRebel(victim) then
						need_damage = true
					end
				elseif self:mayRenegade(target) then
					need_damage = true
				elseif self:mayRebel(target) then
					if not self:mayRebel(victim) then
						need_damage = true
					end
				end
				if need_damage then
					if victim:hasSkill("wuhun") then
						return 2
					end
				end
			end
			return 1
		end
	end
	return false
end
--[[****************************************************************
	武将：☆SP·大乔（吴）
]]--****************************************************************
--[[
	技能：言笑
	描述：出牌阶段，你可以将一张♦牌置于一名角色的判定区内，称为“言笑牌”。判定区内有“言笑牌”的角色的判定阶段开始时获得其判定区内所有牌。 
]]--
--[[
	内容：“言笑牌”的卡牌成分
]]--
sgs.card_constituent["YanxiaoCard"] = {
	use_priority = 3.9,
}
--[[
	内容：“言笑牌”的卡牌仇恨值
]]--
sgs.ai_card_intention["YanxiaoCard"] = -80
--[[
	内容：注册“言笑牌”
]]--
sgs.RegistCard("YanxiaoCard")
--[[
	功能：使用“言笑牌”
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardYanxiaoCard(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["YanxiaoCard"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	local others = self.room:getOtherPlayers(self.player)
	self:sort(self.partners_noself, "defense")
	for _, friend in ipairs(self.partners_noself) do
		if not friend:containsTrick("YanxiaoCard") then
			local judges = friend:getJudgingArea()
			local yanxiao = false
			if friend:containsTrick("indulgence") then
				yanxiao = true
			elseif friend:containsTrick("supply_shortage") then
				yanxiao = true
			elseif friend:containsTrick("lighting") then
				if self:getFinalRetrial(player) == 2 then
					yanxiao = true
				end
			end
			if yanxiao then
				use.card = card
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
	end
	if self:getOverflow() > 0 then
		if not self.player:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then
				use.to:append(self.player)
			end
			return
		end
		local lord = self:getMyLord()
		if lord and not lord:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then
				use.to:append(lord)
			end
			return
		end
		for _, friend in ipairs(self.partners_noself) do
			local judges = friend:getJudgingArea()
			if not friend:containsTrick("YanxiaoCard") then
				use.card = card
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
	end
end
--[[
	内容：“言笑”技能信息
]]--
sgs.ai_skills["yanxiao"] = {
	name = "yanxiao",
	dummyCard = function(self)
		local suit = sgs.YanxiaoCard:getSuitString()
		local number = sgs.YanxiaoCard:getNumberString()
		local card_id = sgs.YanxiaoCard:getEffectiveId()
		local card_str = ("YanxiaoCard:yanxiao[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local cards = self.player:getCards("he")
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Diamond then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“言笑牌”的具体产生方式
]]--
sgs.ai_view_as_func["YanxiaoCard"] = function(self, card)
	local cards = self.player:getCards("he")
	local diamonds = {}
	for _,diamond in sgs.qlist(cards) do
		if diamond:getSuit() == sgs.Card_Diamond then
			table.insert(diamonds, diamond)
		end
	end
	if #diamonds > 0 then
		self:sortByUseValue(diamonds, true)
		local diamond = diamonds[1]
		local suit = diamond:getSuitString()
		local number = diamond:getNumberString()
		local card_id = diamond:getEffectiveId()
		local card_str = ("YanxiaoCard:yanxiao[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end
end
sgs.yanxiao_suit_value = {
	diamond = 3.9
}
--[[
	内容：“言笑”卡牌需求
]]--
sgs.card_need_system["yanxiao"] = function(self, card, player)
	return card:getSuit() == sgs.Card_Diamond
end
--[[
	套路：仅使用“言笑牌”
]]--
sgs.ai_series["YanxiaoCardOnly"] = {
	name = "YanxiaoCardOnly",
	IQ = 2,
	value = 3,
	priority = 2,
	skills = "yanxiao",
	cards = {
		["YanxiaoCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local yanxiao_skill = sgs.ai_skills["yanxiao"]
		local yanxiao_card = yanxiao_skill["dummyCard"](self)
		yanxiao_card:setFlags("isDummy")
		return {yanxiao_card}
	end,
}
table.insert(sgs.ai_card_actions["YanxiaoCard"], "YanxiaoCardOnly")
--[[
	技能：安娴
	描述：每当你使用【杀】对目标角色造成伤害时，你可以防止此伤害，令该角色弃置一张手牌，然后你摸一张牌。每当你被指定为【杀】的目标时，你可以弃置一张手牌，然后此【杀】的使用者摸一张牌，此【杀】对你无效。 
]]--
sgs.ai_skill_invoke["anxian"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isPartner(target) then
		if not self:invokeDamagedEffect(target, self.player) then
			if not self:needToLoseHp(target, self.player, nil, true) then 
				return true 
			end
		end
	end
	if self:hasHeavySlashDamage(self.player, damage.card, damage.to) then 
		return false 
	end
	if self:isOpponent(target) then
		if self:invokeDamagedEffect(target, self.player) then
			if not self:doNotDiscard(target, "h") then 
				return true 
			end
		end
	end
	return false
end
sgs.ai_skill_cardask["@anxian-discard"] = function(self, data)
	if self.player:isKongcheng() then 
		return "." 
	end
	local use = data:toCardUse()
	local source = use.from
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:hasHeavySlashDamage(source, use.card, self.player) then
		--if self:canHit(self.player, source, true) then
			return "$" .. cards[1]:getEffectiveId()
		--end
	end	
	if self:invokeDamagedEffect(self.player, use.from, true) then
		return "."
	end
	if self:needToLoseHp(self.player, use.from, true) then
		return "."
	end
	if self:isPartner(self.player, use.from) then 
		return "$" .. cards[1]:getEffectiveId() 
	end
	if self:needToLoseHp(self.player, use.from, true, true) then
		return "."
	end
	--if self:canHit(self.player, use.from) then
		for _, card in ipairs(cards) do
			if not sgs.isCard("Peach", card, self.player) then
				return "$" .. card:getEffectiveId()
			end
		end
	--end
	if self:getCardsNum("Jink") > 0 then
		return "."
	end
	if #cards == self:getCardsNum("Peach") then 
		return "." 
	end
	for _, card in ipairs(cards) do
		if not sgs.isCard("Peach", card, self.player) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end
--[[****************************************************************
	武将：☆SP·甘宁（群）
]]--****************************************************************
--[[
	技能：银铃
	描述：出牌阶段，若“锦”的数量少于四张，你可以弃置一张黑色牌，将一名其他角色的一张牌置于你的武将牌上，称为“锦”。 
]]--
--[[
	内容：“银铃技能卡”的卡牌成分
]]--
sgs.card_constituent["YinlingCard"] = {
	use_value = sgs.card_constituent["Dismantlement"]["use_value"] + 1,
	use_priority = sgs.card_constituent["Dismantlement"]["use_priority"] + 1,
}
--[[
	内容：“银铃技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["YinlingCard"] = 0
--[[
	内容：注册“银铃技能卡”
]]--
sgs.RegistCard("YinlingCard")
--[[
	内容：“银铃”技能信息
]]--
sgs.ai_skills["yinling"] = {
	name = "yinling",
	dummyCard = function(self)
		local card_str = "@YinlingCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local brocades = self.player:getPile("brocade")
		if brocades:length() < 4 then
			local cards = self.player:getCards("he")
			for _,black in sgs.qlist(cards) do
				if black:isBlack() then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“银铃技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["YinlingCard"] = function(self, card, use)
	local cards = self.player:getCards("he")
	local blacks = {}
	for _,black in sgs.qlist(cards) do
		if black:isBlack() then
			table.insert(blacks, black)
		end
	end
	if #blacks > 0 then
		self:sortByUseValue(blacks, true)
		local black_card
		local has_weapon = false
		for _,weapon in ipairs(blacks)  do
			if weapon:isKindOf("Weapon") then 
				has_weapon = true 
			end
		end
		local value = sgs.getCardValue("YinlingCard", "use_value")
		local overflow = ( self:getOverflow() > 0 )
		for _,black in ipairs(blacks) do
			local can_use = false
			local name = sgs.getCardName(black)
			local use_value = sgs.getCardValue(name, "use_value")
			if overflow then
				can_use = true
			else
				if use_value < value then
					can_use = true
				end
			end
			if can_use then
				if black:isKindOf("Armor") then
					if not self.player:getArmor() then
						can_use = false
					elseif self:hasEquip(black) then
						can_use = false
						if black:isKindOf("SilverLion") then
							if self.player:isWounded() then
								can_use = true
							end
						end
					end
				end
			end
			if can_use then
				if black:isKindOf("Weapon") then
					if not self.player:getWeapon() then 
						can_use = false
					elseif self:hasEquip(black) then
						if not has_weapon then 
							can_use = false
						end
					end
				end
			end
			if can_use then
				if black:isKindOf("Slash") then
					local dummy_use = {
						isDummy = true,
					}
					if self:getCardsNum("Slash") == 1 then
						self:useBasicCard(black, dummy_use)
						if dummy_use.card then 
							can_use = false 
						end
					end
				end
			end
			if can_use then
				if use_value > value then
					if black:isKindOf("TrickCard") then
						local dummy_use = {
							isDummy = true,
						}
						self:useTrickCard(black, dummy_use)
						if dummy_use.card then 
							can_use = false 
						end
					end
				end
			end
			if can_use then
				black_card = black
				break
			end
		end
		if black_card then
			local card_id = black_card:getEffectiveId()
			local card_str = "@YinlingCard=" .. card_id
			local acard = sgs.Card_Parse(card_str)
			self:useDisturbCard(acard, use)
		end
	end
end
sgs.yinling_suit_value = {
	spade = 3.9,
	club = 3.9
}
--[[
	套路：仅使用“银铃技能卡”
]]--
sgs.ai_series["YinlingCardOnly"] = {
	name = "YinlingCardOnly",
	IQ = 2,
	value = 4,
	priority = 3,
	skills = "yinling",
	cards = {
		["YinlingCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local yinling_skill = sgs.ai_skills["yinling"]
		local dummyCard = yinling_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["YinlingCard"], "YinlingCardOnly")
--[[
	技能：军威
	描述：结束阶段开始时，你可以将三张“锦”置入弃牌堆并选择一名角色，令该角色选择一项：1.展示一张【闪】并将该【闪】交给由你选择的一名角色；2.失去1点体力，然后你将其装备区的一张牌移出游戏，该角色的下个回合结束后，将这张装备牌移回其装备区。 
]]--
sgs.ai_playerchosen_intention["junwei"] = 80
sgs.ai_playerchosen_intention["junweigive"] = -80
sgs.ai_skill_invoke["junwei"] = function(self, data)
	for _, enemy in ipairs(self.opponents) do
		if not enemy:hasEquip() then
			return true
		elseif not self:doNotDiscard(enemy, "e") then
			return true
		end
	end
	return false
end
sgs.ai_skill_playerchosen["junwei"] = function(self, targets)
	local tos = {}
	for _,target in sgs.qlist(targets) do
		if self:isOpponent(target) then
			if not target:hasEquip() then
				table.insert(tos, target)
			elseif not self:doNotDiscard(target, "e") then
				table.insert(tos, target)
			end
		end
	end 
	if #tos > 0 then
		self:sort(tos, "defense")
		return tos[1]
	end
end
sgs.ai_skill_playerchosen["junweigive"] = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isPartner(target) then
			if not target:hasSkill("manjuan") then
				if not self:needKongcheng(target, true) then
					table.insert(tos, target)
				end
			end
		end
	end 
	if #tos > 0 then
		for _, to in ipairs(tos) do
			if to:hasSkill("leiji") then 
				return to 
			end
		end
		self:sort(tos, "defense")
		return tos[1]
	end
end
sgs.ai_skill_cardask["@junwei-show"] = function(self, data)
	if self.player:hasArmorEffect("SilverLion") then
		if self.player:getEquips():length() == 1 then 
			return "." 
		end
	end
	local ganning = data:toPlayer()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("Jink") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end
--[[****************************************************************
	武将：☆SP·夏侯惇（魏）
]]--****************************************************************
--[[
	技能：愤勇
	描述：每当你受到伤害后，你可以竖置你的体力牌。每当你受到伤害时，若你的体力牌处于竖置状态，你防止此伤害。 
]]--
sgs.ai_skill_invoke["fenyong"] = function(self, data)
	self.fenyong_choice = nil
	if sgs.turncount <= 1 then
		if #self.opponents == 0 then 
			return false
		end
	end
	local current = self.room:getCurrent()
	if current and current:getPhase() < sgs.Player_Finish then
		if self:isPartner(current) then
			self:sort(self.opponents, "defenseSlash")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, nil, false) then
					local defense = sgs.getDefenseSlash(enemy)
					if defense < 5 then
						local isEffective = false
						if self:slashIsEffective(sgs.slash, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								isEffective = true
							end
						end
						if isEffective then
							if self:willUseSlash(enemy, nil, sgs.slash) then
								return true
							end
						end
					end
				end
				if self.player:getLostHp() == 1 then
					if self:needToThrowArmor(current) then 
						return true 
					end
				end
			end
			return false
		end
	end
	return true
end
local fenyong_damage_invalid = {
	reason = "fenyong",
	judge_func = function(target, nature, source, notThunder)
		if target:getMark("@fenyong") > 0 then
			return target:hasSkill("fenyong") 
		end
		return false
	end
}
table.insert(sgs.damage_invalid_system, fenyong_damage_invalid) --添加到伤害无效判定表
sgs.slash_prohibit_system["fenyong"] = {
	name = "fenyong",
	reason = "fenyong",
	judge_func = function(self, target, source, slash)
		--绝情
		if source:hasSkill("jueqing") then
			return false
		end
		--原版解烦
		if source:hasFlag("nosjiefanUsed") then
			return false
		end
		--原版潜袭
		if source:hasSkill("nosqianxi") then
			if source:distanceTo(target) == 1 then
				return false
			end
		end
		--愤勇
		if target:getMark("@fenyong") > 0 then
			if target:hasSkill("fenyong") then
				return true
			end
		end
		return false
	end
}
sgs.ai_damage_requirement["fenyong"] = function(self, source, target)
	if target:hasSkill("fenyong") then
		if target:hasSkill("xuehen") then
			for _,enemy in ipairs(self.opponents) do
				local defense = sgs.getDefense(enemy)
				if defense < 6 then
					local effective = false
					if self:slashIsEffective(enemy, nil, sgs.slash) then
						if sgs.isGoodTarget(self, enemy, self.opponents) then
							effective = true
						end
					end
					if effective then
						if not self:slashIsProhibited(enemy, target, sgs.slash) then
							if self.player:canSlash(enemy, nil, false) then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end
--[[
	技能：雪恨
	描述：一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之，然后选择一项：1.弃置当前回合角色X张牌。 2.视为你使用一张无距离限制的【杀】。（X为你已损失的体力值） 
]]--
sgs.ai_skill_choice["xuehen"] = function(self, choices)
	if self.fenyong_choice then 
		return self.fenyong_choice 
	end
	local current = self.room:getCurrent()
	local lost = self.player:getLostHp()
	if self:isOpponent(current) then
		if lost >= 3 then
			if current:getCardCount(true) >= 3 then
				if not (self:needKongcheng(current) and current:getCards("e"):length() < 3) then
					if not (self:hasSkills(sgs.lose_equip_skill, current) and current:getHandcardNum() < lost) then
						return "discard"
					end
				end
			end
		end
		if lost >= 2 then
			if self:hasSkills("jijiu|tuntian+zaoxian|beige", current) then
				if current:getCardCount(true) >= 2 then 
					return "discard" 
				end
			end
		end
	end
	self:sort(self.opponents, "defenseSlash")
	for _, enemy in ipairs(self.opponents) do
		if self.player:canSlash(enemy, nil, false) then
			local defense = sgs.getDefense(enemy)
			if defense < 6 then
				local isEffective = false
				if self:slashIsEffective(sgs.slash, enemy) then
					if sgs.isGoodTarget(self, enemy, self.opponents) then
						isEffective = true
					end
				end
				if isEffective then
					if self:willUseSlash(enemy, nil, sgs.slash) then
						self.xuehentarget = enemy
						return "slash"
					end
				end
			end
		end
	end
	if self:isOpponent(current) then
		for _, enemy in ipairs(self.opponent) do
			if self.player:canSlash(enemy, nil, false) then
				if self:willUseSlash(enemy, nil, sgs.slash) then
					if self:hasHeavySlashDamage(self.player, slash, enemy) then
						self.xuehentarget = enemy
						return "slash"
					end
				end
			end
		end
		if lost <= 2 then 
			local armor = current:getArmor()
			if armor then
				if self:evaluateArmor(armor, current) >= 3 then
					if not self:doNotDiscard(current, "e") then
						return "discard" 
					end
				end
			end
		end
	end
	if self:isPartner(current) then
		if lost == 1 then
			if self:needToThrowArmor(current) then 
				return "discard" 
			end
		end
		for _, enemy in ipairs(self.opponents) do
			if self.player:canSlash(enemy, nil, false) then
				if self:willUseSlash(enemy, nil, sgs.slash) then
					self.xuehentarget = enemy
					return "slash"
				end
			end
		end
	end
	return "discard"
end
sgs.ai_skill_playerchosen["xuehen"] = function(self, targets)
	local to = self.xuehentarget
	if to then 
		self.xuehentarget = nil 
		return to 
	end
	to = sgs.ai_skill_playerchosen["zero_card_as_slash"](self, targets)
	return to or targets[1]
end
--[[****************************************************************
	武将：桌游志·司马昭（魏）
]]--****************************************************************
--[[
	技能：昭心
	描述：摸牌阶段结束时，你可以展示所有手牌，视为你使用一张【杀】。 
]]--
--[[
	内容：“昭心技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ZhaoxinCard"] = 80
sgs.ai_skill_use["@@zhaoxin"] = function(self, prompt)
	local target
	self:sort(self.opponents, "defenseSlash")
	for _,enemy in ipairs(self.opponents) do
		local isEffective = false
		if self:slashIsEffective(sgs.slash, enemy) then
			if sgs.isGoodTarget(self, enemy, self.opponents) then
				isEffective = true
			end
		end
		if isEffective then
			if self.player:canSlash(enemy) then
				if not self:slashIsProhibited(enemy, self.player, sgs.slash) then
					local card_str = "@ZhaoxinCard=.->" .. enemy:objectName()
					return card_str
				end
			end
		end
	end
	return "."
end
--[[
	技能：狼顾
	描述：每当你受到1点伤害后，你可以进行一次判定且你可以打出一张手牌代替此判定牌，然后你观看伤害来源的所有手牌，弃置其中任意数量的与判定牌花色相同的牌。 
]]--
sgs.ai_skill_invoke["langgu"] = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	if source then
		return not self:isPartner(source)
	end
	return false
end
sgs.ai_skill_askforag["langgu"] = function(self, card_ids)
	return -1 --Just For Test
end
sgs.ai_skill_cardask["@langgu-card"] = function(self, data)
	local judge = data:toJudge()
	local tag = self.room:getTag("CurrentDamageStruct")
	local damage = tag:toDamage()
	local source = damage.from
	local needRetrial = false
	if source and source:isAlive() then
		if not source:isKongcheng() then
			if source:hasSkill("hongyan") then
				local diamond_num = sgs.getKnownCard(source, "diamond", false)
				local club_num = sgs.getKnownCard(source, "club", false)
				local num = source:getHandcardNum()
				if diamond_num + club_num < num then
					needRetrial = true
				end
			end
		end
	end
	if needRetrial then
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then
				if not sgs.isCard("Peach", card, self.player) then
					return "$" .. card:getId()
				end
			end
		end
		if judge.card:getSuit() == sgs.Card_Spade then
			self:sortByKeepValue(cards)
			for _, card in ipairs(cards) do
				if not card:getSuit() == sgs.Card_Spade then
					if not sgs.isCard("Peach", card, self.player) then
						return "$" .. card:getId()
					end
				end
			end
		end
	end
	return "."
end
sgs.ai_choicemade_filter.skillInvoke["langgu"] = function(player, promptlist, self)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and promptlist[3] == "yes" then
		sgs.updateIntention(player, damage.from, 10)
	end
end
--[[****************************************************************
	武将：桌游志·王元姬（魏）
]]--****************************************************************
--[[
	技能：扶乱
	描述：出牌阶段限一次，若你未于本阶段使用过【杀】，你可以弃置三张相同花色的牌，令你攻击范围内的一名其他角色将武将牌翻面，然后你不能使用【杀】直到回合结束。 
]]--
--[[
	功能：判断一名角色是否可以被选为扶乱的目标
	参数：who（ServerPlayer类型，表示目标角色）
		card（Card类型，表示将使用的扶乱技能卡）
	结果：boolean类型，表示是否可以被选择
]]--
function SmartAI:isFuluanTarget(who, card)
	local subcards = card:getSubcards()
	local weapon = self.player:getWeapon()
	local horse = self.player:getOffensiveHorse()
	local range = self.player:getAttackRange()
	if weapon then
		local id = weapon:getId()
		if subcards:contains(id) then
			local distance_fix = sgs.weapon_range[weapon:getClassName()] - 1
			if horse then
				if subcards:contains(horse:getId()) then
					distance_fix = distance_fix + 1
				end
			end
			local distance = self.player:distanceTo(who, distance_fix)
			return distance <= range
		end
	end
	if horse then
		local id = horse:getId()
		if subcards:contains(id) then
			local distance = self.player:distanceTo(who, 1)
			return distance <= range
		end
	end
	return self.player:inMyAttackRange(who)
end
--[[
	内容：“扶乱技能卡”的卡牌成分
]]--
sgs.card_constituent["FuluanCard"] = {
	use_priority = 2.3,
}
--[[
	内容：“扶乱技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["FuluanCard"] = function(self, card, source, targets)
	local target = targets[1]
	if target:faceUp() then
		sgs.updateIntention(source, target, 80)
	else
		sgs.updateIntention(source, target, -80)
	end
end
--[[
	内容：注册“扶乱技能卡”
]]--
sgs.RegistCard("FuluanCard")
--[[
	内容：“扶乱”技能信息
]]--
sgs.ai_skills["fuluan"] = {
	name = "fuluan",
	dummyCard = function(self)
		local card_srt = "@FuluanCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("FuluanCard") then
			return false
		elseif self.player:hasFlag("ForbidFuluan") then 
			return false
		end
		return true
	end,
}
sgs.ai_skill_use_func["FuluanCard"] = function(self, card, use)
	local cards = self.player:getCards("he")
	local acard = nil
	if cards:length() >= 3 then
		local spades = {}
		local hearts = {}
		local clubs = {}
		local diamonds = {}
		for _,c in sgs.qlist(cards) do
			if not sgs.isCard("Peach", c, self.player) then
				if not sgs.isCard("ExNihilo", c, self.player) then
					local suit = c:getSuit()
					if suit == sgs.Card_Spade then
						table.insert(spades, c)
					elseif suit == sgs.Card_Heart then
						table.insert(hearts, c)
					elseif suit == sgs.Card_Club then
						table.insert(clubs, c)
					elseif suit == sgs.Card_Diamond then
						table.insert(diamonds, c)
					end
				end
			end
		end
		local to_use = {}
		if #spades >= 3 then
			self:sortByUseValue(spades, true)
			for i=1, 3, 1 do
				table.insert(to_use, spades[i])
			end
		elseif #clubs >= 3 then
			self:sortByUseValue(clubs, true)
			for i=1, 3, 1 do
				table.insert(to_use, clubs[i])
			end
		elseif #diamonds >= 3 then
			self:sortByUseValue(diamonds, true)
			for i=1, 3, 1 do
				table.insert(to_use, diamonds[i])
			end
		elseif #hearts >= 3 then
			self:sortByUseValue(hearts, true)
			for i=1, 3, 1 do
				table.insert(to_use, hearts[i])
			end
		end
		if #to_use == 3 then
			local card_str = "@FuluanCard="..table.concat(to_use, "+")
			acard = sgs.Card_Parse(card_str)
		end
	end
	if acard then
		self:sort(self.partners_noself)
		for _, friend in ipairs(self.partners_noself) do
			if not self:toTurnOver(friend, 0) then
				if self:isFuluanTarget(friend, acard) then
					use.card = acard
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
		self:sort(self.opponents, "defense")
		for _, enemy in ipairs(self.opponents) do
			if self:toTurnOver(enemy, 0) then
				if self:isFuluanTarget(enemy, acard) then
					use.card = acard
					if use.to then 
						use.to:append(enemy) 
					end
					return
				end
			end
		end
	end
end
--[[
	套路：仅使用“扶乱技能卡”
]]--
sgs.ai_series["FuluanCardOnly"] = {
	name = "FuluanCardOnly",
	IQ = 2,
	value = 2,
	priority = 3,
	skills = "fuluan",
	cards = {
		["FuluanCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local fuluan_skill = sgs.ai_skills["fuluan"]
		local dummyCard = fuluan_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["FuluanCard"], "FuluanCardOnly")
--[[
	技能：淑德
	描述：结束阶段开始时，你可以将手牌数补至等于体力上限的张数。 
]]--
--[[****************************************************************
	武将：桌游志·刘协（群）
]]--****************************************************************
sgs.ai_chaofeng.diy_liuxie = 3
--[[
	技能：皇恩
	描述：每当一张锦囊牌指定了至少两名目标时，你可以令至多X名角色各摸一张牌，然后该锦囊牌对这些角色无效。（X为你当前体力值） 
]]--
--[[
	功能：判断是否需要发动皇恩
	参数：who（ServerPlayer类型）
	结果：boolean类型，表示是否需要发动
]]--
function SmartAI:needHuangen(who)
	local tag = self.player:getTag("Huangen_user")
	local card_str = tag:toString()
	local card = sgs.Card_Parse(card_str)
	if card then
		local current = self.room:getCurrent()
		if self:isOpponent(who) then
			if card:isKindOf("GodSalvation") then
				if who:isWounded() then
					if self:trickIsEffective(card, who, current) then
						if who:hasSkill("manjuan") then
							if who:getPhase() == sgs.Player_NotActive then 
								return true 
							end
						end
						if self:isWeak(who) then 
							return true 
						end
						if self:hasSkills(sgs.masochism_skill, who) then 
							return true 
						end
					end
				end
			end
			return false
		elseif self:isPartner(who) then
			if self:hasSkills("noswuyan", who) then
				if current:objectName() ~= who:objectName() then 
					return true 
				end
			end
			if card:isKindOf("GodSalvation") then
				if who:isWounded() then
					if self:trickIsEffective(card, who, current) then
						if self:needToLoseHp(who, nil, nil, true, true) then
							if not self:needKongcheng(who, true) then 
								return true 
							end
						end
						return false
					end
				else
					if who:hasSkill("manjuan") then
						if who:getPhase() == sgs.Player_NotActive then 
							return false 
						end
					end
					if self:needKongcheng(who, true) then 
						return false 
					end
					return true
				end
			elseif card:isKindOf("IronChain") then
				if self:needKongcheng(who, true) then
					return false
				elseif who:isChained() then
					if self:trickIsEffective(card, who, current) then
						return false
					end
				end
			elseif card:isKindOf("AmazingGrace") then 
				return not self:trickIsEffective(card, who, current) 
			end
			return true
		end
	end
	return false
end
--[[
	内容：“皇恩技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HuangenCard"] = function(self, card, source, targets)
	local tag = source:getTag("Huangen_user")
	local card_str = tag:toString()
	local cardx = sgs.Card_Parse(card_str)
	if cardx then
		for _, to in ipairs(targets) do
			local intention = -80
			if cardx:isKindOf("GodSalvation") then
				if to:isWounded() then
					if not self:needToLoseHp(to, nil, nil, true, true) then 
						intention = 50 
					end
				end
			end
			if self:needKongcheng(to, true) then 
				intention = 0 
			end
			if cardx:isKindOf("AmazingGrace") then
				if self:trickIsEffective(cardx, to) then 
					intention = 0 
				end
			end
			sgs.updateIntention(source, to, intention)
		end
	end
end
sgs.ai_skill_use["@@huangen"] = function(self, prompt)
	local tag = self.player:getTag("Huangen_user")
	local card_str = tag:toString()
	local card = sgs.Card_Parse(card_str)
	local alives = self.room:getAlivePlayers()
	local targets = {}
	for _,p in sgs.qlist(alives) do
		if p:hasFlag("HuangenTarget") then
			if self:needHuangen(p) then
				table.insert(targets, p)
			end
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		local hp = self.player:getHp()
		if hp > 0 then
			local players = {}
			for index, target in ipairs(targets) do
				if index <= hp then
					table.insert(players, target:objectName())
				else
					break
				end
			end
			local card_str = "@HuangenCard=.->"..table.concat(players, "+")
			return card_str
		end
	end
	return "."
end
--[[
	技能：汉统
	描述：弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到当前回合结束。 
]]--
--[[
	内容：“汉统技能卡”的卡牌成分
]]--
sgs.card_constituent["HantongCard"] = {
	use_value = sgs.card_constituent["JijiangCard"]["use_value"],
	use_priority = sgs.card_constituent["JijiangCard"]["use_priority"],
}
--[[
	内容：“汉统技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HantongCard"] = sgs.ai_card_intention["JijiangCard"]
--[[
	内容：注册“汉统技能卡”
]]--
sgs.RegistCard("HantongCard")
--[[
	内容：“汉统”技能信息
]]--
sgs.ai_skills["hantong"] = {
	name = "hantong",
	dummyCard = function(self)
		return sgs.Card_Parse("@HantongCard=.")
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			return false
		end
		local edicts = self.player:getPile("edict")
		if edicts:isEmpty() then
			return false
		end
		return true
	end,
}
--[[
	内容：“汉统技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["HantongCard"] = function(self, card, use)
	if self.player:hasLordSkill("jijiang") then
		return 
	end
	local can_invoke = false
	for _, friend in ipairs(self.partners_noself) do
		if friend:getKingdom() == "shu" then
			if sgs.getCardsNum("Slash", friend) > 0 then 
				can_invoke = true 
				break
			end
		end
	end
	if can_invoke then
		local acard = sgs.Card_Parse("@JijiangCard=.")
		local dummy_use = { 
			isDummy = true, 
		}
		self:useSkillCard(acard, dummy_use)
		if dummy_use.card then 
			use.card = card 
		end
	end
end
sgs.ai_skill_invoke["hantong"] = true
sgs.ai_skill_invoke["hantong_acquire"] = function(self, data)
	local skill = data:toString()
	if skill == "hujia" then
		local can_invoke = false
		for _, friend in ipairs(self.partners_noself) do
			if friend:getKingdom() == "wei" then
				if sgs.getCardsNum("Jink", friend) > 0 then 
					can_invoke = true 
				end
			end
		end
		if can_invoke then
			self.player:setFlags("ai_hantong")
			local hujia = sgs.ai_skill_invoke.hujia(self, data)
			self.player:setFlags("-ai_hantong")
			return hujia
		end
	elseif skill == "jijiang" then
		if not self.player:hasSkill("jijiang") then
			local can_invoke = false
			for _, friend in ipairs(self.partners_noself) do
				if friend:getKingdom() == "shu" then
					if sgs.getCardsNum("Slash", friend) > 0 then 
						can_invoke = true 
					end
				end
			end
			if can_invoke then
				self.player:setFlags("ai_hantong")
				local jijiang = sgs.ai_skill_invoke["jijiang"](self, data)
				self.player:setFlags("-ai_hantong")
				return jijiang
			end
		end
	elseif skill == "jiuyuan" then
		if not self.player:hasSkill("jiuyuan") then
			return true
		end
	elseif skill == "xueyi" then
		if not self.player:hasSkill("xueyi") then
			local maxcards = self.player:getMaxCards()
			local can_invoke = false
			local others = self.room:getOtherPlayers(self.player)
			for _, player in sgs.qlist(others) do
				if player:getKingdom() == "qun" then 
					can_invoke = true 
				end
			end
			if can_invoke then 
				return self.player:getHandcardNum() > maxcards 
			end
		end
	end
	return false
end
sgs.ai_cardsview_valuable["hantong"] = function(self, class_name, player)
	if class_name == "Slash" then
		if not player:hasSkill("jijiang") then
			local edicts = player:getPile("edict")
			if edicts:length() > 0 then
				local result = sgs.ai_cardsview_valuable["jijiang"](self, class_name, player, false)
				if result then 
					return "@HantongCard=." 
				end
			end
		end
	end
end
--[[
	套路：仅使用“汉统技能卡”
]]--
sgs.ai_series["HantongCardOnly"] = {
	name = "HantongCardOnly",
	IQ = 2,
	value = 2,
	priority = 1.5,
	skills = "hantong",
	cards = {
		["HantongCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local hantong_skill = sgs.ai_skills["hantong"]
		local dummyCard = hantong_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["HantongCard"], "HantongCardOnly")
--[[****************************************************************
	武将：桌游志·公孙瓒（群）
]]--****************************************************************
--[[
	技能：义从
	描述：弃牌阶段结束时，你可以将任意数量的牌置于武将牌上，称为“扈”。其他角色与你的距离+X。（X为“扈”的数量） 
]]--
sgs.ai_skill_use["@@diyyicong"] = function(self, prompt)
	local armor = self.player:getArmor()
	if self:needToThrowArmor() then
		return "@DIYYicongCard=" .. armor:getId() .. "->."
	end
	local yicongcards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local horse = self.player:getDefensiveHorse()
	for _, card in ipairs(cards) do
		if sgs.getKeepValue(card, self.player) < 6 then
			local can_use = true
			if armor then
				if card:getId() == armor:getEffectiveId() then
					can_use = false
				end
			end
			if horse and can_use then
				if card:getId() == horse:getEffectiveId() then
					can_use = false
				end
			end
			if can_use then
				table.insert(yicongcards, card:getId())
				break
			end
		end
	end
	if #yicongcards > 0 then
		return "@DIYYicongCard=" .. table.concat(yicongcards, "+") .. "->."
	end
	return "."
end
--[[
	技能：突骑（锁定技）
	描述：准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量） 
]]--