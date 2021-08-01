AddCSLuaFile( "ulx/modules/sh/urs_cmds.lua" )

URS = URS or {}

HOOK_LOW = HOOK_LOW or 1 -- ensure we don't break on old versions of ULib

function URS.Load()
    URS.restrictions = {}
    URS.limits = {}

    if file.Exists( "ulx/restrictions.txt", "DATA" ) then URS.restrictions = util.JSONToTable( file.Read( "ulx/restrictions.txt", "DATA" ) ) end
    if file.Exists( "ulx/limits.txt", "DATA" ) then URS.limits = util.JSONToTable( file.Read( "ulx/limits.txt", "DATA" ) ) end

    -- Initiallize all tables to prevent errors
    for ursType, types in pairs(URS.types) do
        if not URS[ursType] then
            URS[ursType] = {}
        end

        for _, v in pairs(types) do
            if not URS[ursType][v] then
                URS[ursType][v] = {}
            end
        end
    end
end

URS_SAVE_ALL = 0
URS_SAVE_RESTRICTIONS = 1
URS_SAVE_LIMITS = 2

function URS.Save(n)
    if (n == URS_SAVE_ALL or n == URS_SAVE_RESTRICTIONS) 	and URS.restrictions then file.Write("ulx/restrictions.txt", util.TableToJSON(URS.restrictions)) end
    if (n == URS_SAVE_ALL or n == URS_SAVE_LIMITS) 			and URS.limits then file.Write("ulx/limits.txt", util.TableToJSON(URS.limits)) end

    for _, ply in ipairs( player.GetAll() ) do
        ply.URS_CacheCheck = nil
    end
end

local echoSpawns
local overwriteSbox
local weaponPickups

hook.Add( "Initialize", "URSConfLoad", function()
    echoSpawns = URS.cfg.echoSpawns:GetBool()
    overwriteSbox = URS.cfg.overwriteSbox:GetBool()
    weaponPickups = URS.cfg.weaponPickups:GetInt()
end )

local IsValid = IsValid
local logSpawn = ulx.logSpawn
local tsayError = ULib.tsayError
local stringLower = string.lower
local rawget = rawget
local rawset = rawset

function URS.PrintRestricted(ply, restrictionType, what)
    if restrictionType == "pickup" then return end -- Constant spam

    if echoSpawns then
        logSpawn(ply:Nick() .. "<" .. ply:SteamID() .. "> spawned/used " .. restrictionType .. " " .. what .. " -=RESTRICTED=-" )
    end
    tsayError(ply, "\"" .. what .. "\" is a restricted " .. restrictionType .. " from your rank." )
end
local PrintRestricted = URS.PrintRestricted

-- Return cached value for this check
function URS.CachedCheck(ply, restrictionType, what)
    ply.URS_CacheCheck = ply.URS_CacheCheck or {}

    local existing = ply.URS_CacheCheck
    local restrictionTypes = rawget( existing, restrictionType )

    if not restrictionTypes then return end

    -- true, false, or nil
    return rawget( restrictionTypes, what )
end
local cachedCheck = URS.CachedCheck

-- Caches the given check and returns the given result
function URS.CacheCheck(ply, restrictionType, what, result)
    ply.URS_CacheCheck = ply.URS_CacheCheck or {}

    local existing = ply.URS_CacheCheck
    local restrictionTypes = rawget( existing, restrictionType )

    if not restrictionTypes then
        rawset( existing, restrictionType, {} )
        return result
    end

    rawset( restrictionTypes, what, result )

    return result
end
local cacheCheck = URS.CacheCheck

