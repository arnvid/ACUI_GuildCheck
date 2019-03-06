ES_GuildCheck_Data = { };
ES_GuildCheck_Changes = {
	["offline"] = {
		["count"] = 0,
		["members"] = {}
	},
	["online"] = {
		["count"] = 0,
		["members"] = {}
	}
};
ES_GuildCheck_ConfigString = "";
ES_GuildCheck_Output = true;
ES_GuildCheck_FirstScan = true;
ES_GuildCheck_Version = "1.31+ACUI_WOW2";

function ES_GuildCheck_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("GUILD_ROSTER_UPDATE");
	
	SLASH_GUILDCHECK1 = "/egc";
	SlashCmdList["GUILDCHECK"] = ES_GuildCheck_SlashHandler;
end

function ES_GuildCheck_SlashHandler(msg)
	if( msg == "offline" ) then
		ES_GuildCheck_PrintChanges(ES_GuildCheck_Changes.offline);
	elseif( msg == "online" ) then
		ES_GuildCheck_Output = true;
		ES_GuildCheck_UpdateData();
	else
		ES_GuildCheck_PrintHelp();
	end
end

function ES_GuildCheck_OnEvent(event)
	if ( event == "VARIABLES_LOADED" ) then
		GuildRoster();
	elseif( event == "GUILD_ROSTER_UPDATE" ) then
		if( IsInGuild() ) then
			if( not ES_GuildCheck_ConfigString or ES_GuildCheck_ConfigString == "" ) then
				if( GetCVar("realmName") and GetGuildInfo("player") ) then
					ES_GuildCheck_ConfigString = GetCVar("realmName").."-"..GetGuildInfo("player");
				end
			end

			if(  ES_GuildCheck_ConfigString and ES_GuildCheck_ConfigString ~= "" ) then
				if( not ES_GuildCheck_Data[ES_GuildCheck_ConfigString] ) then
					ES_GuildCheck_Data[ES_GuildCheck_ConfigString] = { };
					ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count = 0;
					ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members = { };
				end
	
				if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count == 0 ) then
					ES_GuildCheck_ReadData();
				elseif( GetNumGuildMembers(true) > 0 ) then
					ES_GuildCheck_UpdateData();
				end
			end
		end
	end
end

function ES_GuildCheck_ReadData()
	for i=1,GetNumGuildMembers(true) do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
		ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name] = {
			["Rang"] = rank,
			["Level"] = level,
			["Klasse"] = class,
			["Notiz"] = note
		--	["Offiziersnotiz"] = officernote
		};
		if( CanViewOfficerNote() ) then
			ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz = officernote;
		end
		ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count = ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count + 1;
	end
end

