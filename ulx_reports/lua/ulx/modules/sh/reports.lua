--[[Information:

Report Module v2
Originally by Kyzer (& ULX Team for used functions :p)
Updated by Flambe
For ULX 3.50<

#Changelog:

	2.0: [meta] Flambe took over dev since Kyzer hasn't been active in a while and the module has been broken for ages

	1.3:	[add] command help moved into "Utilities" Category (if using ULX 3.20 or greater)
		[add] some comments
		[change] minor and useless changes

	1.2:	[fix] some idiotic bugs, improved code a bit
	
	1.1:	[add] antispam
		[add] log in daily files (as an option)

	1.0:	[initial release]


#Commands:
	"!report <text>" in chat
	"ulx report <text>" in console


#Admins Cvars:
	"ulx_reports_enabled" <0-1>
	"ulx_reports_in_logs" <0-1>
	"ulx_reports_interval" <time>
	"ulx_reports_folder" <folder>


#Contact:
	First see this topic: --
	You can contact me here: http://forums.ulyssesmod.net/index.php?action=pm;sa=send;u=3539
]]

ulx.setCategory( "Utilities" )

-- Easy Config:
local r_enabled	= "1"			-- Set this to 0 if you want to disable this script
local r_in_logs	= "1"			-- Set this to 0 if you don't want to log reports in daily logs
local r_interval	= "120"			-- The player can only report once then he need to wait this interval (seconds) before reporting again. 0 = no delay (not recommended)
local r_folder	= "ulx_logs"	-- By default, in the same folder as others log files
-- End of config


-- ulx.convar( "reports_enabled",  reports_enabled,  "", ULib.ACCESS_NONE )
-- ulx.convar( "reports_in_logs",  reports_in_logs,  "", ULib.ACCESS_NONE )
-- ulx.convar( "reports_interval", reports_interval, "", ULib.ACCESS_NONE )
-- ulx.convar( "reports_folder",   reports_folder,   "", ULib.ACCESS_NONE )

--[[Hmm, bug with cvar_name? Won't show in the ulx help if there is _ in the name.]]
ulx.convar( "reports_enabled", r_enabled, "<0-1> - Set this to 0 if you want to disable the report command.", ULib.ACCESS_ADMIN )
ulx.convar( "reports_in_logs", r_in_logs, "<0-1> - Set this to 0 if you don't want to log reports in daily logs.", ULib.ACCESS_ADMIN )
ulx.convar( "reports_interval", r_interval, "<time> - Time between 2 reports from the same player. Set this to 0 to disable.", ULib.ACCESS_SUPERADMIN )
ulx.convar( "reports_folder", r_folder, "<folder> - The folder where to save the reports file.", ULib.ACCESS_SUPERADMIN )



ulx.report_file = nil

local function init()

	if ( util.tobool(GetConVarNumber("ulx_reports_enabled")) ) then
		ulx.reports_file = GetConVarString("ulx_reports_folder") .. "/reports.txt"
		if ( !file.Exists(ulx.reports_file) ) then
			file.Write(ulx.reports_file, "")
		end
	end

end
ulx.OnDoneLoading( init )


function ulx.WriteReport( str )

	if ( util.tobool(GetConVarNumber("ulx_reports_in_logs")) ) then
		ulx.logString( str )
	end
	
	if ( ulx.reports_file ) then
		local date = os.date( "*t" )
		str = string.format( "[%02d-%02d-%02d @ %02d:%02d:%02d] %s", date.month, date.day, date.year, date.hour, date.min, date.sec, str )
		file.Write( ulx.reports_file, file.Read( ulx.reports_file ) .. str .. "\n" )
	end

end


function ulx.cc_report( ply, command, argv, args )

	-- is the command disabled ?
	if ( !util.tobool(GetConVarNumber("ulx_reports_enabled")) ) then
		ULib.tsay( ply, "The report command has been disabled by a server admin." )
		return
	end

	local interval = GetConVarNumber("ulx_reports_interval")

	-- reset the interval to it's default value if less than 0
	if ( interval < 0 ) then
		game.ConsoleCommand("ulx_reports_interval "..r_interval.."\n")
		
	-- if interval is greater than 0, check player delay (antispam) 
	elseif ( interval > 0 ) then
		ply.report_delay = ply.report_delay or nil
		if ( ply.report_delay && ply.report_delay > CurTime() - interval ) then			
			local delay	= math.ceil(ply.report_delay + interval - CurTime())
			local minutes =	math.floor(delay/60) % 60 
			local seconds = delay % 60
			
			if (minutes > 1) then message = minutes .. " minutes and " .. seconds .. " seconds"
			elseif (minutes == 1) then message = "1 minute and " .. seconds .. " seconds"
			else message = seconds .. " seconds"
			end
			
			ULib.tsay( ply, "Please wait " .. message .. " before trying to report again!")
			return
		end
		ply.report_delay = CurTime()
	end

	-- check for low args
	if ( #argv < 1 ) then
		ULib.tsay( ply, ulx.LOW_ARGS )
		return
	end

	-- check for length
	if ( string.len( args ) > 128 ) then -- only console will be affected, as max chat length is 128
		ULib.tsay( ply, "The report is limited to 128 characters, please shorten your text." )
		return
	end

	-- ok, write and send the report to admins
	local str = string.format( "Report by %s (%s): %s", ply:Nick(), ply:SteamID(), args )		
	local players = player.GetAll()
	for _, curply in ipairs( players ) do
		if ( curply:IsUserGroup(ULib.ACCESS_ADMIN) && curply != ply ) then
			ULib.tsay( curply, str )
		end
	end	
	ulx.WriteReport( str )
	
	ULib.tsay( ply, "Your report has been sent to admins and written into a file, thanks!" )
	
end
ulx.concommand( "report", ulx.cc_report, "<text> - Report something to admins.", ULib.ACCESS_ALL, "!report", true )
