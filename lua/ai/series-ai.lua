--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）套路注册文件
]]--
sgs.ai_series = {} --AI出牌套路集合
sgs.ai_series_use_func = {} --AI按套路出牌的具体方式集合
sgs.ai_card_actions = {} --卡牌参与套路表
sgs.ai_card_groups = {} --AI出牌组合表
sgs.ai_card_history = {} --AI出牌历史
sgs.ai_series_failtime = {} --AI套路失败次数
sgs.ai_current_series = {} --当前出牌套路的具体内容
--[[
	功能：注册可以主动使用的卡牌
	参数：card_name（string类型，表示被注册卡牌名）
	结果：无
]]--
function sgs.RegistCard(card_name)
	sgs.ai_card_actions[card_name] = {}
	sgs.ai_card_groups[card_name] = {}
	sgs.ai_series_use_func[card_name] = {}
end
--[[
	功能：检查可用卡牌是否符合套路发动要求
	参数：name（string类型，表示套路名）
		handcards（table类型，表示可用的手牌）
		skillcards（table类型，表示可用的技能卡）
	结果：boolean类型，表示是否符合要求（true表示符合要求，false表示不符合要求）
]]--
function SmartAI:checkSeries(name, handcards, skillcards)
	local series = sgs.ai_series[name]
	if series then
		--智商水平限制
		local IQ_limit = series["IQ"] or 1
		if sgs.ai_IQ < IQ_limit then
			return false
		end
		--失败限制
		local failtime = sgs.ai_series_failtime[name]
		if failtime and failtime > 0 then --Just For Test
			return false
		end
		--技能限制
		local skills = series["skills"]
		if skills then
			if not self:hasAllSkills(skills, self.player) then
				return false
			end
		end
		--条件限制
		local enabled = series["enabled"]
		if enabled then
			if not enabled(self) then
				return false
			end
		end
		--卡牌限制
		local needcards = series["cards"]
		if needcards then
			local needcount = {}
			for index, cardtype in pairs(needcards) do
				needcount[cardtype] = needcards[cardtype] 
			end
			local cardcount = #handcards
			for _,card in ipairs(handcards) do
				local name = sgs.getCardName(card)
				if needcount[name] and needcount[name] > 0 then
					needcount[name] = needcount[name] - 1
					if not card:isKindOf("SkillCard") then
						cardcount = cardcount - 1
					end
				end
			end
			for _,card in ipairs(skillcards) do
				local name = sgs.getCardName(card)
				if needcount[name] and needcount[name] > 0 then
					needcount[name] = needcount[name] - 1
				end
			end
			if needcount["Others"] then
				needcount["Others"] = needcount["Others"] - cardcount
			end
			for index, cardtype in pairs(needcount) do
				if needcount[cardtype] > 0 then
					return false
				end
			end
		end
		return true
	end
	return false
end
--[[
	功能：套路异常中止处理
	参数：reason（string类型，表示套路中止的原因）
		name（string类型，表示套路名称）
	结果：无
]]--
function SmartAI:windUpSeries(reason, name)
	name = name or sgs.SeriesName
	assert(name)
	if reason == "InValid" then
		--收尾处理
		local failtime = sgs.ai_series_failtime[name] or 0
		sgs.ai_series_failtime[name] = failtime + 1
		sgs.SeriesFail = true
		sgs.SeriesName = nil --清除当前套路名
		sgs.ai_current_series = {} --清空当前出牌序列
	elseif reason == "Break" then
		--检测此套路已经进行的程度
		--收尾处理
		sgs.SeriesBreak = true
		sgs.SeriesName = nil --清除当前套路名
		sgs.ai_current_series = {} --清空当前出牌序列
	elseif reason == "Consider" then
		local failtime = sgs.ai_series_failtime[name] or 0
		sgs.ai_series_failtime[name] = failtime + 0.5
	end
