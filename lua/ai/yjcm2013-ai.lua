--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）一将成名2013扩展包部分
]]--
--[[****************************************************************
	武将：三将成名·曹冲（魏）
]]--****************************************************************
--[[
	技能：称象
	描述：每当你受到一次伤害后，你可以展示牌堆顶的四张牌，然后获得其中任意数量点数之和小于13的牌，并将其余的牌置入弃牌堆。 
]]--
sgs.ai_skill_invoke["chengxiang"] = function(self, data)
	if self.player:hasSkill("manjuan") then
		if self.player:getPhase() == sgs.Player_NotActive then
			return false
		end
	end
	return true
end
sgs.ai_skill_askforag["chengxiang"] = function(self, card_ids)
	return self:askForAG(card_ids, false, "dummyreason")
end
--[[
	技能：仁心
	描述：一名其他角色处于濒死状态时，你可以将武将牌翻面并将所有手牌交给该角色，令该角色回复1点体力。 
]]--
--[[
	内容：“仁心技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["RenxinCard"] = sgs.ai_card_intention["Peach"]
sgs.ai_cardsview_valuable["renxin"] = function(self, class_name, player)
	if class_name == "Peach" then
		if not player:isKongcheng() then
			local dying = self.room:getCurrentDyingPlayer()
			if dying and dying:objectName() ~= player:objectName() then
				if not self:isOpponent(dying, player) then
					if dying:hasSkill("manjuan") then
						if dying:getPhase() == sgs.Player_NotActive then
							local peach_num = 0
							if not player:hasFlag("Global_PreventPeach") then
								local cards = player:getCards("he")
								for _, c in sgs.qlist(cards) do
									if sgs.isCard("Peach", c, player) then 
										peach_num = peach_num + 1 
									end
									if peach_num > 1 then 
										return 
									end
								end
							end
						end
					end
					if dying:getHp() < 0 then
						if self:playerGetRound(dying) < self:playerGetRound(self.player) then 
							return nil 
						end
					end
					if not player:faceUp() then
						if player:getHp() < 2 then
							if sgs.getCardsNum("Jink", player) > 0 then
								return 
							elseif sgs.getCardsNum("Analeptic", player) > 0 then 
								return 
							end
						end
						return "@RenxinCard=."
					else
						if not dying:hasFlag("Global_PreventPeach") then
							local handcards = player:getHandcards()
							for _, c in sgs.qlist(handcards) do
								if not sgs.isCard("Peach", c, player) then 
									return 
								end
							end
						end
						return "@RenxinCard=."
					end
				end
			end
		end
	end
end
sgs.ai_cardsview["renxin"] = function(self, class_name, player)
	if class_name == "Peach" then
		if not player:isKongcheng() then
			local dying = self.room:getCurrentDyingPlayer()
			if dying and dying:objectName() ~= player:objectName() then
				if not self:isOpponent(dying, player) then
					if player:getHp() < 2 then
						if sgs.getCardsNum("Jink", player) > 0 then
							return 
						elseif sgs.getCardsNum("Analeptic", player) > 0 then 
							return 
						end
					end
					if not self:isWeak(player) then 
						return "@RenxinCard=." 
					end
				end
			end
		end
	end
end
--[[****************************************************************
	武将：三将成名·伏皇后（群）
]]--****************************************************************
--[[
	技能：惴恐
	描述：一名其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，该角色跳过出牌阶段；若你没赢，该角色与你距离为1，直到回合结束。 
]]--
sgs.ai_skill_invoke["zhuikong"] = function(self, data)
	local count = 1
	if self:isWeak() then
		count = 3
	end
	if self.player:getHandcardNum() <= count then
		return false
	end
	local current = self.room:getCurrent()
	if current then
		if self:isPartner(current) then
			return false
		end
	else
		return false
	end
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	local can_use = true
	if current:hasSkill("zhiji") then
		if current:getMark("zhiji") == 0 then
			if current:getHandcardNum() == 1 then
				can_use = false
			end
		end
	end
	if can_use then
		local enemy_max_card = self:getMaxPointCard(current)
		local enemy_max_point = 100
		if enemy_max_card then
			enemy_max_point = enemy_max_card:getNumber() 
		end
		if my_max_point > enemy_max_point or my_max_point > 10 then
			self.zhuikong_card = my_max_card:getEffectiveId()
			return true
		end
	end
	if current:distanceTo(self.player) == 1 then
		if not self:isValuableCard(my_max_card) then
			self.zhuikong_card = my_max_card:getEffectiveId()
			return true
		end
	end
	return false
end
--[[
	技能：求援
	描述：每当你成为【杀】的目标时，你可以令一名除此【杀】使用者外的有手牌的其他角色正面朝上交给你一张手牌。若此牌不为【闪】，该角色也成为此【杀】的目标。 
]]--
sgs.ai_skill_playerchosen["qiuyuan"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
	local enemy
	for _, p in ipairs(targetlist) do
		if self:isOpponent(p) then
			local flag = false
			if p:getHandcardNum() ~= 1 then
				flag = true
			elseif not p:hasSkill("kongcheng") then
				if not p:hasSkill("zhiji") then
					flag = true
				elseif p:getMark("zhiji") > 0 then
					flag = true
				end
			end
			if flag then
				if p:hasSkills(sgs.cardneed_skill) then 
					return p
				elseif not enemy then
					if not self:canLiuli(p, self.friends_noself) then 
						enemy = p 
					end
				end
			end
		end
	end
	if enemy then 
		return enemy 
	end
	targetlist = sgs.reverse(targetlist)
	local friend
	for _, p in ipairs(targetlist) do
		if self:isPartner(p) then
			if p:hasSkill("kongcheng") then
				if p:getHandcardNum() == 1 then
					return p
				end
			end
			if p:getCardCount(true) >= 2 then
				if self:canLiuli(p, self.enemies) then 
					return p
				end
			end
			if not friend then
				if sgs.getCardsNum("Jink", p) >= 1 then 
					friend = p 
				end
			end
		end
	end
	return friend
end
sgs.ai_skill_cardask["@qiuyuan-give"] = function(self, data, pattern, target)
	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValue(handcards)
	for _,card in ipairs(handcards) do
		local id = card:getEffectiveId()
		local c = sgs.Sanguosha:getEngineCard(id)
		if c:isKindOf("Jink") then
			local flag = true
			if target then
				if target:isAlive() then
					if target:hasSkill("wushen") then
						local suit = c:getSuit()
						if suit == sgs.Card_Heart then
							flag = false
						elseif suit == sgs.Card_Spade then
							if target:hasSkill("hongyan") then
								flag = false
							end
						end
					end
				end
			end
			if flag then
				return "$" .. id
			end
		end
	end
	for _, card in ipairs(handcards) do
		if not self:isValuableCard(card) then
			if sgs.getKeepValue(card, self.player) < 5 then 
				return "$" .. card:getEffectiveId() 
			end
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end
sgs.slash_prohibit_system["qiuyuan"] = {
	name = "qiuyuan",
	reason = "qiuyuan",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target, source) then
			return false
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then
			return false
		end
		--求援
		local friends = self:getPartners(source, nil, true)
		for _,friend in ipairs(friends) do
			local flag = true
			if friend:isKongcheng() then
				flag = false
			elseif friend:getHandcardNum() == 1 then
				if friend:hasSkill("kongcheng") then
					flag = false
				elseif friend:hasSkill("zhiji") then
					if friend:getMark("zhiji") == 0 then
						flag = false
					end
				end
			end
			if flag then
				return true
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：三将成名·郭淮（魏）
]]--****************************************************************
--[[
	技能：精策
	描述：出牌阶段结束时，若你本回合已使用的牌数大于或等于你当前的体力值，你可以摸两张牌。 
]]--
sgs.ai_skill_invoke["jingce"] = function(self, data)
	return not self:needKongcheng(self.player, true)
end
--[[****************************************************************
	武将：三将成名·关平（蜀）
]]--****************************************************************
--[[
	技能：龙吟
	描述：每当一名角色于其出牌阶段内使用【杀】选择目标后，你可以弃置一张牌，令此【杀】不计入出牌阶段限制的使用次数，若此【杀】为红色，你摸一张牌。 
]]--
sgs.ai_skill_cardask["@longyin"] = function(self, data)
	local function getLeastValueCard(isRed)
		if self:needToThrowArmor() then 
			return "$" .. self.player:getArmor():getEffectiveId() 
		end
		local offhorse_avail, weapon_avail
		for _, enemy in ipairs(self.opponents) do
			if self:canAttack(enemy, self.player) then
				if not offhorse_avail then
					if self.player:getOffensiveHorse() then
						if self.player:distanceTo(enemy, 1) <= self.player:getAttackRange() then
							offhorse_avail = true
						end
					end
				end
				if not weapon_avail then
					if self.player:getWeapon() then
						if self.player:distanceTo(enemy) == 1 then
							weapon_avail = true
						end
					end
				end
			end
			if offhorse_avail and weapon_avail then 
				break 
			end
		end
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		if self.player:getPhase() > sgs.Player_Play then
			self:sortByKeepValue(cards)
			for _, c in ipairs(cards) do
				if sgs.getKeepValue(c, self.player) < 8 then
					if not self.player:isJilei(c) then
						if not self:isValuableCard(c) then 
							return "$" .. c:getEffectiveId() 
						end
					end
				end
			end
			if offhorse_avail then
				local horse = self.player:getOffensiveHorse()
				if not self.player:isJilei(horse) then 
					return "$" .. horse:getEffectiveId() 
				end
			end
			if weapon_avail then
				local weapon = self.player:getWeapon()
				if not self.player:isJilei(weapon) then
					if self:evaluateWeapon(weapon) < 5 then 
						return "$" .. weapon:getEffectiveId() 
					end
				end
			end
		else
			local slashc
			self:sortByUseValue(cards)
			for _, c in ipairs(cards) do
				if sgs.getUseValue(c, self.player) < 6 then
					if not self:isValuableCard(c) then
						if not self.player:isJilei(c) then
							if sgs.isCard("Slash", c, self.player) then
								if not slashc then 
									slashc = c 
								end
							else
								return "$" .. c:getEffectiveId()
							end
						end
					end
				end
			end
			if offhorse_avail then
				local horse = self.player:getOffensiveHorse()
				if not self.player:isJilei(horse) then 
					return "$" .. horse:getEffectiveId() 
				end
			end
			if isRed and slashc then 
				return "$" .. slashc:getEffectiveId() 
			end
		end
	end
	
	local use = data:toCardUse()
	local slash = use.card
	local source = use.from
	local slash_num = 0
	if source:objectName() == self.player:objectName() then 
		slash_num = self:getCardsNum("Slash") 
	else 
		slash_num = sgs.getCardsNum("Slash", source) 
	end
	if use.m_addHistory then
		if slash_num > 0 then 
			if self:isOpponent(source) then
				if not self:hasCrossbowEffect(source) then
					return "." 
				end
			end
		end
	end
	local can_use = false
	local isRed = slash:isRed()
	if isRed then
		can_use = true
		if self.player:hasSkill("manjuan") then
			if self.player:getPhase() == sgs.Player_NotActive then
				can_use = false
			end
		end
	end
	if not can_use then
		if use.m_addHistory then
			if use.m_reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				if self:isPartner(source) then
					if slash_num >= 1 then
						can_use = true
					end
				end
			end
		end
	end
	if can_use then
		local str = getLeastValueCard(isRed)
		if str then 
			return str 
		end
	end
	return "."
end
--[[****************************************************************
	武将：三将成名·简雍（蜀）
]]--****************************************************************
--[[
	技能：巧说
	描述：出牌阶段开始时，你可以与一名角色拼点：若你赢，本回合你使用的下一张基本牌或非延时类锦囊牌可以增加一个额外目标（无距离限制）或减少一个目标（若原有多余一个目标）；若你没赢，你不能使用锦囊牌，直到回合结束。 
]]--
--[[
	内容：“巧说技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["QiaoshuiCard"] = 0
sgs.ai_skill_use["@@qiaoshui"] = function(self, prompt)
	local trick_num = 0
	local handcards = self.player:getHandcards()
	for _, card in sgs.qlist(handcards) do
		if card:isNDTrick() then
			if not card:isKindOf("Nullification") then 
				trick_num = trick_num + 1 
			end
		end
	end
	self:sort(self.opponents, "handcard")
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	for _, enemy in ipairs(self.opponents) do
		if not enemy:isKongcheng() then
			if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() ~= 1 then
				local max_card = self:getMaxPointCard(enemy)
				local max_point = 100
				if max_card then
					max_point = max_card:getNumber()
				end
				if my_max_point > max_point then
					self.qiaoshui_card = my_max_card:getEffectiveId()
					return "@QiaoshuiCard=.->" .. enemy:objectName()
				end
			end
		end
	end
	for _, enemy in ipairs(self.opponents) do
		if not enemy:isKongcheng() then
			if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() ~= 1 then
				if my_max_point >= 10 then
					self.qiaoshui_card = my_max_card:getEffectiveId()
					return "@QiaoshuiCard=.->" .. enemy:objectName()
				end
			end
		end
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
				self.qiaoshui_card = my_max_card:getEffectiveId()
				return "@QiaoshuiCard=.->" .. friend:objectName()
			end
		end
	end
	local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
	if ZhuGeLiang then
		if self:isPartner(ZhuGeLiang) then
			if ZhuGeLiang:getHandcardNum() == 1 then
				if ZhuGeLiang:objectName() ~= self.player:objectName() then
					if my_max_point >= 7 then
						self.qiaoshui_card = my_max_card:getEffectiveId()
						return "@QiaoshuiCard=.->" .. ZhuGeLiang:objectName()
					end
				end
			end
		end
	end
	for index = #self.partners_noself, 1, -1 do
		local friend = self.partners_noself[index]
		if not friend:isKongcheng() then
			if my_max_point >= 7 then
				self.qiaoshui_card = my_max_card:getEffectiveId()
				return "@QiaoshuiCard=.->" .. friend:objectName()
			end
		end
	end
	local can_use = false
	if trick_num == 0 then
		can_use = true
	elseif trick_num <= 2 then
		if self.player:hasSkill("zongshih") then
			if not self:isValuableCard(my_max_card) then
				can_use = true
			end
		end
	end
	if can_use then
		for _, enemy in ipairs(self.opponents) do
			if not enemy:isKongcheng() then
				if self:hasLoseHandcardEffective(enemy) then
					if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() ~= 1 then
						self.qiaoshui_card = my_max_card:getEffectiveId()
						return "@QiaoshuiCard=.->" .. enemy:objectName()
					end
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_choice["qiaoshui"] = function(self, choices, data)
	local use = data:toCardUse()
	local card = use.card
	if card:isKindOf("Collateral") then
		local dummy_use = { 
			isDummy = true, 
			to = sgs.SPlayerList(), 
			current_targets = {}, 
		}
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardCollateral(card, dummy_use)
		if dummy_use.card and dummy_use.to:length() == 2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			self.qiaoshui_collateral = { 
				first, 
				second, 
			}
			return "add"
		else
			self.qiaoshui_collateral = nil
		end
	elseif card:isKindOf("Analeptic") then
	elseif card:isKindOf("Peach") then
		self:sort(self.partners_noself, "hp")
		for _, friend in ipairs(self.partners_noself) do
			if friend:isWounded() then
				if friend:getHp() < sgs.getBestHp(friend) then
					self.qiaoshui_extra_target = friend
					return "add"
				end
			end
		end
	elseif card:isKindOf("ExNihilo") then
		local friend = self:findPlayerToDraw(false, 2)
		if friend then
			self.qiaoshui_extra_target = friend
			return "add"
		end
	elseif card:isKindOf("GodSalvation") then
		self:sort(self.opponents, "hp")
		for _, enemy in ipairs(self.opponents) do
			if enemy:isWounded() then
				if self:trickIsEffective(card, enemy, self.player) then
					self.qiaoshui_remove_target = enemy
					return "remove"
				end
			end
		end
	elseif card:isKindOf("AmazingGrace") then
		self:sort(self.opponents)
		for _, enemy in ipairs(self.opponents) do
			if self:trickIsEffective(card, enemy, self.player) then
				if not enemy:hasSkill("manjuan") or enemy:getPhase() ~= sgs.Player_NotActive then
					if not self:needKongcheng(enemy, true) then
						self.qiaoshui_remove_target = enemy
						return "remove"
					end
				end
			end
		end
	elseif card:isKindOf("AOE") then
		local lord = self:getMyLord()
		if lord then
			if lord:objectName() ~= self.player:objectName() then
				if self:isWeak(lord) then
					self.qiaoshui_remove_target = lord
					return "remove"
				end
			end
		end
		self:sort(self.partners_noself)
		for _, friend in ipairs(self.partners_noself) do
			if self:trickIsEffective(card, friend, self.player) then
				self.qiaoshui_remove_target = friend
				return "remove"
			end
		end
	elseif sgs.isKindOf("Snatch|Dismantlement", card) then
		local trick = sgs.cloneCard(card)
		trick:setSkillName("qiaoshui")
		local dummy_use = { 
			isDummy = true, 
			to = sgs.SPlayerList(), 
			current_targets = {}, 
		}
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useDisturbCard(trick, dummy_use)
		if dummy_use.card then
			if dummy_use.to:length() > 0 then
				self.qiaoshui_extra_target = dummy_use.to:first()
				return "add"
			end
		end
	elseif card:isKindOf("Slash") then
		local slash = sgs.cloneCard(card)
		slash:setSkillName("qiaoshui")
		local dummy_use = { 
			isDummy = true, 
			to = sgs.SPlayerList(), 
			current_targets = {}, 
		}
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardSlash(slash, dummy_use)
		if dummy_use.card then
			if dummy_use.to:length() > 0 then
				self.qiaoshui_extra_target = dummy_use.to:first()
				return "add"
			end
		end
	else
		local dummy_use = { 
			isDummy = true, 
			to = sgs.SPlayerList(), 
			current_targets = {}, 
		}
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardByClassName(card, dummy_use)
		if dummy_use.card then
			if dummy_use.to:length() > 0 then
				self.qiaoshui_extra_target = dummy_use.to:first()
				return "add"
			end
		end
	end
	self.qiaoshui_extra_target = nil
	self.qiaoshui_remove_target = nil
	return "cancel"
end
sgs.ai_skill_playerchosen["qiaoshui"] = function(self, targets)
	return self.qiaoshui_extra_target or self.qiaoshui_remove_target
end
sgs.ai_skill_use["@@qiaoshui!"] = function(self, prompt)
	assert(self.qiaoshui_collateral)
	return "@ExtraCollateralCard=.->" .. self.qiaoshui_collateral[1] .. "+" .. self.qiaoshui_collateral[2]
end
--[[
	技能：纵适
	描述：每当你拼点赢，你可以获得对方的拼点牌。每当你拼点没赢，你可以获得你的拼点牌。 
]]--
sgs.ai_skill_invoke["zongshih"] = function(self, data)
	return not self:needKongcheng(self.player, true)
end
--[[****************************************************************
	武将：三将成名·李儒（群）
]]--****************************************************************
--[[
	技能：绝策
	描述：你的回合内，一名体力值大于0的角色失去最后的手牌后，你可以对其造成1点伤害。 
]]--
sgs.ai_skill_invoke["juece"] = function(self, data)
	local move = data:toMoveOneTime()
	local target = move.from
	if target then
		target = findPlayerByObjectName(self.room, target:objectName())
		if target then
			if self:isPartner(target) then
				if self:invokeDamagedEffect(target, self.player) then
					return true
				end
			elseif self:canAttack(target) then
				return true
			end
		end
	end
	return false
end
--[[
	技能：灭计（锁定技）
	描述：你使用黑色非延时类锦囊牌的目标数上限至少为二。 
]]--
--[[
	内容：“超借刀杀人技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ExtraCollateralCard"] = 0
sgs.ai_playerchosen_intention["mieji"] = -50
sgs.ai_skill_playerchosen["mieji"] = function(self, targets) -- extra target for Ex Nihilo
	return self:findPlayerToDraw(false, 2)
end
sgs.ai_skill_use["@@mieji"] = function(self, prompt) -- extra target for Collateral
	local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuitBlack)
	local dummy_use = { 
		isDummy = true, 
		to = sgs.SPlayerList(), 
		current_targets = {}, 
	}
	local property = self.player:property("extra_collateral_current_targets")
	dummy_use.current_targets = property:toString():split("+")
	self:useCardCollateral(collateral, dummy_use)
	if dummy_use.card then
		if dummy_use.to:length() == 2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			return "@ExtraCollateralCard=.->" .. first .. "+" .. second
		end
	end
end
--[[
	技能：焚城（限定技）
	描述：出牌阶段，你可以令所有其他角色选择一项：弃置X张牌，或受到你对其造成的1点火焰伤害。（X为该角色装备区牌的数量且至少为1） 
]]--
--[[
	功能：获得对一名角色发动焚城的价值
	参数：target（ServerPlayer类型，表示目标角色）
	结果：number类型（value），表示发动价值
]]--
function SmartAI:getFenchengValue(target)
	local value = 0
	if self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
		if not target:canDiscard(target, "he") then 
			if self:isWeak(target) then
				return 1.5
			else
				return 1 
			end
		end
		if self.player:hasSkill("juece") then
			if self:isOpponent(target) then
				if target:getEquips():isEmpty() then
					if target:getHandcardNum() == 1 then
						if not self:needKongcheng(target) then
							if not target:isChained() then
								if self:isGoodChainTarget(target, target) then 
									if self:isWeak(target) then
										return 1.5
									else
										return 1
									end
								end
							end
						end
					end
				end
			end
		end
		if self:isGoodChainTarget(target, target) then
			return -0.1
		elseif self:invokeDamagedEffect(target, self.player) then
			return -0.1
		elseif self:needToLoseHp(target, self.player) then 
			return -0.1 
		end
		local needToTA = self:needToThrowArmor(target)
		local num = target:getEquips():length() - target:getHandcardNum()
		if num < 0 then
			if needToTA then 
				num = 1 
			else 
				num = 0 
			end
		elseif num == 0 then
			num = 1
		end
		local equip_table = {}
		if needToTA then 
			table.insert(equip_table, 1) 
		end
		if target:getOffensiveHorse() then 
			table.insert(equip_table, 3) 
		end
		if target:getWeapon() then 
			table.insert(equip_table, 0) 
		end
		if target:getDefensiveHorse() then 
			table.insert(equip_table, 2) 
		end
		if target:getArmor() then
			if not needToTA then
				table.insert(equip_table, 1) 
			end
		end
		for i = 1, num, 1 do
			local index = equip_table[i]
			if index == 0 then 
				value = value + 0.4
			elseif index == 1 then
				value = value + (needToTA and -0.5 or 0.8)
			elseif index == 2 then 
				value = value + 0.7
			elseif index == 3 then 
				value = value + 0.3 
			end
		end
		if target:hasSkills("kofxiaoji|xiaoji") then 
			value = value - 0.8 * num 
		end
		if target:hasSkills("xuanfeng|nosxuanfeng") then
			if num > 0 then 
				value = value - 0.8 
			end
		end
		local handcard = target:getHandcardNum() - num
		value = value + 0.1 * handcard
		if self:needKongcheng(target) then
			value = value - 0.15
		elseif self:getLeastHandcardNum(target) > num then 
			value = value - 0.15
		elseif num == 0 then 
			value = value + 0.1 
		end
	end
	return value
end
--[[
	内容：注册“焚城技能卡”
]]--
sgs.RegistCard("FenchengCard")
--[[
	内容：“焚城”技能信息
]]--
sgs.ai_skills["fencheng"] = {
	name = "fencheng",
	dummyCard = function(self)
		return sgs.Card_Parse("@FenchengCard=.")
	end,
	enabled = function(self)
		if self.player:getMark("@burn") > 0 then
			return true
		end
		return false
	end,
}
--[[
	内容：“焚城技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["FenchengCard"] = function(self, card, use)
	if sgs.turncount > 1 then
		if self:amLoyalist() or self:amRenegade() then
			local lord = self.room:getLord()
			if lord then
				if sgs.isInDanger(lord) or self:isWeak(lord) then
					return 
				end
			end
		end
		local value = 0
		local others = self.room:getOtherPlayers(self.player)
		for _, player in sgs.qlist(others) do
			if self:isPartner(player) then 
				value = value - self:getFenchengValue(player)
			elseif self:isOpponent(player) then 
				value = value + self:getFenchengValue(player) 
			end
		end
		if value > 0 then
			if #self.partners_noself >= #self.opponents then
				local acard = sgs.Card_Parse("@FenchengCard=.")
				use.card = acard
				return 
			end
		end
		local ratio = value / (#self.opponents - #self.partners_noself)
		if ratio >= 0.4 then 
			local acard = sgs.Card_Parse("@FenchengCard=.") 
			use.card = acard
			return 
		end
	end
end
sgs.ai_skill_discard["fencheng"] = function(self, discard_num, min_num, optional, include_equip)
	if discard_num == 1 then
		if self:needToThrowArmor() then 
			local armor = self.player:getArmor()
			return { armor:getEffectiveId() } 
		end
	end
	local LiRu = self.room:getCurrent()
	--Waiting For More Details
end
--[[
	套路：仅使用“焚城技能卡”
]]--
sgs.ai_series["FenchengCardOnly"] = {
	name = "FenchengCardOnly",
	IQ = 2,
	value = 3,
	priority = 1,
	skills = "fencheng",
	cards = {
		["FenchengCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local fencheng_skill = sgs.ai_skills["fencheng"]
		local dummyCard = fencheng_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["FenchengCard"], "FenchengCardOnly")
--[[****************************************************************
	武将：三将成名·刘封（蜀）
]]--****************************************************************
--[[
	技能：陷嗣
	描述：准备阶段开始时，你可以将一至两名角色的各一张牌置于你的武将牌上，称为“逆”。其他角色可以将两张“逆”置入弃牌堆，视为对你使用一张【杀】。 
]]--
--[[
	内容：“陷嗣技能卡”、“陷嗣杀技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["XiansiCard"] = function(self, card, source, targets)
	if source:getState() == "online" then
		for _, to in ipairs(targets) do
			local intention = 80
			if to:hasSkills("tuntian+zaoxian") then
				intention = 0
			elseif self:hasSkills("kongcheng|zhiji|lianying", to) then
				if to:getHandcardNum() == 1 then
					intention = 0
				end
			end
			sgs.updateIntention(source, to, intention)
		end
	else
		for _, to in ipairs(targets) do
			local intention = 80
			if source:hasFlag("AI_XiansiToFriend_" .. to:objectName()) then
				intention = -5
			end
			sgs.updateIntention(source, to, intention)
		end
	end
end
sgs.ai_card_intention["XiansiSlashCard"] = function(self, card, source, targets)
	if self:slashIsEffective(sgs.slash, targets[1], source) then
		return sgs.ai_card_intention["Slash"](self, sgs.slash, source, targets)
	else
		sgs.updateIntention(source, targets[1], -30)
	end
end
--[[
	内容：注册“陷嗣杀技能卡”
]]--
sgs.RegistCard("XiansiSlashCard")
--[[
	内容：“陷嗣（杀）”技能信息
]]--
sgs.ai_skills["xiansi_slash"] = {
	name = "xiansi_slash",
	dummyCard = function(self)
		return sgs.Card_Parse("@XiansiSlashCard=.")
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			local alives = self.room:getOtherPlayers(self.player)
			for _,LiuFeng in sgs.qlist(alives) do
				local counters = LiuFeng:getPile("counter")
				if not counters:isEmpty() then
					if self.player:canSlash(LiuFeng) then
						return true
					end
				end
			end
		end
		return false
	end,
}
--[[
	内容：“陷嗣杀技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["XiansiSlashCard"] = function(self, card, use)
	local LiuFeng = self.room:findPlayerBySkillName("xiansi")
	if LiuFeng then
		local counters = LiuFeng:getPile("counter")
		if counters:length() > 1 then
			if self.player:canSlash(LiuFeng) then
				if sgs.slash:isAvailable(self.player) then
					if not self:slashIsEffective(sgs.slash, LiuFeng, self.player) then
						if self:isPartner(LiuFeng) then
							use.card = card
						end
					end
				end
				if not use.card then
					local dummy_use = { 
						to = sgs.SPlayerList(), 
					}
					self:useCardSlash(sgs.slash, dummy_use)
					if dummy_use.card then
						if sgs.isKindOf("GodSalvation|Analeptic|Weapon", dummy_use.card) then
							if self:getCardsNum("Slash") > 0 then
								use.card = dummy_use.card
								return
							end
						elseif sgs.isKindOf("Slash", dummy_use.card) then
							if dummy_use.to:length() > 0 then
								local include = false
								for _,p in sgs.qlist(dummy_use.to) do
									if p:objectName() == LiuFeng:objectName() then
										include = true
										break
									end
								end
								if include then
									use.card = card
								end
							end
						end
					end
				end
				if not use.card then
					if sgs.slash:isAvailable(self.player) then
						if self:isOpponent(LiuFeng) then
							if self:willUseSlash(LiuFeng, self.player, sgs.slash) then
								if self:slashIsEffective(sgs.slash, LiuFeng) then
									if self:isGoodTarget(self, LiuFeng, self.opponents) then
										use.card = card
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_use["@@xiansi"] = function(self, prompt)
	local crossbow_effect = false
	local tag = self.player:getTag("HuashenSkill")
	if not tag:toString() == "xiansi" then
		for _, enemy in ipairs(self.opponents) do
			if enemy:inMyAttackRange(self.player) then
				if self:hasCrossbowEffect(enemy) then
					crossbow_effect = true
					break
				elseif sgs.getKnownCard(enemy, "Crossbow") > 0 then
					crossbow_effect = true
					break
				end
			end
		end
	end
	local max_num = 999
	if crossbow_effect then 
		max_num = 3
	elseif self:getCardsNum("Jink") < 1 then
		max_num = 5
	elseif self:isWeak() then 
		max_num = 5 
	end
	local counters = self.player:getPile("counter")
	if counters:length() >= max_num then 
		return "." 
	end
	local rest_num = math.min(2, max_num - counters:length())
	local targets = {}
	
	local function add_player(player, isFriend)
		if player:getHandcardNum() == 0 then
			return #targets
		elseif player:objectName() == self.player:objectName() then 
			return #targets 
		end
		if self:mayLord(player) then
			if self:isNeutral(player) then
				--if sgs.current_mode_players["rebel"] > 1 then
					return #targets
				--end
			end
		end
		if #targets == 0 then
			table.insert(targets, player:objectName())
		elseif #targets == 1 then
			if player:objectName() ~= targets[1] then
				table.insert(targets, player:objectName())
			end
		end
		if isFriend and isFriend == 1 then
			self.player:setFlags("AI_XiansiToFriend_" .. player:objectName())
		end
		return #targets
	end
	
	local player = self:findPlayerToDiscard("he", true, false)
	if player then
		if rest_num == 1 then 
			return "@XiansiCard=.->" .. player:objectName() 
		end
		local isFriend = nil
		if self:isPartner(player) then
			isFriend = 1
		end
		add_player(player, isFriend)
		local others = self.room:getOtherPlayers(player)
		local another = nil --self:findPlayerToDiscard("he", true, false, others)
		if another then
			isFriend = nil
			if self:isPartner(another) then
				isFriend = 1
			end
			add_player(another, isFriend)
			return "@XiansiCard=.->" .. table.concat(targets, "+")
		end
	end
	if sgs.turncount <= 1 then
		for _,lordname in ipairs(sgs.ai_lords) do
			local lord = findPlayerByObjectName(self.room, lordname)
			if not lord:isNude() then
				if self:isOpponent(lord) then
					if add_player(lord) == rest_num then
						return "@XiansiCard=.->"..table.concat(targets, "+")
					end
				end
			end
		end
	end
	local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
	local LuXun = self.room:findPlayerBySkillName("lianying")
	local DengAi = self.room:findPlayerBySkillName("tuntian")
	local JiangWei = self.room:findPlayerBySkillName("zhiji")
	if JiangWei then
		if self:isPartner(JiangWei) then
			if JiangWei:getMark("zhiji") == 0 then
				if JiangWei:getHandcardNum()== 1 then
					local limit = 0
					if JiangWei:getHp() >= 3 then
						limit = 1
					end
					if self:getOpponentNumBySeat(self.player, JiangWei) <= limit then
						if add_player(JiangWei, 1) == rest_num then 
							return "@XiansiCard=.->" .. table.concat(targets, "+") 
						end
					end
				end
			end
		end
	end
	if DengAi then
		if DengAi:hasSkill("zaoxian") then
			if self:isPartner(DengAi) then
				if DengAi:getMark("zaoxian") == 0 then
					if DengAi:getPile("field"):length() == 2 then
						if not self:isWeak(DengAi) then
							if add_player(DengAi, 1) == rest_num then
								return "@XiansiCard=.->" .. table.concat(targets, "+")
							end
						elseif self:getOpponentNumBySeat(self.player, DengAi) == 0 then
							if add_player(DengAi, 1) == rest_num then
								return "@XiansiCard=.->" .. table.concat(targets, "+")
							end
						end
					end
				end
			end
		end
	end
	local name = self.player:objectName()
	if ZhuGeLiang then
		if self:isPartner(ZhuGeLiang) then
			if ZhuGeLiang:getHandcardNum() == 1 then
				if self:getOpponentNumBySeat(self.player, ZhuGeLiang) > 0 then
					if ZhuGeLiang:getHp() <= 2 then
						if add_player(ZhuGeLiang, 1) == rest_num then 
							return "@XiansiCard=.->" .. table.concat(targets, "+") 
						end
					else
						local name2 = ZhuGeLiang:objectName()
						local flag = string.format("visible_%s_%s", name, name2)
						local handcards = ZhuGeLiang:getHandcards()
						local cards = sgs.QList2Table(handcards)
						if #cards == 1 then
							local c = cards[1]
							if c:hasFlag("visible") or c:hasFlag(flag) then
								if sgs.isKindOf("TrickCard|Slash|EquipCard", c) then
									if add_player(ZhuGeLiang, 1) == rest_num then 
										return "@XiansiCard=.->" .. table.concat(targets, "+") 
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if LuXun then
		if self:isPartner(LuXun) then
			if LuXun:getHandcardNum() == 1 then
				if self:getOpponentNumBySeat(self.player, LuXun) > 0 then
					local flag = string.format("%s_%s_%s", "visible", name, LuXun:objectName())
					local handcards = LuXun:getHandcards()
					local cards = sgs.QList2Table(handcards)
					if #cards == 1 then
						local c = cards[1]
						if c:hasFlag("visible") or c:hasFlag(flag) then
							if sgs.isKindOf("TrickCard|Slash|EquipCard", c) then
								if add_player(LuXun, 1) == rest_num then 
									return "@XiansiCard=.->" .. table.concat(targets, "+") 
								end
							end
						end
					end
				end
			end
		end
		local limit = nil
		if self:isPartner(LuXun) then
			limit = 1
		end
		if add_player(LuXun, limit) == rest_num then
			return "@XiansiCard=.->" .. table.concat(targets, "+")
		end
	end
	if DengAi then
		if self:isPartner(DengAi) then
			if not self:isWeak(DengAi) then
				if add_player(DengAi, 1) == rest_num then
					return "@XiansiCard=.->" .. table.concat(targets, "+")
				end
			elseif self:getEnemyNumBySeat(self.player, DengAi) == 0 then
				if add_player(DengAi, 1) == rest_num then
					return "@XiansiCard=.->" .. table.concat(targets, "+")
				end
			end
		end
	end
	if #targets == 1 then
		local target = findPlayerByObjectName(self.room, targets[1])
		if target then
			local another = nil
			if rest_num > 1 then 
				local others = self.room:getOtherPlayers(target)
				another = self:findPlayerToDiscard("he", true, false, others) 
			end
			if another then
				local limit = nil
				if self:isPartner(another) then
					limit = 1
				end
				add_player(another, limit)
				return "@XiansiCard=.->" .. table.concat(targets, "+")
			else
				return "@XiansiCard=.->" .. targets[1]
			end
		end
	end
	return "."
end
--[[
	套路：仅使用“陷嗣杀技能卡”
]]--
sgs.ai_series["XiansiSlashCardOnly"] = {
	name = "XiansiSlashCardOnly",
	IQ = 2,
	value = 3,
	priority = 1.5,
	cards = {
		["XiansiSlashCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xiansi_skill = sgs.ai_skills["xiansi_slash"]
		local dummyCard = xiansi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XiansiSlashCard"], "XiansiSlashCardOnly")
--[[****************************************************************
	武将：三将成名·满宠（魏）
]]--****************************************************************
--[[
	技能：峻刑
	描述：出牌阶段限一次，你可以弃置至少一张手牌并选择一名其他角色，该角色须弃置一张与你弃置的牌类型均不同的手牌，否则将其武将牌翻面并摸X张牌。（X为你弃置的牌的数量） 
]]--
--[[
	内容：“峻刑技能卡”的卡牌成分
]]--
sgs.card_constituent["JunxingCard"] = {
	use_priority = 1.2,
}
--[[
	内容：“峻刑技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JunxingCard"] = function(self, card, source, targets)
	local target = targets[1]
	if target:faceUp() then
		if target:getHandcardNum() <= 1 then
			if card:subcardsLength() >= 3 then
				sgs.updateIntention(source, target, -40)
				return 
			end
		end
		sgs.updateIntention(source, target, 80)
	else
		sgs.updateIntention(source, target, -80)
	end
end
--[[
	内容：注册“峻刑技能卡”
]]--
sgs.RegistCard("JunxingCard")
--[[
	内容：“峻刑”技能信息
]]--
sgs.ai_skills["junxing"] = {
	name = "junxing",
	dummyCard = function(self)
		return sgs.Card_Parse("@JunxingCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("JunxingCard") then
			return false
		elseif self.player:isKongcheng() then
			return false
		end
		return true
	end,
}
--[[
	内容：“峻刑技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["JunxingCard"] = function(self, card, use)
	local unprefered_cards = {}
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local use_slash_num = 0
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf("Slash") then
			local will_use = false
			if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, c) then
				local dummy_use = { 
					isDummy = true, 
				}
				self:useBasicCard(c, dummy_use)
				if dummy_use.card then
					will_use = true
					use_slash_num = use_slash_num + 1
				end
			end
			if not will_use then 
				table.insert(unprefered_cards, c:getId()) 
			end
		end
	end
	local num = self:getCardsNum("Jink") - 1
	if self.player:getArmor() then 
		num = num + 1 
	end
	if num > 0 then
		for _, c in ipairs(cards) do
			if c:isKindOf("Jink") and num > 0 then
				table.insert(unprefered_cards, c:getId())
				num = num - 1
			end
		end
	end
	for _, c in ipairs(cards) do
		if c:isKindOf("EquipCard") then
			local dummy_use = { 
				isDummy = true, 
			}
			self:useEquipCard(c, dummy_use)
			if not dummy_use.card then 
				table.insert(unprefered_cards, c:getId()) 
			end
		end
	end
	for _, c in ipairs(cards) do
		if c:isNDTrick() or c:isKindOf("Lightning") then
			local dummy_use = { 
				isDummy = true, 
			}
			self:useTrickCard(c, dummy_use)
			if not dummy_use.card then 
				table.insert(unprefered_cards, c:getId()) 
			end
		end
	end
	local use_cards = {}
	for index = #unprefered_cards, 1, -1 do
		local id = unprefered_cards[index]
		local c = sgs.Sanguosha:getCard(id)
		if not self.player:isJilei(c) then 
			table.insert(use_cards, id) 
		end
	end
	if #use_cards > 0 then 
		self:sort(self.partners_noself, "defense")
		for _, friend in ipairs(self.partners_noself) do
			if not self:toTurnOver(friend, #use_cards) then
				local card_str = "@JunxingCard=" .. table.concat(use_cards, "+")
				use.card = sgs.Card_Parse(card_str)
				if use.to then 
					use.to:append(friend) 
				end
				return
			end
		end
		if #use_cards >= 3 then
			for _, friend in ipairs(self.partners_noself) do
				if friend:getHandcardNum() <= 1 then
					if not self:needKongcheng(friend) then
						local card_str = "@JunxingCard=" .. table.concat(use_cards, "+")
						use.card = sgs.Card_Parse(card_str)
						if use.to then 
							use.to:append(friend) 
						end
						return
					end
				end
			end
		end
		local basic, trick, equip
		for _, id in ipairs(use_cards) do
			local c = sgs.Sanguosha:getEngineCard(id)
			local typeid = c:getTypeId()
			if not basic and typeid == sgs.Card_TypeBasic then 
				basic = id
			elseif not trick and typeid == sgs.Card_TypeTrick then 
				trick = id
			elseif not equip and typeid == sgs.Card_TypeEquip then 
				equip = id
			end
			if basic and trick and equip then 
				break 
			end
		end
		self:sort(self.enemies, "handcard")
		local other_enemy = nil
		for _, enemy in ipairs(self.opponents) do
			local id = nil
			if self:toTurnOver(enemy, 1) then
				if sgs.getKnownCard(enemy, "BasicCard") == 0 then 
					id = equip or trick 
				end
				if not id and sgs.getKnownCard(enemy, "TrickCard") == 0 then 
					id = equip or basic 
				end
				if not id and sgs.getKnownCard(enemy, "EquipCard") == 0 then 
					id = trick or basic 
				end
				if id then
					local card_str = "@JunxingCard=" .. id
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(enemy) 
					end
					return
				elseif not other_enemy then
					other_enemy = enemy
				end
			end
		end
		if other_enemy then
			local card_str = "@JunxingCard=" .. use_cards[1]
			use.card = sgs.Card_Parse(card_str)
			if use.to then 
				use.to:append(other_enemy) 
			end
		end
	end
end
sgs.ai_skill_cardask["@junxing-discard"] = function(self, data, pattern)
	local ManChong = self.room:findPlayerBySkillName("junxing")
	if ManChong then
		if self:isPartner(ManChong) then 
			return "." 
		end
	end
	local patterns = pattern:split("|")
	local types = patterns[1]:split(",")
	local cards = self.player:getHandcards()
	local cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _,classname in ipairs(types) do
				if card:isKindOf(classname) then 
					return "$" .. card:getEffectiveId() 
				end
			end
		end
	end
	return "."
end
--[[
	套路：仅使用“峻刑技能卡”
]]--
sgs.ai_series["JunxingCardOnly"] = {
	name = "JunxingCardOnly",
	IQ = 2,
	value = 2,
	priority = 2,
	skills = "junxing",
	cards = {
		["JunxingCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local junxing_skill = sgs.ai_skills["junxing"]
		local dummyCard = junxing_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["JunxingCard"], "JunxingCardOnly")
--[[
	技能：御策
	描述：每当你受到一次伤害后，你可以展示一张手牌，若此伤害有来源，伤害来源须弃置一张与该牌类型不同的手牌，否则你回复1点体力。 
]]--
sgs.ai_skill_cardask["@yuce-show"] = function(self, data)
	local tag = self.room:getTag("CurrentDamageStruct")
	local damage = tag:toDamage()
	local source = damage.from
	if source then
		if source:isDead() then 
			return "." 
		end
	else
		return "."
	end 
	local handcards = self.player:handCards()
	if self:isFriend(source) then 
		return "$" .. handcards:first() 
	end
	local flag = string.format("visible_%s_%s", self.player:objectName(), source:objectName())
	local types = { 
		sgs.Card_TypeBasic, 
		sgs.Card_TypeEquip, 
		sgs.Card_TypeTrick 
	}
	local cards = source:getHandcards()
	for _,card in sgs.qlist(cards) do
		if card:hasFlag("visible") or card:hasFlag(flag) then
			table.removeOne(types, card:getTypeId())
		end
		if #types == 0 then 
			types = { sgs.Card_TypeBasic }
			break 
		end
	end
	handcards = self.player:getHandcards()
	for _,card in sgs.qlist(handcards) do
		for _,cardtype in ipairs(types) do
			if card:getTypeId() == cardtype then 
				return "$" .. card:getEffectiveId() 
			end
		end
	end
	handcards = self.player:handCards()
	return "$" .. handcards:first()
end
sgs.ai_skill_cardask["@yuce-discard"] = function(self, data, pattern, target)
	if target then
		if self:isPartner(target) then 
			return "." 
		end
	end
	local patterns = pattern:split("|")
	local types = patterns[1]:split(",")
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _,classname in ipairs(types) do
				if card:isKindOf(classname) then 
					return "$" .. card:getEffectiveId() 
				end
			end
		end
	end
	return "."
end
--[[****************************************************************
	武将：三将成名·潘璋马忠（吴）
]]--****************************************************************
--[[
	技能：夺刀
	描述：每当你受到一次【杀】造成的伤害后，你可以弃置一张牌，获得伤害来源装备区的武器牌。 
]]--
sgs.ai_skill_cardask["@duodao-get"] = function(self, data)
end
--[[
	技能：暗箭（锁定技）
	描述：每当你使用【杀】对目标角色造成伤害时，若你不在其攻击范围内，此伤害+1。 
]]--
sgs.heavy_slash_system["anjian"] = {
	name = "anjian",
	reason = "anjian",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if slash then
			if not source:hasSkill("jueqing") then
				if source:hasSkill("anjian") then
					if not target:inMyAttackRange(source) then
						return 1
					end
				end
			end
		end
		return 0
	end,
}
--[[****************************************************************
	武将：三将成名·虞翻（吴）
]]--****************************************************************
--[[
	技能：纵玄
	描述：当你的牌因弃置而置入弃牌堆前，你可以将其中任意数量的牌以任意顺序依次置于牌堆顶。 
]]--
sgs.ai_skill_use["@@zongxuan"] = function(self, prompt)
	if self.top_draw_pile_id then
		return "."
	elseif self.player:getPhase() >= sgs.Player_Finish then 
		return "." 
	end
	local property = self.player:property("zongxuan")
	local list = property:toString():split("+")
	local valuable = nil
	for _, id in ipairs(list) do
		local card_id = tonumber(id)
		local card = sgs.Sanguosha:getCard(card_id)
		if card:isKindOf("EquipCard") then
			for _, friend in ipairs(self.partners) do
				local can_use = true
				if card:isKindOf("Armor") then
					if not friend:getArmor() then
						if friend:hasSkills("bazhen|yizhong") then
							can_use = false
						end
					end
				end
				if can_use then
					can_use = false
					if sgs.isKindOf("DefensiveHorse|OffensiveHorse", card) then
						can_use = true
					elseif not self:getSameTypeEquip(card, friend) then
						can_use = true
					elseif card:isKindOf("Weapon") then
						local weapon = friend:getWeapon()
						if weapon then
							if self:evaluateWeapon(card) > self:evaluateWeapon(weapon) - 1 then
								can_use = true
							end
						end
					end
					if can_use then
						self.top_draw_pile_id = card_id
						return "@ZongxuanCard=" .. card_id
					end
				end
			end
		elseif not valuable then
			if self:isValuableCard(card) then
				valuable = card_id
			end
		end
	end
	if valuable then
		self.top_draw_pile_id = valuable
		return "@ZongxuanCard=" .. valuable
	end
	return "."
end
--[[
	技能：直言
	描述：结束阶段开始时，你可以令一名角色摸一张牌并展示之。若此牌为装备牌，该角色回复1点体力，然后使用之。 
]]--
sgs.ai_playerchosen_intention["zhiyan"] = -60
sgs.ai_skill_playerchosen["zhiyan"] = function(self, targets)
	if self.top_draw_pile_id then
		local card = sgs.Sanguosha:getCard(self.top_draw_pile_id)
		if card:isKindOf("EquipCard") then
			self:sort(self.partners, "hp")
			for _, friend in ipairs(self.partners) do
				local flag = false
				if not self:getSameTypeEquip(card, friend) then
					flag = true
				elseif sgs.isKindOf("DefensiveHorse|OffensiveHorse", card) then
					flag = true
				end
				if flag then
					if card:isKindOf("Armor") then
						if friend:hasSkills("bazhen|yizhong") then
							flag = false
						elseif self:evaluateArmor(card, friend) < 0 then
							flag = false
						end
					end
					if flag then
						return friend
					end
				end
			end
			local flag = true
			if card:isKindOf("Armor") then
				if self.player:hasSkills("bazhen|yizhong") then
					flag = false
				elseif self:evaluateArmor(card) < 0 then
					flag = false
				end
			end
			if flag then
				if card:isKindOf("Weapon") then
					local weapon = self.player:getWeapon()
					if weapon then
						if self:evaluateWeapon(card) < self:evaluateWeapon(weapon) - 1 then
							flag = false
						end
					end
				end
				if flag then
					return self.player
				end
			end
		else
			local cards = { card }
			local player = self:getCardNeedPlayer(cards)
			if player then
				return player
			else
				self:sort(self.partners)
				for _, friend in ipairs(self.partners) do
					if not self:needKongcheng(friend, true) then
						if not friend:hasSkill("manjuan") then
							return friend
						elseif friend:getPhase() ~= sgs.Player_NotActive then
							return friend 
						end
					end
				end
			end
		end
	else
		self:sort(self.partners)
		for _, friend in ipairs(self.partners) do
			if not self:needKongcheng(friend, true) then
				if not friend:hasSkill("manjuan") then
					return friend
				elseif friend:getPhase() ~= sgs.Player_NotActive then 
					return friend 
				end
			end
		end
	end
end
--[[****************************************************************
	武将：三将成名·朱然（吴）
]]--****************************************************************
--[[
	技能：胆守
	描述：每当你造成伤害后，你可以摸一张牌，然后结束当前回合并结束一切结算。 
]]--
sgs.ai_skill_invoke["danshou"] = function(self, data)
	local damage = data:toDamage()
	local phase = self.player:getPhase()
	if phase < sgs.Player_Play then
		return self:willSkipPlayPhase()
	elseif phase == sgs.Player_Play then
		if self.player:isChained() then
			if damage.chain or self.room:getTag("is_chained"):toInt() > 0 then
				if self:isGoodChainTarget(self.player) then
					return false
				end
			end
		end
		if self:getOverflow() >= 2 then
			return true
		else
			if damage.chain or self.room:getTag("is_chained"):toInt() > 0 then
				local next_player
				local alives = self.room:getAlivePlayers()
				for _, p in sgs.qlist(alives) do
					if p:isChained() then
						if self:damageIsEffective(p, damage.nature, self.player) then
							next_player = p
							break
						end
					end
				end
				if not next_player or self:isFriend(next_player) then 
					return true 
				else 
					return false 
				end
			end
			if damage.card then
				if damage.card:isKindOf("Slash") then
					if self:getCardsNum("Slash") >= 1 then
						if sgs.slash:isAvailable(self.player) then
							return false
						end
					end
				end
			end
			local can_invoke = false
			if damage.card and damage.card:isKindOf("AOE") then
				can_invoke = true
			elseif self.player:hasFlag("ShenfenUsing") and self.player:faceUp() then
				can_invoke = true
			end
			if can_invoke then
				local next_alive = damage.to:getNextAlive()
				if next_alive:objectName() == self.player:objectName() then 
					return true
				else
					local value = 0
					local p = damage.to
					repeat
						if self:damageIsEffective(p, damage.nature, self.player) then
							if self:isPartner(p) then
								value = value + 1
							else
								if self:cannotBeHurt(p, damage.damage, self.player) then 
									value = value + 1 
								end
								if self:invokeDamagedEffect(p, self.player) then 
									value = value + 0.5 
								end
								if self:isOpponent(p) then 
									value = value - 1 
								end
							end
						end
						p = p:getNextAlive()
					until p:objectName() == self.player:objectName()
					return value >= 1.5
				end
			end
			local skills = sgs.masochism_skill .. "|zhichi|zhiyu|fenyong"
			if damage.to:hasSkills(skills) then 
				return self:isOpponent(damage.to) 
			end
			return true
		end
	elseif phase > sgs.Player_Play then
		if phase == sgs.Player_NotActive then
			local current = self.room:getCurrent()
			if current and current:isAlive() then
				if current:getPhase() ~= sgs.Player_NotActive then
					if self:isPartner(current) then
						return self:getOverflow(current) >= 2
					else
						if self:getOverflow(current) <= 2 then
							return true
						else
							local threat = sgs.getCardsNum("Duel", current) + sgs.getCardsNum("AOE", current)
							if sgs.slash:isAvailable(current) then
								local slashCount = sgs.getCardsNum("Slash", current)
								if slashCount > 0 then 
									threat = threat + math.min(1, slashCount) 
								end
							end
							return threat >= 1
						end
					end
				end
			end
			return true
		else
			return true
		end
	end
	return false
end