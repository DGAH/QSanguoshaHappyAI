--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）一将成名2012扩展包部分
]]--
--[[****************************************************************
	武将：二将成名·步练师（吴）
]]--****************************************************************
sgs.ai_chaofeng.bulianshi = 4
--[[
	技能：安恤
	描述：出牌阶段限一次，你可以选择两名手牌数不相等的其他角色，令其中手牌少的角色获得手牌多的角色的一张手牌并展示之，若此牌不为♠，你摸一张牌。 
]]--
--[[
	内容：“安恤技能卡”的卡牌成分
]]--
sgs.card_constituent["AnxuCard"] = {
	use_priority = 9.6,
}
--[[
	内容：“安恤技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["AnxuCard"] = 0
--[[
	内容：注册“安恤技能卡”
]]--
sgs.RegistCard("AnxuCard")
--[[
	内容：“安恤”技能信息
]]--
sgs.ai_skills["anxu"] = {
	name = "anxu",
	dummyCard = function(self)
		return sgs.Card_Parse("@AnxuCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("AnxuCard") then 
			return false 
		end
		return true
	end,
}
--[[
	内容：“安恤技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["AnxuCard"] = function(self, card, use)
	if #self.opponents > 0 then
		local intention = 50
		local friends = {}
		for _, friend in ipairs(self.partners_noself) do
			if self:needKongcheng(friend, true) then
				if friend:hasSkill("manjuan") then
					table.insert(friends, friend) 
				end
			else
				table.insert(friends, friend) 
			end
		end
		self:sort(friends, "handcard")
		local least_friend
		local most_friend
		if #friends > 0 then
			least_friend = friends[1]
			most_friend = friends[#friends]
		end
		local need_kongcheng_friend
		for _, friend in ipairs(friends) do
			if friend:getHandcardNum() == 1 then
				if friend:hasSkill("kongcheng") then
					need_kongcheng_friend = friend
					break
				elseif friend:hasSkill("zhiji") then
					if friend:getMark("zhiji") == 0 then
						if friend:getHp() >= 3 then
							need_kongcheng_friend = friend
							break
						end
					end
				end
			end
		end
		local enemies = {}
		for _, enemy in ipairs(self.opponents) do
			local flag = true
			if enemy:hasSkill("tuntian") then
				if enemy:hasSkill("zaoxian") then
					flag = false
				end
			end
			if flag then
				if enemy:isKongcheng() then
					flag = false
				elseif enemy:getHandcardNum() <= 1 then
					if self:needKongcheng(enemy) then
						flag = false
					end
				end
			end
			if flag then
				table.insert(enemies, enemy)
			end
		end
		self:sort(enemies, "handcard")
		enemies = sgs.reverse(enemies)
		local most_enemy
		if #enemies > 0 then 
			most_enemy = enemies[1] 
		end
		local prior_enemy, kongcheng_enemy, manjuan_enemy
		for _, enemy in ipairs(enemies) do
			if not prior_enemy then
				if enemy:getHandcardNum() >= 2 then
					if self:hasSkills(sgs.cardneed_skill, enemy) then
						prior_enemy = enemy 
					end
				end
			end
			if not kongcheng_enemy then
				if enemy:hasSkill("kongcheng") then
					if enemy:isKongcheng() then
						kongcheng_enemy = enemy 
					end
				end
			end
			if not manjuan_enemy then
				if enemy:hasSkill("manjuan") then
					manjuan_enemy = enemy
				end
			end
			if prior_enemy and kongcheng_enemy and manjuan_enemy then 
				break 
			end
		end
		-- Enemy -> Friend
		if least_friend then
			local num = least_friend:getHandcardNum()
			local tg_enemy 
			if not tg_enemy and prior_enemy then
				if prior_enemy:getHandcardNum() > num then 
					tg_enemy = prior_enemy 
				end
			end
			if not tg_enemy and most_enemy then
				if most_enemy:getHandcardNum() > num then 
					tg_enemy = most_enemy 
				end
			end
			if tg_enemy then
				use.card = card
				if use.to then
					use.to:append(tg_enemy)
					use.to:append(least_friend)
				end
				if not use.isDummy then
					sgs.updateIntention(self.player, tg_enemy, intention)
					sgs.updateIntention(self.player, least_friend, -intention)
				end
				return
			end
			if most_enemy and most_enemy:getHandcardNum() > num then
				use.card = card
				if use.to then
					use.to:append(most_enemy)
					use.to:append(least_friend)
				end
				if not use.isDummy then
					sgs.updateIntention(self.player, most_enemy, intention)
					sgs.updateIntention(self.player, least_friend, -intention)
				end
				return
			end
			self:sort(enemies, "defense")
			for _,enemy in ipairs(enemies) do
				if enemy:getHandcardNum() > num then
					use.card = card
					if use.to then
						use.to:append(enemy)
						use.to:append(least_friend)
						return
					end
				end
			end
		end
		-- Friend -> Friend
		if #friends >= 2 then
			if need_kongcheng_friend and least_friend:isKongcheng() then
				use.card = card
				if use.to then
					use.to:append(need_kongcheng_friend)
					use.to:append(least_friend)
				end
				if not use.isDummy then
					sgs.updateIntention(self.player, need_kongcheng_friend, -intention)
					sgs.updateIntention(self.player, least_friend, -intention)
				end
				return
			elseif most_friend:getHandcardNum() >= 4 then
				if most_friend:getHandcardNum() > least_friend:getHandcardNum() then
					use.card = card
					if use.to then
						use.to:append(most_friend)
						use.to:append(least_friend)
					end
					if not use.isDummy then 
						sgs.updateIntention(self.player, least_friend, -intention) 
					end
					return
				end
			end
		end
		-- Enemy -> Enemy
		self:sort(enemies, "handcard", true)
		if kongcheng_enemy and not kongcheng_enemy:hasSkill("manjuan") then
			local tg_enemy = prior_enemy or most_enemy
			if tg_enemy and not tg_enemy:isKongcheng() then
				use.card = card
				if use.to then
					use.to:append(tg_enemy)
					use.to:append(kongcheng_enemy)
				end
				if not use.isDummy then
					sgs.updateIntention(self.player, tg_enemy, intention)
					sgs.updateIntention(self.player, kongcheng_enemy, intention)
				end
				return
			elseif most_friend and most_friend:getHandcardNum() >= 4 then -- Friend -> Enemy for KongCheng
				use.card = card
				if use.to then
					use.to:append(most_friend)
					use.to:append(kongcheng_enemy)
				end
				if not use.isDummy then 
					sgs.updateIntention(self.player, kongcheng_enemy, intention) 
				end
				return
			end
		elseif manjuan_enemy then
			local tg_enemy = prior_enemy or most_enemy
			if tg_enemy and tg_enemy:getHandcardNum() > manjuan_enemy:getHandcardNum() then
				use.card = card
				if use.to then
					use.to:append(tg_enemy)
					use.to:append(manjuan_enemy)
				end
				if not use.isDummy then 
					sgs.updateIntention(self.player, tg_enemy, intention) 
				end
				return
			end
		elseif most_enemy then
			local tg_enemy, second_enemy
			if prior_enemy then
				for _, enemy in ipairs(enemies) do
					if enemy:getHandcardNum() < prior_enemy:getHandcardNum() then
						second_enemy = enemy
						tg_enemy = prior_enemy
						break
					end
				end
			end
			if not second_enemy then
				tg_enemy = most_enemy
				for _, enemy in ipairs(enemies) do
					if enemy:getHandcardNum() < most_enemy:getHandcardNum() then
						second_enemy = enemy
						break
					end
				end
			end
			if tg_enemy and second_enemy then
				use.card = card
				if use.to then
					use.to:append(tg_enemy)
					use.to:append(second_enemy)
				end
				if not use.isDummy then
					sgs.updateIntention(self.player, tg_enemy, intention)
					sgs.updateIntention(self.player, second_enemy, intention)
				end
				return
			end
		end
	end
end
--[[
	套路：仅使用“安恤技能卡”
]]--
sgs.ai_series["AnxuCardOnly"] = {
	name = "AnxuCardOnly",
	IQ = 2,
	value = 4,
	priority = 5,
	skills = "anxu",
	cards = {
		["AnxuCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local anxu_skill = sgs.ai_skills["anxu"]
		local dummyCard = anxu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["AnxuCard"], "AnxuCardOnly")
--[[
	技能：追忆
	描述：当你死亡时，你可以令一名其他角色（杀死你的角色除外）摸三张牌，然后令其回复1点体力。 
]]--
sgs.ai_skill_playerchosen.zhuiyi = function(self, targets)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		elseif self:isTempFriend(p) then
			table.insert(enemies, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "defense")
		for _,friend in ipairs(friends) do
			local can_use = true
			if friend:hasSkill("manjuan") then
				if friend:getPhase() == sgs.Player_NotActive then
					if friend:getLostHp() == 0 then
						can_use = false
					end
				end
			end
			if can_use then
				if self:mayLord(friend) then
					if self:isWeak(friend) then
						return friend
					end
				end
				if friend:hasSkill("zhiji") then
					if friend:getMark("zhiji") == 0 then
						if not self:isWeak(friend) then
							if friend:getPhase() == sgs.Player_NotActive then
								can_use = false
							end
						end
					end
				end
				if can_use then
					if self:mayRenegade() then
						second = friend
					elseif not first then
						first = friend
					end
				end
			end
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "defense")
		for _,p in ipairs(enemies) do
			if p:hasSkill("manjuan") then
				return p
			elseif self:isWeak(p) then
				if not self:mayLord(p) then
					return p
				end
			end
		end
	end
	return first or second
end
--[[****************************************************************
	武将：二将成名·曹彰（魏）
]]--****************************************************************
--[[
	技能：将驰
	描述：摸牌阶段，你可以选择一项：1.少摸一张牌，然后拥有以下锁定技：本回合，你使用【杀】无距离限制，你可以额外使用一张【杀】；2.额外摸一张牌，且你不能使用或打出【杀】，直到回合结束。 
]]--
sgs.ai_skill_choice["jiangchi"] = function(self, choices)
	if self.player:isSkipped(sgs.Player_Play) then 
		return "jiang" 
	end
	if self:needBear() then 
		return "jiang" 
	end
	local can_save_card_num = self.player:getMaxCards() - self.player:getHandcardNum()
	if can_save_card_num > 1 then
		return "jiang"
	end
	local target = 0
	for _,enemy in ipairs(self.opponents) do
		if self.player:canSlash(enemy) then
			target = target + 1
			break
		end
	end
	if target == 0 then
		return "jiang"
	end
	local goodtarget = 0
	local slashnum = 0
	local needburst = 0
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		for _,enemy in ipairs(self.opponents) do
			if self:slashIsEffective(slash, enemy) then 
				slashnum = slashnum + 1
				break
			end 
		end
	end
	for _,enemy in ipairs(self.opponents) do
		for _, slash in ipairs(slashes) do
			if self:willUseSlash(enemy, self.player, slash) then
				if self:slashIsEffective(slash, enemy) then
					if sgs.isGoodTarget(self, enemy, self.opponents) then
						goodtarget = goodtarget + 1
						break
					end
				end
			end
		end
	end
	if slashnum > 1 then
		needburst = 1
	elseif slashnum > 0 then
		if goodtarget > 0 then 
			needburst = 1 
		end
	end
	self:sort(self.opponents, "defenseSlash")
	if needburst > 0 then
		for _,enemy in ipairs(self.opponents) do
			local defense = sgs.getDefense(enemy)
			local effective = false
			if self:slashIsEffective(slash, enemy) then
				if sgs.isGoodTarget(self, enemy, self.opponents) then
					effective = true
				end
			end
			if self:willUseSlash(enemy, self.player, sgs.slash) then
				if effective and defense < 8 then 
					return "chi"
				end
			end
		end
	end
	return "cancel"
end
--[[
	内容：“将驰”卡牌需求
]]--
sgs.card_need_system["jiangchi"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) < 2
	end
	return false
end
sgs.draw_cards_system["jiangchi"] = {
	name = "jiangchi",
	correct_func = function(self, player)
		local choice = sgs.ai_skill_choice["jiangchi"](self, "jiang+chi+cancel")
		if choice == "jiang" then
			return 1
		elseif choice == "chi" then
			return -1
		end
		return 0
	end,
}
--[[****************************************************************
	武将：二将成名·程普（吴）
]]--****************************************************************
--[[
	技能：疠火
	描述：你可以将一张普通【杀】当火【杀】使用，或将你视为使用一张【杀】当你视为使用一张火【杀】，若以此法使用的火【杀】造成伤害，在此【杀】结算后你失去1点体力。锁定技，你使用火【杀】选择目标的个数上限+1。 
]]--
--[[
	内容：注册“疠火火杀”
]]--
sgs.RegistCard("lihuo>>FireSlash")
--[[
	内容：“疠火”技能信息
]]--
sgs.ai_skills["lihuo"] = {
	name = "lihuo",
	dummyCard = function(self)
		local suit = sgs.fire_slash:getSuitString()
		local point = sgs.fire_slash:getNumberString()
		local id = sgs.fire_slash:getEffectiveId()
		local card_str = string.format("fire_slash:lihuo[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			for _,slash in ipairs(handcards) do
				if slash:isKindOf("Slash") then
					if not slash:isKindOf("NatureSlash") then
						return true
					end
				end
			end
		end
		return false
	end,
}
--[[
	内容：“疠火火杀”的具体产生方式
]]--
sgs.ai_view_as_func["lihuo>>FireSlash"] = function(self, card)
	if self.player:getHp() > 1 then 
		local cards = self.player:getCards("h")	
		for _,slash in sgs.qlist(cards) do
			if slash:isKindOf("Slash") then
				if not card:isKindOf("NatureSlash") then
					local suit = slash:getSuitString()
					local number = slash:getNumberString()
					local card_id = slash:getEffectiveId()
					local card_str = ("fire_slash:lihuo[%s:%s]=%d"):format(suit, number, card_id)
					return sgs.Card_Parse(card_str)
				end
			end
		end
	end
end
sgs.ai_skill_invoke["lihuo"] = function(self, data)
	if sgs.ai_skill_invoke["Fan"](self, data) then 
		local use = data:toCardUse()
		for _, player in sgs.qlist(use.to) do
			if self:isOpponent(player) then
				if self:damageIsEffective(player, sgs.DamageStruct_Fire) then
					if sgs.isGoodTarget(self, player, self.opponents) then
						if player:isChained() then 
							return self:isGoodChainTarget(player) 
						end
						if player:hasArmorEffect("Vine") then 
							return true 
						end
					end
				end
			end
		end
	end
	return false
end
--[[
	内容：“疠火”响应方式
	需求：火杀
]]--
sgs.ai_view_as["lihuo"] = function(card, player, place)
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
		if place ~= sgs.Player_PlaceSpecial then
			if card:objectName() == "slash" then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				return ("fire_slash:lihuo[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end
--[[
	内容：“疠火”卡牌需求
]]--
sgs.card_need_system["lihuo"] = function(self, card, player)
	if card:isKindOf("FireSlash") then
		return sgs.getKnownCard(player, "FireSlash", false) == 0
	elseif card:isKindOf("ThunderSlash") then
		return false
	elseif card:isKindOf("Slash") then
		return sgs.getKnownCard(player, "Slash", false) == 0
	end
	return false
end
--[[
	套路：仅使用“疠火火杀”
]]--
sgs.ai_series["lihuo>>FireSlashOnly"] = {
	name = "lihuo>>FireSlashOnly",
	IQ = 2,
	value = 2,
	priority = 1;
	skills = "lihuo",
	cards = {
		["lihuo>>FireSlash"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lihuo_skill = sgs.ai_skills["lihuo"]
		local slash = lihuo_skill["dummyCard"](self)
		slash:setFlags("isDummy")
		return {slash}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["lihuo>>FireSlash"], "lihuo>>FireSlashOnly")
--[[
	技能：醇醪
	描述：结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，令该角色视为使用一张【酒】。 
]]--
--[[
	内容：“醇醪酒技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ChunlaoWineCard"] = sgs.ai_card_intention["Peach"]
sgs.ai_skill_use["@@chunlao"] = function(self, prompt)
	local wines = self.player:getPile("wine")
	if wines:isEmpty() then
		local slashes = {}
		local cards = self.player:getCards("h")
		for _,slash in sgs.qlist(cards) do
			if slash:isKindOf("Slash") then
				table.insert(slashes, slash:getId())
			end
		end
		if #slashes > 0 then
			local card_str = "@ChunlaoCard="..table.concat(slashes, "+").."->."
			return card_str
		end
	end
	return "."
end
sgs.ai_cardsview_valuable["chunlao"] = function(self, class_name, player)
	if class_name == "Peach" then
		local wines = player:getPile("wine")
		if wines:length() > 0 then
			local dying = self.room:getCurrentDyingPlayer()
			if dying then
				if not dying:isLocked(sgs.analeptic) then 
					return "@ChunlaoWineCard=."
				end
			end
		end
	end
end
--[[
	内容：“醇醪”卡牌需求
]]--
sgs.card_need_system["chunlao"] = function(self, card, player)
	if card:isKindOf("Slash") then
		local wines = player:getPile("wine")
		return wines:isEmpty()
	end
	return false
end
--[[
	内容：“醇醪”统计信息
]]--
sgs.card_count_system["chunlao"] = {
	name = "chunlao",
	pattern = "Peach", --统计在“桃”目录下
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("chunlao") then
			local count = data["count"]
			local wines = player:getPile("wine")
			count = count + wines:length()
			return count
		end
	end
}
sgs.chunlao_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Slash = 5.5,
}
--[[****************************************************************
	武将：二将成名·关兴张苞（蜀）
]]--****************************************************************
--[[
	技能：父魂
	描述：你可以将两张手牌当普通【杀】使用或打出。每当你于出牌阶段内以此法使用【杀】造成伤害后，你获得技能“武圣”、“咆哮”，直到回合结束。 
]]--
--[[
	内容：注册“父魂杀”
]]--
sgs.RegistCard("fuhun>>Slash")
--[[
	内容：“父魂”技能信息
]]--
sgs.ai_skills["fuhun"] = {
	name = "fuhun",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local point = sgs.slash:getNumberString()
		local id = sgs.slash:getEffectiveId()
		local card_str = string.format("slash:fuhun[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if #handcards > 1 then
			if sgs.slash:isAvailable(self.player) then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“父魂杀”的具体产生方式
]]--
sgs.ai_view_as_func["fuhun>>Slash"] = function(self, card)
	return self:createSpearSlash("fuhun")
end
sgs.ai_cardsview["fuhun"] = function(self, class_name, player)
	if class_name == "Slash" then
		return self:getSpearCardsView(player, "fuhun")
	end
end
--[[
	套路：仅使用“父魂杀”
]]--
sgs.ai_series["fuhun>>SlashOnly"] = {
	name = "fuhun>>SlashOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "fuhun",
	cards = {
		["fuhun>>Slash"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local fuhun_skill = sgs.ai_skills["fuhun"]
		local slash_card = fuhun_skill["dummyCard"](self)
		slash_card:setFlags("isDummy")
		return {slash_card}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["fuhun>>Slash"], "fuhun>>SlashOnly")
--[[****************************************************************
	武将：二将成名·韩当（吴）
]]--****************************************************************
--[[
	技能：弓骑
	描述：出牌阶段限一次，你可以弃置一张牌，令你于此回合内攻击范围无限，若你以此法弃置的牌为装备牌，你可以弃置一名其他角色的一张牌。 
]]--
--[[
	内容：“弓骑技能卡”的卡牌成分
]]--
sgs.card_constituent["GongqiCard"] = {
	use_value = 2,
	use_priority = 8,
}
--[[
	内容：注册“弓骑技能卡”
]]--
sgs.RegistCard("GongqiCard")
--[[
	内容：“弓骑”技能信息
]]--
sgs.ai_skills["gongqi"] = {
	name = "gongqi",
	dummyCard = function(self)
		local card_str = "@GongqiCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("GongqiCard") then
			return false
		elseif self.player:isNude() then
			return false
		end
		return true
	end,
}
--[[
	内容：“弓骑技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["GongqiCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	elseif #self.opponents == 0 then 
		return
	end
	local acard = nil
	if self:needToThrowArmor() then
		local armor = self.player:getArmor()
		local card_str = "@GongqiCard=" .. armor:getEffectiveId()
		acard = sgs.Card_Parse(card_str)
	end
	if not acard then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		local has_weapon = false
		local has_armor = false
		local has_defhorse = false
		local has_offhorse = false
		local weapon = nil
		local armor = nil
		for _, c in ipairs(handcards) do
			if c:isKindOf("Weapon") then
				has_weapon = true
				if not weapon then
					weapon = c
				elseif self:evaluateWeapon(weapon) < self:evaluateWeapon(c) then 
					weapon = c 
				end
			elseif c:isKindOf("Armor") then
				has_armor = true
				if not armor then
					armor = c
				elseif self:evaluateArmor(armor) < self:evaluateArmor(c) then 
					armor = c 
				end
			elseif c:isKindOf("DefensiveHorse") then 
				has_defhorse = true 
			elseif c:isKindOf("OffensiveHorse") then 
				has_offhorse = true 
			end
		end
		if has_offhorse then
			local horse = self.player:getOffensiveHorse()
			if horse then 
				local card_str = "@GongqiCard=" .. horse:getEffectiveId()
				acard = sgs.Card_Parse(card_str) 
			end
		end
		if not acard then
			if has_defhorse then
				local horse = self.player:getDefensiveHorse()
				if horse then 
					local card_str = "@GongqiCard=" .. horse:getEffectiveId()
					acard = sgs.Card_Parse(card_str) 
				end
			end
		end
		if not acard then
			if has_weapon then
				local equip = self.player:getWeapon()
				if equip then
					if self:evaluateWeapon(equip) <= self:evaluateWeapon(weapon) then
						local card_str = "@GongqiCard=" .. equip:getEffectiveId()
						acard = sgs.Card_Parse(card_str)
					end
				end
			end
		end
		if not acard then
			if has_armor then
				local equip = self.player:getArmor()
				if equip then
					if self:evaluateArmor(equip) <= self:evaluateArmor(armor) then
						local card_str = "@GongqiCard=" .. equip:getEffectiveId()
						acard = sgs.Card_Parse(card_str)
					end
				end
			end
		end
		if not acard then
			if self:getOverflow() > 0 then
				if self:getCardsNum("Slash") >= 1 then
					self:sortByKeepValue(handcards)
					self:sort(self.opponents, "defense")
					for _, c in ipairs(handcards) do
						local can_use = true
						if sgs.isKindOf("Snatch|Dismantlement", c) then
							local dummy_use = {
								isDummy = true,
							}
							self:useDisturbCard(c, dummy_use)
							if dummy_use.card then
								can_use = false
							end
						elseif sgs.isKindOf("Peach|ExNihilo", c) then
							can_use = false
						elseif c:isKindOf("Analeptic") then
							if self.player:getHp() <= 2 then
								can_use = false
							end
						elseif c:isKindOf("Jink") then
							if self:getCardsNum("Jink") < 2 then
								can_use = false
							end
						elseif c:isKindOf("Nullification") then
							if self:getCardsNum("Nullification") < 2 then
								can_use = false
							end
						elseif c:isKindOf("Slash") then
							if self:getCardsNum("Slash") == 1 then
								can_use = false
							end
						elseif not c:isKindOf("EquipCard") then
							if self.player:inMyAttackRange(self.opponents[1]) then
								can_use = false
							end
						end
						if can_use then
							local card_str = "@GongqiCard=" .. c:getEffectiveId()
							acard = sgs.Card_Parse(card_str)
							break
						end
					end
				end
			end
		end
	end
	if acard then
		use.card = acard
	end
end
sgs.ai_skill_playerchosen["gongqi"] = function(self, targets)
	return self:findPlayerToDiscard()
end
--[[
	套路：仅使用“弓骑技能卡”
]]--
sgs.ai_series["GongqiCardOnly"] = {
	name = "GongqiCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "gongqi",
	cards = {
		["GongqiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local gongqi_skill = sgs.ai_skills["gongqi"]
		local dummyCard = gongqi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["GongqiCard"], "GongqiCardOnly")
--[[
	技能：解烦（限定技）
	描述：出牌阶段，你可以选择一名角色，令攻击范围内含有该角色的所有角色各选择一项：1.弃置一张武器牌；2.令其摸一张牌。
]]--
--[[
	内容：“解烦技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JiefanCard"] = -80
--[[
	内容：注册“解烦技能卡”
]]--
sgs.RegistCard("JiefanCard")
--[[
	内容：“解烦”技能信息
]]--
sgs.ai_skills["jiefan"] = {
	name = "jiefan",
	dummyCard = function(self)
		return sgs.Card_Parse("@JiefanCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@rescue") > 0 then
			return true
		end
		return false
	end,
}
--[[
	内容：“解烦技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["JiefanCard"] = function(self, card, use)
	local target
	local use_value = 0
	local max_value = -10000
	local alives = self.room:getAlivePlayers()
	for _,friend in ipairs(self.partners) do
		use_value = 0
		for _, p in sgs.qlist(alives) do
			if p:inMyAttackRange(friend) then
				if self:isFriend(p) then
					if not friend:hasSkill("manjuan") then 
						use_value = use_value + 1 
					end
				else
					if p:getWeapon() then
						use_value = use_value + 1.2
					else
						if not friend:hasSkill("manjuan") then 
							use_value = use_value + p:getHandcardNum() / 5 
						end
					end
				end
			end
		end
		use_value = use_value - friend:getHandcardNum() / 2
		if use_value > max_value then
			max_value = use_value
			target = friend
		end
	end
	if target then
		if max_value >= self.player:aliveCount() / 2 then
			use.card = card
			if use.to then 
				use.to:append(target) 
			end
		end
	end
end
sgs.ai_skill_cardask["@jiefan-discard"] = function(self, data)
	local player = data:toPlayer()
	if player and player:isAlive() then
		if player:hasSkill("manjuan") then
			return "."
		elseif self:isPartner(player) then
			return "."
		end
		local cards = self.player:getCards("he")
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Weapon") then
				if not self.player:hasEquip(card) then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		local weapon = self.player:getWeapon()
		if weapon then 
			local count = 0
			local range_fix = sgs.weapon_range[weapon:getClassName()] - 1
			local alives = self.room:getAlivePlayers()
			local range = self.player:getAttackRange()
			for _, p in sgs.qlist(alives) do
				if self:isOpponent(p) then
					if self.player:distanceTo(p, range_fix) > range then 
						count = count + 1 
					end
				end
			end
			if count <= 2 then 
				return "$" .. weapon:getEffectiveId() 
			end
		end
	end
	return "."
end
--[[
	内容：“解烦”卡牌需求（这个有对杀的需求？）
]]--
sgs.card_need_system["jiefan"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) == 0
	end
	return false
end
--[[
	套路：仅使用“解烦技能卡”
]]--
sgs.ai_series["JiefanCardOnly"] = {
	name = "JiefanCardOnly",
	IQ = 2,
	value = 5,
	priority = 1,
	skills = "jiefan",
	cards = {
		["JiefanCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jiefan_skill = sgs.ai_skills["jiefan"]
		local dummyCard = jiefan_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["JiefanCard"], "JiefanCardOnly")
--[[****************************************************************
	武将：二将成名·华雄（群）
]]--****************************************************************
--[[
	技能：恃勇（锁定技）
	描述：每当你受到一次红色【杀】或【酒】【杀】造成的伤害后，你减1点体力上限。 
]]--
--[[****************************************************************
	武将：二将成名·廖化（蜀）
]]--****************************************************************
--[[
	技能：当先（锁定技）
	描述：回合开始时，你执行一个额外的出牌阶段。 
]]--
--[[
	内容：“当先”卡牌需求
]]--
sgs.card_need_system["dangxian"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) == 0
	end
	return false
end
--[[
	技能：伏枥（限定技）
	描述：当你处于濒死状态时，你可以将你当前的体力值回复至X点（X为现存势力数），然后将你的武将牌翻面。 
]]--
sgs.ai_skill_invoke["fuli"] = true
--[[****************************************************************
	武将：二将成名·刘表（群）
]]--****************************************************************
--[[
	技能：自守
	描述：摸牌阶段，若你已受伤，你可以额外摸X张牌，然后跳过出牌阶段。（X为你已损失的体力值） 
]]--
sgs.ai_skill_invoke["zishou"] = function(self, data)
	if self:needBear() then 
		return true 
	end
	if self.player:isSkipped(sgs.Player_Play) then 
		return true 
	end
	local chance_value = 1
	local peach_num = self:getCardsNum("Peach")
	local overflow = self:getOverflow(self.player, true)
	local num = self.player:getHandcardNum()
	local can_save_card_num = overflow - num
	local hp = self.player:getHp()
	if hp <= 2 then
		if hp < sgs.getBestHp(self.player) then 
			chance_value = chance_value + 1 
		end
	end
	if self:hasSkills("nosrende|rende") then
		if self:hasPartners("draw") then 
			chance_value = chance_value - 1 
		end
	end
	if self.player:hasSkill("qingnang") then
		for _,friend in ipairs(self.partners) do
			if friend:isWounded() then 
				chance_value = chance_value - 1 
				break 
			end
		end
	end
	if self.player:hasSkill("jieyin") then
		for _,friend in ipairs(self.partners) do
			if friend:isWounded() then 
				if friend:isMale() then 
					chance_value = chance_value - 1 
					break 
				end
			end
		end
	end
	local skills = self.player:getVisibleSkillList()
	local drawNCards = self:ImitateResult_DrawNCards(self.player, skills)
	return drawNCards - can_save_card_num + peach_num <= chance_value
end
sgs.draw_cards_system["zishou"] = {
	name = "zishou",
	correct_func = function(self, player)
		local lost = player:getLostHp()
		return lost
	end,
}
--[[
	技能：宗室（锁定技）
	描述：你的手牌上限+X。（X为现存势力数） 
]]--
--[[****************************************************************
	武将：二将成名·马岱（蜀）
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：潜袭
	描述：准备阶段开始时，你可以进行一次判定，然后令一名距离为1的角色不能使用或打出与判定结果颜色相同的手牌，直到回合结束。 
]]--
sgs.ai_playerchosen_intention["qianxi"] = 80
sgs.ai_skill_invoke["qianxi"] = function(self, data)
 	for _,p in ipairs(self.opponents) do
		if self.player:distanceTo(p) == 1 then
			if not p:isKongcheng() then
				return true
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["qianxi"] = function(self, targets)
	local enemies = {}
	local slash = self:getCard("Slash") or sgs.slash
	local tag = self.player:getTag("qianxi")
	local isRed = ( tag:toString() == "red" )
	for _,target in sgs.qlist(targets) do
		if self:isOpponent(target) then
			if not target:isKongcheng() then
				table.insert(enemies, target)
			end
		end
	end
	if #enemies == 1 then
		return enemies[1]
	else
		self:sort(enemies, "defense")
		if isRed then
			for _,enemy in ipairs(enemies) do
				if sgs.getKnownCard(enemy, "Jink", false, "h") > 0 then
					if self:slashIsEffective(slash, enemy) then
						if sgs.isGoodTarget(self, enemy, self.opponents) then 
							return enemy 
						end
					end
				end
			end
			for _,enemy in ipairs(enemies) do
				if sgs.getKnownCard(enemy, "Peach", true, "h") > 0 then
					return enemy
				elseif enemy:hasSkill("jijiu") then 
					return enemy 
				end
			end
			for _,enemy in ipairs(enemies) do
				if sgs.getKnownCard(enemy, "Jink", false, "h") > 0 then
					if self:slashIsEffective(slash, enemy) then 
						return enemy 
					end
				end
			end
		else
			for _,enemy in ipairs(enemies) do
				if enemy:hasSkill("qingguo") then
					if self:slashIsEffective(slash, enemy) then 
						return enemy 
					end
				end
			end
			for _,enemy in ipairs(enemies) do
				if enemy:hasSkill("kanpo") then 
					return enemy 
				end
			end
		end
		for _,enemy in ipairs(enemies) do
			if self:hasSkills("longhun|noslonghun", enemy) then 
				return enemy 
			end
		end
		return enemies[1]
	end
	return targets:first()
end
--[[****************************************************************
	武将：二将成名·王异（魏）
]]--****************************************************************
--[[
	技能：贞烈
	描述：每当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标后，你可以失去1点体力，令此牌对你无效，然后你弃置其一张牌。 
]]--
sgs.ai_skill_invoke["zhenlie"] = function(self, data)
	local use = data:toCardUse()
	local source = use.from
	if source and source:isAlive() then
		if self:amRebel() then
			if self:mayRebel(source) then
				if not source:hasSkill("jueqing") then
					if self.player:getHp() == 1 then
						if self:getAllPeachNum() < 1 then
							return false
						end
					end
				end
			end
		end
	end
	local can_invoke = false
	if self:isOpponent(source) then
		can_invoke = true
	elseif self:isPartner(source) then
		if self:amLoyalist() then
			if not source:hasSkill("jueqing") then
				if self:mayLord(source) then
					if self.player:getHp() == 1 then
						can_invoke = true
					end
				end
			end
		end
	end
	if can_invoke then
		local card = use.card
		if card:isKindOf("Slash") then
			if self:slashIsEffective(card, self.player, source) then
				if self:hasHeavySlashDamage(source, card, self.player) then 
					return true 
				end
				local jink_num = 0 --self:getExpectedJinkNum(use)
				local hasHeart = false
				local jinks = self:getCards("Jink")
				for _, jink in ipairs(jinks) do
					if jink:getSuit() == sgs.Card_Heart then
						hasHeart = true
						break
					end
				end
				local flag = false
				if jink_num == 0 then
					flag = true
				elseif not hasHeart then
					if source:hasSkill("dahe") then
						if self.player:hasFlag("dahe") then
							flag = true
						end
					end
				end
				if not flag then
					local n = self:getCardsNum("Jink")
					if n == 0 then
						flag = true
					elseif n < jink_num then
						flag = true
					end
				end
				if flag then
					if card:isKindOf("NatureSlash") then
						if self.player:isChained() then	
							if not self:isGoodChainTarget(self.player, nil, nil, nil, card) then 
								return true 
							end
						end
					end
					if source:hasSkill("nosqianxi") then
						if source:distanceTo(self.player) == 1 then 
							return true 
						end
					end
					if self:isPartner(source) then
						if self:amLoyalist() then
							if not source:hasSkill("jueqing") then
								if self:mayLord(source) then
									if self.player:getHp() == 1 then 
										return true 
									end
								end
							end
						end
					end
					if not self:doNotDiscard(source) then
						if source:hasSkill("jueqing") then
							return true
						elseif not self:hasSkills(sgs.masochism_skill) then
							if not self.player:hasSkill("tianxiang") then
								return true
							elseif sgs.getKnownCard(self.player, "heart") == 0 then
								return true
							end
						end
					end
				end
			end
		elseif card:isKindOf("AOE") then
			if card:isKindOf("SavageAssault") then
				local MengHuo = self.room:findPlayerBySkillName("huoshou")
				if MengHuo then 
					source = MengHuo 
				end
			end
			if self:trickIsEffective(card, self.player, source) then 
				if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, source) then
					if source:hasSkill("drwushuang") then
						if self.player:getCardCount(true) == 1 then
							if self:hasLoseHandcardEffective() then 
								return true 
							end
						end
					end
					local friend_null = self:getCardsNum("Nullification")
					local others = self.room:getOtherPlayers(self.player)
					for _, p in sgs.qlist(others) do
						if self:isPartner(p) then 
							friend_null = friend_null + sgs.getCardsNum("Nullification", p) 
						elseif self:isOpponent(p) then 
							friend_null = friend_null - sgs.getCardsNum("Nullification", p) 
						end
					end
					if friend_null <= 0 then
						local sj_num = 0
						if card:isKindOf("SavageAssault") then
							sj_num = self:getCardsNum("Slash")
						elseif card:isKindOf("ArcheryAttack") then
							sj_num = self:getCardsNum("Jink")
						end
						if sj_num == 0 then
							if self:isOpponent(source) then
								if source:hasSkill("jueqing") then 
									return not self:doNotDiscard(source) 
								end
							elseif self:Partner(source) then
								if self:amLoyalist() then
									if self:mayLord(source) then
										if self.player:getHp() == 1 then
											if not source:hasSkill("jueqing") then 
												return true 
											end
										end
									end
								end
							end
							if not self:doNotDiscard(source) then
								if source:hasSkill("jueqing") then
									return true
								elseif not self:hasSkills(sgs.masochism_skill) then
									if not self.player:hasSkill("tianxiang") then
										return true
									elseif sgs.getKnownCard(self.player, "heart") == 0 then
										return true
									end
								end
							end
						end
					end
				end
			end
		elseif self:isOpponent(source) then
			if card:isKindOf("FireAttack") then
				if self:trickIsEffective(card, self.player) then
					if self:damageIsEffective(self.player, sgs.DamageStruct_Fire, source) then
						if not self:doNotDiscard(source) then
							if self.player:isChained() then
								if not self:isGoodChainTarget(self.player) then
									return true
								end
							end
							if source:getHandcardNum() > 3 then
								if self.player:hasArmorEffect("Vine") or self.player:getMark("@gale") > 0 then
									if not source:hasSkill("hongyan") then
										return true
									elseif sgs.getKnownCard(self.player, "spade") == 0 then
										return true
									end
								end
							end
						end
					end
				end
			elseif sgs.isKindOf("Snatch|Dismantlement", card) then
				if self:trickIsEffective(card, self.player) then
					if not self.player:isKongcheng() then
						if self:getCardsNum("Peach") == self.player:getHandcardNum() then
							return not self:doNotDiscard(use.from)
						end
					end
				end
			elseif card:isKindOf("Duel") then
				if self:trickIsEffective(card, self.player) then
					if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, source) then
						if not self:doNotDiscard(source) then
							if self:getCardsNum("Slash") == 0 then
								return true
							elseif self:getCardsNum("Slash") < sgs.getCardsNum("Slash", source) then
								return true
							end
						end
					end
				end
			elseif card:isKindOf("TrickCard") then
				if not card:isKindOf("AmazingGrace") then
					if not self:doNotDiscard(source) then
						if self:needToLoseHp(self.player) then
							return true
						end
					end
				end
			end
		end
	end
	return false
end
--[[
	技能：秘计
	描述：结束阶段开始时，若你已受伤，你可以摸一至X张牌（X为你已损失的体力值），然后将相同数量的手牌以任意分配方式交给任意数量的其他角色。 
]]--
sgs.ai_skill_invoke["miji"] = function(self, data)
	if #self.partners_noself > 0 then 
		for _,friend in ipairs(self.partners_noself) do
			if not friend:hasSkill("manjuan") then
				if not self:isLihunTarget(friend) then 
					return true 
				end
			end
		end
	end
	return false
end
sgs.ai_skill_choice["miji_draw"] = function(self, choices)
	return "" .. self.player:getLostHp()
end
sgs.ai_skill_askforyiji["miji"] = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.partners_noself) do
		if not friend:hasSkill("manjuan") then
			if not self:isLihunTarget(friend) then 
				table.insert(available_friends, friend) 
			end
		end
	end
	local cards = {}
	local to_give = {}
	local keep = false
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
		if keep then
			table.insert(to_give, card)
		else
			if sgs.isCard("Jink", card, self.player) then
				keep = true
			elseif sgs.isCard("Analeptic", card, self.player) then
				keep = true
			else
				table.insert(to_give, card)
			end
		end	
	end
	if #to_give > 0 then
		cards = to_give
	end
	self:sortByKeepValue(cards, true)
	local id = cards[1]:getId()
	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend then
		if table.contains(available_friends, friend) then 
			return friend, card:getId() 
		end
	end
	if #available_friends > 0 then
		self:sort(available_friends, "handcard")
		for _, friend in ipairs(available_friends) do
			if not self:needKongcheng(friend, true) then
				return friend, id
			end
		end
		self:sort(available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end
--[[****************************************************************
	武将：二将成名·荀攸（魏）
]]--****************************************************************
sgs.ai_chaofeng.xunyou = 2
--[[
	技能：奇策
	描述：出牌阶段限一次，你可以将你的所有手牌（至少一张）当任意一张非延时锦囊牌使用。 
]]--
--[[
	内容：“奇策技能卡”的卡牌成分
]]--
sgs.card_constituent["QiceCard"] = {
	use_priority = 1.5,
}
--[[
	内容：注册“奇策技能卡”
]]--
sgs.RegistCard("QiceCard")
--[[
	内容：“奇策”技能信息
]]--
sgs.ai_skills["qice"] = {
	name = "qice",
	dummyCard = function(self)
		return sgs.Card_Parse("@QiceCard=.")
	end,
	enabled = function(self, handcards)
		if #handcards > 0 then
			if not self.player:hasUsed("QiceCard") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“奇策技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["QiceCard"] = function(self, card, use)
	local tricks = {
		"savage_assault",
		"archery_attack",
		"ex_nihilo",
		"god_salvation",
		"duel",
	}
	for _,trickname in ipairs(tricks) do
		local trick = sgs[trickname]
		if self.player:isLocked(trick) then
			return 
		end
	end
	local cards = self.player:getHandcards()
	if self.player:getHandcardNum() > 1 then
		if self.player:isWounded() then
			if not self:needToLoseHp(self.player, nil, nil, true, true) then
				for _,peach in sgs.qlist(cards) do
					if peach:isKindOf("Peach") then
						use.card = peach
						return
					end
				end
			end
		end
	end	
	local card_ids = {}
	for _,c in sgs.qlist(cards) do
		local id = c:getId()
		table.insert(card_ids, id)
	end
	local AOEs = {
		"savage_assault",
		"archery_attack",
	}
	local CaoCao = self.room:findPlayerBySkillName("jianxiong") 
	local num = self.player:getHandcardNum()
	local acard = nil
	local qice_trick = nil
	if num < 3 then
		for _,AOEname in ipairs(AOEs) do
			local trick = sgs[AOEname]
			if self:getAoeValue(trick) > 0 then
				local card_str = "@QiceCard="..table.concat(card_ids, "+")..":"..AOEname
				acard = sgs.Card_Parse(card_str)
				qice_trick = trick
				break
			end
		end
		if not acard then
			if self:willUseGodSalvation(sgs.god_salvation) then
				local card_str = "@QiceCard="..table.concat(card_ids, "+")..":god_salvation"
				acard = sgs.Card_Parse(card_str)
				qice_trick = sgs.god_salvation
			end
		end
		if not acard then
			if self:getCardsNum("Jink") == 0 then
				if self:getCardsNum("Peach") == 0 then
					local card_str = "@QiceCard="..table.concat(card_ids, "+")..":ex_nihilo"
					acard = sgs.Card_Parse(card_str)
					qice_trick = sgs.ex_nihilo
				end
			end
		end
	elseif num == 3 then
		for _,AOEname in ipairs(AOEs) do
			local trick = sgs[AOEname]
			if self:getAoeValue(trick) > 0 then
				local card_str = "@QiceCard="..table.concat(card_ids, "+")..":"..AOEname
				acard = sgs.Card_Parse(card_str)
				qice_trick = trick
				break
			end
		end
		if not acard then
			if self.player:isWounded() then
				if self:willUseGodSalvation(sgs.god_salvation) then
					local card_str = "@QiceCard="..table.concat(card_ids, "+")..":god_salvation"
					acard = sgs.Card_Parse(card_str)
					qice_trick = sgs.god_salvation
				end
			end
		end
		if not acard then
			if self:getCardsNum("Jink") == 0 then
				if self:getCardsNum("Peach") == 0 then
					if self:getCardsNum("Analeptic") == 0 then
						if self:getCardsNum("Nullification") == 0 then
							local card_str = "@QiceCard="..table.concat(card_ids, "+")..":ex_nihilo"
							acard = sgs.Card_Parse(card_str)
							qice_trick = sgs.ex_nihilo
						end
					end
				end
			end
		end
	end
	if not acard then
		if CaoCao and self:isPartner(CaoCao) then
			if CaoCao:getHp() > 1 then
				if not self.player:hasSkill("jueqing") then
					if not self:willSkipPlayPhase(CaoCao) then
						for _,AOEname in ipairs(AOEs) do
							local trick = sgs[AOEname]
							if self:getAoeValue(trick) > 0 then
								if self:aoeIsEffective(trick, CaoCao, self.player) then
									local card_str = "@QiceCard="..table.concat(card_ids, "+")..":"..AOEname
									acard = sgs.Card_Parse(card_str)
									qice_trick = trick
									break
								end
							end
						end
					end
				end
			end
		end
	end
	if not acard then
		if num <= 3 then
			if self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 then
				if self:getCardsNum("Analeptic") == 0 and self:getCardsNum("Nullification") == 0 then
					if self.player:isWounded() then
						if self:willUseGodSalvation(sgs.god_salvation) then
							local card_str = "@QiceCard=" ..table.concat(card_ids, "+")..":god_salvation"
							acard = sgs.Card_Parse(card_str)
							qice_trick = sgs.god_salvation
						end
					end
					if not acard then
						local card_str = "@QiceCard="..table.concat(card_ids, "+")..":ex_nihilo"
						acard = sgs.Card_Parse(card_str)
						qice_trick = sgs.ex_nihilo
					end
				end
			end
		end
	end
	if acard then
		self:useTrickCard(qice_trick, use)
		if use.card then
			use.card = acard
		end
	end
end
--[[
	套路：仅使用“奇策技能卡”
]]--
sgs.ai_series["QiceCardOnly"] = {
	name = "QiceCardOnly",
	IQ = 2,
	value = 4,
	priority = 2,
	skills = "qice",
	cards = {
		["QiceCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local qice_skill = sgs.ai_skills["qice"]
		local dummyCard = qice_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["QiceCard"], "QiceCardOnly")
--[[
	技能：智愚
	描述：每当你受到一次伤害后，你可以摸一张牌，然后展示所有手牌，若颜色均相同，伤害来源弃置一张手牌。 
]]--
sgs.ai_skill_invoke["zhiyu"] = function(self, data)
	local damage = data:toDamage()
	local target = nil
	if damage then
		target = damage.from
	end
	local cards = self.player:getCards("h")	
	local first
	local difcolor = 0
	for _,card in sgs.qlist(cards)  do
		if not first then 
			first = card 
		end
		if first:isRed() and card:isBlack() then
			difcolor = 1
			break
		elseif card:isRed() and first:isBlack() then
			difcolor = 1
			break
		end
	end
	if difcolor == 0 and target then
		if self:isPartner(target) then
			if not target:isKongcheng() then
				return false
			end
		elseif self:isOpponent(target) then
			if self:doNotDiscard(target, "h") then
				if not target:isKongcheng() then 
					return false 
				end
			end
			return true
		end
	end
	if self.player:hasSkill("manjuan") then
		if self.player:getPhase() == sgs.Player_NotActive then 
			return false 
		end
	end
	return true
end