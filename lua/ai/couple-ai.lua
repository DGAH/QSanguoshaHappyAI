--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）夫妻协战模式部分
]]--
sgs.couple_camp = {
	--caocao
	caocao = "caocao",
	--couple01
	caopi = "couple01",
	caozhi = "couple01",
	zhenji = "couple01",
	--couple02
	simayi = "couple02",
	zhangchunhua = "couple02",
	--couple03
	liubei = "couple03",
	ganfuren = "couple03",
	sp_sunshangxiang = "couple03",
	--couple04
	zhugeliang = "couple04",
	wolong = "couple04",
	huangyueying = "couple04",
	--couple05
	menghuo = "couple05",
	zhurong = "couple05",
	--couple06
	zhouyu = "couple06",
	xiaoqiao = "couple06",
	--couple07
	lvbu = "couple07",
	dongzhuo = "couple07",
	diaochan = "couple07",
	--couple08
	sunjian = "couple08",
	wuguotai = "couple08",
	--couple09
	sunce = "couple09",
	daqiao = "couple09",
	--couple10
	sunquan = "couple10",
	bulianshi = "couple10",
	--couple11
	diy_simazhao = "couple11",
	diy_wangyuanji = "couple11",
	--couple12
	liuxie = "couple12",
	diy_liuxie = "couple12",
	fuhuanghou = "couple12",
	as_fuhuanghou = "couple12",
}
sgs.ai_role_to_camp["couple"] = {
	lord = "caocao",
	loyalist = "caocao",
	renegade = "couple",
	skip = 1,
	convert_func = function(role, player)
		if role == "lord" then
			return "caocao"
		elseif role == "renegade" then
			local name = player:objectName()
			local camp = sgs.couple_camp[name] or "renegade"
			return camp
		end
		return "renegade"
	end,
}
sgs.InitRelationship["couple"] = function()
	local lord = global_room:getLord()
	local lordname = lord:objectName()
	sgs.ai_lord[lordname] = lordname
	table.insert(sgs.ai_lords, lordname)
	local allplayers = global_room:getAllPlayers()
	for _,p in sgs.qlist(allplayers) do
		local nameA = p:objectName()
		for _,p2 in sgs.qlist(allplayers) do
			local nameB = p2:objectName()
			if sgs.couple_camp[nameA] == sgs.couple_camp[nameB] then
				sgs.ai_relationship[nameA][nameB] = "partner"
			else
				sgs.ai_relationship[nameA][nameB] = "opponent"
			end
		end
		sgs.ai_camp[nameA] = sgs.couple_camp[nameA]
	end
end
--[[
	技能：重选
	描述：游戏开始时，选择曹丕的角色可以重选成曹植，诸葛亮和吕布等同理。
]]--
sgs.ai_skill_invoke["reselect"] = function(self, data)
	return math.random(0, 2) == 0
end