end
--[[
	功能：对指定范围内的所有套路进行排序
	参数：series（table类型，表示套路集合）
		key（string类型，表示排序标准）
		inverse（boolean类型，表示是否逆序）
	结果：table类型（series），表示排序后的所有套路
]]--
function sgs.sortSeries(series, key, inverse)
	local function compare_func(a, b)
		local nameA = a["name"] or a
		local nameB = b["name"] or b
		local seriesA = sgs.ai_series[a]
		local seriesB = sgs.ai_series[b]
		local valueA = 0
		local valueB = 0
		if seriesA then
			valueA = seriesA[key] or 0
		end
		if seriesB then
			valueB = seriesB[key] or 0
		end
		if inverse then
			return valueA < valueB
		else
			return valueA > valueB
		end
	end
	table.sort(series, compare_func)
	return series
end
--[[
	功能：对指定范围内的所有套路按使用价值排序
	参数：series（table类型，表示套路集合）
		inverse（boolean类型，表示是否逆序）
	结果：table类型，表示排序结果
]]--
function sgs.sortSeriesByUseValue(series, inverse)
	return sgs.sortSeries(series, "value", inverse)
end
--[[
	功能：对指定范围内的所有套路按使用优先级排序
	参数：series（table类型，表示套路集合）
		inverse（boolean类型，表示是否逆序）
	结果：table类型，表示排序结果
]]--
function sgs.sortSeriesByUsePriority(series, inverse)
	return sgs.sortSeries(series, "priority", inverse)
end
--[[
	内容：按套路要求使用卡牌
	参数：self（即表SmartAI）
		card（Card类型，表示待使用的卡牌的dummyCard）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构体）
		name（string类型，表示待使用卡牌的统一用名）
	结果：string类型，表示使用结果状态
]]--
function sgs.useCardInSeries(self, card, use, name)
	if sgs.SeriesName then
		name = name or sgs.getCardName(card)
		local series_use = sgs.ai_series_use_func[name]
		if series_use then
			local callback = series_use[sgs.SeriesName]
			if type(callback) == "function" then
				return callback(self, card, use) 
			end
		end
	end
	return "NOTHING"
end
--[[
	套路示例
]]--
sgs.ai_series["Demo"] = {
	--套路名称（string类型）
	name = "Demo",
	--套路施行的最低智商水平（number类型）
	IQ = 0,
	--套路的采用价值（number类型），数值越大，价值越高
	value = 0,
	--套路的采用优先级（number类型），数值越大，优先级越高
	priority = -1,
	--套路中涉及到的技能（table类型或用"+"分割的string类型），只有同时拥有此处列出的所有技能时，才采用此套路
	skills = "",
	--套路中涉及到的卡牌（table类型），表示每种卡牌最少需要的数目，只要当前卡牌数低于此限制，则不能采用此套路；Others表示除指定种类卡牌外还需要的任意卡牌的最少数目
	cards = {
		["Others"] = 0,
	},
	--套路的发动条件（function类型，参数为self<即表SmartAI>，结果为boolean类型），只有当此函数的结果为true时才能采用此套路。这是除卡牌数要求外，套路发动的最低要求；保证卡牌条件下的任何情形，只要此最低要求满足，就可以考虑采用此套路。
	enabled = function(self)
		return false
	end,
	--具体的出牌序列（function类型，参数为self<即表SmartAI>，以及cards<table类型，表示此时可用的手牌和dummy技能卡>，结果为table类型<以Card为元素类型>），只有当此函数的结果不为空表时才会采用此套路，使AI按照结果中提供的各卡牌的次序依次使用卡牌。
	action = function(self, handcards, skillcards)
		return {}
	end,
	--套路中止条件（function类型，参数为self<即表SmartAI>，结果为boolean类型），用于在环境变化时，判断多步骤套路是否应当中断，以考虑采用其它更合适的套路。当此函数结果为true时，AI出牌不再继续依照当前套路行动。此函数对于单步骤套路无效。
	break_condition = function(self)
		return false
	end
}