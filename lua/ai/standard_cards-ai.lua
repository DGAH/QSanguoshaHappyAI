--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）标准卡牌包部分
]]--
--[[****************************************************************
	----------------------------------------------------------------
	卡 牌 控 制
	----------------------------------------------------------------
]]--****************************************************************
sgs.slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) --杀
sgs.jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0) --闪
sgs.peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0) --桃
sgs.god_salvation = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0) --桃园结义
sgs.amazing_grace = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0) --五谷丰登
sgs.savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0) --南蛮入侵
sgs.archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0) --万箭齐发
sgs.collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0) --借刀杀人
sgs.ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0) --无中生有
sgs.duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0) --决斗
sgs.snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0) --顺手牵羊
sgs.dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0) --过河拆桥
sgs.indulgence = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0) --乐不思蜀
sgs.lightning = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0) --闪电
sgs.ai_slash_weapon_filter = {} --武器适用场合
sgs.ai_weapon_value = {} --武器价值表
sgs.ai_armor_value = {} --防具价值表
--卡牌对象名
sgs.objectName = {
	["Slash"] = "slash",
	["Jink"] = "jink",
	["Peach"] = "peach",
	["GodSalvation"] = "god_salvation",
	["AmazingGrace"] = "amazing_grace",
	["SavageAssault"] = "savage_assault",
	["ArcheryAttack"] = "archery_attack",
	["Collateral"] = "collateral",
	["ExNihilo"] = "ex_nihilo",
	["Duel"] = "duel",
	["Snatch"] = "snatch",
	["Dismantlement"] = "dismantlement",
	["Indulgence"] = "indulgence",
	["Lightning"] = "lightning",
}
--卡牌类型名
sgs.className = {
	["slash"] = "Slash",
	["jink"] = "Jink",
	["peach"] = "Peach",
	["god_salvation"] = "GodSalvation",
	["amazing_grace"] = "AmazingGrace",
	["savage_assault"] = "SavageAssault",
	["archery_attack"] = "ArcheryAttack",
	["collateral"] = "Collateral",
	["ex_nihilo"] = "ExNihilo",
	["duel"] = "Duel",
	["snatch"] = "Snatch",
	["dismantlement"] = "Dismantlement",
	["indulgence"] = "Indulgence",
	["lightning"] = "Lightning",
}
--[[
	功能：产生特定卡牌
	参数：name（string类型，表示卡牌对象名；或Card类型，表示目标卡牌）
		suit（sgs.Card_Suit类型，表示卡牌花色）
		point（number类型，表示卡牌点数）
	结果：Card类型，表示产生的卡牌
]]--
function sgs.cloneCard(name, suit, point)
	if name then
		if type(name) == "userdata" then
			suit = name:getSuit()
			point = name:getNumber()
			name = name:objectName()
		elseif type(name) == "string" then
			suit = suit or sgs.Card_NoSuit
			point = point or 0
		end
		return sgs.Sanguosha:cloneCard(name, suit, point)
	end
