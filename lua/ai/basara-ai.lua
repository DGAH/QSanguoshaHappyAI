--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）暗将模式部分
]]--
--国战模式
if sgs.GetConfig("EnableHegemony", false) then
	--[[
		功能：获取暗将的势力名
		参数：player（ServerPlayer类型，表示目标暗将）
		结果：string类型，表示势力名
	]]--
	function getHegemonyKingdom(player)
		local key = player:objectName()
		local tag = global_room:getTag(key)
		if tag then
			local names = tag:toStringList()
			if names and #names > 0 then
				local general = sgs.Sanguosha:getGeneral(names[1])
				return general:getKingdom()
			end
		end
		return player:getKingdom()
	end
	--[[
		功能：获取暗将的武将名
		参数：player（ServerPlayer类型，表示目标暗将）
		结果：string类型，表示武将名
	]]--
	function getHegemonyGeneral(player)
		local key = player:objectName()
		local tag = global_room:getTag(key)
		if tag then
			local names = tag:toStringList()
			if names and #names > 0 then
				return names[1]
			end
		end
		return player:getGeneralName()
	end
end