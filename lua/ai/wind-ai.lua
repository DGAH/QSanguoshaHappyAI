--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）风扩展包部分
]]--
--[[****************************************************************
	武将：风·夏侯渊（魏）
]]--****************************************************************
--[[
	技能：神速
	描述：你可以选择一至两项：1.跳过你的判定阶段和摸牌阶段。2.跳过你的出牌阶段并弃置一张装备牌。你每选择一项，视为使用一张【杀】（无距离限制）。 
]]--
--[[
	内容：“神速卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShensuCard"] = 80
sgs.ai_skill_use["@@shensu1"] = function(self, prompt)
	if #self.opponents == 0 then
		return "."
	end
	if self.player:containsTrick("lightning") then
		local judges = self.player:getCards("j")
		if judges:length() == 1 then
			if self:hasWizard(self.partners) then
				if not self:hasWizard(self.opponents) then
					return "."
				end
			end
		end
	end
	if self:needBear() then
		return "."
	end
	local hp = self.player:getHp()
	local num = self.player:getHandcardNum()
	local defense = sgs.getDefense(self.player)
	self:sort(self.opponents, "defense")
	local enemy_defense_table = {}
	local effective_table = {}
	for _,enemy in ipairs(self.opponents) do
		local name = enemy:objectName()
		local enemy_defense = sgs.getDefense(enemy)
		enemy_defense_table[name] = enemy_defense
		local effective = false
		if self:slashIsEffective(sgs.slash, enemy) then
			if sgs.isGoodTarget(self, enemy, self.opponents) then
				effective = true
			end
		end
		effective_table[name] = effective
		if enemy_defense < 6 then
			if effective then
				if self.player:canSlash(enemy, sgs.slash, false) then 
					if not self:slashIsProhibited(enemy, self.player, sgs.slash) then 
						local card_str = "@ShensuCard=.->"..name
						return card_str
					end
				end
			end
		end
	end
	if hp - num >= 2 then
		return "."
	end
	if defense < 6 then
		return "."
	end
	for _,enemy in ipairs(self.opponents) do
		local name = enemy:objectName()
		local enemy_defense = enemy_defense_table[name] or sgs.getDefense(enemy)
		local effective = effective_table[name] or true
		if effective then
			if enemy_defense < 8 then
				if self.player:canSlash(enemy, sgs.slash, false) then 
					if not self:slashIsProhibited(enemy, self.player, sgs.slash) then 
						local card_str = "@ShensuCard=.->"..name
						return card_str
					end
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_use["@@shensu2"] = function(self, prompt)
	self:updatePlayers()
	self:sort(self.opponents, "defenseSlash")
	local cards = self.player:getCards("he")
	local equips = {}
	local hasType = {0, 0, 0, 0}
	local equip = nil
	if self:needToThrowArmor() then
		equip = self.player:getArmor()
	end
	if not equip then
		for _,card in sgs.qlist(cards) do
			if card:isKindOf("EquipCard") then
				table.insert(equips, equip)
			end
		end
		if #equips > 0 then
			for _,card in ipairs(equips) do
				local type = sgs.ai_get_cardType(card)
				hasType[type] = hasType[type] + 1
			end
			for _,card in ipairs(equips) do
				local type = sgs.ai_get_cardType(card)
				if hasType[type] > 1 then
					equip = card
					break
				end
			end
			if not equip then
				for _,card in ipairs(equips) do
					if sgs.ai_get_cardType(card) > 3 then
						equip = card
						break
					end
				end
			end
			if not equip then
				for _,card in ipairs(cards) do
					if not card:isKindOf("Armor") then
						equip = card
						break
					end
				end
			end
		end
	end
	if equip then
		local effectslash, best_target, target, throw_weapon
		local min_defense = 6
		local weapon = self.player:getWeapon()
		if weapon then
			if equip:getId() == weapon:getId() then
				if equip:isKindOf("Fan") or equip:isKindOf("QinggangSword") then 
					throw_weapon = true 
				end
			end
		end
		local hp = self.player:getHp()
		local num = self.player:getHandcardNum()
		local delt = hp - num
		for _,enemy in ipairs(self.opponents) do
			if self.player:canSlash(enemy, sgs.slash, false) then
				if not self:slashIsProhibited(enemy) then
					local defense = sgs.getDefense(enemy)
					local isEffective = false
					if self:slashIsEffective(sgs.slash, enemy) then
						if sgs.isGoodTarget(self, enemy, self.opponents) then
							isEffective = true
						end
					end
					if isEffective then
						local flag = true
						if throw_weapon then
							if enemy:hasArmorEffect("Vine") then
								if not self.player:hasSkill("zonghuo") then
									flag = false
								end
							end
						end
						if flag then
							if enemy:getHp() == 1 then
								if sgs.getCardsNum("Jink", enemy) == 0 then 
									best_target = enemy 
									break 
								end
							end
							if defense < min_defense then
								best_target = enemy
								min_defense = defense
							end
							target = enemy
						end
					end
				end
			end
			if delt < 0 then 
				return "." 
			end
		end
		if best_target then 
			return "@ShensuCard="..equip:getEffectiveId().."->"..best_target:objectName() 
		end
		if target then 
			return "@ShensuCard="..equip:getEffectiveId().."->"..target:objectName() 
		end
	end
	return "."
end
sgs.shensu_keep_value = sgs.xiaoji_keep_value
--[[
	内容：“神速”卡牌需求
]]--
sgs.card_need_system["shensu"] = function(self, card, player)
	if card:getTypeId() == sgs.Card_TypeEquip then
		return sgs.getKnownCard(player, "EquipCard", false) < 2
	end
	return false
end
--[[****************************************************************
	武将：风·曹仁（魏）
]]--****************************************************************
--[[
	技能：据守
	描述：结束阶段开始时，你可以摸三张牌，然后将你的武将牌翻面。 
]]--
sgs.ai_skill_invoke["jushou"] = function(self, data)
	if self.player:faceUp() then
		for _,friend in ipairs(self.partners_noself) do
			if self:hasSkills("fangzhu|jilve", friend) then
				return true
			elseif friend:hasSkill("junxing") then
				if friend:faceUp() then
					if not friend:isKongcheng() then
						return true
					end
				end
			end
		end
		return self:isWeak()
	end
	return true
end
--[[****************************************************************
	武将：风·黄忠（蜀）
]]--****************************************************************
sgs.ai_chaofeng.huangzhong = 1
--[[
	技能：烈弓
	描述：每当你于出牌阶段内指定【杀】的目标后，若目标角色的手牌数大于或等于你的体力值，或目标角色的手牌数小于或等于你的攻击范围，你可以令该角色不能使用【闪】响应此【杀】。 
]]--
sgs.ai_skill_invoke["liegong"] = function(self, data)
	local target = data:toPlayer()
	return not self:isPartner(target)
end
--[[
	内容：“烈弓”卡牌需求
]]--
sgs.card_need_system["liegong"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		if sgs.getKnownCard(player, "Slash", true) == 0 then
			return true
		end
	end
	if card:isKindOf("Weapon") then
		if not player:getWeapon() then
			if sgs.getKnownCard(player, "Weapon", false) == 0 then
				return true
			end
		end
	end
	return false
end
--[[****************************************************************
	武将：风·魏延（蜀）
]]--****************************************************************
sgs.ai_chaofeng.weiyan = -2
--[[
	技能：狂骨（锁定技）
	描述：每当你对一名距离1以内角色造成1点伤害后，你回复1点体力。 
]]--
--[[
	内容：“狂骨”卡牌需求
]]--
sgs.card_need_system["kuanggu"] = function(self, card, player)
	if card:isKindOf("OffensiveHorse") then
		if not player:getOffensiveHorse() then
			return sgs.getKnownCard(player, "OffensiveHorse", false) == 0
		end
	end
	return false
end
--[[****************************************************************
	武将：风·小乔（吴）
]]--****************************************************************
--[[
	技能：天香
	描述：每当你受到伤害时，你可以弃置一张♥手牌并选择一名其他角色，将此伤害转移给该角色，然后其在伤害结算后摸X张牌（X为其当前已损失的体力值）。 
]]--
--[[
	内容：“天香卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TianxiangCard"] = function(self, card, source, targets)
	local target = targets[1]
	if self:invokeDamagedEffect(target) then
		return 
	elseif self:needToLoseHp(target) then 
		return
	end
	local intention = 10
	if target:getHp() >= 2 then
		if self:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu", target) then
			intention = -10
		end
	elseif target:getHandcardNum() < 3 then
		if target:hasSkill("nosrende") then
			intention = -10
		elseif target:hasSkill("rende") then
			if not target:hasUsed("RendeCard") then
				intention = -10
			end
		end
	elseif target:hasSkill("buqu") then
		intention = -10
	end
	sgs.updateIntention(source, target, intention)
end
sgs.ai_skill_use["@@tianxiang"] = function(self, data)
	local damage = nil
	if data and data == "@tianxiang-card" then
		local tag = self.player:getTag("TianxiangDamage")
		damage = tag:toDamage()
	else
		damage = data
	end
	if damage then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local card_id = nil
		for _,heart in ipairs(cards) do
			local suit = heart:getSuit()
			local isHeart = false
			if suit == sgs.Card_Heart then
				isHeart = true
			elseif suit == sgs.Card_Spade then
				if self.player:hasSkill("hongyan") then
					isHeart = true
				end
			end
			if isHeart then
				if not heart:isKindOf("Peach") then
					card_id = heart:getId()
					break
				end
			end
		end
		if card_id then
			self:sort(self.opponents, "hp")
			local current = self.room:getCurrent()
			local source = damage.from or current
			for _,enemy in ipairs(self.opponents) do
				if enemy:isAlive() then
					local can_use = false
					local hp = enemy:getHp()
					if hp <= damage.damage then
						if enemy:getHandcardNum() <= 2 then
							can_use = true
						elseif enemy:containsTrick("indulgence") then
							can_use = true
						elseif self:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng", enemy) then
							can_use = true
						end
						if can_use then
							if self:canAttack(enemy, source, damage.nature) then
								if enemy:hasSkill("wuyan") then
									if damage.card and damage.card:isKindOf("TrickCard") then
										can_use = false
									end
								end
								if can_use then
									local card_str = "@TianxiangCard="..card_id.."->"..enemy:objectName() 
									return card_str
								end
							end
						end
					end
				end
			end
			for _,friend in ipairs(self.partners_noself) do
				if friend:isAlive() then
					local lost = friend:getLostHp()
					if lost + damage.damage > 1 then
						local can_use = true
						if friend:isChained() then
							if damage.nature ~= sgs.DamageStruct_Normal then
								if self:isGoodChainTarget(friend, damage.from, damage.nature, damage.damage, damage.card) then
									can_use = false
								end
							end
						end
						if can_use then
							local hp = friend:getHp()
							if hp >= 2 then
								if damage.damage < 2 then
									can_use = false
									if self:hasSkills("yiji|zaiqi|yinghun|jianxiong|fangzhu", friend) then
										can_use = true
									elseif self:hasSkills("shuangxiong|buqu", friend) then
										can_use = true
									elseif self:invokeDamagedEffect(friend, source) then
										can_use = true
									elseif self:needToLoseHp(friend, source, nil, true) then
										can_use = true
									elseif friend:hasSkill("rende") then
										if friend:getHandcardNum() < 3 then
											can_use = true
										end
									end
									if can_use then
										local card_str = "@TianxiangCard="..card_id.."->"..friend:objectName()
										return card_str
									end
								end
							end
							if friend:hasSkill("wuyan") then
								if damage.card and damage.card:isKindOf("TrickCard") then
									if friend:getLostHp() > 1 then
										local card_str = "@TianxiangCard="..card_id.."->"..friend:objectName()
										return card_str
									end
								end
							end
							if friend:hasSkill("buqu") then
								local card_str = "@TianxiangCard="..card_id.."->"..friend:objectName()
								return card_str
							end
						end
					end
				end
			end
			for _,enemy in ipairs(self.opponents) do
				if enemy:isAlive() then
					local can_use = false
					local lost = enemy:getLostHp()
					if lost <= 1 then
						can_use = true
					elseif damage.damage > 1 then
						can_use = true
					end
					if can_use then
						can_use = false
						if enemy:getHandcardNum() <= 2 then
							can_use = true
						elseif enemy:containsTrick("indulgence") then
							can_use = true
						elseif self:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng", enemy) then
							can_use = true
						end
						if can_use then
							if self:canAttack(enemy, source, damage.nature) then
								if enemy:hasSkill("wuyan") then
									if damage.card and damage.card:isKindOf("TrickCard") then
										can_use = false
									end
								end
								if can_use then
									local card_str = "@TianxiangCard="..card_id.."->"..enemy:objectName() 
									return card_str
								end
							end
						end
					end
				end
			end
			for index = #self.opponents, 1, -1 do
				local enemy = self.opponents[index]
				if enemy:isAlive() then
					if not enemy:isWounded() then
						if not self:hasSkills(sgs.masochism_skill, enemy) then
							if self:canAttack(enemy, source, damage.nature) then
								local can_use = false
								if self:isWeak() then
									can_use = true
								else
									can_use = true
									if enemy:hasSkill("wuyan") then
										if damage.card and damage.card:isKindOf("TrickCard") then
											if enemy:getLostHp() > 0 then
												can_use = false
											end
										end
									end
								end
								if can_use then
									local card_str = "@TianxiangCard="..card_id.."->"..enemy:objectName()
									return card_str
								end
							end
						end
					end
				end
			end
		else
			return "."
		end
	else
		self.room:writeToConsole(debug.traceback()) 
	end
	return "." 
end
--[[
	内容：“天香”卡牌需求
]]--
sgs.card_need_system["tianxiang"] = function(self, card, player)
	local suit = card:getSuit()
	local isHeart = false
	if suit == sgs.Card_Heart then
		isHeart = true
	elseif suit == sgs.Card_Spade then
		if player:hasSkill("hongyan") then
			isHeart = true
		end
	end
	if isHeart then
		local heartNum = sgs.getKnownCard(player, "heart", false)
		if player:hasSkill("hongyan") then
			heartNum = heartNum + sgs.getKnownCard(player, "spade", false)
		end
		return heartNum < 2
	end
	return false
end
sgs.slash_prohibit_system["tianxiang"] = {
	name = "tianxiang",
	reason = "tianxiang",
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
		if source:hasFlag("NosJiefanUsed") then 
			return false 
		end
		--友方
		if self:isFriend(target, source) then 
			return false 
		end
		--免伤
		if self:cannotBeHurt(target, 1, source) then
			return true
		end
		return false
	end
}
sgs.damage_avoid_system["tianxiang"] = {
	reason = "tianxiang",
	judge_func = function(self, target, damage, source)
		return false
	end
}
--[[
	技能：红颜（锁定技）
	描述：你的♠牌视为♥牌。 
]]--
sgs.ai_filterskill_filter["hongyan"] = function(card, player, place)
	if card:getSuit() == sgs.Card_Spade then
		local name = card:objectName()
		local point = card:getNumber()
		local id = card:getId()
		local card_str = string.format("%s:hongyan[heart:%s]=%d", name, point, id)
		return card_str
	end
end
sgs.trick_invalid_system["lightning"] = {
	name = "lightning",
	reason = "wuyan|hongyan",
	judge_func = function(card, target, source)
		if card:isKindOf("Lightning") then
			if self:hasSkills(reason, target) then
				return true
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：风·周泰（吴）
]]--****************************************************************
sgs.ai_chaofeng.zhoutai = -4
--[[
	技能：不屈
	描述：每当你扣减1点体力后，若你当前的体力值为0，你可以从牌堆顶亮出一张牌置于你的武将牌上。若此牌的点数与你武将牌上已有的任何一张牌都不同，你不会死亡。若出现相同点数的牌，你进入濒死状态。 
]]--
sgs.ai_skill_askforag["buqu"] = function(self, card_ids)
	for i, id in ipairs(card_ids) do
		for j, id2 in ipairs(card_ids) do
			if i ~= j then
				local cardA = sgs.Sanguosha:getCard(id)
				local cardB = sgs.Sanguosha:getCard(id2)
				if cardA:getNumber() == cardB:getNumber() then
					return card_id
				end
			end
		end
	end
	return card_ids[1]
end
sgs.ai_skill_invoke["buqu"] = function(self, data)
	if #self.opponents == 1 then
		if self.opponents[1]:hasSkill("guhuo") then
			return false
		end
	end
	return true
end
--[[****************************************************************
	武将：风·张角（群）
]]--****************************************************************
sgs.ai_chaofeng.zhangjiao = 4
--[[
	技能：鬼道
	描述：每当一名角色的判定牌生效前，你可以打出一张黑色牌替换之。 
]]--
sgs.ai_skill_cardask["@guidao-card"] = function(self, data)
	if not self.player:isNude() then
		local judge = data:toJudge()
		local cards = self.player:getCards("he")
		local blacks = {}
		for _,black in sgs.qlist(cards) do
			if black:isBlack() then
				if not black:hasFlag("using") then
					table.insert(blacks, black)
				end
			end
		end
		if #blacks > 0 then
			local needRetrial = self:needRetrial(judge)
			local card_id = self:getRetrialCardId(blacks, judge)
			local judge_name = sgs.getCardName(judge.card)
			local judge_value = sgs.getCardValue(judge_name, "use_value")
			if card_id == -1 then
				if needRetrial then
					if judge.reason ~= "beige" then
						if self:needToThrowArmor() then 
							local armor = self.player:getArmor()
							return "$" .. armor:getEffectiveId() 
						end
						self:sortByUseValue(blacks, true)
						local use_card = blacks[1]
						local use_name = sgs.getCardName(use_card)
						local use_value = sgs.getCardValue(use_name, "use_value")
						if judge_value > use_value then
							return "$" .. use_card:getId() 
						end
					end
				end
			else
				if needRetrial then
					return "$" .. card_id
				else
					local use_card = sgs.Sanguosha:getCard(card_id)
					local use_name = sgs.getCardName(use_card)
					local use_value = sgs.getCardValue(use_name, "use_value")
					if judge_value > use_value then
						return "$" .. card_id
					end
				end
			end
		end
	end
	return "."
end
--[[
	内容：“鬼道”卡牌需求
]]--
sgs.card_need_system["guidao"] = function(self, card, player)
	if self:getFinalRetrial(player) == 1 then
		local alives = self.room:getAlivePlayers()
		local suit = card:getSuit()
		for _,p in sgs.qlist(alives) do
			if suit == sgs.Card_Spade then
				if player:containsTrick("lightning") then
					if not player:containsTrick("YanxiaoCard") then
						if not self:hasSkills("hongyan|wuyan") then
							if card:getNumber() >= 2 then
								if card:getNumber() <= 9 then
									return true
								end
							end
						end
					end
				end
			elseif suit == sgs.Card_Club then
				if self:isPartner(p) then
					if self:willSkipDrawPhase(p) then
						return self:hasSuit("club", true, player)
					end
				end
			end
		end
	end
end
sgs.ai_wizard_system["guidao"] = {
	name = "guidao",
	skill = "guidao",
	retrial_enabled = function(self, source, target)
		if source:hasSkill("guidao") then
			if source:isKongcheng() then
				local equips = source:getEquips()
				for _,equip in sgs.qlist(equips) do
					if equip:isBlack() then
						return true
					end
				end
			else
				return true
			end
		end
		return false
	end,
}
--[[
	技能：雷击
	描述：每当你使用【闪】选择目标后或打出【闪】，你可以令一名角色进行一次判定：若判定结果为♠，你对该角色造成2点雷电伤害。 
]]--
--[[
	功能：寻找雷击的目标
	参数：source（ServerPlayer类型，表示可能发动雷击的角色）
		value（number类型）
	结果：ServerPlayer类型，表示雷击目标
]]--
function SmartAI:findLeijiTarget(source, value)
	local function getHitValue(target)
		local v = 100
		if self:damageIsEffective(target, sgs.DamageStruct_Thunder, source) then
			if target:hasSkill("hongyan") then
				return 99
			else
				if self:cannotBeHurt(target, 2, source) then
					return 100
				elseif self:objectiveLevel(target) < 3 then
					return 100
				elseif target:isChained() then
					if not self:isGoodChainTarget(target, source, sgs.DamageStruct_Thunder, 2) then 
						return 100 
					end
				end
				if not sgs.isGoodTarget(self, target, self.opponents) then 
					v = v + 50
				end
				if target:hasArmorEffect("SilverLion") then 
					v = v + 20 
				end
				if self:hasSkills(sgs.exclusive_skill, target) then 
					v = v + 5 
				end
				if self:hasSkills(sgs.masochism_skill, target) then 
					v = v + 3 
				end
				if self:hasSkills("tiandu|zhenlie", target) then 
					v = v + 2 
				end
				if self:invokeDamagedEffect(target, source) then
					v = v + 5
				elseif self:needToLoseHp(target, source) then 
					v = v + 5 
				end
				if target:isChained() then
					if self:isGoodChainTarget(target, source, sgs.DamageStruct_Thunder, 2) then
						local chained_opponents = self:getChainedOpponents(source)
						if #chained_opponents > 1 then 
							value = value - 25 
						end
					end
				end
				if self:mayLord(target) then
					v = v - 5
				end
				local hp = target:getHp()
				local defense = sgs.getDefenseSlash(target)
				v = v + hp * 2 + defense * 0.01
			end
		else
			return 99
		end
		return v
	end
	local hitValues = {}
	local opponents = self:getOpponents(source)
	for _,enemy in ipairs(opponents) do
		hitValues[enemy:objectName()] = getHitValue(enemy)
	end
	local compare_func = function(a, b)
		local valueA = hitValues[a:objectName()]
		local valueB = hitValues[b:objectName()]
		return valueA > valueB
	end
	table.sort(opponents, compare_func)
	for _,enemy in ipairs(opponents) do
		if hitValues[enemy:objectName()] < value then
			return enemy
		end
	end
	return nil
end
--[[
	功能：判断一名角色对目标角色使用杀后是否会引发雷击
	参数：target（ServerPlayer类型，表示可能发动雷击的目标角色）
		source（ServerPlayer类型，表示使用杀的角色）
	结果：boolean类型，表示是否会引发雷击
]]--
function SmartAI:canLeiji(target, source)
	source = source or self.room:getCurrent()
	target = target or self.player
	if target:hasSkill("leiji") then
		if source then
			if self:canLiegong(target, source) then
				if not self:isPartner(target, source) then 
					return false 
				end
			end
		end
		if sgs.card_lack[target:objectName()]["Jink"] == 1 then 
			return false
		end
		local hasSpade = false
		if self:hasSuit("spade", true, target) then
			if target:hasSkill("guidao") then
				hasSpade = true
			end
			if target:hasSkill("guicai") then
				hasSpade = true
			end
			if target:hasSkill("jilve") then
				if target:getMark("@bear") > 0 then
					hasSpade = true
				end
			end
		end
		if target:getHandcardNum() > 4 then
			hasSpade = true
		end
		local hasJink = false
		if sgs.getKnownCard(target, "Jink", true) >= 1 then
			hasJink = true
		elseif sgs.card_lack[target:objectName()]["Jink"] == 2 then
			hasJink = true
		elseif not sgs.IgnoreArmor(source, target) then
			if not self:isWeak(target) then
				if self:hasEightDiagramEffect(target) then
					if sgs.card_lack[target:objectName()]["Jink"] == 0 then
						hasJink = true
					end
				end
			end
		end
		if hasJink and hasSpade then
			if self:findLeijiTarget(target, 50) then
				if self:getFinalRetrial(target) == 1 then
					return true
				end
			end
		end
	end
	return false
end
--[[
	内容：“雷击卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["LeijiCard"] = 80
sgs.ai_skill_playerchosen["leiji"] = function(self, targets)
	--小场景
	local mode = sgs.current_mode
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers()
		for _, p in sgs.qlist(players) do
			if p:getState() ~= "robot" then
				return p
			end
		end
	end
	--一般情形
	self:updatePlayers()
	return self:findLeijiTarget(self.player, 100)
end
--[[
	内容：“雷击”卡牌需求
]]--
sgs.card_need_system["leiji"] = function(self, card, player)
	if sgs.isCard("Jink", card, player) then
		if sgs.getKnownCard(player, "Jink", true) == 0 then
			return true
		end
	end
	if card:getSuit() == sgs.Card_Spade then
		if not self:hasSuit("spade", true, player) then
			return true
		end
	end
	if card:isKindOf("EightDiagram") then
		if not self:hasEquipDiagramEffect() then
			if sgs.getKnownCard(player, "EightDiagram", false) == 0 then
				return true
			end
		end
	end
	return false
end
sgs.slash_prohibit_system["leiji"] = {
	name = "leiji",
	reason = "leiji",
	judge_func = function(self, target, source, slash)
		source = source or self.room:getCurrent()
		--友方
		if self:isFriend(target, source) then
			return false
		end
		--潜袭
		if target:hasFlag("qianxi_target") then 
			return false 
		end
		--烈弓
		if self:canLiegong(target, source) then 
			return false 
		end
		--团队
		if self:amRebel() and self:mayLord(to) then
			local other_rebel
			local others = self.room:getOtherPlayers(self.player)
			for _,player in sgs.qlist(others) do
				if self:mayRebel(player) then 
					other_rebel = player
					break
				end
			end		
			if not other_rebel then
				if self:hasSkills("hongyan") or self.player:getHp() >= 4 then
					if self:getCardsNum("Peach") > 0 then
						return false
					elseif self:hasSkills("hongyan|ganglie|neoganglie") then
						return false
					end
				end
			end
		end
		--缺闪
		if sgs.card_lack[target:objectName()]["Jink"] == 2 then 
			return true 
		end
		--黑桃牌
		local num = target:getHandcardNum()
		if num > 4 then
			return true
		elseif num >= 2 then
			if self:hasSuit("spade", true, target) then
				return true
			end
		end
		if sgs.getKnownCard(to, "Jink", true) >= 1 then
			return true
		end
		--八卦阵
		if self:hasEightDiagramEffect(target) then
			if not sgs.IgnoreArmor(source, target) then 
				return true 
			end
		end
		return false
	end
}
--[[
	技能：黄天（主公技）
	描述：出牌阶段限一次，其他群雄角色的出牌阶段，该角色可以交给你一张【闪】或【闪电】。
]]--
--[[
	内容：“黄天技能卡”的卡牌成分
]]--
sgs.card_constituent["HuangtianCard"] = {
	use_value = 8.5,
	use_priority = 10,
}
--[[
	内容：“黄天技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HuangtianCard"] = -80
--[[
	内容：注册“黄天技能卡”
]]--
sgs.RegistCard("HuangtianCard")
--[[
	内容：“黄天”技能信息
]]--
sgs.ai_skills["huangtianv"] = {
	name = "huangtianv",
	dummyCard = function(self)
		local card_str = "@HuangtianCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasFlag("ForbidHuangtian") then
			if self.player:getKingdom() == "qun" then
				if not self.player:isKongcheng() then
					return true
				end
			end
		end
		return false
	end
}
--[[
	内容：“黄天技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["HuangtianCard"] = function(self, card, use)
	if self:needBear() then
		return "."
	elseif self:getCardsNum("Jink", self.player, "h") <= 1 then
		return "."
	end
	--确定一张闪
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local jink = nil
	for _,c in ipairs(cards) do
		if c:isKindOf("Jink") then
			jink = c
			break
		end
	end
	if jink then
	--确定黄天目标
		local targets = {}
		for _,friend in ipairs(self.partners_noself) do
			if friend:hasLordSkill("huangtian") then
				if not friend:hasFlag("HuangtianInvoked") then
					if not friend:hasSkill("manjuan") then
						table.insert(targets, friend)
					end
				end
			end
		end
		local card_str = "@HuangtianCard="..jink:getEffectiveId()
		--黄天己方
		if #targets > 0 then
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(targets[1])
			end
		--黄天对方
		else
			if self:getCardsNum("Slash", self.player, "he") >= 2 then 
				for _,enemy in ipairs(self.opponents) do
					if enemy:hasLordSkill("huangtian") then
						if not enemy:hasFlag("HuangtianInvoked") then
							if not enemy:hasSkill("manjuan") then
								if enemy:isKongcheng() then
									if not enemy:hasSkill("kongcheng") then
										if not enemy:hasSkills("tuntian+zaoxian") then 
										--必须保证对方空城，以保证天义/陷阵的拼点成功
											table.insert(targets, enemy)
										end
									end
								end
							end
						end
					end
				end
				if #targets > 0 then
					local flag = false
					if self.player:hasSkill("tianyi") then
						if not self.player:hasUsed("TianyiCard") then
							flag = true
						end
					end
					if not flag then
						if self.player:hasSkill("xianzhen") then
							if not self.player:hasUsed("XianzhenCard") then
								flag = true
							end
						end
					end
					if flag then
						local maxCard = self:getMaxPointCard(self.player) --最大点数的手牌
						if maxCard:getNumber() > jink:getNumber() then --可以保证拼点成功
							self:sort(targets, "defense", true) 
							for _,enemy in ipairs(targets) do
								if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
									use.card = jink
									enemy:setFlags("AI_HuangtianPindian")
									if use.to then
										use.to:append(enemy)
									end
									break
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
	套路：仅使用“黄天技能卡”
]]--
sgs.ai_series["HuangtianCardOnly"] = {
	name = "HuangtianCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	cards = {
		["HuangtianCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local huangtian_skill = sgs.ai_skills["huangtianv"]
		local dummyCard = huangtian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["HuangtianCard"], "HuangtianCardOnly")
--[[****************************************************************
	武将：风·于吉（群）
]]--****************************************************************
--[[
	技能：蛊惑
	描述：你可以声明一张基本牌或非延时类锦囊牌的名称并背面朝上使用或打出一张手牌。若无其他角色质疑，亮出此牌并按你所述之牌结算。若有其他角色质疑，亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。若被质疑的牌为♥且为真，此牌仍然进行结算，否则无论真假，你将此牌置入弃牌堆。 
]]--
--[[
	内容：“蛊惑技能卡”的卡牌成分
]]--
sgs.card_constituent["GuhuoCard"] = {
	use_priority = 10,
}
--[[
	内容：注册“蛊惑技能卡”
]]--
sgs.RegistCard("GuhuoCard")
--[[
	内容：“蛊惑”技能信息
]]--
sgs.ai_skills["guhuo"] = {
	name = "guhuo",
	dummyCard = function(self)
		local card_str = "@GuhuoCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return not self.player:isKongcheng()
	end
}
table.insert(sgs.ai_global_flags, "questioner")
table.insert(sgs.ai_choicemade_filter["cardUsed"], guhuo_filter)
--[[
	内容：“蛊惑技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["GuhuoCard"] = function(self, card, use)
	local handcards = self.player:getHandcards()
	local guhuo_str = {}
	local other_str = {}
	for _,trick in sgs.qlist(handcards) do
		if trick:isNDTrick() then
			local dummy_use = {
				isDummy = true, 
			}
			self:useTrickCard(trick, dummy_use)
			if dummy_use.card then
				local card_str = "@GuhuoCard=" .. trick:getId() .. ":" .. trick:objectName()
				if trick:getSuit() == sgs.Card_Heart then
					table.insert(guhuo_str, card_str)
				else
					table.insert(other_str, card_str)
				end
			end
		end
	end
	local other_suit = true
	local weak_enemy = false
	local ZhuGeLiang_kongcheng = false
	local can_fake_guhuo = ( sgs.turncount > 1 )
	for _,enemy in ipairs(self.opponents) do
		local hp = enemy:getHp()
		if hp > 2 then
			other_suit = false
		end
		if hp > 1 then
			can_fake_guhuo = true
		end
		if self:isWeak(enemy) then
			weak_enemy = true
		end
		if enemy:hasSkill("kongcheng") then
			if enemy:isKongcheng() then
				ZhuGeLiang_kongcheng = true
			end
		end
	end
	if other_suit then
		if #other_str > 0 then
			table.insertTable(guhuo_str, other_str)
		end
	end
	local peach_str = self:getGuhuoCard("Peach", self.player, true)
	if peach_str then
		table.insert(guhuo_str, peach_str)
	end
	local fake_cards = {}
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			if self:getCardsNum("Slash", self.player, "h") >= 2 then
				if not self:isEquip("Crossbow") then
					table.insert(fake_cards, c)
				end
			end
		elseif c:isKindOf("Jink") then
			if self:getCardsNum("Jink", self.player, "h") >= 3 then
				table.insert(fake_cards, c)
			end
		elseif c:isKindOf("EquipCard") then
			if self:getSameTypeEquip(card) then
				table.insert(fake_cards, c)
			end
		elseif c:isKindOf("Disaster") then
			table.insert(fake_cards, c)
		end
	end
	self:sortByUseValue(fake_cards, true)
	local banPackages = sgs.Sanguosha:getBanPackages()
	local withManeuvering = true
	for _,package in sgs.qlist(banPackages) do
		if package == "maneuvering" then
			withManeuvering = false
			break
		end
	end
	
	local function fake_guhuo(object_name, can_fake_guhuo)
		if #fake_cards > 0 then
			local fake_card = nil
			local to_guhuo = {
				"peach", "ex_nihilo", "dismantlement", 
				"amazing_grace", "archery_attack", "savage_assault", "god_salvation", 
				"fire_attack"
			}
			if not withManeuvering then
				table.remove(to_guhuo, #to_guhuo)
			end
			for i=1, #to_guhuo, 1 do
				local forbiden = to_guhuo[i]
				local c = sgs.Sanguosha:cloneCard(forbiden, sgs.Card_NoSuit, 0)
				if self.player:isLocked(c) then 
					table.remove(forbiden, #to_guhuo) 
				end
			end
			if can_fake_guhuo then
				for i=1, #to_guhuo do
					if to_guhuo[i] == "god_salvation" then 
						table.remove(to_guhuo, i) 
						break 
					end
				end
			end
			for i=1, 10, 1 do
				local to_use = fake_cards[math.random(1, #fake_cards)]
				local guhuo_name = object_name or to_guhuo[math.random(1, #to_guhuo)]
				local guhuo_card = sgs.Sanguosha:cloneCard(guhuo_name, to_use:getSuit(), to_use:getNumber())
				local guhuo_class = guhuo_card:getClassName()
				if self:getRestCardsNum(guhuo_class) > 0 then
					local dummy_use = {
						isDummy = true,
					}
				end
				if guhuo_name == "peach" then
					self:useBasicCard(guhuo_card, dummy_use)
				else
					self:useTrickCard(guhuo_card, dummy_use)
				end
				if dummy_use.card then
					local card_str = "@GuhuoCard=" .. to_use:getId() .. ":" .. guhuo_name
					fake_card = sgs.Card_Parse(card_str)
					break
				end
			end
		end
		return fake_card
	end
	
	local acard = nil
	if #guhuo_str > 0 then
		local card_str = guhuo_str[math.random(1, #guhuo_str)]
		local str = card_str:split("=")
		str = str[2]:split(":")
		local card_id = str[1]
		local card_name = str[2]
		if card_name == "ex_nihilo" then
			local c = sgs.Sanguosha:getCard(card_id)
			if c:objectName() == card_name then
				if math.random(1, 3) == 1 then
					acard = fake_guhuo(card_name)
				end
				if not acard then
					acard = sgs.Card_Parse(card_str)
				end
			end
		end
		if not acard then
			if math.random(1, 5) == 1 then
				acard = fake_guhuo()
			end
		end
		if not acard then
			acard = sgs.Card_Parse(card_str)
		end
	end
	if not acard then
		if can_fake_guhuo then
			if math.random(1, 4) ~= 1 then
				acard = fake_guhuo(nil, can_fake_guhuo)
			end
		end
	end
	if not acard then
		if ZhuGeLiang_kongcheng then
			if fake_cards > 0 then
				local id = fake_cards[1]:getEffectiveId()
				local card_str = "@GuhuoCard="..id..":".."amazing_grace"
				acard = sgs.Card_Parse(card_str)
			end
		end
	end
	if not acard then
		if #fake_cards > 0 then
			local to_draw = false
			for _,lordname in ipairs(sgs.ai_lords) do
				local lord = findPlayerByObjectName(self.room, lordname)
				if self:isPartner(lord) then
					if lord:getHp() <= 1 then
						if self:isWeak(lord) then
							if not self:amLord() then
								to_draw = true
								break
							end
						end
					end
				end
			end
			if not to_draw then
				if not weak_enemy then
					if self:amLoyalist() then
						if self:countRebel() > 0 then
							if self:countLoyalist() > self:countRenegade() + self:countRebel() then
								to_draw = true
							end
						end
					elseif self:amRebel() then
						if self:countRebel() > self:countRenegade() + self:countLoyalist() + 2 then
							to_draw = true
						end
					end
				end
			end
			if to_draw then
				local card_name = nil
				local names = {
					"ex_nihilo", "snatch", "dismantlement",
					"amazing_grace", "archery_attack", "savage_assault", "god_salvation", 
					"duel"
				}
				for _,name in ipairs(names) do
					local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
					if self:getRestCardsNum(c:getClassName()) > 0 then
						card_name = name
						break 
					end
				end
				if card_name then
					local id = fake_cards[1]:getEffectiveId()
					local card_str = "@GuhuoCard="..id..":"..card_name
					acard = sgs.Card_Parse(card_str)
				end
			end
		end
	end
	if not acard then
		if sgs.slash:isAvailable(self.player) then
			local card_str = self:getGuhuoCard("Slash", self.player, true)
			if card_str then
				local dummy_use = {
					isDummy = true,
				}
				self:useBasicCard(sgs.slash, dummy_use)
				if dummy_use.card then
					acard = sgs.Card_Parse(card_str)
				end
			end
		end
	end
	if acard then
		local card_str = acard:toString()
		local name = card_str:split(":")[3]
		local guhuo_card = sgs.Sanguosha:cloneCard(name, acard:getSuit(), acard:getNumber())
		guhuo_card:setSkillName("guhuo")
		if guhuo_card:getTypeId() == sgs.Card_Basic then
			self:useBasicCard(guhuo_card, use)
		else
			self:useTrickCard(guhuo_card, use)
		end
		if use.card then
			use.card = acard
		end
	end
end
sgs.ai_skill_choice["guhuo"] = function(self, choices)
	local YuJi = self.room:findPlayerBySkillName("guhuo")
	local tag = self.room:getTag("GuhuoType")
	local guhuoName = tag:toString()
	if guhuoName == "peach+analeptic" then 
		guhuoName = "peach" 
	elseif guhuoName == "normal_slash" then 
		guhuoName = "slash" 
	end
	local guhuoCard = sgs.Sanguosha:cloneCard(guhuoName, sgs.Card_NoSuit, 0)
	local guhuoType = guhuoCard:getClassName()
	if guhuoType then
		--Waiting For More Details
		if guhuoType == "AmazingGrace" then 
			return "noquestion"
		elseif guhuoType:match("Slash") then
			if not sgs.questioner then
				if YuJi:getState() ~= "robot" then
					if math.random(1, 4) == 1 then 
						return "question" 
					end
				end
			end
			if not self:isEquip("Crossbow", YuJi) then 
				return "noquestion" 
			end
		end
	end
	if YuJi:hasFlag("guhuo_failed") then
		if math.random(1, 6) == 1 then
			if self:isOpponent(YuJi) then
				if self.player:getHp() >= 3 then
					if self.player:getHp() > self.player:getLostHp() then 
						return "question" 
					end
				end
			end
		end
	end
	local x = math.random(1, 5)
	self:sort(self.partners, "hp")
	if self.player:getHp() < 2 then
		if self:getCardsNum("Peach") < 1 then
			if self.room:alivePlayerCount() > 2 then 
				return "noquestion" 
			end
		end
	end
	local maxfriend = self.partners[#self.partners]
	if self:isPartner(YuJi) then 
		return "noquestion"
	elseif sgs.questioner then 
		return "noquestion"
	else
		if self.player:getHp() < maxfriend:getHp() then 
			return "noquestion" 
		end
	end
	if x ~= 1 then 
		if self:needToLoseHp(self.player) then
			if not self:hasSkills(sgs.masochism_skill, self.player) then
				return "question" 
			end
		end
	end
	local questioner = nil
	local skills = "rende|kuanggu|zaiqi|buqu|yinghun|longhun|xueji|baobian"
	for _, friend in ipairs(self.partners) do
		if friend:getHp() == maxfriend:getHp() then
			if self:hasSkills(skills, friend) then
				questioner = friend
				break
			end
		end
	end
	if not questioner then 
		questioner = maxfriend 
	end
	if x ~= 1 then
		if self.player:objectName() == questioner:objectName() then
			return "question"
		end
	end
	return "noquestion" 
end
sgs.ai_skill_choice["guhuo_saveself"] = function(self, choices)
	if self:getCard("Peach") then
		return "peach"
	elseif self:getCard("Analeptic") then 
		return "analeptic" 
	else 
		return "peach" 
	end
end
sgs.ai_skill_choice["guhuo_slash"] = function(self, choices)
	return "slash"
end
sgs.ai_choicemade_filter.skillChoice["guhuo"] = function(player, promptlist)
	if promptlist[#promptlist] == "question" then
		sgs.questioner = player
	end
end
--[[
	内容：“蛊惑”卡牌需求
]]--
sgs.card_need_system["guhuo"] = function(self, card, player)
	if card:getSuit() == sgs.Card_Heart then
		if card:isKindOf("BasicCard") then
			return true
		elseif card:isNDTrick() then
			return true
		end
	end
	return false
end
--[[
	套路：仅使用“蛊惑技能卡”
]]--
sgs.ai_series["GuhuoCardOnly"] = {
	name = "GuhuoCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "guhuo",
	cards = {
		["GuhuoCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local guhuo_skill = sgs.ai_skills["guhuo"]
		local dummyCard = guhuo_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["GuhuoCard"], "GuhuoCardOnly")