end
--[[****************************************************************
	----------------------------------------------------------------
	基 本 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[
	功能：计算一名角色的防御杀的能力
	参数：player（Player类型，表示目标角色）
	结果：number类型（defense），表示角色的防御水平数值
]]--
function sgs.getDefenseSlash(player)
	if player then
		local self = sgs.recorder
		local attacker = global_room:getCurrent()
		local jinkNum = sgs.getCardsNum("Jink", player)
		local defense = jinkNum
		local hp = player:getHp()
		defense = defense + math.min(10, hp * 0.45)
		local knownJink = sgs.getKnownCard(player, "Jink", true)
		if knownJink == 0 then
			if sgs.card_lack[player:objectName()]["Jink"] == 1 then
				defense = 0
			end
		end
		defense = defense + knownJink * 1.2
		local hasEightDiagram = false
		if not sgs.IgnoreArmor(attacker, player) then
			if player:hasArmorEffect("EightDiagram") then
				hasEightDiagram = true
			elseif player:hasSkill("bazhen") then
				if not player:getArmor() then
					hasEightDiagram = true
				end
			end
		end
		if hasEightDiagram then 
			defense = defense + 1.3 
			if player:hasSkill("tiandu") then 
				defense = defense + 0.6 
			end
			if player:hasSkill("gushou") then 
				defense = defense + 0.4 
			end
			if player:hasSkill("leiji") then 
				defense = defense + 0.4 
			end
			if player:hasSkill("noszhenlie") then 
				defense = defense + 0.2 
			end
			if player:hasSkill("hongyan") then 
				defense = defense + 0.2 
			end
		end
		if jinkNum >= 1 then
			if player:hasSkill("mingzhe") then
				defense = defense + 0.2	
			end
			if player:hasSkill("gushou") then
				defense = defense + 0.2	
			end
			if player:hasSkill("tuntian") then
				if player:hasSkill("zaoxian") then
					defense = defense + 1.5	
				end
			end
		end
		if player:hasSkill("aocai") then
			if player:getPhase() == sgs.Player_NotActive then 
				defense = defense + 0.5 
			end
		end
		local hujiaJink = 0
		if player:hasLordSkill("hujia") then
			local lieges = global_room:getLieges("wei", player)
			for _,liege in sgs.qlist(lieges) do
				if self:isPartner(liege, player) then
					hujiaJink = hujiaJink + sgs.getCardsNum("Jink", liege)
					if liege:hasArmorEffect("EightDiagram") then 
						hujiaJink = hujiaJink + 0.8 
					end
				end
			end
			defense = defense + hujiaJink
		end
		if player:getMark("@tied") > 0 then
			if not attacker:hasSkill("jueqing") then 
				defense = defense + 1 
			end
		end
		local num = player:getHandcardNum()
		if attacker:canSlashWithoutCrossbow() then
			if attacker:getPhase() == sgs.Player_Play then
				if attacker:hasSkill("liegong") then
					if num >= attacker:getHp() then
						defense = 0
					elseif num <= attacker:getAttackRange() then 
						defense = 0 
					end
				end
				if attacker:hasSkill("kofliegong") then
					if num >= attacker:getHp() then 
						defense = 0 
					end
				end
			end
		end	
		if attacker:hasSkill("wushuang") then
			if sgs.getKnownCard(player, "Jink", true, "he") < 2 then
				if num < 2 or jinkNum < 2 then
					if player:hasLordSkill("hujia") then
						if hujiaJink < 2 then
							defense = 0
						end
					else
						if num < 2 then
							defense = 0
						end
					end
				end
			end
		end
		if attacker:hasSkill("dahe") then
			if player:hasFlag("dahe") then
				if sgs.getKnownCard(player, "Jink", true, "he") == 0 then
					if sgs.getKnownNum(player) == num then
						if not player:hasLordSkill("hujia") then
							defense = 0
						elseif hujiaJink < 1 then
							defense = 0
						end
					end
				end
			end
		end
		if player:hasFlag("QianxiTarget") then
			local red = player:getMark("@qianxi_red") > 0
			local black = player:getMark("@qianxi_black") > 0
			if red then
				if player:hasSkill("qingguo") then
					defense = defense - 1
				elseif player:hasSkill("longhun") and player:isWounded() then
					defense = defense - 1
				else
					defense = 0
				end
			elseif black then
				if player:hasSkill("qingguo") then
					defense = defense - 1
				end
			end
		end
		if attacker then
			if not attacker:hasSkill("jueqing") then
				local m = sgs.masochism_skill:split("|")
				if sgs.isGoodHp(player) then
					for _, masochism in ipairs(m) do
						if player:hasSkill(masochism) then
							defense = defense + 1
						end
					end
				end
				if player:hasSkill("jieming") then 
					defense = defense + 4 
				end
				if player:hasSkill("yiji") then 
					defense = defense + 4 
				end
				if player:hasSkill("guixin") then 
					defense = defense + 4 
				end
				if player:hasSkill("yuce") then 
					defense = defense + 2 
				end
			end
		end
		if not sgs.isGoodTarget(nil, player) then 
			defense = defense + 10 
		end
		if player:hasSkills("nosrende|rende") then
			if hp > 2 then 
				defense = defense + 1 
			end
		end
		if player:hasSkill("kuanggu") then
			if hp > 1 then 
				defense = defense + 0.2 
			end
		end
		if player:hasSkill("zaiqi") then
			if hp > 1 then 
				defense = defense + 0.35 
			end
		end
		if player:hasSkill("tianming") then 
			defense = defense + 0.1 
		end
		if hp > sgs.getBestHp(player) then 
			defense = defense + 0.8 
		end
		if hp <= 2 then 
			defense = defense - 0.4 
		end
		local playerCount = global_room:alivePlayerCount()
		local myseat = player:getSeat()
		local seat = attacker:getSeat()
		if (myseat - seat) % playerCount >= playerCount - 2 then
			if playerCount > 3 then
				if num <= 2 then
					if hp <= 2 then
						defense = defense - 0.4
					end
				end
			end
		end
		if player:hasSkill("tianxiang") then 
			defense = defense + num * 0.5 
		end
		if num == 0 then
			if hujiaJink == 0 then
				if not player:hasSkill("kongcheng") then
					if hp <= 1 then 
						defense = defense - 2.5 
					end
					if hp == 2 then 
						defense = defense - 1.5 
					end
					if not hasEightDiagram then 
						defense = defense - 2 
					end
					if attacker:hasWeapon("GudingBlade") then
						if num == 0 then
							if not player:hasArmorEffect("SilverLion") then
								defense = defense - 2
							elseif sgs.IgnoreArmor(attacker, player) then
								defense = defense - 2
							end
						end
					end
				end
			end
		end
		local has_fire_slash = false
		local cards = attacker:getHandcards()
		cards = sgs.QList2Table(cards)
		for i = 1, #cards, 1 do
			local fireSlash = cards[i]
			if fireSlash:isKindOf("FireSlash") then
				has_fire_slash = true
				break
			elseif attacker:hasWeapon("Fan") then
				if fireSlash:isKindOf("Slash") then
					if not fireSlash:isKindOf("NatureSlash") then
						has_fire_slash = true
						break
					end
				end
			end
		end
		if has_fire_slash then
			if player:hasArmorEffect("Vine") then
				if not sgs.IgnoreArmor(attacker, player) then 
					defense = defense - 0.6
				end
			end	
		end
		if sgs.ai_lord[player:objectName()] == player:objectName() then
			defense = defense - 0.4
			if sgs.isInDanger(player) then
				defense = defense - 0.7
			end
		end
		local chaofeng = sgs.ai_chaofeng[player:getGeneralName()] or 0
		if chaofeng >= 3 then
			defense = defense - math.max(6, chaofeng) * 0.035
		end
		if not player:faceUp() then 
			defense = defense - 0.35 
		end
		if not player:containsTrick("YanxiaoCard") then
			if player:containsTrick("indulgence") then 
				defense = defense - 0.15 
			end
			if player:containsTrick("supply_shortage") then 
				defense = defense - 0.15 
			end
		end
		local caseRoulin = false
		if attacker:hasSkill("roulin") then
			if player:isFemale() then
				caseRoulin = true
			end
		end
		if player:hasSkill("roulin") then
			if attacker:isFemale() then
				caseRoulin = true
			end
		end
		if caseRoulin then
			defense = defense - 2.4
		end
		if not hasEightDiagram then
			if player:hasSkill("jijiu") then 
				defense = defense - 3 
			end
			if player:hasSkill("dimeng") then 
				defense = defense - 2.5 
			end
			if player:hasSkill("guzheng") then
				if knownJink == 0 then 
					defense = defense - 2.5 
				end
			end
			if player:hasSkill("qiaobian") then 
				defense = defense - 2.4 
			end
			if player:hasSkill("jieyin") then 
				defense = defense - 2.3 
			end
			if player:hasSkills("noslijian|lijian") then 
				defense = defense - 2.2 
			end
			if player:hasSkill("nosmiji") then
				if player:isWounded() then 
					defense = defense - 1.5 
				end
			end
			if player:hasSkill("xiliang") then
				if knownJink == 0 then 
					defense = defense - 2 
				end
			end
			if player:hasSkill("shouye") then 
				defense = defense - 2 
			end
		end
		return defense
	end
	return 0
end
--按角色防御杀的能力比较
sgs.ai_compare_funcs["defenseSlash"] = function(a, b)
	local defenseA = sgs.getDefenseSlash(a)
	local defenseB = sgs.getDefenseSlash(b)
	return defenseA < defenseB
end
--[[****************************************************************
	杀
]]--****************************************************************
--[[
	功能：判断一名友方角色是否是杀的首要目标
	参数：friend（ServerPlayer类型，表示待判断的目标角色）
		card（Card类型，表示待使用的杀）
	结果：boolean类型，表示是否是首要目标
]]--
function SmartAI:isPriorFriendOfSlash(friend, card)
	local HuaTuo = self.room:findPlayerBySkillName("jijiu")
	local alives = self.room:getAlivePlayers()
	for _, p in sgs.qlist(alives) do
		if p:hasSkill("jijiu") then
			if self:isPartner(p) then 
				HuaTuo = p 
				break 
			end
		end
	end
	if not self:hasHeavySlashDamage(self.player, card, friend) then
		if card:getSkillName() ~= "lihuo" then
			if self:canLeiji(friend, self.player) then
				return true
			end
			if self:mayLord(friend) then
				if self.player:hasSkill("guagu") then
					if friend:getLostHp() >= 1 then
						if sgs.getCardsNum("Jink", friend) == 0 then
							return true
						end
					end
				end
			end
			if friend:hasSkill("jieming") then
				if self.player:hasSkill("rende") then
					if not self.player:hasSkill("jueqing") then
						if HuaTuo and self:isPartner(HuaTuo) then
							return true
						end
					end
				end
			end
			if friend:hasSkill("hunzi") then
				if friend:getHp() == 2 then
					if self:invokeDamagedEffect(friend, self.player) then
						return true
					end
				end
			end
		end
	end
	if not self.player:hasSkill("jueqing") then
		if card:isKindOf("NatureSlash") then
			if friend:isChained() then
				if self:isGoodChainTarget(friend, nil, nil, nil, card) then 
					return true 
				end
			end
		end
	end
	return false
end
--[[
	内容：“杀”的卡牌成分
]]--
sgs.card_constituent["Slash"] = {
	damage = 1,
	use_value = 4.5,
	keep_value = 2,
	use_priority = 2.6,
}
--[[
	内容：“杀”的卡牌仇恨值
]]--
sgs.ai_card_intention["Slash"] = function(self, card, from, tos)
	if sgs.ai_liuli_effect then
		sgs.ai_liuli_effect = false
		return
	end
	for _,to in ipairs(tos) do
		local value = 80
		--借刀杀人
		if sgs.ai_collateral then 
			sgs.ai_collateral = false 
			value = 0 
		end
		--雷击
		if sgs.ai_leiji_effect then
			if self:canLiegong(to, from) then 
				sgs.ai_leiji_effect = false
			end
			--破军
			if sgs.ai_pojun_effect then
				value = value / 1.5
			else
				value = 0
			end
		end
		speakTrigger(card, from, to)
		--遗计
		local hp = to:getHp()
		if to:hasSkill("yiji") then
			value = value * ( 2-hp ) / 1.1
			value = math.max(value, 0)
		end
		--雷击
		if to:hasSkill("leiji") then
			if self:getCardsNum("Jink", to) > 0 then
				value = 0 
			end
		end
		--高伤害
		if not self:hasHeavySlashDamage(from, card, to) then
			if self:invokeDamagedEffect(to, from, sgs.slash) then
				value = 0
			elseif self:needToLoseHp(to, from, true, true) then 
				value = 0 
			end
		end
		--破军
		if from:hasSkill("pojun") then
			local damage = self:hasHeavySlashDamage(from, card, to, true)
			if hp > 2 + damage then
				value = 0
			end
		end
		--雷击
		if self:canLeiji(to, from) then 
			value = -10 
		end
		sgs.updateIntention(from, to, value)
	end
end
--[[
	内容：注册杀
]]--
sgs.RegistCard("Slash")
--[[
	功能：使用杀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSlash(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Slash"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	local weapon = self.player:getWeapon()
	if not use.isDummy then
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if card:isVirtualCard() then
				if card:subcardsLength() > 0 then
					if weapon and weapon:isKindOf("Crossbow") then
						local weapon_id = weapon:getEffectiveId()
						if card:getSubcards():contains(weapon_id) then
							if not self.player:canSlashWithoutCrossbow() then
								return
							end
						end
					end
				end
			end
		end
	end
	local basicNum = 0
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _,basic in ipairs(cards) do
		if basic:getTypeId() == sgs.Card_TypeBasic then
			if not basic:isKindOf("Peach") then 
				basicNum = basicNum + 1 
			end
		end
	end
	local no_distance = false
	if sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) > 50 then
		no_distance = true
	elseif self.player:hasFlag("slashNoDistanceLimit") then
		no_distance = true
	elseif card:getSkillName() == "qiaoshui" then
		no_distance = true
	end
	local extra_target = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	self.slash_targets = 1 + extra_target
	if self.player:hasSkill("duanbing") then 
		self.slash_targets = self.slash_targets + 1 
	end
	local rangefix = 0
	if card:isVirtualCard() then
		if weapon then
			local weapon_id = weapon:getEffectiveId()
			if card:getSubcards():contains(weapon_id) then
				if weapon:getClassName() ~= "Weapon" then
					rangefix = sgs.weapon_range[weapon:getClassName()] - 1
				end
			end
		end
		local horse = self.player:getOffensiveHorse()
		if horse then
			local horse_id = horse:getEffectiveId()
			if card:getSubcards():contains(horse_id) then
				rangefix = rangefix + 1
			end
		end
	end
	if not use.isDummy then
		if self.player:hasSkill("qingnang") then
			if self:isWeak() and self:getOverflow() == 0 then 
				return 
			end
		end
	end
	for _,friend in ipairs(self.partners_noself) do
		if self:willUseSlash(friend, self.player, card) then
			if self:isPriorFriendOfSlash(friend, card) then
				local can_use = false
				if not use.current_targets then
					can_use = true
				elseif not table.contains(use.current_targets, friend:objectName()) then
					can_use = true
				end
				if can_use then
					can_use = false
					if self.player:canSlash(friend, card, not no_distance, rangefix) then
						can_use = true
					elseif use.isDummy then
						if self.player:distanceTo(friend, rangefix) <= self.predictedRange then
							can_use = true
						end
					end
					if can_use then
						if self:slashIsEffective(card, friend) then
							use.card = card
							if use.to then
								if use.to:length() == self.slash_targets - 1 then
									if self.player:hasSkill("duanbing") then
										local has_extra = false
										for _,tg in sgs.qlist(use.to) do
											if self.player:distanceTo(tg, rangefix) == 1 then
												has_extra = true
												break
											end
										end
										if has_extra or self.player:distanceTo(friend, rangefix) == 1 then
											use.to:append(friend)
										end
									end
								elseif use.to:length() < self.slash_targets then
									use.to:append(friend)
								end
								self:speak("hostile", self.player:isFemale())
							end
							if not use.to then
								return 
							elseif self.slash_targets <= use.to:length() then 
								return 
							end
						end
					end
				end
			end
		end
	end
	local targets = {}
	local forbidden = {}
	self:sort(self.opponents, "defenseSlash")
	for _,enemy in ipairs(self.opponents) do
		if self:willUseSlash(enemy, self.player, card) then
			if sgs.isGoodTarget(self, enemy, self.opponents, true) then
				if self:invokeDamagedEffect(enemy, self.player, card) then 
					table.insert(forbidden, enemy)
				else 
					table.insert(targets, enemy)
				end
			end
		end
	end
	if #targets == 0 then
		if #forbidden > 0 then 
			targets = forbidden 
		end
	end
	if #targets == 1 then
		if card:getSkillName() == "lihuo" then
			if not targets[1]:hasArmorEffect("Vine") then 
				return 
			end
		end
	end
	for _,target in ipairs(targets) do
		local canliuli = false
		for _,friend in ipairs(self.partners_noself) do
			if self:canLiuli(target, friend) then
				if self:slashIsEffective(card, friend) then
					if #targets > 1 then
						if friend:getHp() < 3 then 
							canliuli = true 
						end
					end
				end
			end
		end
		local can_use = false
		if not use.current_targets then
			can_use = true
		elseif not table.contains(use.current_targets, target:objectName()) then
			can_use = true
		end
		if can_use then
			can_use = false
			if self.player:canSlash(target, card, not no_distance, rangefix) then
				can_use = true
			elseif use.isDummy then
				if self.predictedRange then
					if self.player:distanceTo(target, rangefix) <= self.predictedRange then
						can_use = true
					end
				end
			end
		end
		if can_use then
			can_use = false
			if self:friendshipLevel(target) < -4 then
				if self:slashIsEffective(card, target) then
					if not canliuli then
						can_use = true
					end
				end
			end
		end
		if can_use then
			can_use = false
			if not target:hasSkill("xiangle") then
				can_use = true
			elseif basicNum >= 2 then
				can_use = true
			end
		end
		if can_use then
			can_use = false
			if self:isWeak(target) then
				can_use = true
			elseif #self.enemies <= 1 then
				can_use = true
			elseif #self.friends <= 1 then
				can_use = true
			elseif not self.player:hasSkill("keji") then
				can_use = true
			elseif self:getOverflow() <= 0 then
				can_use = true
			elseif self:hasCrossbowEffect() then
				can_use = true
			end
		end
		if can_use then
			local usecard = card
			if not use.to or use.to:isEmpty() then
				can_use = true
				if self.player:hasWeapon("Spear") then
					if card:getSkillName() == "Spear" then
						can_use = false
					end
				elseif self.player:hasWeapon("Crossbow") then
					if self:getCardsNum("Slash") > 1 then
						can_use = false
					end
				end
				if can_use then
					if not use.isDummy then
						local Weapons = {}
						local handcards = self.player:getHandcards()
						for _,c in sgs.qlist(handcards) do
							if c:isKindOf("Weapon") then
								local callback = sgs.ai_slash_weapon_filter[c:objectName()]
								if type(callback) == "function" then
									if callback(self, target) then
										local range = sgs.weapon_range[c:getClassName()] or 1
										if self.player:distanceTo(target) <= range then
											self:useEquipCard(c, use)
											if use.card then 
												table.insert(Weapons, c) 
											end
										end
									end
								end
							end
						end
						if #Weapons > 0 then
							local function compare_func(a, b)
								return self:evaluateWeapon(a) > self:evaluateWeapon(b)
							end
							table.sort(Weapons, compare_func)
							use.card = Weapons[1]
							return
						end
					end
					if target:isChained() then
						if self:isGoodChainTarget(target, nil, nil, nil, card) then
							if not use.card then
								if card:isKindOf("NatureSlash") then
									if self:isEquip("Crossbow") then
										local slashes = self:getCards("Slash")
										for _,slash in ipairs(slashes) do
											if not slash:isKindOf("NatureSlash") then
												if self:slashIsEffective(slash, target) then
													if self:willUseSlash(target, self.player, slash) then
														usecard = slash
														break
													end
												end
											end
										end
									end
								else
									local slash = self:getCard("NatureSlash")
									if slash then
										if self:slashIsEffective(slash, target) then
											if self:willUseSlash(target, self.player, slash) then
												usecard = slash
											end
										end
									end
								end
							end
						end
					end
					local gs = self:getCard("GodSalvation")
					if not use.isDummy then
						if gs and gs:getId() ~= card:getId() then
							if self:willUseGodSalvation(gs) then
								if not target:isWounded() then
									use.card = gs
									return
								elseif not self:hasTrickEffective(gs, target, self.player) then
									use.card = gs
									return
								end
							end
						end
					end
				end
			end
			use.card = use.card or usecard
			if use.to then
				if not use.to:contains(target) then
					if use.to:length() == self.slash_targets - 1 and self.player:hasSkill("duanbing") then
						local has_extra = false
						for _, tg in sgs.qlist(use.to) do
							if self.player:distanceTo(tg, rangefix) == 1 then
								has_extra = true
								break
							end
						end
						if has_extra or self.player:distanceTo(target, rangefix) == 1 then
							use.to:append(target)
						end
					elseif use.to:length() < self.slash_targets then
						use.to:append(target)
					end
				end
			end
			if not use.isDummy then
				local anal = self:searchForAnaleptic(use, use.card)
				if anal then
					if self:willUseAnaleptic(target, use.card, anal) then
						if anal:getEffectiveId() ~= card:getEffectiveId() then
							use.card = anal
							if use.to then 
								use.to = sgs.SPlayerList() 
							end
							return
						end
					end
				end
			end
			if not use.to or self.slash_targets <= use.to:length() then 
				return 
			end
		end
	end
	for _,friend in ipairs(self.partners_noself) do
		local can_use = self:willUseSlash(friend, self.player, card)
		if can_use then
			can_use = false
			if not use.current_target then
				can_use = true
			elseif not table.contains(use.current_targets, friend:objectName()) then
				can_use = true
			end
			if can_use then
				can_use = false
				if not self:hasHeavySlashDamage(self.player, card, friend) then
					if card:getSkillName() == "lihuo" then
						can_use = true
					end
				end
			end
			if can_use then
				can_use = false
				if not use.to then
					can_use = true
				elseif not use.to:contains(friend) then
					can_use = true
				end
			end
			if can_use then
				can_use = false
				if self.player:hasSkill("pojun") then
					if friend:getHp() > 4 then
						if sgs.getCardsNum("Jink", friend) == 0 then
							if friend:getHandcardNum() < 3 then
								can_use = true
							end
						end
					end
				end
			end
			if not can_use then
				if self:invokeDamagedEffect(friend, self.player) then
					if not self:mayLord(friend) then
						can_use = true
					elseif #self.enemies >= 1 then
						can_use = true
					end
				end
			end
			if not can_use then
				if self:needToLoseHp(friend, self.player, true, true) then
					if not self:mayLord(friend) then
						can_use = true
					elseif #self.enemies >= 1 then
						can_use = true
					end
				end
			end
			if can_use then
				if self:slashIsEffective(card, friend) then
					can_use = false
					if self.player:canSlash(friend, card, not no_distance, rangefix) then
						can_use = true
					elseif use.isDummy then
						if self.predictedRange then
							if self.player:distanceTo(friend, rangefix) <= self.predictedRange then
								can_use = true
							end
						end
					end
					if can_use then
						use.card = card
						if use.to then
							if use.to:length() == self.slash_targets - 1 and self.player:hasSkill("duanbing") then
								local has_extra = false
								for _, tg in sgs.qlist(use.to) do
									if self.player:distanceTo(tg, rangefix) == 1 then
										has_extra = true
										break
									end
								end
								if has_extra or self.player:distanceTo(friend, rangefix) == 1 then
									use.to:append(friend)
								end
							elseif use.to:length() < self.slash_targets then
								use.to:append(friend)
							end
							self:speak("hostile", self.player:isFemale())
						end
						if not use.to or self.slash_targets <= use.to:length() then 
							return 
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_use["slash"] = function(self, prompt)
	local parsedPrompt = prompt:split(":")
	local reason = parsedPrompt[1]
	local callback = sgs.ai_skill_cardask[reason] -- for askForUseSlashTo
	if type(callback) == "function" then
		if self.player:hasFlag("slashTargetFixToOne") then
			local target = nil
			local others = self.room:getOtherPlayers(self.player)
			for _, player in sgs.qlist(others) do
				if player:hasFlag("SlashAssignee") then 
					target = player 
					break 
				end
			end
			if not target then 
				return "." 
			end
			local target2 = nil
			if #parsedPrompt >= 3 then
				local alives = self.room:getAlivePlayers()
				for _, p in sgs.qlist(alives) do
					if p:objectName() == parsedPrompt[3] then
						target2 = p
						break
					end
				end
			end
			local result = callback(self, nil, nil, target, target2, prompt)
			if result == nil or result == "." then 
				return "." 
			end
			local slash = sgs.Card_Parse(result)
			local no_distance = false
			if sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 then
				no_distance = true
			elseif self.player:hasFlag("slashNoDistanceLimit") then
				no_distance = true
			end
			local targets = {}
			local use = { to = sgs.SPlayerList() }
			if self.player:canSlash(target, slash, not no_distance) then 
				use.to:append(target) 
			else 
				return "." 
			end
			if target:hasSkill("xiansi") then
				if target:getPile("counter"):length() > 1 then
					if not self:needKongcheng() then
						return "@XiansiSlashCard=.->" .. target:objectName()
					elseif not self.player:isLastHandCard(slash, true) then
						return "@XiansiSlashCard=.->" .. target:objectName()
					end
				end
			end
			self:useCardSlash(slash, use)
			for _, p in sgs.qlist(use.to) do 
				table.insert(targets, p:objectName()) 
			end
			if table.contains(targets, target:objectName()) then 
				return result .. "->" .. table.concat(targets, "+") 
			end
			return "."
		end
	end
	local useslash, target
	local slashes = self:getCards("Slash")
	self:sort(self.opponents, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local limit = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash)
		local no_distance = limit > 50 or self.player:hasFlag("slashNoDistanceLimit")
		for _, friend in ipairs(self.partners_noself) do
			local can_use = self:willUseSlash(friend, self.player, card)
			if can_use then
				if self.player:canSlash(friend, slash, not no_distance) then
					if self:slashIsEffective(slash, friend) then
						if not self:hasHeavySlashDamage(self.player, card, friend) then
							can_use = false
							if self:canLeiji(friend, self.player) then
								can_use = true
							elseif self:mayLord(friend) then
								if self.player:hasSkill("guagu") then
									if friend:getLostHp() >= 1 then
										if sgs.getCardsNum("Jink", friend) == 0 then
											can_use = true
										end
									end
								end
							end
							if not can_use then
								if friend:hasSkill("jieming") then
									if self.player:hasSkill("nosrende") then
										if HuaTuo and self:isPartner(HuaTuo) then
											can_use = true
										end
									end
								end
							end
							if can_use then
								if self.player:hasFlag("slashTargetFix") then
									if not friend:hasFlag("SlashAssignee") then
										can_use = false
									end
								end
								if can_use then
									if slash:isKindOf("XiansiSlashCard") then
										local counters = friend:getPile("counter")
										if counters:length() < 2 then
											can_use = false
										end
									end
									if can_use then
										useslash = slash
										target = friend
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
	if not useslash then
		for _, slash in ipairs(slashes) do
			local limit = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash)
			local no_distance = limit > 50 or self.player:hasFlag("slashNoDistanceLimit")
			for _, enemy in ipairs(self.opponents) do
				if self.player:canSlash(enemy, slash, not no_distance) then
					if self:willUseSlash(enemy, self.player, slash) then
						if self:slashIsEffective(slash, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								local can_use = true
								if self.player:hasFlag("slashTargetFix") then
									if not enemy:hasFlag("SlashAssignee") then
										can_use = false
									end
								end
								if can_use then
									useslash = slash
									target = enemy
									break
								end
							end
						end
					end
				end
			end
		end
	end
	if useslash and target then
		if target:hasSkill("xiansi") then
			local counters = target:getPile("counter")
			if counters:length() > 1 then
				local can_use = true
				if self:needKongcheng() then
					if self.player:isLastHandCard(slash, true) then
						can_use = false
					end
				end
				if can_use then
					return "@XiansiSlashCard=.->" .. target:objectName()
				end
			end
		end
		local targets = {}
		local use = { 
			to = sgs.SPlayerList(), 
		}
		use.to:append(target)
		self:useCardSlash(useslash, use)
		for _, p in sgs.qlist(use.to) do 
			table.insert(targets, p:objectName()) 
		end
		if table.contains(targets, target:objectName()) then 
			return useslash:toString() .. "->" .. table.concat(targets, "+") 
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["slash_extra_targets"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defenseSlash")
	for _, target in ipairs(targets) do
		if self:isOpponent(target) then
			if self:willUseSlash(target, self.player, sgs.slash) then
				if sgs.isGoodTarget(self, target, targetlist) then
					if self:slashIsEffective(sgs.slash, target) then
						return target
					end
				end
			end
		end
	end
	return nil
end
sgs.ai_skill_playerchosen["zero_card_as_slash"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local arrBestHp, canAvoidSlash, forbidden = {}, {}, {}
	self:sort(targetlist, "defenseSlash")
	for _, target in ipairs(targetlist) do
		if self:isOpponent(target) then
			if self:willUseSlash(target, self.player, sgs.slash) then
				if sgs.isGoodTarget(self, target, targetlist) then
					if self:slashIsEffective(slash, target) then
						if self:invokeDamagedEffect(target, self.player, sgs.slash) then
							table.insert(forbidden, target)
						elseif self:canLeiji(target, self.player) then
							table.insert(forbidden, target)
						elseif self:needToLoseHp(target, self.player, true, true) then
							table.insert(arrBestHp, target)
						else
							return target
						end
					else
						table.insert(canAvoidSlash, target)
					end
				end
			end
		end
	end
	for i=#targetlist, 1, -1 do
		local target = targetlist[i]
		if self:willUseSlash(target, self.player, sgs.slash) then
			if self:slashIsEffective(slash, target) then
				if self:isPartner(target) then
					if self:needToLoseHp(target, self.player, true, true) then
						return target
					end
				end
				if self:invokeDamagedEffect(target, self.player, sgs.slash) then
					return target
				elseif self:canLeiji(target, self.player) then
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	if #canAvoidSlash > 0 then 
		return canAvoidSlash[1] 
	end
	if #arrBestHp > 0 then 
		return arrBestHp[1] 
	end
	self:sort(targetlist, "defenseSlash")
	targetlist = sgs.reverse(targetlist)
	for _,target in ipairs(targetlist) do
		if target:objectName() ~= self.player:objectName() then
			if not self:isPartner(target) then
				if not table.contains(forbidden, target) then
					return target
				end
			end
		end
	end
	return targetlist[1]
end
--[[
	套路：仅使用杀
]]--
sgs.ai_series["SlashOnly"] = {
	name = "SlashOnly", --套路名
	IQ = 1,
	value = 1, --套路发动价值
	priority = 1, --套路发动优先级
	cards = { --所需卡牌
		["Slash"] = 1, --所需卡牌的最少数目
		["Others"] = 0, --其它任意卡牌的最少数目
	},
	enabled = function(self) --是否适合发动（self：即表SmartAI）
		return sgs.Slash_IsAvailable(self.player) --self.player:usedTimes("Slash") < (sgs.slashAvail or 0) 
	end,
	action = function(self, handcards, skillcards) --行动内容（self：即表SmartAI；handcards：表示可以使用的手牌；skillcards：表示可用的技能卡>）
		if handcards then
			for _,slash in ipairs(handcards) do
				if slash:isKindOf("Slash") then
					return {slash} --结果：产生的出牌序列
				end
			end
		end
		return {}
	end,
	break_condition = function(self) --何时被中断以重新选择套路
		return false
	end,
}
table.insert(sgs.ai_card_actions["Slash"], "SlashOnly")
--[[****************************************************************
	闪
]]--****************************************************************
--[[
	内容：“闪”的卡牌成分
]]--
sgs.card_constituent["Jink"] = {
	use_value = 8.9,
	keep_value = 4,
}
sgs.ai_skill_cardask["slash-jink"] = function(self, data, pattern, target)
	local slash
	if type(data) == "userdata" then
		local effect = data:toSlashEffect()
		slash = effect.slash
	else
		slash = sgs.slash
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	--原版解烦
	if not target or self:isPartner(target) then
		if slash:hasFlag("nosjiefan-slash") then
			return "."
		end
	end
	--无视
	local ignore_func = sgs.ai_skill_cardask["nullfilter"]
	if ignore_func(self, data, pattern, target) then 
		return "." 
	end
	--大喝
	local jinks = self:getCards("Jink")
	local getDaheJink = function()
		if target then
			if target:hasSkill("dahe") then
				if self.player:hasFlag("dahe") then
					for _, card in ipairs(jinks) do
						if card:getSuit() == sgs.Card_Heart then
							return card:getId()
						end
					end
				end
			end
		end
		return nil
	end
	if not target then
		return getDaheJink()
	end
	if not self:hasHeavySlashDamage(target, slash, self.player) then
		if self:invokeDamagedEffect(self.player, target, slash) then
			return "." 
		end
	end
	if slash:isKindOf("NatureSlash") then
		if self.player:isChained() then
			if self:isGoodChainTarget(self.player, nil, nil, nil, slash) then 
				return "." 
			end
		end
	end
	if self:isPartner(target) then
		if target:hasSkill("jieyin") then
			if not self.player:isWounded() then
				if self.player:isMale() then
					if not self.player:hasSkill("leiji") then 
						return "." 
					end
				end
			end
		end
		if not target:hasSkill("jueqing") then
			if self.player:hasSkill("jieming") then
				if target:hasSkill("nosrende") then
					return "."
				elseif target:hasSkill("rende") then
					if not target:hasUsed("RendeCard") then
						return "." 
					end
				end
			end
			if target:hasSkill("pojun") then
				if not self.player:faceUp() then 
					return "." 
				end
			end
		end
	else
		local isHeavy = self:hasHeavySlashDamage(target, slash)
		if isHeavy then 
			return getDaheJink()
		end
		local current = self.room:getCurrent()
		if current then
			if current:hasSkill("juece") then
				if self.player:getHp() > 0 then
					local use = false
					for _, card in ipairs(jinks) do
						if not self.player:isLastHandCard(card, true) then
							use = true
							break
						end
					end
					if not use then 
						return "." 
					end
				end
			end
		end
		if self.player:getHandcardNum() == 1 then
			if self:needKongcheng() then 
				return getDaheJink()
			end
		end
		local qxFlag = false
		if target:hasSkill("nosqianxi") then
			if target:distanceTo(self.player) > 1 then
				qxFlag = true
			end
		end
		if target:hasSkill("mengjin") then
			if not qxFlag then
				if self:doNotDiscard(self.player, "he", true) then 
					return getDaheJink()
				end
				if self.player:getCards("he"):length() == 1 then
					if not self.player:getArmor() then 
						return getDaheJink()
					end
				end
				if self.player:hasSkills("jijiu|qingnang") then
					if self.player:getCards("he"):length() > 1 then 
						return "." 
					end
				end
				if self:canUseJieyuanDecrease(target) then 
					return "." 
				end
				if not self.player:hasSkills("tuntian+zaoxian") then
					if not self:willSkipPlayPhase() then
						if self:getCardsNum("Peach") > 0 then
							return "."
						elseif self:getCardsNum("Analeptic") > 0 then
							if self:isWeak() then
								return "."
							end
						end
					end
				end
			end
		end
		if not qxFlag then
			--贯石斧
			if target:hasWeapon("Axe") then
				if target:hasSkills(sgs.lose_equip_skill) then
					if target:getEquips():length() > 1 then
						if target:getCards("he"):length() > 2 then 
							return "." 
						end
					end
				end
				if target:getHandcardNum() - target:getHp() > 2 then
					if not self:isWeak() then
						if not self:getOverflow() then 
							return "." 
						end
					end
				end
			--青龙偃月刀
			elseif target:hasWeapon("Blade") then
				local flag = true
				if slash:isKindOf("FireSlash") then
					if not target:hasSkill("jueqing") then
						if self.player:hasArmorEffect("Vine") then
							flag = false
						elseif self.player:getMark("@gale") > 0 then
							flag = false
						end
					end
				end
				if flag and isHeavy then
					flag = false
				end
				if flag and self.player:getHp() == 1 then
					if #self.friends_noself == 0 then
						flag = false
					end
				end
				if flag then
					local flag2 = false
					if self.player:getHp() > 1 then
						if self:getCardsNum("Jink") <= sgs.getCardsNum("Slash", target) then
							flag2 = true
						end
						if self.player:hasSkill("qingnang") then
							flag2 = true
						end
					end
					if not flag2 then
						if self.player:hasSkill("jijiu") then
							if sgs.getKnownCard(self.player, "red") > 0 then
								flag2 = true
							end
						end
					end
					if not flag2 then
						if self:canUseJieyuanDecrease(target) then
							flag2 = true
						end
					end
					if flag2 then
						return "."
					end
				end
			end
		end
	end
end
--[[****************************************************************
	桃
]]--****************************************************************
--[[
	内容：“桃”的卡牌成分
]]--
sgs.card_constituent["Peach"] = {
	benefit = 1,
	use_value = 6,
	keep_value = 5,
	use_priority = 0.9,
}
--[[
	内容：“桃”的卡牌仇恨值
]]--
sgs.ai_card_intention["Peach"] = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if not to:hasSkill("wuhun") then 
			sgs.updateIntention(from, to, -120)
		end
	end
end
--[[
	内容：注册桃
]]--
sgs.RegistCard("Peach")
--[[
	功能：使用桃
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardPeach(card, use)
	if self.player:isWounded() then
		if sgs.SeriesName then
			local callback = sgs.ai_series_use_func["Peach"][sgs.SeriesName]
			if callback then
				if callback(self, card, use) then
					return 
				end
			end
		end
		--一般情形
		local peachCount = self:getCardsNum("Peach")
		local overflow = self:getOverflow(nil, true)
		if self.player:hasSkill("yongsi") then
			if peachCount > overflow then
				use.card = card
				return
			end
		end
		local maxcard = self.player:getMaxCards()
		local num = self.player:getHandcardNum()
		if self.player:hasSkill("longhun") then
			if not self:amLord() then
				local equips = self.player:getCards("e")
				if math.min(maxcard, num) + equips:length() > 3 then 
					return 
				end
			end
		end
		local peaches = 0
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		local myname = self.player:objectName()
		local lordname = sgs.ai_lord[myname]
		local lord = nil
		if lordname then
			lord = findPlayerByObjectName(self.room, lordname)
		end
		for _,c in ipairs(cards) do
			if sgs.isCard("Peach", c, self.player) then 
				peaches = peaches + 1 
			end
		end
		local hp = self.player:getHp()
		if self:amLord() then
			if self.player:hasSkill("hunzi") then
				if self.player:getMark("hunzi") == 0 then
					if hp < 4 then
						if hp > peaches then 
							return 
						end
					end
				end
			end
		end
		local canRende = false
		if self.player:hasSkill("nosrende") then
			canRende = true
		elseif self.player:hasSkill("rende") then
			if not self.player:hasUsed("RendeCard") then
				canRende = true
			end
		end
		if canRende then
			if self:hasPartners("draw") then 
				return 
			end
		end
		if self.player:hasArmorEffect("SilverLion") then
			for _,c in sgs.qlist(handcards) do
				if c:isKindOf("Armor") then
					if self:evaluateArmor(c) > 0 then
						use.card = card
						return
					end
				end
			end
		end
		local SilverLion, OtherArmor
		for _,c in sgs.qlist(handcards) do
			if c:isKindOf("SilverLion") then
				SilverLion = c
			elseif c:isKindOf("Armor") then
				if self:evaluateArmor(c) > 0 then
					OtherArmor = true
				end
			end
		end
		if SilverLion and OtherArmor then
			use.card = SilverLion
			return
		end
		local must_use = false
		for _,enemy in ipairs(self.opponents) do
			if num < 3 then
				if self:hasSkills(sgs.drawpeach_skill, enemy) then
					must_use = true
					break
				elseif sgs.getCardsNum("Dismantlement", enemy) >= 1 then
					must_use = true
					break
				end
				if enemy:hasSkill("jixi") then
					if enemy:getPile("field"):length() >0 then
						if enemy:distanceTo(self.player) == 1 then
							must_use = true
							break
						end
					end
				end
				if enemy:hasSkill("qixi") then
					if sgs.getKnownCard(enemy, "black", nil, "he") >= 1 then
						must_use = true
						break
					end
				end
				if sgs.getCardsNum("Snatch", enemy) >= 1 then
					if enemy:distanceTo(self.player) == 1 then
						must_use = true
						break
					end
				end
				if enemy:hasSkill("tiaoxin") then
					if self.player:inMyAttackRange(enemy) then
						if self:getCardsNum("Slash") < 1 then
							must_use = true
							break
						elseif not self.player:canSlash(enemy) then
							must_use = true
							break
						end
					end
				end
			end
		end
		local lost = self.player:getLostHp()
		local JinXuanDi = self.room:findPlayerBySkillName("wuling")
		if JinXuanDi then
			if JinXuanDi:getMark("@water") > 0 then
				if lost >= 2 then
					must_use = true
				end
			end
		end
		if hp == 1 then
			local flag = true
			if lord then
				if lord:getHp() < 2 then
					if self:isWeak(lord) then
						flag = false
					end
				end
			end
			if flag then
				must_use = true
			end
		end
		if must_use then
			use.card = card
			return
		elseif self.player:hasSkill("buqu") and hp < 1 then
			use.card = card
			return 
		elseif peaches > hp then
			use.card = card
			return
		end
		overflow = self:getOverflow()
		if overflow <= 0 then
			if #self.partners_noself > 0 then
				return
			end
		end
		if self.player:hasSkill("kuanggu") then
			if not self.player:hasSkill("jueqing") then
				if lost == 1 then
					if self.player:getOffensiveHorse() then
						return
					end
				end
			end
		end
		if self:needToLoseHp(self.player, nil, nil, nil, true) then 
			return 
		end
		if lord then
			if lord:getHp() <= 2 then
				if self:isWeak(lord) then
					if self:amLord() then 
						use.card = card 
					elseif peachCount > 1 then
						if peachCount + self:getCardsNum("Jink") > maxcard then 
							use.card = card 
						end
					end
					return
				end
			end
		end
		self:sort(self.partners, "hp")
		if self.partners[1]:objectName() == myname then
			use.card = card
			return
		elseif hp < 2 then
			use.card = card
			return
		end
		if #self.partners > 1 then
			if self.partners[2]:getHp() < 3 then
				if not self.partners[2]:hasSkill("buqu") then
					if overflow < 1 then
						return
					end
				end
			end
		end
		if self.player:hasSkill("jieyin") then
			if overflow > 0 then
				for _,friend in ipairs(self.partners) do
					if friend:isWounded() then
						if friend:isMale() then 
							return 
						end
					end
				end
			end
		end
		if self.player:hasSkill("ganlu") then
			if not self.player:hasUsed("GanluCard") then
				local dummy_use = {
					isDummy = true,
				}
				local ganlu_card = sgs.Card_Parse("@GanluCard=.")
				self:useSkillCard(ganlu_card, dummy_use)
				if dummy_use.card then 
					return 
				end
			end
		end
		use.card = card
	end
end
--[[
	套路：仅使用桃
]]--
sgs.ai_series["PeachOnly"] = {
	name = "PeachOnly",
	IQ = 1,
	value = 2, 
	priority = 1, 
	cards = {
		["Peach"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return self.player:isWounded()
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,peach in ipairs(handcards) do
				if peach:isKindOf("Peach") then
					return {peach}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Peach"], "PeachOnly")
--[[****************************************************************
	----------------------------------------------------------------
	锦 囊 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[****************************************************************
	桃园结义（非延时性锦囊，全局效果）
]]--****************************************************************
--[[
	内容：“桃园结义”的卡牌成分
]]--
sgs.card_constituent["GodSalvation"] = {
	benefit = 1,
	use_priority = 1.1,
}
--[[
	内容：“桃园结义”的卡牌仇恨值
]]--
sgs.ai_card_intention["GodSalvation"] = function(self, card, from, tos)
	local can, first
	for _, to in ipairs(tos) do
		if to:isWounded() and not first then
			first = to
			can = true
		elseif first and to:isWounded() and not self:isFriend(first, to) then
			can = false
			break
		end
	end
	if can then
		sgs.updateIntention(from, first, -10)
	end
end
--[[
	内容：注册桃园结义
]]--
sgs.RegistCard("GodSalvation")
--[[
	功能：使用桃园结义
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardGodSalvation(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["GodSalvation"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	if self:willUseGodSalvation(card) then
		use.card = card
	end
end
--[[
	套路：仅使用桃园结义
]]--
sgs.ai_series["GodSalvationOnly"] = {
	name = "GodSalvationOnly",
	IQ = 1,
	value = 1, 
	priority = 1, 
	cards = {
		["GodSalvation"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		for _,partner in ipairs(self.partners) do
			if partner:isWounded() then
				if not self.player:isProhibited(partner, sgs.god_salvation) then
					return true
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,gs in ipairs(handcards) do
				if gs:isKindOf("GodSalvation") then
					return {gs}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["GodSalvation"], "GodSalvationOnly")
--[[****************************************************************
	五谷丰登（非延时性锦囊，全局效果）
]]--****************************************************************
--[[
	内容：“五谷丰登”的卡牌成分
]]--
sgs.card_constituent["AmazingGrace"] = {
	use_value = 3,
	keep_value = -1,
	use_priority = 1.2,
}
sgs.ai_skill_askforag["amazing_grace"] = function(self, card_ids)
	local count = #card_ids
	if count == 1 then
		return card_ids[1]
	end
	--初始化
	local cards = {}
	local tricks = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
		if card:isKindOf("TrickCard") then
			table.insert(tricks, card)
		end
	end
	--下家数据
	local next_alive = self.player:getNextAlive()
	local next_can_use = false
	local next_is_enemy = false
	if sgs.turncount > 1 then
		if not self:willSkipPlayPhase(next_alive) then
			if self:isPartner(next_alive) then
				next_can_use = true
			else
				next_is_enemy = true
			end
		end
	end
	--离魂对下家数据的影响
	if next_can_use then
		if next_alive:isMale() then
			if not next_alive:faceUp() then
				if next_alive:getHandcardNum() > 4 then
					for _,enemy in ipairs(self.opponents) do
						if enemy:hasSkill("lihun") then
							next_can_use = false
							break
						end
					end
				end
			end
		end
	end
	--补益
	local need_buyi = false
	if self.player:getHp() <= 1 then
		for _,friend in ipairs(self.partners) do
			if friend:hasSkill("buyi") then
				need_buyi = false
				break
			end
		end
	end
	if need_buyi then
		local maxValue = -100
		local maxValueCard = nil
		local minValue = 100
		local minValueCard = nil
		for _,card in ipairs(cards) do
			if not card:isKindOf("BasicCard") then
				local value = sgs.getUseValue(card, self.player)
				if value > maxValue then
					maxValue = value
					maxValueCard = card
				end
				if value < minValue then
					minValue = value
					minValueCard = card
				end
			end
		end
		if minValueCard and next_can_use then
			return minValueCard:getEffectiveId()
		elseif maxValueCard then
			return maxValueCard:getEffectiveId()
		end
	end
	--桃
	local current = self.room:getCurrent()
	local amCurrent = ( current:objectName() == self.player:objectName() )
	--Waiting For More Details
	local index = math.random(1, count)
	return card_ids[index]--:getEffectiveId() --Just For Test
end
--[[
	内容：注册五谷丰登
]]--
sgs.RegistCard("AmazingGrace")
--[[
	功能：使用五谷丰登
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardAmazingGrace(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["AmazingGrace"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	--一般情形
	if self.player:hasSkill("noswuyan") then 
		use.card = card 
		return 
	end
	if sgs.turncount <= 2 then
		if self.player:getSeat() <= 3 then
			if self.player:aliveCount() > 5 then
				if self:amLord() then
					return
				elseif self:amLoyalist() then
					return 
				end
			end
		end
	end
	local value = 1
	local suf, coeff = 0.8, 0.8
	if self:needKongcheng() then
		if self.player:getHandcardNum() == 1 then
			suf = 0.6
			coeff = 0.6
		elseif self.player:hasSkills("nosjizhi|jizhi") then
			suf = 0.6
			coeff = 0.6
		end
	end
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		local index = 0
		local isEffective = self:AG_IsEffective(card, p, self.player)
		if isEffective then
			if self:isPartner(p) then
				index = 1
			elseif self:isOpponent(p) then
				index = -1
			end
		end
		value = value + index * suf
		if value < 0 then 
			return 
		end
		suf = suf * coeff
	end
	use.card = card
end
--[[
	套路：仅使用五谷丰登
]]--
sgs.ai_series["AmazingGraceOnly"] = {
	name = "AmazingGraceOnly",
	IQ = 1,
	value = 1, 
	priority = 1, 
	cards = {
		["AmazingGrace"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,ag in ipairs(handcards) do
				if ag:isKindOf("AmazingGrace") then
					return {ag}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["AmazingGrace"], "AmazingGraceOnly")
--[[****************************************************************
	南蛮入侵（非延时性锦囊，多目标攻击性锦囊）
]]--****************************************************************
--[[
	内容：“南蛮入侵”的卡牌成分
]]--
sgs.card_constituent["SavageAssault"] = {
	damage = 3,
	use_value = 3.9,
	use_priority = 3.5,
}
sgs.ai_skill_cardask["savage-assault-slash"] = function(self, data, pattern, target)
	if sgs.ai_skill_cardask["nullfilter"](self, data, pattern, target) then 
		return "." 
	end
	local attacker = target
	local menghuo = self.room:findPlayerBySkillName("huoshou")
	if menghuo then 
		attacker = menghuo 
	end
	if not self:damageIsEffective(nil, nil, attacker) then 
		return "." 
	end
	if self:invokeDamagedEffect(self.player, attacker, sgs.savage_assault) then
		return "."
	end
	if self:needToLoseHp(self.player, attacker) then 
		return "." 
	end
	if not attacker:hasSkill("jueqing") then
		if self.player:hasSkill("wuyan") then
			return "."
		end
		if attacker:hasSkill("wuyan") then
			return "."
		end
		if self.player:hasSkill("fenyong") then
			if self.player:getMark("@fenyong") > 0 then
				return "."
			end
		end
		if self.player:hasSkill("jianxiong") then
			if not self.player:containsTrick("indulgence") then
				local flag = false
				if self.player:getHp() > 1 then
					flag = true
				elseif self:getAllPeachNum() > 0 then
					flag = true
				end
				if flag then
					if not self:needKongcheng(self.player, true) then
						if self:getAoeValue(sgs.savage_assault) > -10 then
							return "."
						end
					end
					if sgs.ai_qice_data then
						local damage_card = sgs.ai_qice_card:toCardUse().card
						if damage_card:subcardsLength() > 2 then
							self.jianxiong = true
							return "."
						end
						if not self:needKongcheng(self.player, true) then
							local subcards = damage_card:getSubcards()
							for _,id in sgs.qlist(subcards) do
								local card = sgs.Sanguosha:getCard(id)
								if sgs.isCard("Peach", card, self.player) then
									return "."
								end
							end
						end
					end
				end
			end
		end
	end
	local current = self.room:getCurrent()
	if current then
		if current:hasSkill("juece") then
			if self:isOpponent(current) then
				if self.player:getHp() > 0 then
					local use = false
					local slashes = self:getCards("Slash")
					for _,card in ipairs(slashes) do
						if not self.player:isLastHandCard(card, true) then
							use = true
							break
						end
					end
					if not use then 
						return "." 
					end
				end
			end
		end
	end
end
--[[
	内容：注册南蛮入侵
]]--
sgs.RegistCard("SavageAssault")
--[[
	功能：使用南蛮入侵
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSavageAssault(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["SavageAssault"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	use.card = card
end
--[[
	套路：仅使用南蛮入侵
]]--
sgs.ai_series["SavageAssaultOnly"] = {
	name = "SavageAssaultOnly",
	IQ = 1,
	value = 2, 
	priority = 1, 
	cards = {
		["SavageAssault"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,sa in ipairs(handcards) do
				if sa:isKindOf("SavageAssault") then
					return {sa}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["SavageAssault"], "SavageAssaultOnly")
--[[****************************************************************
	万箭齐发（非延时性锦囊，多目标攻击性锦囊）
]]--****************************************************************
--[[
	内容：“万箭齐发”的卡牌成分
]]--
sgs.card_constituent["ArcheryAttack"] = {
	damage = 3,
	use_value = 3.8,
	use_priority = 3.5,
}
sgs.ai_skill_cardask["archery-attack-jink"] = function(self, data, pattern, target)
	if sgs.current_mode:find("_mini_35") then
		if self.player:getLostHp() == 1 then 
			return "." 
		end
	end
	if sgs.ai_skill_cardask["nullfilter"](self, data, pattern, target) then 
		return "." 
	end
	local attacker = target
	if not self:damageIsEffective(nil, nil, attacker) then 
		return "." 
	end
	if self:invokeDamagedEffect(self.player, attacker, sgs.archery_attack) then
		return "."
	end
	if self:needToLoseHp(self.player, attacker) then 
		return "." 
	end
	if not attacker:hasSkill("jueqing") then
		if self.player:hasSkill("wuyan") then
			return "."
		end
		if attacker:hasSkill("wuyan") then
			return "."
		end
		if self.player:hasSkill("fenyong") then
			if self.player:getMark("@fenyong") > 0 then
				return "."
			end
		end
		if self.player:hasSkill("jianxiong") then
			if not self.player:containsTrick("indulgence") then
				local flag = false
				if self.player:getHp() > 1 then
					flag = true
				elseif self:getAllPeachNum() > 0 then
					flag = true
				end
				if flag then
					if not self:needKongcheng(self.player, true) then
						if self:getAoeValue(sgs.archery_attack) > -10 then
							return "."
						end
					end
					if sgs.ai_qice_data then
						local damage_card = sgs.ai_qice_data:toCardUse().card
						if damage_card:subcardsLength() > 2 then
							self.jianxiong = true
							return "."
						end
						if not self:needKongcheng(self.player, true) then
							local subcards = damage_card:getSubcards()
							for _,id in sgs.qlist(subcards) do
								local card = sgs.Sanguosha:getCard(id)
								if sgs.isCard("Peach", card, self.player) then
									return "."
								end
							end
						end
					end
				end
			end
		end
	end
	local current = self.room:getCurrent()
	if current then
		if current:hasSkill("juece") then
			if self:isOpponent(current) then	
				if self.player:getHp() > 0 then
					local use = false
					local jinks = self:getCards("Jink")
					for _, card in ipairs(jinks) do
						if not self.player:isLastHandCard(card, true) then
							use = true
							break
						end
					end
					if not use then 
						return "." 
					end
				end
			end
		end
	end
end
--[[
	内容：注册万箭齐发
]]--
sgs.RegistCard("ArcheryAttack")
--[[
	功能：使用万箭齐发
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardArcheryAttack(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["ArcheryAttack"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	use.card = card
end
--[[
	套路：仅使用万箭齐发
]]--
sgs.ai_series["ArcheryAttackOnly"] = {
	name = "ArcheryAttackOnly",
	IQ = 1,
	value = 2, 
	priority = 1, 
	cards = {
		["ArcheryAttack"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,aa in ipairs(handcards) do
				if aa:isKindOf("ArcheryAttack") then
					return {aa}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["ArcheryAttack"], "ArcheryAttackOnly")
--[[****************************************************************
	借刀杀人（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	内容：“借刀杀人”的卡牌成分
]]--
sgs.card_constituent["Collateral"] = {
	control = 1,
	use_value = 5.8,
	use_priority = 2.75,
}
--[[
	内容：“借刀杀人”的卡牌仇恨值
]]--
sgs.ai_card_intention["Collateral"] = function(self, card, from, tos)
	assert(#tos == 1)
	sgs.ai_collateral = false
end
sgs.ai_skill_cardask["collateral-slash"] = function(self, data, pattern, target2, target, prompt)
	return "." --Just For Test
end
--[[
	内容：注册借刀杀人
]]--
sgs.RegistCard("Collateral")
--[[
	功能：使用借刀杀人
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardCollateral(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Collateral"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	if self.player:hasSkill("noswuyan") then 
		return 
	end	
	local others = self.room:getOtherPlayers(self.player)
	local alives = self.room:getAlivePlayers()
	local fromList = sgs.QList2Table(others)
	local toList = sgs.QList2Table(alives)
	local function compare_func(a, b)
		local anum = sgs.getCardsNum("Slash", a)
		local bnum = sgs.getCardsNum("Slash", b)
		if anum ~= bnum then 
			return anum < bnum 
		end
		return a:getHandcardNum() < b:getHandcardNum()
	end
	table.sort(fromList, compare_func)
	self:sort(toList, "defense")
	local needCrossbow = false
	for _,enemy in ipairs(self.opponents) do
		if self.player:canSlash(enemy) then
			if sgs.isGoodTarget(self, enemy, self.enemies) then
				if self:willUseSlash(enemy) then
					needCrossbow = true
					break
				end
			end
		end
	end
	if not needCrossbow then
		if self:getCardsNum("Slash", friend) > 2 then
			needCrossbow = not self.player:hasSkill("paoxiao")
		end
	end
	if needCrossbow then
		for i = #fromList, 1, -1 do
			local friend = fromList[i]
			local can_use = true
			if use.current_targets then
				if table.contains(use.current_targets, friend:objectName()) then
					can_use = false
				end
			end
			if can_use then
				can_use = false
				local weapon = friend:getWeapon()
				if weapon then
					if weapon:isKindOf("Crossbow") then
						if self:trickIsEffective(card, friend) then
							can_use = true
						end
					end
				end
			end
			if can_use then
				for _, enemy in ipairs(toList) do
					if friend:canSlash(enemy, nil) then
						if friend:objectName() ~= enemy:objectName() then
							self.room:setPlayerFlag(self.player, "needCrossbow")
							use.card = card
							if use.to then 
								use.to:append(friend) 
								use.to:append(enemy)
							end
							return
						end
					end
				end
			end
		end
	end
	local n = nil
	local final_enemy = nil
	for _, enemy in ipairs(fromList) do
		local can_use = false
		if enemy:getWeapon() then
			if self:isOpponent(self.player, enemy) then
				if self:trickIsEffective(card, enemy) then
					if not self:hasSkills(sgs.lose_equip_skill, enemy) then
						if not self:hasAllSkills("tuntian+zaoxian", enemy) then
							can_use = true
						end
					end
				end
			end
		end
		if can_use then
			if use.current_targets then
				if table.contains(use.current_targets, enemy:objectName()) then
					can_use = false
				end
			end
		end
		if can_use then
			if enemy:hasSkill("weimu") then
				if card:isBlack() then
					can_use = false
				end
			end
		end
		if can_use then
			for _, enemy2 in ipairs(toList) do
				if enemy:canSlash(enemy2) then
					if self:isOpponent(enemy2) then
						if enemy:objectName() ~= enemy2:objectName() then
							n = 1
							final_enemy = enemy2
							break
						end
					end
				end
			end
			if not n then
				for _, enemy2 in ipairs(toList) do
					if enemy:canSlash(enemy2) then
						if self:isTempEnemy(enemy2) then
							if enemy:objectName() ~= enemy2:objectName() then
								n = 1
								final_enemy = enemy2
								break
							end
						end
					end
				end
			end
			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) then
						if self:isPartner(friend) then
							if enemy:objectName() ~= friend:objectName() then
								if self:needToLoseHp(friend, enemy, true, true) then
									n = 1
									final_enemy = friend
									break
								elseif self:invokeDamagedEffect(friend, enemy, true) then
									n = 1
									final_enemy = friend
									break
								end
							end
						end
					end
				end
			end
			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) then
						if self:isPartner(friend) then
							if enemy:objectName() ~= friend:objectName() then
								if sgs.getKnownCard(friend, "Jink", true, "he") >= 2 then
									n = 1
									final_enemy = friend
									break
								elseif sgs.getCardsNum("Slash", enemy) < 1 then
									n = 1
									final_enemy = friend
									break
								end
							end
						end
					end
				end
			end
			if n then 
				use.card = card
				if use.to then 
					use.to:append(enemy) 
					use.to:append(final_enemy)
				end
				return
			end
		end
		n = nil
	end
	for _,friend in ipairs(fromList) do
		if self:isPartner(friend) then
			if friend:getWeapon() then
				if not self.room:isProhibited(self.player, friend, card) then
					if self:trickIsEffective(card, friend) then
						local can_use = true
						if use.current_targets then
							if table.contains(use.current_targets, friend:objectName()) then
								can_use = false
							end
						end
						if can_use then
							can_use = false
							if sgs.getKnownCard(friend, "Slash", true, "he") > 0 then
								can_use = true
							elseif sgs.getCardsNum("Slash", friend) > 1 then
								can_use = true
							elseif friend:getHandcardNum() >= 4 then
								can_use = true
							end
						end
						if can_use then
							for _, enemy in ipairs(toList) do
								if friend:canSlash(enemy, nil) then
									if self:isOpponent(enemy) then
										if friend:objectName() ~= enemy:objectName() then
											if sgs.isGoodTarget(self, enemy, self.opponents) then
												if self:willUseSlash(enemy, self.player) then
													use.card = card
													if use.to then 
														use.to:append(friend) 
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
					end
				end
			end
		end
	end
	for _,friend in ipairs(fromList) do
		local can_use = false
		local weapon = friend:getWeapon()
		if weapon then
			if friend:hasSkills(sgs.lose_equip_skill) then
				if self:isPartner(friend) then
					if self:trickIsEffective(card, friend) then
						if not self.room:isProhibited(self.player, friend, card) then
							can_use = true
						end
					end
				end
			end
		end
		if can_use then
			if use.current_targets then
				if table.contains(use.current_targets, friend:objectName()) then
					can_use = false
				end
			end
		end
		if can_use then
			if weapon:isKindOf("Crossbow") then
				if sgs.getCardsNum("Slash", friend) > 1 then
					can_use = false
				end
			end
		end
		if can_use then
			for _, enemy in ipairs(toList) do
				if friend:canSlash(enemy, nil) then
					if friend:objectName() ~= enemy:objectName() then
						use.card = card
						if use.to then 
							use.to:append(friend) 
							use.to:append(enemy)
						end
						return
					end
				end
			end
		end
	end
end
--[[
	套路：仅使用借刀杀人
]]--
sgs.ai_series["CollateralOnly"] = {
	name = "CollateralOnly",
	IQ = 1,
	value = 2, 
	priority = 1, 
	cards = {
		["Collateral"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		local others = self.room:getOtherPlayers(self.player)
		for _,target in sgs.qlist(others) do
			if target:getWeapon() then
				local victims = self.room:getOtherPlayers(target)
				for _,victim in sgs.qlist(victims) do
					if target:canSlash(victim) then
						return true
					end
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,collateral in ipairs(handcards) do
				if collateral:isKindOf("Collateral") then
					return {collateral}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Collateral"], "CollateralOnly")
--[[****************************************************************
	无中生有（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	内容：“无中生有”的卡牌成分
]]--
sgs.card_constituent["ExNihilo"] = {
	benefit = 2,
	use_value = 10,
	keep_value = 3.6,
	use_priority = 9.3,
}
--[[
	内容：“无中生有”的卡牌仇恨值
]]--
sgs.ai_card_intention["ExNihilo"] = -80
--[[
	内容：注册无中生有
]]--
sgs.RegistCard("ExNihilo")
--[[
	功能：使用无中生有
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardExNihilo(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["ExNihilo"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	use.card = card
	if not use.isDummy then
		self:speak("lucky")
	end
end
--[[
	套路：仅使用无中生有
]]--
sgs.ai_series["ExNihiloOnly"] = {
	name = "ExNihiloOnly",
	IQ = 1,
	value = 3, 
	priority = 1, 
	cards = {
		["ExNihilo"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,en in ipairs(handcards) do
				if en:isKindOf("ExNihilo") then
					return {en}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["ExNihilo"], "ExNihiloOnly")
--[[****************************************************************
	决斗（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	内容：“决斗”的卡牌成分
]]--
sgs.card_constituent["Duel"] = {
	damage = 2,
	use_value = 3.7,
	keep_value = 1.7,
	use_priority = 2.9,
}
--[[
	内容：“决斗”的卡牌仇恨值
]]--
sgs.ai_card_intention["Duel"] = function(self, card, source, targets)
	if sgs.ai_lijian_effect then 
		sgs.ai_lijian_effect = false
		return
	end
	sgs.updateIntentions(source, targets, 80)
end
sgs.ai_skill_cardask["duel-slash"] = function(self, data, pattern, target)
	if self.player:getPhase() == sgs.Player_Play then 
		return self:getCardId("Slash") 
	end
	if sgs.ai_skill_cardask["nullfilter"](self, data, pattern, target) then 
		return "." 
	end
	if self.player:hasFlag("AIGlobal_NeedToWake") then
		if self.player:getHp() > 1 then 
			return "." 
		end
	end
	if not target:hasSkill("jueqing") then
		if target:hasSkill("wuyan") then
			return "."
		elseif self.player:hasSkill("wuyan") then
			return "."
		end
		if self.player:getMark("@fenyong") > 0 then
			if self.player:hasSkill("fenyong") then 
				return "." 
			end
		end
	end
	if self.player:hasSkill("wuhun") then
		if self:isEnemy(target) then
			if self:mayLord(target) then
				if #self.friends_noself > 0 then 
					return "." 
				end
			end
		end
	end
	if self:cannotBeHurt(target) then 
		return "." 
	end
	if self:isPartner(target) then
		if target:hasSkill("rende") then
			if self.player:hasSkill("jieming") then 
				return "." 
			end
		end
	end
	if self:isOpponent(target) then
		if not self:isWeak() then
			if self:invokeDamagedEffect(self.player, target) then 
				return "." 
			end
		end
	end
	if self:isPartner(target) then
		if self:invokeDamagedEffect(self.player, target) then
			return "."
		elseif self:needToLoseHp(self.player, target) then 
			return "." 
		end
		if self:invokeDamagedEffect(target, self.player) then
			return self:getCardId("Slash")
		elseif self:needToLoseHp(target, self.player) then
			return self:getCardId("Slash")
		else
			if self:mayLord(target) then
				if not sgs.isGoodHp(self.player) then
					if not sgs.isInDanger(target) then
						return self:getCardId("Slash")
					end
				end
			end
			if self:amLord() then
				if sgs.isInDanger(self.player) then
					return self:getCardId("Slash")
				end
			end
		end
	end
	if not self:isPartner(target) then
		if self:getCardsNum("Slash") >= sgs.getCardsNum("Slash", target) then
			return self:getCardId("Slash")
		end
	end
	if target:getHp() > 2 then
		if self.player:getHp() <= 1 then
			if self:getCardsNum("Peach") == 0 then
				if not self.player:hasSkill("buqu") then
					return self:getCardId("Slash")
				end
			end
		end
	end
	return "."
end
--[[
	内容：注册决斗
]]--
sgs.RegistCard("Duel")
--[[
	功能：使用决斗
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDuel(duel, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Duel"][sgs.SeriesName]
		if type(callback) == "function" then
			if callback(self, card, use) then
				return 
			end
		end
	end
	if self.player:hasSkill("wuyan") then
		if not self.player:hasSkill("jueqing") then 
			return 
		end
	end
	if self.player:hasSkill("noswuyan") then 
		return 
	end
	local enemies = self:exclude(self.opponents, duel)
	local friends = self:exclude(self.partners_noself, duel)
	local targets = {}
	local function canUseDuelTo(target)
		if self:trickIsEffective(duel, target) then
			if self:damageIsEffective(target, sgs.DamageStruct_Normal) then
				return not self.player:isProhibited(target, duel)
			end
		end
		return false
	end
	local HuaTuo = self.room:findPlayerBySkillName("jijiu")
	if HuaTuo then
		if self:isPartner(HuaTuo) then
			if self.player:hasSkill("rende") then
				for _,friend in ipairs(friends) do
					if friend:hasSkill("jieming") then
						if canUseDuelTo(friend) then
							table.insert(targets, friend)
						end
					end
				end
			end
		end
	end
	for _, enemy in ipairs(enemies) do
		if canUseDuelTo(enemy) then
			local name = enemy:objectName()
			local flag = "duelTo_" .. name
			if self.player:hasFlag(flag) then
				if not use.current_targets then
					table.insert(targets, enemy)
				elseif not table.contains(use.current_targets, name) then
					table.insert(targets, enemy)
				end
			end
		end
	end
	local function compare_func(a, b)
		local v1 = sgs.getCardsNum("Slash", a) + a:getHp()
		local v2 = sgs.getCardsNum("Slash", b) + b:getHp()
		if self:invokeDamagedEffect(a, self.player) then v1 = v1 + 20 end
		if self:invokeDamagedEffect(b, self.player) then v2 = v2 + 20 end
		if not self.player:hasSkill("jueqing") then
			if not self:isWeak(a) and a:hasSkill("jianxiong") then v1 = v1 + 10 end
			if not self:isWeak(b) and b:hasSkill("jianxiong") then v2 = v2 + 10 end
		end
		if self:needToLoseHp(a) then v1 = v1 + 5 end
		if self:needToLoseHp(b) then v2 = v2 + 5 end
		if self:hasSkills(sgs.masochism_skill, a) then v1 = v1 + 5 end
		if self:hasSkills(sgs.masochism_skill, b) then v2 = v2 + 5 end
		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end
		--if a:hasLordSkill("jijiang") then v1 = v1 + self:JijiangSlash(a) * 2 end
		--if b:hasLordSkill("jijiang") then v2 = v2 + self:JijiangSlash(b) * 2 end
		if v1 == v2 then 
			return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b) 
		end
		return v1 < v2
	end
	table.sort(enemies, compare_func)
	local n1 = self:getCardsNum("Slash")
	for _,enemy in ipairs(enemies) do
		if canUseDuelTo(enemy) then
			if not self:cannotBeHurt(enemy) then
				if sgs.isGoodTarget(self, enemy, enemies) then
					if not table.contains(targets, enemy) then 
						local can_use = false
						local n2 = sgs.getCardsNum("Slash", enemy)
						if sgs.card_lack[enemy:objectName()]["Slash"] == 1 then 
							n2 = 0 
						end
						if n1 >= n2 then
							can_use = true
						elseif self:needToLoseHp(self.player, nil, nil, true) then
							can_use = true
						elseif self:invokeDamagedEffect(self.player, enemy) then
							can_use = true
						elseif sgs.isGoodHp(self.player) then
							if n2 < 1 then
								can_use = true
							elseif self.player:hasSkill("jianxiong") then
								can_use = true
							elseif self.player:getMark("shuangxiong") > 0 then
								can_use = true
							end
						end
						if can_use then
							if not use.current_targets then
								table.insert(targets, enemy)
							elseif not table.contains(use.current_targets, enemy:objectName()) then
								table.insert(targets, enemy) 
							end
						end
					end
				end
			end
		end
	end
	if #targets > 0 then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation then
			if godsalvation:getId() ~= duel:getId() then
				if self:willUseGodSalvation(godsalvation) then
					local use_gs = true
					for _, p in ipairs(targets) do
						if not p:isWounded() or not self:trickIsEffective(godsalvation, p, self.player) then 
							break 
						end
						use_gs = false
					end
					if use_gs then
						use.card = godsalvation
						return
					end
				end
			end
		end
		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, duel)
		local enemySlash = 0
		local setFlag = false
		local LiuXie = self.room:findPlayerBySkillName("huangen")
		local LiuXieFlag = false
		if LiuXie then
			if self:isOpponent(LiuXie) then
				if LiuXie:getHp() > targets_num / 2 then
					LiuXieFlag = true
				end
			end
		end
		use.card = duel
		for i=1, #targets, 1 do
			local target = targets[i]
			local n2 = sgs.getCardsNum("Slash", target)
			if sgs.card_lack[target:objectName()]["Slash"] == 1 then 
				n2 = 0 
			end
			if self:isOpponent(target) then 
				enemySlash = enemySlash + n2 
			end
			if use.to then
				if i == 1 and not use.current_targets then
					use.to:append(target)
					if not use.isDummy then 
						self:speak("duel", self.player:isFemale()) 
					end
				elseif n1 >= enemySlash then
					if not target:hasSkill("danlao") then
						if not LiuXieFlag then
							use.to:append(target)
						end
					end
				end
				if not setFlag then
					if self.player:getPhase() == sgs.Player_Play then
						if self:isOpponent(target) then 
							self.player:setFlags("duelTo" .. target:objectName())
							setFlag = true
						end
					end
				end
				if use.to:length() == targets_num then 
					return 
				end
			end
		end
	end
end
--[[
	套路：仅使用决斗
]]--
sgs.ai_series["DuelOnly"] = {
	name = "DuelOnly",
	IQ = 1,
	value = 3, 
	priority = 1, 
	cards = {
		["Duel"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,duel in ipairs(handcards) do
				if duel:isKindOf("Duel") then
					return {duel}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Duel"], "DuelOnly")
--[[****************************************************************
	顺手牵羊（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	功能：使用顺拆
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useDisturbCard(card, use)
	local isYinling = ( card:isKindOf("YinlingCard") )
	local isJixi = ( card:getSkillName() == "jixi" )
	local isDiscard = ( not card:isKindOf("Snatch") )
	local name = card:objectName()
	if isYinling then
		name = "yinling"
	end
	local using_2013 = false
	if name == "dismantlement" then
		if sgs.current_mode == "02_1v1" then
			if sgs.GetConfig("1v1/Rule", "Classical") == "2013" then
				use_2013 = true
			end
		end
	end
	if not isYinling then
		if self.player:hasSkill("noswuyan") then 
			return 
		end
	end
	local usecard = false
	local targets = {}
	local targets_num = 1
	if not isYinling then
		targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	end
	local LiuXie = self.room:findPlayerBySkillName("huangen")
	
	local function addTarget(player, cardid)
		local can_use = false
		if not table.contains(targets, player:objectName()) then
			if not use.current_targets then
				can_use = true
			elseif not table.contains(use.current_targets, player:objectName()) then
				can_use = true
			end
		end
		if can_use then
			if use.to then
				if use.to:length() > 0 then
					if player:hasSkill("danlao") then
						can_use = false
					end
					if LiuXie then
						if self:isOpponent(LiuXie) then
							if LiuXie:getHp() > targets_num / 2 then
								can_use = false
							end
						end
					end
				end
			end
		end
		if can_use then
			if not usecard then
				use.card = card
				usecard = true
			end
			table.insert(targets, player:objectName())
			if usecard then
				if use.to then
					if use.to:length() < targets_num then
						use.to:append(player)
						if not use.isDummy then
							sgs.Sanguosha:getCard(cardid):setFlags("AIGlobal_SDCardChosen_" .. name)
							if use.to:length() == 1 then 
								self:speak("hostile", self.player:isFemale()) 
							end
						end
					end
				end
			end
			if #targets == targets_num then 
				return true 
			end
		end
	end
	
	local players = self.room:getOtherPlayers(self.player)
	local tricks = nil
	players = self:exclude(players, card)
	if not isYinling then
		if not using_2013 then
			for _, player in ipairs(players) do
				local can_use = false
				local judges = player:getJudgingArea()
				if not judges:isEmpty() then
					if self:trickIsEffective(card, player) then
						if #self.opponents == 0 then
							can_use = true
						elseif player:containsTrick("lightning") then
							if self:getFinalRetrial(player) == 2 then
								can_use = true
							end
						end
					end
				end
				if can_use then
					tricks = player:getCards("j")
					for _, trick in sgs.qlist(tricks) do
						if trick:isKindOf("Lightning") then
							if not isDiscard or self.player:canDiscard(player, trick:getId()) then
								if addTarget(player, trick:getEffectiveId()) then 
									return 
								end
							end
						end
					end
				end
			end
		end
	end
	local enemies = {}
	if #self.opponents == 0 and self:getOverflow() > 0 then
		local lord = self:getMyLord(self.player)
		local amLord = self:amLord()
		for _,player in ipairs(players) do
			if not self:isPartner(player) then
				if lord then
					if amLord then
						local kingdoms = {}
						local general1 = lord:getGeneral()
						if general1:isLord() then 
							table.insert(kingdoms, general1:getKingdom()) 
						end
						local general2 = lord:getGeneral2()
						if general2 and general2:isLord() then 
							table.insert(kingdoms, general2:getKingdom()) 
						end
						if not table.contains(kingdoms, player:getKingdom()) then
							if not lord:hasSkill("yongsi") then 
								table.insert(enemies, player) 
							end
						end
					elseif player:objectName() ~= lord:objectName() then
						table.insert(enemies, player)
					end
				else
					table.insert(enemies, player)
				end
			end
		end
		enemies = self:exclude(enemies, card)
		self:sort(enemies, "defense")
		enemies = sgs.reverse(enemies)
	else
		enemies = self:exclude(self.enemies, card)
		self:sort(enemies, "defense")
	end
	local slashes = self:getCards("Slash")
	for _, enemy in ipairs(enemies) do
		if sgs.slash:isAvailable(self.player) then
			for _, slash in ipairs(slashes) do
				local can_use = false
				if self:willUseSlash(enemy, self.player, slash) then
					if enemy:getHandcardNum() == 1 then
						if enemy:getHp() == 1 then
							if self:hasLoseHandcardEffective(enemy) then
								if self:friendshipLevel(enemy) < -4 then
									if not self:cannotBeHurt(enemy) then
										if not enemy:hasSkills("kongcheng|tianming") then
											if self.player:canSlash(enemy, slash) then
												if isYinling then
													can_use = true
												elseif self:trickIsEffective(card, enemy) then
													can_use = true
												end
											end
										end
									end
								end
							end
						end
					end
				end
				if can_use then
					can_use = false
					if not enemy:isChained() then
						can_use = true
					elseif self:isGoodChainTarget(enemy, nil, nil, nil, slash) then
						can_use = true
					end
				end
				if can_use then
					can_use = false
					if not self:hasEightDiagramEffect() then
						can_use = true
					elseif sgs.IgnoreArmor(self.player, enemy) then
						can_use = true
					end
				end
				if can_use then
					local handcards = enemy:getHandcards()
					local handcard = handcards:first()
					if addTarget(enemy, handcard:getEffectiveId()) then 
						return 
					end
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if self:trickIsEffective(card, enemy) or isYinling then
				local dangerous = self:getDangerousCard(enemy)
				if dangerous then
					if not isDiscard or self.player:canDiscard(enemy, dangerous) then
						if addTarget(enemy, dangerous) then 
							return 
						end
					end
				end
			end
		end
	end
	self:sort(self.partners_noself, "defense")
	local friends = self:exclude(self.partners_noself, card)
	if not isYinling and not using_2013 then
		for _, friend in ipairs(friends) do
			local can_use = false
			if self:trickIsEffective(card, friend) then
				if not friend:containsTrick("YanxiaoCard") then
					if friend:containsTrick("indulgence") then
						can_use = true
					elseif friend:containsTrick("supply_shortage") then
						can_use = true
					end
				end
			end
			if can_use then
				local cardchosen
				tricks = friend:getJudgingArea()
				for _,trick in sgs.qlist(tricks) do
					can_use = false
					if not isDiscard then
						can_use = true
					elseif self.player:canDiscard(friend, trick:getId()) then
						can_use = true
					end
					if can_use then
						if trick:isKindOf("Indulgence") then
							if friend:getHp() <= friend:getHandcardNum() then
								cardchosen = trick:getEffectiveId()
								break
							elseif self:mayLord(friend) then
								cardchosen = trick:getEffectiveId()
								break
							elseif name == "snatch" then
								cardchosen = trick:getEffectiveId()
								break
							end
						end
						if trick:isKindOf("SupplyShortage") then
							cardchosen = trick:getEffectiveId()
							break
						elseif trick:isKindOf("Indulgence") then
							cardchosen = trick:getEffectiveId()
							break
						end
					end
				end
				if cardchosen then
					if addTarget(friend, cardchosen) then 
						return 
					end
				end
			end
		end
	end
	local hasLion = false
	local target = nil
	for _,friend in ipairs(friends) do
		local can_use = false
		if isYinling then
			can_use = true
		elseif self:trickIsEffective(card, friend) then
			can_use = true
		end
		if can_use then
			if self:needToThrowArmor(friend) then
				can_use = false
				if not isDiscard then
					can_use = true
				elseif self.player:canDiscard(friend, friend:getArmor():getEffectiveId()) then
					can_use = true
				end
			end
		end
		if can_use then
			hasLion = true
			target = friend
		end
	end
	for _,enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if isYinling or self:trickIsEffective(card, enemy) then
				local valuable = self:getValuableCard(enemy)
				if valuable then
					if not isDiscard or self.player:canDiscard(enemy, valuable) then
						if addTarget(enemy, valuable) then 
							return 
						end
					end
				end
			end
		end
	end
	local new_enemies = table.copyFrom(enemies)
	local compare_JudgingArea = function(a, b)
		local areaA = a:getJudgingArea()
		local areaB = b:getJudgingArea()
		return areaA:length() > areaB:length()
	end
	table.sort(new_enemies, compare_JudgingArea)
	local yanxiao_card, yanxiao_target, yanxiao_prior
	if not isYinling and not using_2013 then
		for _,enemy in ipairs(new_enemies) do
			local judges = enemy:getJudgingArea()
			for _, trick in sgs.qlist(judges) do
				if trick:isKindOf("YanxiaoCard") then
					if self:trickIsEffective(card, enemy) then
						if (not isDiscard or self.player:canDiscard(enemy, trick:getId())) then
							yanxiao_card = trick
							yanxiao_target = enemy
							if enemy:containsTrick("indulgence") then
								yanxiao_prior = true 
							elseif enemy:containsTrick("supply_shortage") then 
								yanxiao_prior = true 
							end
							break
						end
					end
				end
			end
			if yanxiao_card and yanxiao_target then 
				break 
			end
		end
		if yanxiao_prior and yanxiao_card and yanxiao_target then
			if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then 
				return 
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		local handcards = enemy:getHandcards()
		local cards = sgs.QList2Table(handcards)
		local flag = string.format("visible_%s_%s", self.player:objectName(), enemy:objectName())
		if #cards <= 2 then
			if not enemy:isKongcheng() then
				if isYinling or self:trickIsEffective(card, enemy) then
					if not self:doNotDiscard(enemy, "h", true) then
						for _, c in ipairs(cards) do
							if c:hasFlag("visible") or c:hasFlag(flag) then
								if c:isKindOf("Peach") or c:isKindOf("Analeptic") then
									if addTarget(enemy, self:getCardRandomly(enemy, "h")) then 
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
	for _,enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if (isYinling or self:trickIsEffective(card, enemy)) then
				if self:hasSkills("jijiu|qingnang|jieyin", enemy) then
					local cardchosen
					local equips = { 
						enemy:getDefensiveHorse(), 
						enemy:getArmor(), 
						enemy:getOffensiveHorse(), 
						enemy:getWeapon() 
					}
					for _, equip in ipairs(equips) do
						if equip then
							if not enemy:hasSkill("jijiu") or equip:isRed() then
								local id = equip:getEffectiveId()
								if not isDiscard or self.player:canDiscard(enemy, id) then
									cardchosen = id
									break
								end
							end
						end
					end
					if not cardchosen then
						local horse = enemy:getDefensiveHorse()
						if horse then
							if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then 
								cardchosen = horse:getEffectiveEffectiveId() 
							end
						end
					end
					if not cardchosen then
						local armor = enemy:getArmor()
						if armor then
							if not self:needToThrowArmor(enemy) then
								if not isDiscard or self.player:canDiscard(enemy, armor:getEffectiveId()) then
									cardchosen = armor:getEffectiveId()
								end
							end
						end
					end
					if not cardchosen then
						if not enemy:isKongcheng() then
							if enemy:getHandcardNum() <= 3 then
								if not isDiscard or self.player:canDiscard(enemy, "h") then
									cardchosen = self:getCardRandomly(enemy, "h")
								end
							end
						end
					end
					if cardchosen then
						if addTarget(enemy, cardchosen) then 
							return 
						end
					end
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if isYinling or self:trickIsEffective(card, enemy) then
			if enemy:hasArmorEffect("EightDiagram") then
				if not self:needToThrowArmor(enemy) then
					local armor = enemy:getArmor()
					local id = armor:getEffectiveId()
					if not isDiscard or self.player:canDiscard(enemy, id) then
						addTarget(enemy, id)
					end
				end
			end
		end
	end
	local delt = 0
	if isJixi then
		delt = 3
	end
	for i=1, 2+delt, 1 do
		for _, enemy in ipairs(enemies) do
			local can_use = false
			if not enemy:isNude() then
				if isYinling or self:trickIsEffective(card, enemy) then
					if not self:needKongcheng(enemy) or i > 2 then
						if not self:doNotDiscard(enemy) then
							if enemy:getHandcardNum() == i then
								if sgs.getDefenseSlash(enemy) < 6 + (isJixi and 6 or 0) then
									if enemy:getHp() <= 3 + (isJixi and 2 or 0) then
										can_use = true
									end
								end
							end
						end
					end
				end
			end
			if can_use then
				local cardchosen = nil
				if self.player:distanceTo(enemy) == self.player:getAttackRange() + 1 then
					local horse = enemy:getDefensiveHorse()
					if horse then
						if not self:doNotDiscard(enemy, "e") then
							if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then
								cardchosen = horse:getEffectiveId()
							end
						end
					end
				end
				if not cardchosen then
					local armor = enemy:getArmor()
					if armor then
						if not self:needToThrowArmor(enemy) then
							if not self:doNotDiscard(enemy, "e") then
								if not isDiscard or self.player:canDiscard(enemy, armor:getEffectiveId()) then
									cardchosen = armor:getEffectiveId()
								end
							end
						end
					end
				end
				if not cardchosen then
					if not isDiscard or self.player:canDiscard(enemy, "h") then
						cardchosen = self:getCardRandomly(enemy, "h")
					end
				end
				if cardchosen then
					if addTarget(enemy, cardchosen) then 
						return 
					end
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if isYinling or self:trickIsEffective(card, enemy) then
				local valuable = self:getValuableCard(enemy)
				if valuable then
					if (not isDiscard or self.player:canDiscard(enemy, valuable)) then
						if addTarget(enemy, valuable) then 
							return 
						end
					end
				end
			end
		end
	end
	if hasLion then
		local armor = target:getArmor()
		if armor then
			local id = armor:getEffectiveId()
			if not isDiscard or self.player:canDiscard(target, id) then
				if addTarget(target, id) then 
					return 
				end
			end
		end
	end
	if not isYinling and not using_2013 then
		if yanxiao_card and yanxiao_target then
			if not isDiscard or self.player:canDiscard(yanxiao_target, yanxiao_card:getId()) then
				if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then 
					return 
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if not enemy:isKongcheng() then
			if not self:doNotDiscard(enemy, "h") then
				if isYinling or self:trickIsEffective(card, enemy) then
					if self:hasSkills(sgs.cardneed_skill, enemy) then
						if not isDiscard or self.player:canDiscard(enemy, "h") then
							if addTarget(enemy, self:getCardRandomly(enemy, "h")) then 
								return 
							end
						end
					end
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if enemy:hasEquip() then
			if not self:doNotDiscard(enemy, "e") then
				if isYinling or self:trickIsEffective(card, enemy) then
					local cardchosen = nil
					local horse = enemy:getDefensiveHorse()
					if horse then
						if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then
							cardchosen = horse:getEffectiveId()
						end
					end
					if not cardchosen then
						local armor = enemy:getArmor()
						if armor then
							if not self:needToThrowArmor(enemy) then
								if not isDiscard or self.player:canDiscard(enemy, armor:getEffectiveId()) then
									cardchosen = armor:getEffectiveId()
								end
							end
						end
					end
					if not cardchosen then
						horse = enemy:getOffensiveHorse()
						if horse then
							if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then
								cardchosen = horse:getEffectiveId()
							end
						end
					end
					if not cardchosen then
						local weapon = enemy:getWeapon()
						if weapon then
							if not isDiscard or self.player:canDiscard(enemy, weapon:getEffectiveId()) then
								cardchosen = weapon:getEffectiveId()
							end
						end
					end
					if cardchosen then
						if addTarget(enemy, cardchosen) then 
							return 
						end
					end
				end
			end
		end
	end
	if name == "snatch" or self:getOverflow() > 0 then
		for _,enemy in ipairs(enemies) do
			local equips = enemy:getEquips()
			if not enemy:isNude() then
				if self:trickIsEffective(card, enemy) then
					if not self:doNotDiscard(enemy, "he") then
						local cardchosen
						if not equips:isEmpty() and not self:doNotDiscard(enemy, "e") then
							cardchosen = self:getCardRandomly(enemy, "e")
						else
							cardchosen = self:getCardRandomly(enemy, "h") 
						end
						if cardchosen then
							if addTarget(enemy, cardchosen) then 
								return 
							end
						end
					end
				end
			end
		end
	end
end
--[[
	内容：“顺手牵羊”的卡牌成分
]]--
sgs.card_constituent["Snatch"] = {
	control = 2,
	use_value = 9,
	use_priority = 4.3,
}
--[[
	功能：
	参数：player（ServerPlayer类型，无意义）
		promptlist（table类型，表示提示信息）
		self（即表SmartAI）
	结果：无
]]--
function ChoiceMade_Undermine(player, promptlist, self)
	local from = findPlayerByObjectName(self.room, promptlist[4])
	local to = findPlayerByObjectName(self.room, promptlist[5])
	if from and to then
		local id = tonumber(promptlist[3])
		local place = self.room:getCardPlace(id)
		local card = sgs.Sanguosha:getCard(id)
	end
end
sgs.ai_choicemade_filter["cardChosen"]["snatch"] = ChoiceMade_Undermine
--[[
	内容：注册顺手牵羊
]]--
sgs.RegistCard("Snatch")
--[[
	功能：使用顺手牵羊
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSnatch(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Snatch"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	self:useDisturbCard(card, use)
	--[[
	for _,enemy in ipairs(self.opponents) do
		if not enemy:isNude() then
			if not self.player:isProhibited(enemy, sgs.snatch) then
				local limit = 1
				if self.player:distanceTo(enemy) <= limit then
					use.card = card
					if use.to then
						use.to:append(enemy)
					end
					return 
				end
			end
		end
	end]]--
end
--[[
	套路：仅使用顺手牵羊
]]--
sgs.ai_series["SnatchOnly"] = {
	name = "SnatchOnly",
	IQ = 1,
	value = 3, 
	priority = 2, 
	cards = {
		["Snatch"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,snatch in ipairs(handcards) do
				if snatch:isKindOf("Snatch") then
					return {snatch}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Snatch"], "SnatchOnly")
--[[****************************************************************
	过河拆桥（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	内容：“过河拆桥”的卡牌成分
]]--
sgs.card_constituent["Dismantlement"] = {
	control = 2,
	use_value = 5.6,
	use_priority = 4.4,
}
sgs.ai_choicemade_filter["cardChosen"]["dismantlement"] = ChoiceMade_Undermine
--[[
	内容：注册过河拆桥
]]--
sgs.RegistCard("Dismantlement")
--[[
	功能：使用过河拆桥
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDismantlement(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Dismantlement"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	self:useDisturbCard(card, use)
	--[[
	for _,enemy in ipairs(self.opponents) do
		if not enemy:isNude() then
			if not self.player:isProhibited(enemy, sgs.snatch) then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return 
			end
		end
	end]]--
end
--[[
	套路：仅使用过河拆桥
]]--
sgs.ai_series["DismantlementOnly"] = {
	name = "DismantlementOnly",
	IQ = 1,
	value = 3, 
	priority = 2.1, 
	cards = {
		["Dismantlement"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,dismantlement in ipairs(handcards) do
				if dismantlement:isKindOf("Dismantlement") then
					return {dismantlement}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Dismantlement"], "DismantlementOnly")
--[[****************************************************************
	乐不思蜀（延时性锦囊）
]]--****************************************************************
--[[
	内容：“乐不思蜀”的卡牌成分
]]--
sgs.card_constituent["Indulgence"] = {
	control = 3,
	use_value = 8,
	keep_value = 1.5,
	use_priority = 0.5,
}
--[[
	内容：“乐不思蜀”的卡牌仇恨值
]]--
sgs.ai_card_intention["Indulgence"] = 120
--[[
	内容：注册乐不思蜀
]]--
sgs.RegistCard("Indulgence")
--[[
	功能：使用乐不思蜀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardIndulgence(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Indulgence"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	for _,enemy in ipairs(self.opponents) do
		if not self.player:isProhibited(enemy, card) then
			local area = enemy:getJudgingArea()
			for _,judge in sgs.qlist(area) do
				if judge:isKindOf("Indulgence") then
					return 
				end
				if judge:isKindOf("YanxiaoCard") then
					return
				end
			end
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return 
		end
	end
end
--[[
	套路：仅使用乐不思蜀
]]--
sgs.ai_series["IndulgenceOnly"] = {
	name = "IndulgenceOnly",
	IQ = 1,
	value = 4, 
	priority = 0.9, 
	cards = {
		["Indulgence"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,indulgence in ipairs(handcards) do
				if indulgence:isKindOf("Indulgence") then
					return {indulgence}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Indulgence"], "IndulgenceOnly")
--[[****************************************************************
	闪电（延时性锦囊，天灾）
]]--****************************************************************
--[[
	功能：判断是否需要使用闪电
	参数：card（Card类型，表示将使用的闪电）
	结果：boolean类型，表示是否需要
]]--
function SmartAI:willUseLightning(card)
	if card then
		if self.player:containsTrick("lightning") then 
			return false
		end
		if self.player:hasSkill("weimu") then
			if card:isBlack() then 
				return false
			end
		end
		if self.room:isProhibited(self.player, self.player, card) then 
			return false
		end
		local function hasDangerousFriend() 
			local hasHongYan = false
			for _, aplayer in ipairs(self.opponents) do
				if aplayer:hasSkill("hongyan") then 
					hasHongYan = true 
					break 
				end
			end
			for _, aplayer in ipairs(self.opponents) do
				local next_alive = aplayer:getNextAlive()
				if self:isPartner(next_alive) then
					if aplayer:hasSkill("guanxing") then
						return true
					elseif aplayer:hasSkill("xinzhan") then
						return true
					elseif aplayer:hasSkill("gongxin") and hasHongYan then
						return true 
					end
				end
			end
			return false
		end
		local final = self:getFinalRetrial(self.player)
		if final == 2 then 
			return false
		elseif final == 1 then
			return true
		elseif not hasDangerousFriend() then
			local alives = self.room:getAllPlayers()
			local friends = 0
			local enemies = 0
			for _,player in sgs.qlist(alives) do
				if not player:hasSkill("hongyan") then
					if not player:hasSkill("wuyan") then
						if not (player:hasSkill("weimu") and card:isBlack()) then
							if self:isPartner(player) then
								friends = friends + 1
							else
								enemies = enemies + 1
							end
						end
					end
				end
			end
			local ratio = 0
			if friends == 0 then 
				ratio = 999
			else 
				ratio = enemies / friends
			end
			if ratio > 1.5 then
				return true
			end
		end
	else
		self.room:writeToConsole(debug.traceback()) 
		return false
	end
end
--[[
	内容：“闪电”的卡牌成分
]]--
sgs.card_constituent["Lightning"] = {
	lucky = 1,
	keep_value = -1,
	use_priority = 0,
}
--[[
	内容：注册闪电
]]--
sgs.RegistCard("Lightning")
--[[
	功能：使用闪电
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardLightning(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Lightning"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	if self:willUseLightning(card) then
		use.card = card
	end
end
--[[
	套路：仅使用闪电
]]--
sgs.ai_series["LightningOnly"] = {
	name = "LightningOnly",
	IQ = 1,
	value = 4, 
	priority = 0.9, 
	cards = {
		["Lightning"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		if handcards then
			for _,lightning in ipairs(handcards) do
				if lightning:isKindOf("Lightning") then
					return {lightning}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Lightning"], "LightningOnly")
--[[****************************************************************
	无懈可击（非延时性锦囊，单目标锦囊）
]]--****************************************************************
--[[
	内容：“无懈可击”的卡牌成分
]]--
sgs.card_constituent["Nullification"] = {
	use_value = 8,
	keep_value = 3,
}
--[[****************************************************************
	----------------------------------------------------------------
	装 备 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[
	功能：获取一名角色装备的与目标卡牌同类型的装备牌
	参数：card（Card类型，表示目标卡牌）
		player（ServerPlayer类型，表示待判断的角色）
	结果：Card类型，表示已装备的卡牌
]]--
function SmartAI:getSameTypeEquip(card, player)
	if card then
		player = player or self.player
		if card:isKindOf("Weapon") then
			return player:getWeapon()
		elseif card:isKindOf("Armor") then
			return player:getArmor()
		elseif card:isKindOf("DefensiveHorse") then
			return player:getDefensiveHorse()
		elseif card:isKindOf("OffensiveHorse") then
			return player:getOffensiveHorse()
		end
	end
end
--[[
	功能：评价武器对自己的价值
	参数：weapon（Card类型，表示待评价的武器卡牌）
	结果：number类型（threat），表示武器价值
]]--
function SmartAI:evaluateWeapon(weapon)
	if weapon then
		local range = sgs.weapon_range[weapon:getClassName()] or 0
		local threat = 0
		local enemies = {}
		for _,enemy in ipairs(self.opponents) do
			if self.player:distanceTo(enemy) <= range then
				local defense = sgs.getDefense(enemy)
				threat = threat + 6 / defense
				table.insert(enemies, enemy)
			end
		end
		if weapon:isKindOf("Crossbow") then
			if not self.player:hasSkill("paoxiao") then
				if threat > 0 then
					local slashCount = self:getCardsNum("Slash") 
					threat = threat + slashCount * 3 - 2
					if self.player:hasSkill("kurou") then
						local peachCount = self.getCardsNum("Peach")
						local analCount = self.getCardsNum("Analeptic")
						local hp = self.player:getHp()
						threat = threat + peachCount + analCount + hp
					end
					if self.player:getWeapon() then
						if not self:hasCrossbowEffect() then
							if not self.player:canSlashWithoutCrossbow() then
								if slashCount > 0 then
									for _,enemy in ipairs(enemies) do
										if slashCount >= enemy:getHp() then
											threat = threat + 10
										elseif sgs.card_lack[enemy:objectName()]["Jink"] == 1 then
											threat = threat + 10
										end
									end
								end
							end
						end
					end
				end
			end
		end
		local callback = sgs.ai_weapon_value[weapon:objectName()]
		if type(callback) == "function" then
			local v = callback(self, nil) or 0
			threat = threat + v
			for _,enemy in ipairs(enemies) do
				local extra_func = sgs.ai_slash_weapon_filter[weapon:objectName()]
				if type(extra_func) == "function" then
					if extra_func(self, enemy) then
						threat = threat + 1
					end
				end
				local v = callback(self, enemy) or 0
				threat = threat + v
			end
		end
		if self.player:hasSkill("jijiu") then
			if weapon:isRed() then
				threat = threat + 0.5
			end
		end
		if self:hasSkills("qixi|guidao") then
			if weapon:isBlack() then
				threat = threat + 0.5
			end
		end
		return threat
	end
	return -1
end
--[[****************************************************************
	武器类
]]--****************************************************************
sgs.weapon_range = { --武器攻击范围
	Weapon = 1
}
--[[****************************************************************
	诸葛连弩（武器）
]]--****************************************************************
sgs.weapon_range.Crossbow = 1
sgs.card_constituent["Crossbow"] = {
	use_priority = 2.63,
}
--[[
	内容：注册诸葛连弩
]]--
sgs.RegistCard("Crossbow")
--[[
	功能：使用诸葛连弩
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardCrossbow(card, use)
	use.card = card
end
--[[
	套路：仅使用“诸葛连弩”
]]--
sgs.ai_series["CrossbowOnly"] = {
	name = "CrossbowOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["Crossbow"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,bow in ipairs(handcards) do
			if bow:isKindOf("Crossbow") then
				return {bow}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Crossbow"], "CrossbowOnly")
--[[****************************************************************
	雌雄双股剑（武器）
]]--****************************************************************
sgs.weapon_range.DoubleSword = 2
sgs.card_constituent["DoubleSword"] = {
	use_priority = 2.665,
}
--[[
	内容：注册雌雄双股剑
]]--
sgs.RegistCard("DoubleSword")
--[[
	技能：雌雄双股剑
	描述：每当你使用【杀】指定一名异性角色为目标后，你可以令其选择一项：弃置一张手牌，或令你摸一张牌。
]]--
sgs.ai_skill_invoke["DoubleSword"] = function(self, data)
	return not self:needKongcheng(self.player, true)
end
sgs.ai_skill_cardask["double-sword-card"] = function(self, data, pattern, target)
	if self.player:isKongcheng() then 
		return "." 
	end
	local use = data:toCardUse()
	return "." --Just For Test
end
--[[
	功能：使用雌雄双股剑
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDoubleSword(card, use)
	use.card = card
end
sgs.ai_slash_weapon_filter["DoubleSword"] = function(self, target)
	return self.player:getGender() ~= target:getGender()
end
sgs.ai_weapon_value["DoubleSword"] = function(self, target)
	if target then
		if target:isMale() ~= self.player:isMale() then 
			return 4 
		end
	end
end
--[[
	套路：仅使用“雌雄双股剑”
]]--
sgs.ai_series["DoubleSwordOnly"] = {
	name = "DoubleSwordOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["DoubleSword"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,sword in ipairs(handcards) do
			if sword:isKindOf("DoubleSword") then
				return {sword}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DoubleSword"], "DoubleSwordOnly")
--[[****************************************************************
	青釭剑（武器）
]]--****************************************************************
sgs.weapon_range.QinggangSword = 2
sgs.card_constituent["QinggangSword"] = {
	use_priority = 2.645,
}
--[[
	内容：注册青釭剑
]]--
sgs.RegistCard("QinggangSword")
--[[
	功能：使用青釭剑
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardQinggangSword(card, use)
	use.card = card
end
sgs.ai_weapon_value["QinggangSword"] = function(self, target)
	if target then
		if target:getArmor() then
			return 3
		end
	end
end
--[[
	套路：仅使用“青釭剑”
]]--
sgs.ai_series["QinggangSwordOnly"] = {
	name = "QinggangSwordOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["QinggangSword"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,sword in ipairs(handcards) do
			if sword:isKindOf("QinggangSword") then
				return {sword}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["QinggangSword"], "QinggangSwordOnly")
--[[****************************************************************
	青龙偃月刀（武器）
]]--****************************************************************
sgs.weapon_range.Blade = 3
sgs.card_constituent["Blade"] = {
	use_priority = 2.675,
}
--[[
	内容：注册青龙偃月刀
]]--
sgs.RegistCard("Blade")
--[[
	技能：青龙偃月刀
	描述：每当你使用的【杀】被【闪】抵消后，你可以对该角色再使用一张【杀】。
]]--
sgs.ai_skill_cardask["blade-slash"] = function(self, data, pattern, target)
	return "." --Just For Test
end
--[[
	功能：使用青龙偃月刀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardBlade(card, use)
	use.card = card
end
sgs.ai_weapon_value["Blade"] = function(self, target)
	if target then
		local count = self:getCardsNum("Slash")
		return math.min(count, 3)
	end
end
--[[
	套路：仅使用“青龙偃月刀”
]]--
sgs.ai_series["BladeOnly"] = {
	name = "BladeOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["Blade"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,blade in ipairs(handcards) do
			if blade:isKindOf("Blade") then
				return {blade}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Blade"], "BladeOnly")
--[[****************************************************************
	丈八蛇矛（武器）
]]--****************************************************************
sgs.weapon_range.Spear = 3
--[[
	功能：用两张手牌产生一张杀
	参数：skillname（string类型，表示技能名称）
	结果：Card类型，表示产生的杀
]]--
function SmartAI:createSpearSlash(skillname)
	skillname = skillname or "Spear"
	--判断是否真的需要将两张手牌当做一张杀使用
	if skillname ~= "fuhun" or self.player:hasSkill("wusheng") then
		local cards = self.player:getCards("he")
		for _,card in sgs.qlist(cards) do
			if sgs.isCard("Slash", card, self.player) then
				return 
			end
		end
	end
	--判断是否有产生杀的必要
	local cards = self.player:getCards("h")
	local hp = self.player:getHp()
	if cards:length() <= hp - 1 then
		if hp <= 4 then
			if not self:hasHeavySlashDamage(self.player) then
				local skills = "kongcheng|lianying|paoxiao|shangshi|noshangshi|zhiji|benghuai"
				if not self:hasSkills(skills) then 
					return 
				end
			end
		end
	end
	--寻找用于产生杀的两张手牌
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local to_use = {}
	local isPlaying = ( self.player:getPhase() == sgs.Player_Play )
	for _,card in ipairs(cards) do
		if not sgs.isCard("Slash", card, self.player) then
			if not sgs.isCard("Peach", card, self.player) then
				if not (isPlaying and sgs.isCard("ExNihilo", card, self.player)) then
					table.insert(to_use, card) 
				end
			end
		end
	end
	if #to_use >= 2 then
		local cardA = to_use[1]
		local cardB = to_use[2]
		local idA = cardA:getEffectiveId()
		local idB = cardB:getEffectiveId()
		if cardA:isBlack() and cardB:isBlack() then
			local blackSlash = sgs.cloneCard("Slash", sgs.Card_NoSuitBlack)
			self:sort(self.opponents, "defenseSlash")
			for _,enemy in ipairs(self.opponents) do
				if self.player:canSlash(enemy) then
					if self:willUseSlash(enemy, self.player, sgs.slash) then
						if self:slashIsEffective(enemy, self.player, sgs.slash) then
							if self:canAttack(enemy) then
								if not self:willUseSlash(enemy, self.player, blackSlash) then
									if self:isWeak(enemy) then
										local reds = {}
										local blacks = {}
										for _,red in ipairs(to_use) do
											if red:isBlack() then
												table.insert(blacks, red)
											else
												table.insert(reds, red)
											end
										end
										if #reds == 0 then
											break
										end
										self:sortByUseValue(blacks, true)
										self:sortByUseValue(reds, true)
										cardA = reds[1]
										if #blacks > 0 then
											cardB = blacks[1]
										elseif #reds > 1 then
											cardB = reds[2]
										end
										if cardA and cardB then
											idA = cardA:getEffectiveId()
											idB = cardB:getEffectiveId()
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
		local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skillname, "to_be_decided", 0, idA, idB)
		return sgs.Card_Parse(card_str)
	end
end
--[[
	功能：
	参数：player（ServerPlayer类型，表示进行响应的角色）
		skillname（string类型，表示技能名）
	结果：string类型，表示杀的产生方式
]]--
function SmartAI:getSpearCardsView(player, skillname)
	skillname = skillname or "Spear"
	local cards = player:getCards("he")
	if skillname ~= "fuhun" or player:hasSkill("wusheng") then
		for _, c in sgs.qlist(cards) do
			if sgs.isCard("Slash", c, player) then 
				return 
			end
		end
	end
	cards = player:getCards("h")
	local newcards = {}
	for _, card in sgs.qlist(cards) do
		if not sgs.isCard("Slash", card, player) then
			if not sgs.isCard("Peach", card, player) then
				if not (sgs.isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play) then 
					table.insert(newcards, card) 
				end
			end
		end
	end
	if #newcards >= 2 then
		self:sortByKeepValue(newcards)
		local card_id1 = newcards[1]:getEffectiveId()
		local card_id2 = newcards[2]:getEffectiveId()
		local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skillname, "to_be_decided", 0, card_id1, card_id2)
		return card_str
	end
end
sgs.card_constituent["Spear"] = {
	use_priority = 2.66,
}
--[[
	内容：注册丈八蛇矛、丈八蛇矛杀
]]--
sgs.RegistCard("Spear")
sgs.RegistCard("Spear>>Slash")
--[[
	技能：丈八蛇矛
	描述：你可以将两张手牌当【杀】使用或打出
]]--
sgs.ai_skills["Spear"] = {
	name = "Spear",
	dummyCard = function(self)
		local id = sgs.slash:getEffectiveId()
		local suit = sgs.slash:getSuitString()
		local point = sgs.slash:getNumberString()
		local card_str = string.format("slash:Spear[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasWeapon("Spear") then
			if #handcards > 1 then
				if sgs.slash:isAvailable(self.player) then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	功能：使用丈八蛇矛
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSpear(card, use)
	use.card = card
end
--[[
	内容：“丈八蛇矛杀”的具体产生方式
]]--
sgs.ai_view_as_func["Spear>>Slash"] = function(self, card)
	return self:createSpearSlash()
end
sgs.ai_cardsview["Spear"] = function(self, class_name, player)
	if class_name == "Slash" then
		return self:getSpearCardsView(player, "Spear")
	end
end
sgs.ai_weapon_value["Spear"] = function(self, target)
	if target then	
		if self:getCardsNum("Slash") == 0 then
			if self:getOverflow() > 0 then 
				return 2
			elseif self.player:getHandcardNum() > 2 then 
				return 1
			end
		end
	end
	return 0
end
--[[
	套路：仅使用“丈八蛇矛”
]]--
sgs.ai_series["SpearOnly"] = {
	name = "SpearOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["Spear"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,spear in ipairs(handcards) do
			if spear:isKindOf("Spear") then
				return {spear}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Spear"], "SpearOnly")
--[[
	套路：仅使用“丈八蛇矛杀”
]]--
sgs.ai_series["Spear>>SlashOnly"] = {
	name = "Spear>>SlashOnly",
	IQ = 1,
	value = 1,
	priority = 2,
	cards = {
		["Spear>>Slash"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local spear_skill = sgs.ai_skills["Spear"]
		local slash = spear_skill["dummyCard"](self)
		slash:setFlags("isDummy")
		return {slash}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Spear>>Slash"], "Spear>>SlashOnly")
--[[****************************************************************
	贯石斧（武器）
]]--****************************************************************
sgs.weapon_range.Axe = 3
sgs.card_constituent["Axe"] = {
	use_priority = 2.688,
}
--[[
	内容：注册贯石斧
]]--
sgs.RegistCard("Axe")
--[[
	技能：贯石斧
	描述：每当你使用的【杀】被【闪】抵消后，你可以弃置两张牌，则此【杀】继续造成伤害。
]]--
sgs.ai_skill_cardask["@Axe"] = function(self, data, pattern, target)
	if target then
		if self:isPartner(target) then
			return "."
		end
	end
	local effect = data:toSlashEffect()
	return "." --Just For Test
end
--[[
	功能：使用贯石斧
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardAxe(card, use)
	use.card = card
end
sgs.ai_slash_weapon_filter["Axe"] = function(self, target)
	return self:getOverflow() > 0
end
--[[
	套路：仅使用“贯石斧”
]]--
sgs.ai_series["AxeOnly"] = {
	name = "AxeOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["Axe"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,axe in ipairs(handcards) do
			if axe:isKindOf("Axe") then
				return {axe}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Axe"], "AxeOnly")
--[[****************************************************************
	方天画戟（武器）
]]--****************************************************************
sgs.weapon_range.Halberd = 4
sgs.card_constituent["Halberd"] = {
	use_priority = 2.685,
}
--[[
	内容：注册方天画戟
]]--
sgs.RegistCard("Halberd")
--[[
	功能：使用方天画戟
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardHalberd(card, use)
	use.card = card
end
--[[
	套路：仅使用“方天画戟”
]]--
sgs.ai_series["HalberdOnly"] = {
	name = "HalberdOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["Halberd"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,halberd in ipairs(handcards) do
			if halberd:isKindOf("Halberd") then
				return {halberd}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["Halberd"], "HalberdOnly")
--[[****************************************************************
	麒麟弓（武器）
]]--****************************************************************
sgs.weapon_range.KylinBow = 5
sgs.card_constituent["KylinBow"] = {
	use_priority = 2.68,
}
--[[
	内容：注册麒麟弓
]]--
sgs.RegistCard("KylinBow")
--[[
	技能：麒麟弓
	描述：每当你使用【杀】对目标角色造成伤害时，你可以弃置其装备区内的一张坐骑牌。
]]--
sgs.ai_skill_invoke["KylinBow"] = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	local target = damage.to
	if source:hasSkill("kuangfu") then
		local equips = target:getCards("e")
		if equips:length() == 1 then
			return false
		end
	end
	if self:hasSkills(sgs.lose_equip_skill, target) then
		return self:isPartner(target)
	end
	return self:isOpponent(target)
end
--[[
	功能：使用麒麟弓
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardKylinBow(card, use)
	use.card = card
end
sgs.ai_slash_weapon_filter["KylinBow"] = function(self, target)
	if target:getDefensiveHorse() then 
		return true 
	else 
		return false 
	end
end
sgs.ai_weapon_value["KylinBow"] = function(self, target)
	if not target then
		for _, enemy in ipairs(self.opponents) do
			if enemy:getOffensiveHorse() then
				return 1
			elseif enemy:getDefensiveHorse() then 
				return 1 
			end
		end
	end
end
--[[
	套路：仅使用“麒麟弓”
]]--
sgs.ai_series["KylinBowOnly"] = {
	name = "KylinBowOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["KylinBow"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,bow in ipairs(handcards) do
			if bow:isKindOf("KylinBow") then
				return {bow}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["KylinBow"], "KylinBowOnly")
--[[****************************************************************
	防具类
]]--****************************************************************
--[[****************************************************************
	八卦阵（防具）
]]--****************************************************************
sgs.card_constituent["EightDiagram"] = {
	use_priority = 0.8,
}
--[[
	内容：注册八卦阵
]]--
sgs.RegistCard("EightDiagram")
--[[
	技能：八卦阵
	描述：每当你需要使用或打出一张【闪】时，你可以进行一次判定：若判定结果为红色，视为你使用或打出了一张【闪】。
]]--
sgs.ai_skill_invoke["EightDiagram"] = function(self, data)
	local HanDang = self.room:findPlayerBySkillName("nosjiefan")
	local dying = 0
	if HanDang then
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:getHp() < 1 then
				if not p:hasSkill("buqu") then
					dying = dying + 1
					break 
				end
			end
		end
	end
	local heartJink = false
	local cards = self.player:getCards("he")
	for _,jink in sgs.qlist(cards) do
		if jink:getSuit() == sgs.Card_Heart then
			if sgs.isCard("Jink", jink, self.player) then
				heartJink = true
				break
			end
		end
	end
	local daheFlag = ( self.player:hasFlag("dahe") )
	if self:hasSkills("tiandu|leiji|gushou") then
		if daheFlag then
			if not heartJink then
				return true
			end
		end
		if sgs.hujiasource then
			if not self:isPartner(sgs.hujiasource) then
				if daheFlag then
					return true
				elseif sgs.hujiasouse:hasFlag("dahe") then
					return true 
				end
			end
		end
		if sgs.lianlisource then
			if not self:isPartner(sgs.lianlisource) then
				if daheFlag then
					return true
				elseif sgs.lianlisource:hasFlag("dahe") then
					return true 
				end
			end
		end
		if daheFlag then
			if HanDang then
				if self:isPartner(HanDang) then
					if dying > 0 then 
						return true 
					end
				end
			end
		end
	end
	local current = self.room:getCurrent()
	if self.player:getHandcardNum() == 1 then
		if self.player:hasSkills("zhiji|beifa") then
			if self:needKongcheng() then
				if self:getCardsNum("Jink") == 1 then
					local enemy_num = self:getOpponentNumBySeat(current, self.player, self.player)
					if self.player:getHp() > enemy_num then
						if enemy_num <= 1 then 
							return false 
						end
					end
				end
			end
		end
	end
	if HanDang then
		if self:isPartner(HanDang) then
			if dying > 0 then 
				return false 
			end
		end
	end
	if daheFlag then 
		return false 
	end
	if sgs.hujiasource then
		if not self:isPartner(sgs.hujiasource) then
			return false
		elseif sgs.hujiasource:hasFlag("dahe") then 
			return false 
		end
	end
	if sgs.lianlisource then
		if not self:isFriend(sgs.lianlisource) then
			return false
		elseif sgs.lianlisource:hasFlag("dahe") then 
			return false 
		end
	end
	if self:invokeDamagedEffect(self.player, nil, true) then
		return false
	elseif self:needToLoseHp(self.player, nil, true, true) then 
		return false 
	end
	if self:getCardsNum("Jink") == 0 then 
		return true 
	end
	local ZhangJiao = self.room:findPlayerBySkillName("guidao")
	if ZhangJiao then
		if self:isOpponent(ZhangJiao) then
			local knownCount = sgs.getKnownCard(ZhangJiao, "black", false, "he")
			if knownCount > 1 then 
				return false 
			end
			if knownCount > 0 then 
				if self:getCardsNum("Jink") > 1 then
					return false 
				end
			end
		end
	end
	return true
end
--[[
	功能：使用八卦阵
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardEightDiagram(card, use)
	use.card = card
end
--[[
	套路：仅使用八卦阵
]]--
sgs.ai_series["EightDiagramOnly"] = {
	name = "EightDiagramOnly",
	value = 1, 
	priority = 1, 
	cards = {
		["EightDiagram"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, cards)
		if cards then
			for _,ed in ipairs(cards) do
				if ed:isKindOf("EightDiagram") then
					return {ed}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["EightDiagram"], "EightDiagramOnly")
--[[
	功能：判断一名角色是否等效于装备八卦阵
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否等效
]]--
function SmartAI:hasEightDiagramEffect(player)
	player = player or self.player
	if player:hasArmorEffect("EightDiagram") then
		return true
	elseif player:hasArmorEffect("bazhen") then
		return true
	end
	return false
end
--[[****************************************************************
	仁王盾（防具）
]]--****************************************************************
sgs.card_constituent["RenwangShield"] = {
	use_priority = 0.85,
}
--[[
	内容：注册仁王盾
]]--
sgs.RegistCard("RenwangShield")
--[[
	功能：使用仁王盾
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardRenwangShield(card, use)
	use.card = card
end
--[[
	套路：仅使用仁王盾
]]--
sgs.ai_series["RenwangShieldOnly"] = {
	name = "RenwangShieldOnly",
	value = 1, 
	priority = 1, 
	cards = {
		["RenwangShield"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, cards)
		if cards then
			for _,rs in ipairs(cards) do
				if rs:isKindOf("RenwangShield") then
					return {rs}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["RenwangShield"], "RenwangShieldOnly")
--[[****************************************************************
	防御马类
]]--****************************************************************
sgs.card_constituent["DefensiveHorse"] = {
	use_priority = 2.75,
}
--[[
	内容：注册防御马
]]--
sgs.RegistCard("DefensiveHorse")
--[[
	功能：使用防御马
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDefensiveHorse(card, use)
	use.card = card
end
--[[
	套路：仅使用防御马
]]--
sgs.ai_series["DefensiveHorseOnly"] = {
	name = "DefensiveHorseOnly",
	value = 1, 
	priority = 1, 
	cards = {
		["DefensiveHorse"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, cards)
		if cards then
			for _,dh in ipairs(cards) do
				if dh:isKindOf("DefensiveHorse") then
					return {dh}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["DefensiveHorse"], "DefensiveHorseOnly")
--[[****************************************************************
	绝影（防御马）
]]--****************************************************************
sgs.card_constituent["JueYing"] = {
	use_priority = 2.75,
}
--[[
	功能：使用绝影
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardJueYing(card, use)
	self:useCardDefensiveHorse(card, use)
end
--[[****************************************************************
	的卢（防御马）
]]--****************************************************************
sgs.card_constituent["DiLu"] = {
	use_priority = 2.75,
}
--[[
	功能：使用的卢
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDiLu(card, use)
	self:useCardDefensiveHorse(card, use)
end
--[[****************************************************************
	爪黄飞电（防御马）
]]--****************************************************************
sgs.card_constituent["ZhuaHuangFeiDian"] = {
	use_priority = 2.75,
}
--[[
	功能：使用爪黄飞电
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardZhuaHuangFeiDian(card, use)
	self:useCardDefensiveHorse(card, use)
end
--[[****************************************************************
	进攻马类
]]--****************************************************************
sgs.card_constituent["OffensiveHorse"] = {
	use_priority = 2.69,
}
--[[
	内容：注册进攻马
]]--
sgs.RegistCard("OffensiveHorse")
--[[
	功能：使用进攻马
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardOffensiveHorse(card, use)
	use.card = card
end
--[[
	套路：仅使用进攻马
]]--
sgs.ai_series["OffensiveHorseOnly"] = {
	name = "OffensiveHorseOnly",
	value = 1, 
	priority = 1, 
	cards = {
		["OffensiveHorse"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, cards)
		if cards then
			for _,oh in ipairs(cards) do
				if oh:isKindOf("OffensiveHorse") then
					return {oh}
				end
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["OffensiveHorse"], "OffensiveHorseOnly")
--[[****************************************************************
	赤兔（进攻马）
]]--****************************************************************
sgs.card_constituent["ChiTu"] = {
	use_priority = 2.69,
}
--[[
	功能：使用赤兔
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardChiTu(card, use)
	self:useCardOffensiveHorse(card, use)
end
--[[****************************************************************
	大宛（进攻马）
]]--****************************************************************
sgs.card_constituent["DaYuan"] = {
	use_priority = 2.69,
}
--[[
	功能：使用大宛
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardDaYuan(card, use)
	self:useCardOffensiveHorse(card, use)
end
--[[****************************************************************
	紫骍（进攻马）
]]--****************************************************************
sgs.card_constituent["ZiXing"] = {
	use_priority = 2.69,
}
--[[
	功能：使用紫骍
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardZiXing(card, use)
	self:useCardOffensiveHorse(card, use)
end