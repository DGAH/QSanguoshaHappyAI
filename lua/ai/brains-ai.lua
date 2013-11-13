--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）套路扩充部分
]]--
--[[****************************************************************
	套路：大制衡连弩N杀
]]--****************************************************************
sgs.ai_series["SuperCrossbow"] = {
	name = "SuperCrossbow",
	IQ = 3,
	value = 5,
	priority = 4,
	skills = "zhiheng", --拥有技能“制衡”可发动
	cards = {
		["Others"] = 3, --至少三张手牌可发动
	},
	enabled = function(self)
		sgs.SuperCrossbow_weapon = nil
		sgs.SuperCrossbow_horse = nil
		sgs.SuperCrossbow_Target = nil
		local cards = self.player:getCards("he")
		if cards:length() >= 4 then
			local hasCrossbow = false
			local hasOffensiveHorse = false
			for _,card in sgs.qlist(cards) do
				if card:isKindOf("Crossbow") then
					hasCrossbow = true
					sgs.SuperCrossbow_weapon = card:getId()
				elseif card:isKindOf("OffensiveHorse") then
					hasOffensiveHorse = true
					sgs.SuperCrossbow_horse = card:getId()
				end
				if hasCrossbow and hasOffensiveHorse then
					break
				end
			end
			hasCrossbow = hasCrossbow or self.player:hasSkill("paoxiao")
			if hasCrossbow then
				if #self.opponents > 0 then
					for _,enemy in ipairs(self.opponents) do
						if self.player:canSlash(enemy, sgs.slash, false) then
							if self:slashIsEffective(sgs.slash, enemy, self.player, false) then
								local flag = false
								local hp = enemy:getHp()
								if hp <= 1 then
									flag = true
								else -- hp>1
									if not self:hasSkills("fankui|guixin|zhichi|fenyong", enemy) then	
										flag = true
									end
								end
								if flag then
									sgs.SuperCrossbow_Target = enemy:objectName()
									if self.slashIsDistLimited then
										return true
									else
										local limit = self.slashDistLimit or 1
										if self.player:distanceTo(enemy) <= limit then
											return true
										end
									end
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		local series = {}
		local zhiheng_skill = sgs.ai_skills["zhiheng"]
		local zhiheng_card = zhiheng_skill["dummyCard"](self)
		table.insert(series, zhiheng_card)
		local cards = self.player:getCards("he")
		local count = cards:length()
		for i=1, count, 1 do
			table.insert(series, sgs.slash)
		end
		return series
	end,
	break_condition = function(self)
		local name = sgs.SuperCrossbow_Target
		if name then
			local target = findPlayerByObjectName(self.room, name, true)
			if not target or not target:isAlive() then
				return true
			end
		end
		local weapon = sgs.SuperCrossbow_Weapon
		if weapon then
			local place = self.room:getCardPlace(weapon)
			if place ~= sgs.Player_PlaceEquip then
				local crossbow = sgs.Sanguosha:getCard(weapon)
				table.insert(sgs.ai_current_series, 1, crossbow)
			end
		end
		return false
	end
}
table.insert(sgs.ai_card_actions["ZhihengCard"], "SuperCrossbow")
--制衡
sgs.ai_series_use_func["ZhihengCard"]["SuperCrossbow"] = function(self, card, use)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local weapon = sgs.SuperCrossbow_weapon
	local horse = sgs.SuperCrossbow_horse
	for _,c in sgs.qlist(cards) do
		local id = c:getId()
		if id ~= weapon then
			if id ~= horse then
				if not sgs.isCard("Slash", c, self.player) then
					table.insert(to_discard, id)
				end
			end
		end
	end
	if #to_discard > 0 then
		local card_str = "@ZhihengCard="..table.concat(to_discard, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		return "SUCCESS"
	end
	return "ERROR"
end
--杀
sgs.ai_series_use_func["Slash"]["SuperCrossbow"] = function(self, card, use)
	local target = sgs.SuperCrossbow_Target
	target = findPlayerByObjectName(self.room, target)
	if target then
		local slashes = self:getCards("Slash", "he")
		for _,slash in ipairs(slashes) do
			local id = slash:getEffectiveId()
			if id ~= sgs.SuperCrossbow_weapon then
				if id ~= sgs.SuperCrossbow_Horse then
					use.card = slash
					if use.to then
						use.to:append(target)
					end
					return "SUCCESS"
				end
			end
		end
	end
	return "ERROR"
end
--[[****************************************************************
	套路：驼背狗组合
]]--****************************************************************
sgs.ai_series["TuoBeiGou"] = {
	name = "TuoBeiGou",
	IQ = 5,
	value = 9,
	priority = 5,
	skills = "nosrende",
	cards = {
		["NosRendeCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		if self.player:hasSkill("jueqing|wansha") then
			return false
		end
		sgs.TuoBeiGou_Huatuo = nil
		sgs.TuoBeiGou_Liubei = nil
		sgs.TuoBeiGou_Xunyu = nil
		sgs.TuoBeiGou_AttackCard = nil
		for _,friend in ipairs(self.partners_noself) do
			if friend:hasSkill("jijiu") then
				sgs.TuoBeiGou_Huatuo = friend
			end
			if friend:hasSkill("jieming") then
				sgs.TuoBeiGou_Xunyu = friend
			end
		end
		if sgs.TuoBeiGou_Huatuo then
			if sgs.TuoBeiGou_Xunyu then
				local handcards = self.player:getHandcards()
				for _,card in sgs.qlist(handcards) do
					if self:TuoBeiGou_canAttackXunyu(card) then
						sgs.TuoBeiGou_AttackCard = card:getId()
						break
					end
				end
				if sgs.TuoBeiGou_AttackCard then
					sgs.TuoBeiGou_Liubei = self.player
					return true
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		local rende_skill = sgs.ai_skills["nosrende"]
		local rende_card = rende_skill["dummyCard"](self)
		local series = {}
		for i=1, #handcards, 1 do
			table.insert(series, rende_card)
		end
		return series
	end,
	break_condition = function(self)
		if self.player:getHandcardNum() == 1 then
			local cards = self.player:getHandcards()
			local card = cards:first()
			if self:TuoBeiGou_canAttackXunyu(card) then
				table.insert(sgs.ai_current_series, 1, card)
			end
		elseif self.player:isKongcheng() then
			return true
		end
		return false
	end,
}
table.insert(sgs.ai_card_actions["NosRendeCard"], "TuoBeiGou")
--仁德
sgs.ai_series_use_func["NosRendeCard"]["TuoBeiGou"] = function(self, card, use)
	local cards = self.player:getHandcards()
	local reds = {}
	local blacks = {}
	for _,c in sgs.qlist(cards) do
		local id = c:getId()
		if id ~= sgs.TuoBeiGou_AttackCard then
			if c:isRed() then
				table.insert(reds, id)
			else
				table.insert(blacks, id)
			end
		end
	end
	if #reds > 0 then
		local card_str = "@NosRendeCard="..table.concat(reds, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(sgs.TuoBeiGou_Huatuo)
		end
		return "SUCCESS"
	end
	if #blacks > 0 then
		local card_str = "@NosRendeCard="..table.concat(blacks, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(sgs.TuoBeiGou_Xunyu)
		end
		return "SUCCESS"
	end
	return "NOTHING"
end
sgs.ai_series_playerchosen["TuoBeiGou"] = {
	--节命
	["jieming"] = function(self, targets)
		for _,target in sgs.qlist(targets) do
			if target:objectName() == sgs.TuoBeiGou_Liubei:objectName() then
				return target
			end
		end
		return targets:first()
	end
}
--急救
--[[
	功能：判断卡牌是否可以攻击到荀彧
	参数：card（Card类型）
	结果：boolean类型，表示是否可以攻击到
]]--
function SmartAI:TuoBeiGou_canAttackXunyu(card)
	local target = sgs.TuoBeiGou_Xunyu
	local source = sgs.TuoBeiGou_Liubei
	if target and source then 
		local flag = false
		if sgs.isCard("Duel", card, source) then
			flag = true
		elseif sgs.isCard("AOE", card, source) then
			flag = true
		elseif sgs.isCard("Slash", card, source) then
			if source:canSlash(target, card) then
				flag = true
			end
		end
		if flag then
			if not source:isProhibited(target, card) then
				if self:damageIsEffective(target, sgs.DamageStruct_Normal, source) then
					return true
				end
			end
		end
	end
	return false
end
--[[****************************************************************
	套路：大制衡双雄带走
]]--****************************************************************
sgs.ai_series["SuperDuels"] = {
	name = "SuperDuels",
	IQ = 3,
	value = 4,
	priority = 5,
	skills = "zhiheng+shuangxiong",
	cards = {
		["ZhihengCard"] = 1,
		["shuangxiong>>Duel"] = 1,
		["Others"] = 3,
	},
	enabled = function(self)
		sgs.SuperDuels_Victim = nil
		if self.player:getMark("shuangxiong") > 0 then
			if #self.opponents > 0 then
				for _,enemy in ipairs(self.opponents) do
					if not self:hasSkills("jilei|fenyong|zhichi", enemy) then
						if self:trickIsEffective(sgs.duel, enemy, self.player) then
							sgs.SuperDuels_Victim = enemy
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
		local zhiheng_card = zhiheng_skill["dummyCard"](self)
		local shuangxiong_skill = sgs.ai_skills["shuangxiong"]
		local duel_card = shuangxiong_skill["dummyCard"](self)
		duel_card:setFlags("isDummy")
		local series = {zhiheng_card}
		local count = self.player:getCardCount(true)
		for i=1, count, 1 do
			table.insert(series, duel_card)
		end
		return series
	end,
	break_condition = function(self)
		if self.player:isKongcheng() then
			return true
		end
		local target = sgs.SuperDuels_Victim
		if target then
			if target:isAlive() then
				if self:trickIsEffective(sgs.duel, target, self.player) then
					return false
				end
			end
		end
		sgs.SuperDuels_Victim = nil
		return true
	end,
}
table.insert(sgs.ai_card_actions["ZhihengCard"], "SuperDuels")
--制衡
sgs.ai_series_use_func["ZhihengCard"]["SuperDuels"] = function(self, card, use)
	local mark = self.player:getMark("shuangxiong")
	local to_discard = {}
	local cards = self.player:getCards("h")
	local equips = self.player:getCards("e")
	for _,e in sgs.qlist(equips) do
		table.insert(to_discard, e:getId())
	end
	for _,c in sgs.qlist(cards) do
		if mark == 1 then
			if c:isRed() then
				table.insert(to_discard, c:getId())
			end
		elseif mark == 2 then
			if c:isBlack() then
				table.insert(to_discard, c:getId())
			end
		end
	end
	if #to_discard > 0 then
		local card_str = "@ZhihengCard="..table.concat(to_discard, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		return "SUCCESS"
	end
	return "NOTHING"
end
--[[****************************************************************
	套路：火攻破空城
]]--****************************************************************
sgs.ai_series["FireAttackVSKongcheng"] = {
	name = "FireAttackVSKongcheng",
	IQ = 4,
	value = 2,
	priority = 4,
	cards = {
		["FireAttack"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		local can_use = false
		for _,enemy in ipairs(self.opponents) do
			if enemy:isKongcheng() then
				if not enemy:hasSkill("manjuan") then
					if self:trickIsEffective(sgs.fire_attack, enemy, self.player) then
						can_use = true
					end
				end
			end
		end
		sgs.FireAttackVSKongcheng_case = nil
		if can_use then
			if self.player:hasSkill("nosrende") then
				sgs.FireAttackVSKongcheng_case = 1
			elseif self.player:hasSkill("rende") then
				if not self.player:hasUsed("RendeCard") then
					sgs.FireAttackVSKongcheng_case = 2
				end
			elseif self:getCardsNum("AmazingGrace") > 0 then
				sgs.FireAttackVSKongcheng_case = 3
			end
		end
		if not sgs.FireAttackVSKongcheng_case then
			return false
		end
		local handcards = self.player:getHandcards()
		if sgs.FireAttackVSKongcheng_case < 3 then
			local suits = {
				["spade"] = 0,
				["heart"] = 0,
				["club"] = 0,
				["diamond"] = 0,
			}
			local fa_suits = {
				["spade"] = false,
				["heart"] = false,
				["club"] = false,
				["diamond"] = false,
			}
			for _,card in sgs.qlist(handcards) do
				local suit = card:getSuitString()
				suits[suit] = suits[suit] + 1
				if not fa_suits[suit] then
					if sgs.isCard("FireAttack", card, self.player) then
						fa_suits[suit] = true
					end
				end
			end
			for suit, count in pairs(suits) do
				if fa_suits[suit] then
					count = count - 1
				end
				if count > 1 then
					return true
				end
			end
		elseif sgs.FireAttackVSKongcheng_case == 3 then
			local suits = {}
			local count = 0
			for _,card in sgs.qlist(handcards) do
				local suit = card:getSuitString()
				if not suits[suit] then
					suits[suit] = true
					count = count + 1
				end
			end
			if count > 2 then
				return true
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		local case = sgs.FireAttackVSKongcheng_case
		if case then
			if case == 1 then
				local rende_card = sgs.ai_skills["nosrende"]["dummyCard"](self)
				return {rende_card, sgs.fire_attack}
			elseif case == 2 then
				local rende_card = sgs.ai_skills["rende"]["dummyCard"](self)
				return {rende_card, sgs.fire_attack}
			elseif case == 3 then
				return {sgs.amazing_grace, sgs.fire_attack}
			end
		end
		return {}
	end,
	break_condition = function(self)
		local target = sgs.FireAttackVSKongcheng_target
		if target then
			if target:isDead() then
				return true
			elseif target:getHandcardNum() ~= 1 then
				return true
			end
		end
		return false
	end,
}
table.insert(sgs.ai_card_actions["FireAttack"], "FireAttackVSKongcheng")
--仁德
sgs.ai_series_use_func["NosRendeCard"]["FireAttackVSKongcheng"] = function(self, card, use)
	assert(sgs.FireAttackVSKongcheng_case == 1)
	local targets = {}
	for _,enemy in ipairs(self.opponents) do
		if enemy:isKongcheng() then
			if not enemy:hasSkill("manjuan") then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		local handcards = self.player:getHandcards()
		local cards = {
			["spade"] = {},
			["heart"] = {},
			["club"] = {},
			["diamond"] = {},
		}
		for _,c in sgs.qlist(handcards) do
			local suit = c:getSuitString()
			table.insert(cards[suit], c)
		end
		local usecards = {}
		for suit, suitcards in pairs(cards) do
			local count = #suitcards
			if count == 2 then
				for _,fa in ipairs(suitcards) do
					if sgs.isCard("FireAttack", fa, self.player) then
						count = count - 1
						break
					end
				end
			end
			if count >= 2 then
				for _,c in ipairs(suitcards) do
					table.insert(usecards, c)
				end
			end
		end
		if #usecards > 0 then
			sgs.FireAttackVSKongcheng_FireAttack = nil
			sgs.FireAttackVSKongcheng_target = nil
			self:sortByKeepValue(usecards)
			for _,enemy in ipairs(targets) do
				for _,c in ipairs(usecards) do
					local used = false
					if not sgs.FireAttackVSKongcheng_FireAttack then
						if sgs.isCard("FireAttack", c, self.player) then
							local card_str = self:getCardId("FireAttack", self.player, c)
							sgs.FireAttackVSKongcheng_FireAttack = sgs.Card_Parse(card_str)
							used = true
							if use.card then
								return 
							end
						end
					end
					if not used and not use.card then
						if not sgs.isCard("Peach", c, enemy) then
							if not sgs.isCard("Analeptic", c, enemy) then
								if not sgs.isCard("Nullification", c, enemy) then
									sgs.FireAttackVSKongcheng_target = enemy
									local card_str = "@NosRendeCard="..c:getId().."->"..enemy:objectName()
									local acard = sgs.Card_Parse(card_str)
									use.card = acard
									if use.to then
										use.to:append(enemy)
									end
									if sgs.FireAttackVSKongcheng_FireAttack then
										return 
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
--仁德
sgs.ai_series_use_func["RendeCard"]["FireAttackVSKongcheng"] = function(self, card, use)
	assert(sgs.FireAttackVSKongcheng_case == 2)
	local targets = {}
	for _,enemy in ipairs(self.opponents) do
		if enemy:isKongcheng() then
			if not enemy:hasSkill("manjuan") then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		local handcards = self.player:getHandcards()
		local cards = {
			["spade"] = {},
			["heart"] = {},
			["club"] = {},
			["diamond"] = {},
		}
		for _,c in sgs.qlist(handcards) do
			local suit = c:getSuitString()
			table.insert(cards[suit], c)
		end
		local usecards = {}
		for suit, suitcards in pairs(cards) do
			local count = #suitcards
			if count == 2 then
				for _,fa in ipairs(suitcards) do
					if sgs.isCard("FireAttack", fa, self.player) then
						count = count - 1
						break
					end
				end
			end
			if count >= 2 then
				for _,c in ipairs(suitcards) do
					table.insert(usecards, c)
				end
			end
		end
		if #usecards > 0 then
			self:sortByKeepValue(usecards)
			sgs.FireAttackVSKongcheng_FireAttack = nil
			sgs.FireAttackVSKongcheng_target = nil
			for _,enemy in ipairs(targets) do
				for _,c in ipairs(usecards) do
					local used = false
					if not sgs.FireAttackVSKongcheng_FireAttack then
						if sgs.isCard("FireAttack", c, self.player) then
							local card_str = self:getCardId("FireAttack", self.player, c)
							sgs.FireAttackVSKongcheng_FireAttack = sgs.Card_Parse(card_str)
							used = true
							if use.card then
								return 
							end
						end
					end
					if not used and not use.card then
						if not sgs.isCard("Peach", c, enemy) then
							if not sgs.isCard("Analeptic", c, enemy) then
								if not sgs.isCard("Nullification", c, enemy) then
									sgs.FireAttackVSKongcheng_target = enemy
									local card_str = "@RendeCard="..c:getId().."->"..enemy:objectName()
									local acard = sgs.Card_Parse(card_str)
									use.card = acard
									if use.to then
										use.to:append(enemy)
									end
									if sgs.FireAttackVSKongcheng_FireAttack then
										return 
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
--五谷丰登
sgs.ai_series_use_func["AmazingGrace"]["FireAttackVSKongcheng"] = function(self, card, use)
	assert(sgs.FireAttackVSKongcheng_case == 3)
	local targets = {}
	for _,enemy in ipairs(self.opponents) do
		if enemy:isKongcheng() then
			if not enemy:hasSkill("manjuan") then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		local handcards = self.player:getHandcards()
		local cards = {
			["spade"] = {},
			["heart"] = {},
			["club"] = {},
			["diamond"] = {},
		}
		for _,c in sgs.qlist(handcards) do
			local suit = c:getSuitString()
			table.insert(cards[suit], c)
		end
		local counts = {}
		local gotAG = nil
		local gotFA = nil
		for suit, suitcards in pairs(cards) do
			counts[suit] = #suitcards
			for _,c in ipairs(suitcards) do
				if not gotAG then
					if counts[suit] > 1 then
						if sgs.isCard("AmazingGrace", c, self.player) then
							local card_str = self:getCardId("AmazingGrace", self.player, c)
							gotAG = sgs.Card_Parse(card_str)
							for _,target in ipairs(targets) do
								if self:AG_IsEffective(gotAG, target, self.player) then
									sgs.FireAttackVSKongcheng_target = target
									break
								end
							end
							if sgs.FireAttackVSKongcheng_target then
								counts[suit] = counts[suit] - 1
							else
								gotAG = nil
							end
						end
					end
				end
				if not gotFA then
					if counts[suit] > 1 then
						if sgs.isCard("FireAttack", c, self.player) then
							local card_str = self:getCardId("FireAttack", self.player, c)
							gotFA = sgs.Card_Parse(card_str)
							counts[suit] = counts[suit] - 1
						end
					end
				end
			end
		end
		if gotAG and gotFA then
			sgs.FireAttackVSKongcheng_FireAttack = gotFA
			use.card = gotAG
		end
	end
end
--火攻
sgs.ai_series_use_func["FireAttack"]["FireAttackVSKongcheng"] = function(self, card, use)
	assert(sgs.FireAttackVSKongcheng_FireAttack)
	assert(sgs.FireAttackVSKongcheng_target)
	use.card = sgs.FireAttackVSKongcheng_FireAttack
	if use.to then
		use.to:append(sgs.FireAttackVSKongcheng_target)
	end
	sgs.FireAttackVSKongcheng_FireAttack = nil
	sgs.FireAttackVSKongcheng_target = nil
end
--[[****************************************************************
	套路：
]]--****************************************************************