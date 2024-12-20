local function showPointSummary(cur)
	local stuff = {}

	local pKeys = LocalPlayer():GetPointsKeys()
	if table.IsEmpty(pKeys) then
		table.insert(stuff, "point_nil")
	else
		table.insert(stuff, "point_total")
		table.Add(stuff, pKeys)
	end

	table.insert(stuff, "point_summary")

	local totalEntries = #stuff

	local shift = 0
	for k, v in ipairs(stuff) do
		if CurTime() - cur < 2 + (totalEntries - k) * 0.35 then
			continue
		end

		local langText
		if v == "point_summary" or v == "point_nil" then
			langText = SlashCo.Language(v)
		elseif v == "point_total" then
			langText = SlashCo.Language(v, LocalPlayer():GetTotalPoints())
		else
			local amount, num = LocalPlayer():GetPoints(v)
			if amount > 0 then
				amount = "+" .. amount
			end

			langText = SlashCo.Language("points_" .. v, amount)

			if num > 1 then
				langText = langText .. " x" .. num
			end
		end

		local str = string.format("<font=TVCD_small>%s</font>", langText)
		local parsedItem = markup.Parse(str)

		parsedItem:Draw(ScrW() * 0.025 + 4, ScrH() * 0.95 - shift, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

		shift = shift + 14 + 8
	end
end

local function printPlayersNeatly(players)
	local count = #players
	if count == 0 then
		return SlashCo.Language("nobody"), 0
	end
	if count == 1 then
		return players[1]:GetName(), 1
	end
	if count == 2 then
		return SlashCo.Language("TwoElements", players[1]:GetName(), players[2]:GetName()), 2
	end

	local strings = {}
	for i = 1, count - 2 do
		table.insert(strings, SlashCo.Language("InList", players[i]:GetName()))
	end
	table.insert(strings, SlashCo.Language("TwoElements", players[count - 1]:GetName(), players[count]:GetName()))

	return table.concat(strings), count
end

local function printRescued(rescued)
	local plysRescued = table.Copy(rescued)
	for k, ply in pairs(plysRescued) do
		if not IsValid(ply) then
			table.remove(plysRescued, k)
		end
	end

	local neatString, count = printPlayersNeatly(plysRescued)
	if count <= 0 then
		return
	end
	return SlashCo.Language(count == 1 and "RescuedOnlyOne" or "Rescued", neatString)
end

local function printLeftBehind(rescued)
	local plysLeftBehind = {}
	for _, v in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
		local isRescued
		for _, v1 in ipairs(rescued) do
			if not IsValid(v1) then continue end
			if v:UserID() == v1:UserID() then
				isRescued = true
				break
			end
		end

		if not isRescued then
			table.insert(plysLeftBehind, v)
		end
	end

	local neatString, count = printPlayersNeatly(plysLeftBehind)
	if count <= 0 then
		return
	end
	return SlashCo.Language(count == 1 and "LeftBehindOnlyOne" or "LeftBehind", neatString)
end

local function printKilled(survivors, rescued)
	local plysKilled = {}
	for k, ply in ipairs(survivors) do
		if not IsValid(ply) then continue end
		if ply:Team() == TEAM_SURVIVOR then continue end

		for _, v in ipairs(rescued) do
			if not IsValid(v) then continue end
			if ply:UserID() == v:UserID() then
				goto CONTINUE --needed to continue out of multiple loops
			end
		end

		table.insert(plysKilled, ply)
		:: CONTINUE ::
	end

	local neatString, count = printPlayersNeatly(plysKilled)
	if count <= 0 then
		return
	end
	return SlashCo.Language(count == 1 and "KilledOnlyOne" or "Killed", neatString)
end

local function teamSummary(lines, survivors, rescued)
	local rescuedString = printRescued(rescued)
	if rescuedString then
		table.insert(lines, rescuedString)
	end

	local leftBehindString = printLeftBehind(rescued)
	if leftBehindString then
		table.insert(lines, leftBehindString)
	end

	local killedString = printKilled(survivors, rescued)
	if killedString then
		table.insert(lines, killedString)
	end
end

local dangerTable = {
	[0] = "Unknown",
	"Moderate",
	"Considerable",
	"Devastating"
}
local classTable = {
	[0] = "Unknown",
	"Cryptid",
	"Demon",
	"Umbra"
}
local difficultyTable = {
	[0] = "Easy",
	"Novice",
	"Intermediate",
	"Hard"
}
local stateTable = {
	[0] = "wonAllSurvivors",
	"wonSomeSurvivors",
	"wonNoSurvivors",
	"lost",
	"wonBeacon",
	"cursed",
	"intro"
}
local stringTable = {
	wonAllSurvivors = function()
		surface.PlaySound("slashco/music/slashco_win_full.mp3")
		return {
			SlashCo.Language("AssignmentSuccess"),
			SlashCo.Language("AllRescued"),
		}
	end,
	wonSomeSurvivors = function(survivors, rescued)
		surface.PlaySound("slashco/music/slashco_win_2.mp3")
		local lines = {
			SlashCo.Language("AssignmentSuccess"),
			SlashCo.Language("SomeRescued"),
		}
		teamSummary(lines, survivors, rescued)

		return lines
	end,
	wonNoSurvivors = function()
		surface.PlaySound("slashco/music/slashco_lost_active.mp3")
		return {
			SlashCo.Language("AssignmentSuccess"),
			SlashCo.Language("NoneRescued"),
		}
	end,
	lost = function()
		surface.PlaySound("slashco/music/slashco_lost.mp3")
		return {
			SlashCo.Language("AssignmentFail"),
			SlashCo.Language("NoneRescued"),
		}
	end,
	wonBeacon = function(survivors, rescued)
		surface.PlaySound("slashco/music/slashco_win_db.mp3")
		local lines = {
			SlashCo.Language("AssignmentAborted"),
		}
		teamSummary(lines, survivors, rescued)

		return lines
	end,
	cursed = function()
		surface.PlaySound("slashco/music/slashco_lost.mp3")
		local lines = {}
		for i = 0, 19 do
			local line = string.Split(SlashCo.Language("Cursed"), SlashCo.Language("WordSeparator"))
			for i1 = 1, i do
				line[math.random(1, #line)] = SlashCo.Language("Judgement")
			end
			table.insert(lines, table.concat(line, SlashCo.Language("WordSeparator")))
		end

		return lines
	end,
	intro = function(info)
		stop_lobbymusic = true --incredibly lame
		surface.PlaySound("slashco/music/slashco_intro.mp3")
		local lines = {
			SlashCo.Language("cur_assignment", info[1]),
			SlashCo.Language("slasher_assess"),
			SlashCo.Language("Name", info[2]),
			SlashCo.Language("Class", classTable[info[3]]),
			SlashCo.Language("DangerLevel", dangerTable[info[4]]),
			SlashCo.Language("Difficulty", difficultyTable[info[5]]),
		}
		if info[6] ~= "Regular" then
			table.insert(lines, SlashCo.Language("Offering_name", info[6]))
		end

		return lines
	end
}

local function fadeIn(panel)
	local anim = Derma_Anim("Fade", nil, function(_, _, delta)
		panel:SetAlpha(255 * delta)
	end)
	anim:Start(1)

	function panel.Think()
		if anim:Active() then
			anim:Run()
		end
	end
end

local function nextLine(panel, lines)
	local line = panel:Add("DLabel")
	line:Dock(TOP)
	line:SetFont("OutroFont")
	line:SetContentAlignment(8)
	line:SetTall(40)
	line:SetText(lines[#lines])

	timer.Simple(0, function()
		local w = line:GetTextSize()
		if w > ScrW() then
			line:SetWrap(true)
			line:SetTall(80)
		end
	end)

	fadeIn(line)

	local fill = panel:Add("Panel")
	fill:Dock(TOP)
	fill:SetTall(ScrH() / 20)

	table.remove(lines)
end

hook.Add("scValue_RoundEnd", "SlashCoRoundEnd", function(state, survivors, rescued)
	local stateString = stateTable[state]
	local lines = stringTable[stateString](survivors, rescued)
	if table.IsEmpty(lines) then
		return
	end

	local cur = CurTime()

	local linesPlay = table.Reverse(lines)
	local panel = vgui.Create("Panel")
	panel:Dock(FILL)
	fadeIn(panel)

	function panel.Paint()
		surface.SetDrawColor(0, 0, 0)
		panel:DrawFilledRect()

		if stateTable[state] ~= "intro" and CurTime() - cur > 2 then
			showPointSummary(cur)
		end
	end

	timer.Simple(0, function()
		if not IsValid(panel) then
			return
		end

		local fill = panel:Add("Panel")
		fill:Dock(TOP)
		fill:SetTall(ScrH() / 5)

		nextLine(panel, linesPlay)

		local fill1 = panel:Add("Panel")
		fill1:Dock(TOP)
		fill1:SetTall(ScrH() / 20)
	end)

	local shows
	timer.Create("SlashCoRoundEnd", 1, 0, function()
		if not next(linesPlay) or not IsValid(panel) then
			timer.Remove("SlashCoRoundEndThink")
			return
		end

		if not shows then
			shows = true
			return
		end

		nextLine(panel, linesPlay)
	end)
end)

local helimusic_antispam
local heli_music
net.Receive("mantislashcoHelicopterMusic", function()
	if not helimusic_antispam then
		heli_music = CreateSound(LocalPlayer(), "slashco/music/slashco_helicopter.wav")
		heli_music:Play()
		helimusic_antispam = true
		g_AmbientStop = true
	end
end)