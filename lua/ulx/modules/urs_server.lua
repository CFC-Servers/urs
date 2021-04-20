AddCSLuaFile( "ulx/modules/sh/urs_cmds.lua" )

URS = URS or {}

HOOK_LOW = HOOK_LOW or 1 -- ensure we don't break on old versions of ULib

function URS.Load()
    URS.restricions = {}
    URS.limits = {}
    URS.loadouts = {}

    if file.Exists( "ulx/restrictions.txt", "DATA" ) then URS.restrictions = util.JSONToTable( file.Read( "ulx/restrictions.txt", "DATA" ) ) end
    if file.Exists( "ulx/limits.txt", "DATA" ) then URS.limits = util.JSONToTable( file.Read( "ulx/limits.txt", "DATA" ) ) end
    if file.Exists( "ulx/loadouts.txt", "DATA" ) then URS.loadouts = util.JSONToTable( file.Read( "ulx/loadouts.txt", "DATA" ) ) end

    -- Initiallize all tables to prevent errors
    for ursType, types in pairs(URS.types) do
        if not URS[ursType] then
            URS[ursType] = {}
        end

        for k, v in pairs(types) do
            if not URS[ursType][v] then
                URS[ursType][v] = {}
            end
        end
    end
end

URS_SAVE_ALL = 0
URS_SAVE_RESTRICIONS = 1
URS_SAVE_LIMITS = 2
URS_SAVE_LOADOUTS = 3

function URS.Save(n)
    if (n == URS_SAVE_ALL or n == URS_SAVE_RESTRICTIONS) 	and URS.restrictions then file.Write("ulx/restrictions.txt", util.TableToJSON(URS.restrictions)) end
    if (n == URS_SAVE_ALL or n == URS_SAVE_LIMITS) 			and URS.limits then file.Write("ulx/limits.txt", util.TableToJSON(URS.limits)) end
    if (n == URS_SAVE_ALL or n == URS_SAVE_LOADOUTS) 		and URS.loadouts then file.Write("ulx/loadouts.txt", util.TableToJSON(URS.loadouts)) end
end

local echoSpawns = URS.cfg.echoSpawns:GetBool()
local overwriteSbox = URS.cfg.overwriteSbox:GetBool()
local weaponPickups = URS.cfg.weaponPickups:GetInt()
local logSpawn = ulx.logSpawn

local stringLower = string.lower

local rawget = rawget

function URS.PrintRestricted(ply, restrictionType, what)
    if restrictionType == "pickup" then return end -- Constant spam

    if echoSpawns then
        logSpawn(ply:Nick() .."<".. ply:SteamID() .."> spawned/used ".. restrictionType .." ".. what .." -=RESTRICTED=-")
    end
    ULib.tsayError(ply, "\"".. what .."\" is a restricted ".. restrictionType .." from your rank.")
end
local PrintRestricted = URS.PrintRestricted

function URS.Check(ply, restrictionType, what)
    what = stringLower(what)
    local restrictionTypePlural = restrictionType .. "s"
    local group = ply:GetUserGroup()

    local restriction = false

    local ursRestrictions = rawget( URS, "restrictions" )
    local typeRestrictions = ursRestrictions and rawget( ursRestrictions, restrictionType )
    local theseRestrictions = typeRestrictions and rawget( typeRestrictions, what )

    if theseRestrictions then
        restriction = theseRestrictions
    end

    if restriction then
        local hasGroup = rawget( restriction, group )
        local hasPlayer = rawget( restriction, ply:SteamID() )

        if rawget( restriction, "*" ) then
            if not ( hasGroup or hasPlayer ) then
                PrintRestricted( ply, restrictionType, what )
                return false
            end
        elseif hasGroup or hasPlayer then
            PrintRestricted( ply, restrictionType, what )
            return false
        end
    end

    local allRestrictions = rawget( ursRestrictions, "all" )
    local allTypeRestrictions = allRestrictions and rawget( allRestrictions, restrictionType )
    local hasGroup = allTypeRestrictions and rawget( allTypeRestrictions, group )

    local ursTypes = rawget( URS, "types" )
    local ursTypeLimits = rawget( ursTypes, "limits" )
    local limitsHasType = rawget( ursTypeLimits, restrictionType )

    local ursLimits = rawget( URS, "limits" )
    local typeLimits = rawget( ursLimits, restrictionType )
    local playerTypeLimit = typeLimits and rawget( typeLimits, ply:SteamID() )
    local groupTypeLimit = typeLimits and rawget( tyleLimits, group )

    if hasGroup then
        ULib.tsayError(ply, "Your rank is restricted from all ".. restrictionTypePlural)
        return false

    elseif limitsHasType and typeLimits and ( playerTypeLimit or groupTypeLimit ) then
        if playerTypeLimit then
            if ply:GetCount(restrictionTypePlural) >= playerTypeLimit then
                ply:LimitHit( restrictionTypePlural )
                return false
            end
        elseif groupTypeLimit then
            if ply:GetCount(restrictionTypePlural) >= groupTypeLimit then
                ply:LimitHit( restrictionTypePlural )
                return false
            end
        end
        if overwriteSbox then
            return true -- Overwrite sbox limit (ours is greater)
        end
    end