function ES_GuildCheck_UpdateData()
	local changes = 0;
	local target;
	if( ES_GuildCheck_FirstScan ) then
		target = ES_GuildCheck_Changes.offline;
		ES_GuildCheck_FirstScan = false;
	else
		target = ES_GuildCheck_Changes.online;
	end
	
	
	for n,d in pairs(ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members) do
		local found = false;
		for i=1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
			if( name == n ) then
				found = true;
			end
		end
		if( not found ) then
			target.members[n] = {
				[1] = "    " .. ES_GUILDCHECK_GUILDLEFT,
				[2] = "    " .. ES_GUILDCHECK_RANK .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Rang,
				[3] = "    " .. ES_GUILDCHECK_LEVEL .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Level,
				[4] = "    " .. ES_GUILDCHECK_CLASS .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Klasse
			};
			if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Notiz ) then
				table.insert(target.members[n], "    " .. ES_GUILDCHECK_NOTE .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Notiz);
			end
			if( CanViewOfficerNote() and ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Offiziersnotiz ) then
				table.insert(target.members[n], "    " .. ES_GUILDCHECK_ONOTE .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n].Offiziersnotiz);
			end
			target.count = target.count + 1;
			ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[n] = nil;
			ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count = ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count - 1;
		end
	end
	
	for i=1,GetNumGuildMembers(true) do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
		if( not ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name] ) then
			target.members[name] = {
				[1] = "    " .. ES_GUILDCHECK_GUILDJOIN,
				[2] = "    " .. ES_GUILDCHECK_RANK .. ": " .. rank,
				[3] = "    " .. ES_GUILDCHECK_LEVEL .. ": " .. level,
				[4] = "    " .. ES_GUILDCHECK_CLASS .. ": " .. class
			};
			if( note ) then
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_NOTE .. ": " .. note);
			end
			if( CanViewOfficerNote() ) then
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_ONOTE .. ": " .. officernote);
			end
			target.count = target.count + 1;
			ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name] = {
				["Rang"] = rank,
				["Level"] = level,
				["Klasse"] = class,
				["Notiz"] = note,
				["Offiziersnotiz"] = officernote
			};
			ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count = ES_GuildCheck_Data[ES_GuildCheck_ConfigString].count + 1;
		else
			if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Rang ~= rank ) then
				if( not target.members[name] ) then
					target.members[name] = {};
				end
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_RANK .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Rang.." => "..rank);
				target.count = target.count + 1;
				ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Rang = rank;
			end
			if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Level ~= level ) then
				if( not target.members[name] ) then
					target.members[name] = {};
				end
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_LEVEL .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Level.." => "..level);
				target.count = target.count + 1;
				ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Level = level;
			end
			if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Klasse ~= class ) then
				if( not target.members[name] ) then
					target.members[name] = {};
				end
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_CLASS .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Klasse.." => "..class);
				target.count = target.count + 1;
				ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Klasse = class;
			end
			if( ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Notiz ~= note ) then
				if( not target.members[name] ) then
					target.members[name] = {};
				end
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_NOTE .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Notiz.." => "..note);
				target.count = target.count + 1;
				ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Notiz = note;
			end
			if( CanViewOfficerNote() and ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz ~= officernote ) then
				if( not target.members[name] ) then
					target.members[name] = {};
				end
				if( not ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz ) then
					ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz = " ";
				end
				table.insert(target.members[name], "    " .. ES_GUILDCHECK_ONOTE .. ": " .. ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz.." => "..officernote);
				target.count = target.count + 1;
				ES_GuildCheck_Data[ES_GuildCheck_ConfigString].members[name].Offiziersnotiz = officernote;
			end
		end
	end
	
	if( ES_GuildCheck_Output ) then
		ES_GuildCheck_PrintChanges(target);
		ES_GuildCheck_Output = false;
	end
end

function ES_GuildCheck_PrintHelp()
	ES_GuildCheck_Print("ES_GuildCheck (v"..ES_GuildCheck_Version.."):");
	ES_GuildCheck_Print(ES_GUILDCHECK_HELP1);
	ES_GuildCheck_Print(ES_GUILDCHECK_HELP2);
	ES_GuildCheck_Print(ES_GUILDCHECK_HELP3);
end

function ES_GuildCheck_PrintChanges( target )
	ES_GuildCheck_Print("ES_GuildCheck (v"..ES_GuildCheck_Version.."):");
		
	for name,data in pairs(target.members) do
		ES_GuildCheck_Print("  " .. name);
		for ind,change in pairs(data) do
			ES_GuildCheck_Print(change);
		end
	end
	
	if( target.count > 1 ) then
		ES_GuildCheck_Print(ES_GUILDCHECK_TOTAL .. " " .. target.count .. " " .. ES_GUILDCHECK_CHANGES);
	elseif( target.count == 1 ) then
		ES_GuildCheck_Print(ES_GUILDCHECK_ONECHANGE);
	else
		ES_GuildCheck_Print(ES_GUILDCHECK_NOCHANGE);
	end
end

function ES_GuildCheck_Print(str)
	DEFAULT_CHAT_FRAME:AddMessage(str, 0, 1, 0);
end