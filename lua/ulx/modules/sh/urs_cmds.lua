URS = URS or {}

URS.types = {}
URS.types.restrictions = {"tool","vehicle","effect","swep", "npc","ragdoll","prop","sent", "all", "advdupe", "pickup"}
URS.types.limits = {"vehicle","effect", "npc","ragdoll","prop","sent"}
URS.types.limitsMap = {
    vehicle = true,
    effect = true,
    npc = true,
    ragdoll = true,
    prop = true,
    sent = true
}

URS.restrictions = {}
URS.limits = {}

URS.cfg = {}

local rawget = rawget
local stringLower = string.lower

if SERVER then
    URS.cfg.weaponPickups = ulx.convar("urs_weaponpickups", 2)
    URS.cfg.echoSpawns = ulx.convar("urs_echo_spawns", 1)
    URS.cfg.echoCommands = ulx.convar("urs_echo_commands", 1)
    URS.cfg.overwriteSbox = ulx.convar("urs_overwrite_sbox", 1)

    URS.Load()
end

local validRestrictions = {
    tool = true,
    vehicle = true,
    effect = true,
    swep = true,
    npc = true,
    ragdoll = true,
    prop = true,
    sent = true
}

function ulx.restrict( ply, type, what, ... )
    local groupsArg = {...}
    local groups = {}

    for _, groupName in ipairs( groupsArg ) do
        groups[groupName] = true
    end

    local removers = {}
    what = stringLower(what)

    if type == "all" and not rawget( validRestrictions, what ) then
        ULib.tsayError(ply, "Global Restrictions are limited to:\ntool, vehicle, effect, swep, npc, ragdoll, prop, sent")
        return
    end

    local ursRestrictions = rawget( URS, "restrictions" )
    local typeRestrictions = rawget( ursRestrictions, type )
    local theseRestrictions = rawget( typeRestrictions, what )

    if not theseRestrictions then
        URS.restrictions[type][what] = groups
    else
        for groupName in pairs( groups ) do
            if table.HasValue(URS.restrictions[type][what], groupName) then
                tableInsert(removers, groupName)
                ULib.tsayError(ply, groupName .." is already restricted from this rank.")
            else
                URS.restrictions[type][what][groupName] = true
            end
        end
    end

    xgui.sendDataTable({}, "URSRestrictions")
    URS.Save(URS_SAVE_RESTRICTIONS)

    if #removers > 0 then
        for _, groupName in pairs( removers ) do
            groups[groupName] = nil
        end
    end

    if groups[1] then
        ulx.fancyLogAdmin(ply, URS.cfg.echoCommands:GetBool(), "#A restricted #s #s from #s", type, what, table.concat(groups, ", "))
    end
end
local restrict = ulx.command( "URS", "ulx restrict", ulx.restrict, "!restrict" )
restrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=URS.types.restrictions, ULib.cmds.restrictToCompletes }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
restrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
restrict:help( "Add a restriction to a group." )

function ulx.unrestrict( ply, type, what, ... )
    local groups = {...}

    local groupsLookup = {}
    for _, groupName in ipairs( groups ) do
        groupsLookup[groupName] = true
    end

    what = stringLower( what )

    if not URS.restrictions[type][what] then
        ULib.tsayError( ply, what .." is not a restricted ".. type )
        return
    end

    local handled = {}

    -- if given *
    if groupsLookup["*"] then
        -- if we currently track *
        if URS.restrictions[type][what]["*"] then
            -- if removing this will empty the entire table
            if table.Count( URS.restrictions[type][what] ) > 1 then
                URS.restrictions[type][what] = nil
            else
                URS.restrictions[type][what]["*"] = nil
            end
        else
            URS.restrictions[type][what] = nil
        end
    else
        for v in pairs( groupsLookup ) do
            if URS.restrictions[type][what][v] then
                URS.restrictions[type][what][v] = nil
                table.insert( handled, v )
            else
                ULib.tsayError( ply, v .." is not restricted from ".. what )
            end
        end
    end

    URS.Save(URS_SAVE_RESTRICTIONS)
    xgui.sendDataTable( {}, "URSRestrictions" )

    if groups[1] then
        if groups[1] == "*" and not URS.restrictions[type][what] then
            ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A removed all restrictions from #s", what )
        else
            ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A unrestricted #s from #s", what, table.concat(handled,", ") )
        end
    end
end
local unrestrict = ulx.command( "URS", "ulx unrestrict", ulx.unrestrict, "!unrestrict")
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=URS.types.restrictions, ULib.cmds.restrictToCompletes }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
unrestrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
unrestrict:help( "Remove a restrictions from a group." )

function ulx.setlimit( ply, type, group, limit )
    if limit == -1 then URS.limits[type][group] = nil else URS.limits[type][group] = limit end
    xgui.sendDataTable( {}, "URSLimits" )
    URS.Save(URS_SAVE_LIMITS)
    ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A set the #s limit for #s to #i", type, group, limit )
end
local limit = ulx.command( "URS", "ulx setlimit", ulx.setlimit, "!setlimit" )
limit:addParam{ type=ULib.cmds.StringArg, ULib.cmds.restrictToCompletes, completes=URS.types.limits, hint="Type" }
limit:addParam{ type=ULib.cmds.StringArg, hint="Group" }
limit:addParam{ type=ULib.cmds.NumArg, min=-1, default=-1, hint="Amount (-1 is default)" }
limit:defaultAccess( ULib.ACCESS_SUPERADMIN )
limit:help( "Set limits for specific groups." )