function URS.Check(ply, restrictionType, what)
    local cachedResult = cachedCheck( ply, restrictionType, what )
    if cachedResult ~= nil then
        PrintRestricted( ply, restrictionType, what )
        return cachedResult
    end

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
                return cacheCheck( ply, restrictionType, what, false )
            end
        elseif hasGroup or hasPlayer then
            PrintRestricted( ply, restrictionType, what )
            return cacheCheck( ply, restrictionType, what, false )
        end
    end

    local allRestrictions = rawget( ursRestrictions, "all" )
    local allTypeRestrictions = allRestrictions and rawget( allRestrictions, restrictionType )
    local hasGroup = allTypeRestrictions and rawget( allTypeRestrictions, group )

    if hasGroup then
        tsayError(ply, "Your rank is restricted from all " .. restrictionTypePlural)
        return cacheCheck( ply, restrictionType, what, false )
    end

    local ursTypes = rawget( URS, "types" )
    local ursTypeLimits = rawget( ursTypes, "limitsMap" )
    local limitsHasType = rawget( ursTypeLimits, restrictionType )
    if not limitsHasType then return end

    local ursLimits = rawget( URS, "limits" )
    local typeLimits = rawget( ursLimits, restrictionType )
    if not typeLimits then return end

    local playerTypeLimit = rawget( typeLimits, ply:SteamID() )
    local groupTypeLimit = rawget( typeLimits, group )
    if not playerTypeLimit and not groupTypeLimit then return end

    -- TODO: Should this be an elseif? Shouldn't both cases be possible?
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
local Check = URS.Check

timer.Simple( 0.1, function()
    --  Wiremod's Advanced Duplicator
    if AdvDupe then
        AdvDupe.AdminSettings.AddEntCheckHook( "URSDupeCheck",
        function( ply, _, EntTable )
            return Check( ply, "advdupe", EntTable.Class )
        end,
        function()
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
end)

local function CheckRestrictedSENT(ply, sent)
    return Check( ply, "sent", sent )
end
hook.Add( "PlayerSpawnSENT", "URSCheckRestrictedSENT", CheckRestrictedSENT, HOOK_LOW )

local function CheckRestrictedProp(ply, mdl)
    return Check( ply, "prop", mdl )
end
hook.Add( "PlayerSpawnProp", "URSCheckRestrictedProp", CheckRestrictedProp, HOOK_LOW )

local ignoredTools = {
    inflator = true,
    paint = true
}

local function CheckRestrictedTool(ply, tr, tool)
    if Check( ply, "tool", tool ) == false then return false end

    if not echoSpawns then return end
    if ignoredTools[tool] then return end

    local ent = rawget( tr, "Entity" )
    if not IsValid( ent ) then return end

    logSpawn( ply:Nick() .. "<" .. ply:SteamID() .. "> used the tool " .. tool .. " on " .. ent:GetModel() )
end
hook.Add( "CanTool", "URSCheckRestrictedTool", CheckRestrictedTool, HOOK_LOW )

local function CheckRestrictedEffect( ply, mdl )
    return Check( ply, "effect", mdl )
end
hook.Add( "PlayerSpawnEffect", "URSCheckRestrictedEffect", CheckRestrictedEffect, HOOK_LOW )

local function CheckRestrictedNPC( ply, npc )
    return Check( ply, "npc", npc )
end
hook.Add( "PlayerSpawnNPC", "URSCheckRestrictedNPC", CheckRestrictedNPC, HOOK_LOW )

local function CheckRestrictedRagdoll( ply, mdl )
    return Check( ply, "ragdoll", mdl )
end
hook.Add( "PlayerSpawnRagdoll", "URSCheckRestrictedRagdoll", CheckRestrictedRagdoll, HOOK_LOW )

local function CheckRestrictedSWEP( ply, class )
    if Check( ply, "swep", class ) == false then
        return false
    end

    if not echoSpawns then return end

    logSpawn( ply:Nick() .. "<" .. ply:SteamID() .. "> spawned/gave himself swep " .. class )
end
hook.Add( "PlayerSpawnSWEP", "URSCheckRestrictedSWEP", CheckRestrictedSWEP, HOOK_LOW )
hook.Add( "PlayerGiveSWEP", "URSCheckRestrictedSWEP2", CheckRestrictedSWEP, HOOK_LOW )

local function CheckRestrictedPickUp( ply, weapon )
    if weaponPickups == 2 and Check( ply, "pickup", weapon:GetClass(), true ) == false then
        return false
    end

    if weaponPickups == 1 and Check( ply, "swep", weapon:GetClass() ) == false then
        return false
    end
end
hook.Add( "PlayerCanPickupWeapon", "URSCheckRestrictedPickUp", CheckRestrictedPickUp, HOOK_LOW )

local function CheckRestrictedVehicle( ply, mdl, name )
    return Check( ply, "vehicle", mdl ) and Check( ply, "vehicle", name )
end
hook.Add( "PlayerSpawnVehicle", "URSCheckRestrictedVehicle", CheckRestrictedVehicle, HOOK_LOW )
