--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）观星部分
]]--
--[[
	内容：解判定牌的花色（对于闪电而言是中判定牌）
]]--
sgs.ai_judge_string = { 
	indulgence = "heart", --乐不思蜀
	supply_shortage = "club", --兵粮寸断
	lightning = "spade", --闪电
	diamond = "heart", --“国色”视作的乐不思蜀（方块）
	spade = "club", --“断粮”视作的兵粮寸断（黑桃）
	club = "club", --“断粮”视作的兵粮寸断（草花）
}
--[[
	功能：将一组卡牌编号转化成对应的卡牌
	参数：ids（table类型）
	结果：table类型（cards）
]]--
function sgs.Ids_to_Cards(ids)
	local cards = {}
	for _,id in ipairs(ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	return cards
end
--[[
	功能：将一组卡牌转化成对应的卡牌编号
	参数：cards（table类型）
	结果：table类型（ids）
]]--
function sgs.Cards_to_Ids(cards)
	local ids = {}
	for _,card in ipairs(cards) do
		local id = card:getEffectiveId()
		table.insert(ids, id)
	end
	return ids
end
--[[
	功能：执行观星
	参数：self（即表SmartAI）
		cards（table类型，表示待排列的卡牌编号列表）
	结果：table类型（表示位于牌堆顶的卡牌）和table类型（表示位于牌堆底的卡牌）
]]--
function sgs.DoGuanXing(self, cards)
	local up = {}
	local bottom = sgs.Ids_to_Cards(cards)
	self:sortByUseValue(bottom, true)
	--解自己的延时性锦囊牌
	local judges = self.player:getJudgingArea() --延时性锦囊牌列表
	local need_judge = true --是否需要通过观星获得解判定牌
	if judges:isEmpty() then
		need_judge = false
	else
		for _,judge in sgs.qlist(judges) do
			if judge:isKindOf("YanxiaoCard") then
				need_judge = false
				break
			end
		end
	end
	local lightning = nil --可能有的闪电
	local hasJudged = false --是否存在解判定牌
	local judgeList = {}
	if need_judge then
		judges = sgs.QList2Table(judges)
		judges = sgs.reverse(judges)
		for index, judge in ipairs(judges) do
			local judge_str = sgs.ai_judge_string[judge:objectName()]
			judge_str = judge_str or sgs.ai_judge_string[judge:getSuitString()]
			local pos = 1 --解判定牌在当前bottom中的位置
			local lightning_flag = false --当前判定牌为闪电的标志
			for _,card in ipairs(bottom) do
				if judge_str == "spade" then
					if not lightning_flag then
						lightning = judge --记录存在的闪电
						local point = card:getNumber()
						if point >= 2 and point <= 9 then
							lightning_flag = true --中闪电的判定牌
						end
					end
				end
				local flag = false --是否将当前判定牌放入牌堆顶的标志
				if judge_str == card:getSuitString() then --是解判定牌/闪电的中判定牌
					flag = not lightning_flag --除闪电外均可
				else --不是解判定牌/闪电的中判定牌
					flag = lightning_flag --仅闪电可
				end
				if flag then
					table.insert(up, card)
					table.remove(bottom, pos)
					judgeList[index] = 1
					hasJudged = true
					break
				end
				pos = pos + 1
			end
			if not judgeList[index] then
				judgeList[index] = 0
			end
		end
		if hasJudged then --若存在可起作用的解判定牌
			--对不可解的延时性锦囊牌位置随意装填中判定牌，保证其他解判定牌起作用
			for index=1, #judgeList, 1 do
				if judgeList[index] == 0 then
					table.insert(up, index, table.remove(bottom))
				end
			end
		else --没有可起作用的解判定牌
			--全部放入牌堆底，祈求自然不中（很自私的做法，权宜之计，待改进）
			return {}, cards
		end
	end
	--昭烈
	if #bottom > 0 then
		local zhaolie_flag = false
		if self.player:hasSkill("zhaolie") then
			local targets = {}
			local others = self.room:getOtherPlayers(self.player)
			for _,p in sgs.qlist(others) do
				if self.player:inMyAttackRange(p) then
					table.insert(targets, p)
				end
			end
			if #targets > 0 then
				self:sort(targets, "hp")
				local target = nil
				for _,p in ipairs(targets) do
					if self:isOpponent(p) then --这里只考虑了昭烈对手，其实有观星的控制时还可以考虑昭烈队友的
						if self:damageIsEffective(p) then
							if sgs.isGoodTarget(self, p, targets) then
								target = p
								break
							end
						end
					end
				end
				if target then
					zhaolie_flag = true
				end
			end
		end
		if zhaolie_flag then
			local drawCount = 1 --自身摸牌数目，待完善
			local basic = {}
			local peach = {}
			local not_basic = {}
			for index, gcard in ipairs(bottom) do
				if gcard:isKindOf("Peach") then
					table.insert(peach, gcard)
				elseif gcard:isKindOf("BasicCard") then
					table.insert(basic, gcard)
				else
					table.insert(not_basic, gcard)
				end
			end
			bottom = {}
			for i=1, drawCount, 1 do
				if self:isWeak() and #peach > 0 then
					table.insert(up, peach[1])
					table.remove(peach, 1)
				elseif #basic > 0 then
					table.insert(up, basic[1])
					table.remove(basic, 1)
				elseif #not_basic > 0 then
					table.insert(up, not_basic[1])
					table.remove(not_basic, 1)
				end
			end
			if #not_basic > 0 then
				for index, card in ipairs(not_basic) do
					table.insert(up, card)
				end
			end
			if #peach > 0 then
				for _,peach in ipairs(peach) do
					table.insert(bottom, peach)
				end
			end
			if #basic > 0 then
				for _,card in ipairs(basic) do
					table.insert(bottom, card)
				end
			end
			up = sgs.Cards_to_Ids(up)
			bottom = sgs.Cards_to_Ids(bottom)
			return up, bottom
		end
	end
	--为下家寻找合适的判定牌
	local next_alive = self.player:getNextAlive()
	local next_judges = {}
	judges = next_alive:getJudgingArea()
	judges = sgs.QList2Table(judges)
	judges = sgs.reverse(judges)
	if lightning then
		table.insert(judges, 1, lightning)
	end
	hasJudged = false
	judgeList = {}
	local luoshen_flag = false
	local pos = 1
	while (#bottom >= 3) do
		if pos > #judges then
			break
		end
		local index = 1
		local lightning_flag = false
		local judge = judges[pos]
		local judge_str = sgs.ai_judge_string[judge:objectName()]
		judge_str = judge_str or sgs.ai_judge_string[judge:getSuitString()]
		for _,card in ipairs(bottom) do
			if judge_str == "spade" then
				if not lightning_flag then
					local point = card:getNumber()
					if point >= 2 and point <= 9 then
						lightning_flag = true
					end
				end
			end
			if self:isPartner(next_alive) then
				if next_alive:hasSkill("luoshen") then
					if card:isBlack() then
						table.insert(next_judges, card)
						table.remove(bottom, index)
						hasJudged = true
						judgeList[index] = 1
						break
					end
				else
					if judge_str == card:getSuitString() then
						if not lightning_flag then
							table.insert(next_judges, card)
							table.remove(bottom, index)
							hasJudged = true
							judgeList[index] = 1
							break
						end
					end
				end
			else
				if next_alive:hasSkill("luoshen") then
					if card:isRed() then
						if not luoshen_flag then
							table.insert(next_judges, card)
							table.remove(bottom, index)
							hasJudged = true
							judgeList[index] = 1
							break
						end
					end
				end
				local flag = false
				if judge_str == card:getSuitString() then
					if judge_str == "spade" then
						if lightning_flag then
							flag = true
						end
					end
				else
					flag = true
				end
				if flag then
					table.insert(next_judges, card)
					table.remove(bottom, index)
					hasJudged = true
					judgeList[index] = 1
				end
			end
			index = index + 1
		end
		if not judgeList[pos] then
			judgeList[pos] = 0
		end
		pos = pos + 1
	end
	if hasJudged then
		for index=1, #judgeList, 1 do
			if judgeList[index] == 0 then
				table.insert(next_judges, index, table.remove(bottom))
			end
		end
	end
	--选择自己使用的牌
	local function getOwnCards(up, bottom, next_judges)
		self:sortByUseValue(bottom)
		local hasSlash = ( self:getCardsNum("Slash") > 0 )
		local hasNext = false
		local fuhun1, fuhun2
		local shuangxiong
		local hasBignumber = false
		for index, card in ipairs(bottom) do
			if index >= 3 then
				break
			end
			if #next_judges > 0 then
				table.insert(up, card)
				table.remove(bottom, index)
				hasNext = true
			else
				if self.player:hasSkill("nosfuhun") then
					if not fuhun1 then
						if card:isRed() then
							table.insert(up, card)
							table.remove(bottom, index)
							fuhun1 = true
						end
					end
					if not fuhun2 then
						if card:isBlack() then
							if sgs.isCard("Slash", card, self.player) then
								table.insert(up, card)
								table.remove(bottom, index)
								fuhun2 = true
							end
						end
					end
					if not fuhun2 then
						if card:isBlack() then
							if card:isKindOf("EquipCard") then
								table.insert(up, card)
								table.remove(bottom, index)
								fuhun2 = true
							end
						end
					end
					if not fuhun2 then
						if card:isBlack() then
							table.insert(up, card)
							table.remove(bottom, index)
							fuhun2 = true
						end
					end
				elseif self.player:hasSkill("shuangxiong") then
					local rednum, blacknum = 0, 0
					local handcards = self.player:getHandcards()
					local cards = sgs.QList2Table(handcards)
					for _, c in ipairs(cards) do
						if c:isRed() then 
							rednum = rednum +1 
						else 
							blacknum = blacknum +1 
						end
					end
					if not shuangxiong then
						if (rednum > blacknum and card:isBlack()) or (blacknum > rednum and card:isRed()) then
							if sgs.isCard("Slash", card, self.player) or sgs.isCard("Duel", card, self.player) then
								table.insert(up, card) 
								table.remove(bottom, index)
								shuangxiong = true
							end
						end
					end
					if not shuangxiong then
						if (rednum > blacknum and card:isBlack()) or (blacknum > rednum and card:isRed()) then
							table.insert(up, card) 
							table.remove(bottom, index)
							shuangxiong = true
						end
					end
				elseif self:hasSkills("tianyi|xianzhen|dahe") then
					local maxcard = self:getMaxPointCard(self.player)
					hasBignumber = maxcard and maxcard:getNumber() > 10
					if not hasBignumber then
						if card:getNumber() > 10 then
							table.insert(up, card) 
							table.remove(bottom, index)
							hasBignumber = true
						end
					end
					if sgs.isCard("Slash", card, self.player) then 
						table.insert(up, card) 
						table.remove(bottom, index)
					end
				else
					if hasSlash then 
						if not card:isKindOf("Slash") then 
							table.insert(up, card) 
							table.remove(bottom, index)
						end
					else
						if sgs.isCard("Slash", card, self.player) then 
							table.insert(up, card) 
							table.remove(bottom, index)
							hasSlash = true 
						end
					end
				end
			end
		end
		if hasNext then
			for _, card in ipairs(next_judges) do
				table.insert(up, card) 
			end
		end
		return up, bottom
	end
	up, bottom = getOwnCards(up, bottom, next_judges)
	up = sgs.Cards_to_Ids(up)
	bottom = sgs.Cards_To_Ids(bottom)
	return up, bottom
end
--[[
	功能：执行心战
	参数：self（即表SmartAI）
		cards（table类型，表示待排列的卡牌编号列表）
	结果：table类型（表示位于牌堆顶的卡牌）和table类型（表示位于牌堆底的卡牌）
]]--
function sgs.DoXinZhan(self, cards)
	local up = {}
	local bottom = sgs.Ids_to_Cards(cards)
	local judgeList = {}
	local hasJudged = false
	local next_alive = self.player:getNextAlive()
	local judges = next_alive:getJudgingArea()
	local need_judge = true
	if judges:isEmpty() then
		need_judge = false
	else
		for _,judge in sgs.qlist(judges) do
			if judge:isKindOf("YanxiaoCard") then
				need_judge = false
			end
		end
	end
	if need_judge then
		judges = sgs.QList2Table(judges)
		judges = sgs.reverse(judges)
		for index, judge in ipairs(judges) do
			local pos = 1
			local lightning_flag = false
			local judge_str = sgs.ai_judge_string[judge:objectName()]
			judge_str = judge_str or sgs.ai_judge_string[judge:getSuitString()]
			for _,card in ipairs(bottom) do
				if judge_str == "spade" then
					if not lightning_flag then
						local point = card:getNumber()
						if point >= 2 and point <= 9 then
							lightning_flag = true
						end
					end
				end
				if self:isPartner(next_alive) then
					if judge_str == card:getSuitString() then
						if not lightning_flag then
							table.insert(up, card)
							table.remove(bottom, pos)
							hasJudged = true
							judgeList[index] = 1
							break
						end
					end
				else
					local flag = false
					if judge_str == card:getSuitString() then
						if judge_str == "spade" then
							if lightning_flag then
								flag = true
							end
						end
					else
						flag = true
					end
					if flag then
						table.insert(up, card)
						table.remove(bottom, pos)
						hasJudged = true
						judgeList[index] = 1
						break
					end
				end
				pos = pos + 1
			end
			if not judgeList[index] then
				judgeList[index] = 0
			end
		end
	end
	if hasJudged then
		for index=1, #judgeList, 1 do
			if judgeList[index] == 0 then
				table.insert(up, index, table.remove(bottom))
			end
		end
	end
	while #bottom > 0 do
		table.insert(up, table.remove(bottom))
	end
	up = sgs.Cards_to_Ids(up)
	bottom = sgs.Cards_to_Ids(bottom)
	return up, bottom
end
--[[
	功能：响应askForGuanxing询问
	参数：cards（table类型，表示待排列的卡牌列表）
		up_only（boolean类型，表示是否只在牌堆顶排列）
	结果：table类型（表示位于牌堆顶的卡牌）和table类型（表示位于牌堆底的卡牌）
]]--
function SmartAI:askForGuanxing(cards, up_only)
	if sgs.SeriesName then
		local callback = sgs.ai_series_guanxing[sgs.SeriesName]
		if type(callback) == "function" then
			local up, down = callback(self, cards, up_only)
			if up and down then
				return up, down
			end
		end
	end
	if up_only then
		return sgs.DoXinZhan(self, cards)
	else
		return sgs.DoGuanXing(self, cards)
	end
	return cards, {}
end