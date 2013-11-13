--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）工具函数库
]]--
--[[
	功能：复制一张表
	参数：source（table类型，表示待复制的表）
	结果：table类型（result），表示对source的一份复制结果
]]--
function sgs.CopyTable(source)
	local result = {}
	for key, value in pairs( source or {} ) do
		if type(value) == "table" then
			result[key] = sgs.CopyTable(value)
		else
			result[key] = value
		end
	end
	return result
end
--[[
	功能：合并两张表
	参数：tableA（table类型，表示第一张表）
		tableB（table类型，表示第二张表）
	结果：table类型（result），表示合并的结果
]]--
function sgs.ConcatTable(tableA, tableB)
	local result = {}
	for key, value in pairs(tableA) do
		if type(key) == "number" then
			table.insert(result, value)
		else
			result[key] = value
		end
	end
	for key, value in pairs(tableB) do
		if type(key) == "number" then
			table.insert(result, value)
		else
			result[key] = value
		end
	end
	return result
end
--[[
	功能：将一张表的内容转化成字符串
	参数：source（table类型，表示待转化的表）
		level（number类型，表示表的层级）
	结果：string类型（result），表示对source的一份转化结果
]]--
function sgs.TableContext(source, level)
	if source then
		level = level or 0
		local blanks = ""
		for i=1, level, 1 do
			blanks = blanks .. "    "
		end
		local result = blanks .. "{"
		for key, value in pairs( source or {} ) do
			local sub_result = "    "
			local value_type = type(value)
			if value_type == "table" then
				sub_result = "    table:"..tostring(key).. "\r\n".. sgs.TableContext(value, level+1)
			elseif value_type == "function" then
				sub_result = "    function:"..tostring(key)
			elseif value_type == "userdata" then
				sub_result = "    userdata:"..tostring(key)
			else
				sub_result = "    "..value_type..":"..tostring(value)
			end
			result = result .. "\r\n" .. blanks .. sub_result
		end
		result = result .. "\r\n" .. blanks .. "}"
		return result
	end
	return "ERROR:A NIL TABLE!"
end
--[[
	功能：查找两份技能名单中的公共技能
	参数：first（table或string类型，表示第一份技能名单）
		second（table或string类型，表示第二份技能名单）
	结果：table类型（findings），表示所有找到的公共技能
]]--
function sgs.findIntersectionSkills(first, second)
	if type(first) == "string" then 
		first = first:split("|") 
	end
	if type(second) == "string" then 
		second = second:split("|") 
	end

	local findings = {}
	for _, skill in ipairs(first) do
		for _, compare_skill in ipairs(second) do
			if skill == compare_skill then
				if not table.contains(findings, skill) then 
					table.insert(findings, skill) 
				end
			end
		end
	end
	
	return findings
end
--[[
	功能：合并两份技能名单
	参数：first（table或string类型，表示第一份技能名单）
		second（table或string类型，表示第二份技能名单）
	结果：table类型（findings），表示合并后的技能名单，包括所有在first或second中出现的技能
]]--
function sgs.findUnionSkills(first, second)
	if type(first) == "string" then 
		first = first:split("|") 
	end
	if type(second) == "string" then 
		second = second:split("|") 
	end
	
	local findings = table.copyFrom(first)
	for _, skill in ipairs(second) do
		if not table.contains(findings, skill) then 
			table.insert(findings, skill) 
		end
	end
	
	return findings
end
--[[
	功能：查找指定对象名的角色
	参数：room（Room类型，表示所在的房间）
		name（string类型，表示指定的对象名）
		include_death（boolean类型，表示是否考虑已阵亡的角色）
		except（Player类型，表示不加以考虑的特殊角色）
	结果：ServerPlayer类型（p），表示找到的以name为对象名的角色
]]--
function findPlayerByObjectName(room, name, include_death, except)
	if room then
		local players = nil
		if include_death then
			players = room:getPlayers()
		else
			players = room:getAlivePlayers()
		end
		if except then
			players:removeOne(except)
		end
		for _,p in sgs.qlist(players) do
			if p:objectName() == name then
				return p
			end
		end
	end
end
--[[
	功能：判断一名角色是否拥有指定范围内的至少一项技能
	参数：skills（table类型或string类型，表示目标技能名单）
		target（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否拥有
]]--
function SmartAI:hasSkills(skills, target)
	target = target or self.player
	if type(skills) == "string" then
		skills = skills:split("|")
	end
	for _,skill in ipairs(skills) do
		if target:hasSkill(skill) then
			return true
		end
	end
	return false
end
--[[
	功能：判断一名角色是否拥有指定范围内的所有技能
	参数：skills（table类型或string类型，表示目标技能名单）
		target（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否全部拥有
]]--
function SmartAI:hasAllSkills(skills, target)
	target = target or self.player
	if type(skills) == "string" then
		skills = skills:split("+")
	end
	for _,skill in ipairs(skills) do
		if not target:hasSkill(skill) then
			return false
		end
	end
	return true
end
--[[
	功能：判断一张卡牌是否属于指定范围内的某一类型
	参数：types（table类型或string类型，表示目标类型范围）
		card（Card类型，表示待判断的卡牌）
	结果：boolean类型，表示是否属于其中一种类型
]]--
function sgs.isKindOf(types, card)
	if card then
		if type(types) == "string" then
			types = types:split("|")
		end
		for _,class_name in ipairs(types) do
			if card:isKindOf(class_name) then
				return true
			end
		end
	end
	return false
end
--[[
	功能：统计指定范围的角色中出现的势力数目
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有指定范围中的角色）
	结果：number类型（count），表示势力数目
]]--
function sgs.getKingdomsCount(players)
	players = players or global_room:getAlivePlayers()
	local count = 0
	local kingdoms = {}
	for _,p in sgs.qlist(players) do
		local kingdom = p:getKingdom()
		if not kingdoms[kingdom] then
			kingdoms[kingdom] = true
			count = count + 1
		end
	end
	return count
end