end
local Check = URS.Check

timer.Simple(0.1, function()

    --  Wiremod's Advanced Duplicator
    if AdvDupe then
        AdvDupe.AdminSettings.AddEntCheckHook( "URSDupeCheck",
        function(ply, Ent, EntTable)
            return Check( ply, "advdupe", EntTable.Class )
        end,
        function(Hook)
            ULib.tsayColor( nil, false, Color( 255, 0, 0 ), "URSDupeCheck has failed.  Please contact Aaron113 @\nhttp://forums.ulyssesmod.net/index.php/topic,5269.0.html" )
        end )
    end

    -- Advanced Duplicator 2 (http://facepunch.com/showthread.php?t=1136597)
    if AdvDupe2 then
        hook.Add("PlayerSpawnEntity", "URSCheckRestrictedEntity", function(ply, EntTable)
            if Check(ply, "advdupe", EntTable.Class) == false or Check(ply, "advdupe", EntTable.Model) == false then
                return false
            end
        end)
    end

end )

function URS.CheckRestrictedSENT(ply, sent)
    return Check( ply, "sent", sent )
end
hook.Add( "PlayerSpawnSENT", "URSCheckRestrictedSENT", URS.CheckRestrictedSENT, HOOK_LOW )

function URS.CheckRestrictedProp(ply, mdl)
    return Check( ply, "prop", mdl )
end
hook.Add( "PlayerSpawnProp", "URSCheckRestrictedProp", URS.CheckRestrictedProp, HOOK_LOW )

function URS.CheckRestrictedTool(ply, tr, tool)
    if Check( ply, "tool", tool ) == false then return false end
    if echoSpawns and tool ~= "inflator" then
        logSpawn( ply:Nick().."<".. ply:SteamID() .."> used the tool ".. tool .." on ".. tr.Entity:GetModel() )
    end
end
hook.Add( "CanTool", "URSCheckRestrictedTool", URS.CheckRestrictedTool, HOOK_LOW )

function URS.CheckRestrictedEffect(ply, mdl)
    return Check( ply, "effect", mdl )
end
hook.Add( "PlayerSpawnEffect", "URSCheckRestrictedEffect", URS.CheckRestrictedEffect, HOOK_LOW )

function URS.CheckRestrictedNPC(ply, npc, weapon)
    return Check( ply, "npc", npc )
end
hook.Add( "PlayerSpawnNPC", "URSCheckRestrictedNPC", URS.CheckRestrictedNPC, HOOK_LOW )

function URS.CheckRestrictedRagdoll(ply, mdl)
    return Check( ply, "ragdoll", mdl )
end
hook.Add( "PlayerSpawnRagdoll", "URSCheckRestrictedRagdoll", URS.CheckRestrictedRagdoll, HOOK_LOW )

function URS.CheckRestrictedSWEP(ply, class, weapon)
    if Check( ply, "swep", class ) == false then
        return false
    elseif echoSpawns then
        logSpawn( ply:Nick().."<".. ply:SteamID() .."> spawned/gave himself swep ".. class )
    end
end
hook.Add( "PlayerSpawnSWEP", "URSCheckRestrictedSWEP", URS.CheckRestrictedSWEP, HOOK_LOW )
hook.Add( "PlayerGiveSWEP", "URSCheckRestrictedSWEP2", URS.CheckRestrictedSWEP, HOOK_LOW )

function URS.CheckRestrictedPickUp(ply, weapon)
    if weaponPickups == 2 then
        if Check( ply, "pickup", weapon:GetClass(), true) == false then
            return false
        end
    elseif weaponPickups == 1 then
        if Check( ply, "swep", weapon:GetClass()) == false then
            return false
        end
    end
end
hook.Add( "PlayerCanPickupWeapon", "URSCheckRestrictedPickUp", URS.CheckRestrictedPickUp, HOOK_LOW )

function URS.CheckRestrictedVehicle(ply, mdl, name, vehicle_table)
    return Check( ply, "vehicle", mdl ) and Check( ply, "vehicle", name )
end
hook.Add( "PlayerSpawnVehicle", "URSCheckRestrictedVehicle", URS.CheckRestrictedVehicle, HOOK_LOW )

function URS.CustomLoadouts(ply)
    if URS.loadouts[ply:SteamID()] then
        ply:StripWeapons()
        for k, v in pairs( URS.loadouts[ply:SteamID()] ) do
            ply:Give( v )
        end
        return true
    elseif URS.loadouts[ply:GetUserGroup()] then
        ply:StripWeapons()
        for k, v in pairs( URS.loadouts[ply:GetUserGroup()] ) do
            ply:Give( v )
        end
        return true
    end
end
hook.Add( "PlayerLoadout", "URSCustomLoadouts", URS.CustomLoadouts, HOOK_LOW )
