function ulx.report(plr, string)

end
local report = ulx.command( "Utility", "ulx report", ulx.report, "!report")
report:addParam{ type=ULib.cmds.StringArg, hint="infop", ULib.cmds.takeRestOfLine }
report:defaultAccess(ULib.ACCESS_ALL)
report:help( "Report players who are disobeying the rules." )
report:logString( "#1s sent a report")
ulx.addToMenu( ulx.ID_MCLIENT, "Report", "ulx report" )