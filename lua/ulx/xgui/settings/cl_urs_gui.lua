xgui.prepareDataType( "URSRestrictions" )
xgui.prepareDataType( "URSLimits" )
xgui.prepareDataType( "URSLoadouts" )

urs = {}
urs.removers = {}
urs.weapons2 = {"weapon_para", "weapon_crowbar", "weapon_stunstick", "weapon_physcannon", "weapon_physgun", "weapon_pistol", "weapon_357", "weapon_smg1", "weapon_ar2", "weapon_shotgun", "weapon_crossbow",  "weapon_frag", "weapon_rpg", "weapon_slam", "weapon_bugbait", "item_ml_grenade", "item_ar2_grenade", "item_ammo_ar2_altfire", "gmod_camera", "gmod_tool"}
urs.weapons = weapons.GetList()
urs.arg1save = nil

urs.back = xlib.makepanel{ parent = xgui.null }
urs.restrictionlist = xlib.makelistview{ parent = urs.back, x = 5, y = 5, w = 150, h = 71 }
urs.typelist = xlib.makelistview{ parent = urs.back, x = 5, y = 81, w = 150, h = 220 }
urs.itemlist = xlib.makelistview{ parent = urs.back, x = 160, y = 5, w = 425, h = 295, multiselect = true }
urs.addbutton = xlib.makebutton{ parent = urs.back, x = 485, y = 306, w = 100, h = 25, label = "Add", disabled = true }
urs.removebutton = xlib.makebutton{ parent = urs.back, x = 5, y = 306, w = 150, h = 25, label = "Remove Selected Items", disabled = true }
urs.arg1 = xlib.makecombobox{ parent = urs.back, x = 160, y = 306, w = 155, h = 25, disabled = true}
urs.arg2 = xlib.makecombobox{ parent = urs.back, x = 320, y = 306, w = 160, h = 25, disabled = true}
urs.arg3 = xlib.maketextbox{ parent = urs.back, x = 320, y = 306, w = 160, h = 25, disabled = true, visible = false}
urs.arg2Old = urs.arg2

urs.restrictionlist:AddColumn( "Type of Restriction" )
urs.restrictionlist:AddLine( "Restrictions" )
urs.restrictionlist:AddLine( "Limits" )
urs.restrictionlist:AddLine( "Loadouts" )
urs.typelist:AddColumn( " " )
urs.itemlist:AddColumn( " " )
urs.itemlist:AddColumn( " " )

--------------------------------------------------------------------------------------------------------------------------------------------

urs.restrictionlist.OnRowSelected = function( self, lineid, line )
    urs.arg1:Clear()
    urs.arg2:Clear()
    urs.arg1save = nil
    if line:GetValue( 1 ) == "Loadouts" then
        urs.arg2 = urs.arg2Old
        urs.arg2:SetVisible( true )
        urs.arg3:SetVisible( false )
        urs.addbutton:SetDisabled( false )
        urs.arg1:SetDisabled( false )
        urs.arg2:SetDisabled( false )
        urs.arg1:SetText( "Group" )
        urs.arg2:SetText( "Weapon( s )" )
        for weapon, weapons in pairs( urs.weapons ) do
            urs.arg2:AddChoice( weapons.ClassName )
        end
        for weapon, weapons in pairs( urs.weapons2 ) do
            urs.arg2:AddChoice( weapons )
        end
        for group, groups in pairs( xgui.data.groups ) do
            urs.arg1:AddChoice( groups )
        end
    else
        urs.arg2:SetVisible( false )
        urs.arg3:SetVisible( true )
        urs.arg2 = urs.arg3
        urs.addbutton:SetDisabled( true )
        urs.arg1:SetDisabled( true )
        urs.arg2:SetDisabled( true )
        urs.removebutton:SetDisabled( true )
        if line:GetValue( 1 ) == "Restrictions" then
            urs.arg1:SetText( "Group( s )" )
            urs.arg2:SetText( "Target" )
            -- urs.arg2:AddChoice( " * " )
            for group, groups in pairs( xgui.data.groups ) do
                urs.arg1:AddChoice( groups )
            end
        elseif line:GetValue( 1 ) == "Limits" then
            urs.arg1:SetText( "Group" )
            urs.arg2:SetText( "Limit" )
            for group, groups in pairs( xgui.data.groups ) do
                urs.arg1:AddChoice( groups )
            end
        end
    end
    urs.itemlist:Clear()
    urs.typelist:Clear()
    if line:GetValue( 1 ) == "Restrictions" then
        urs.typelist.Columns[1]:SetName( "Type" )
        urs.itemlist.Columns[1]:SetName( "Target" )
        urs.itemlist.Columns[2]:SetName( "Group" )
        for type, types in pairs( xgui.data.URSRestrictions ) do
            urs.typelist:AddLine( type )
        end
    elseif line:GetValue( 1 ) == "Limits" then
        urs.typelist.Columns[1]:SetName( " " )
        urs.itemlist.Columns[1]:SetName( "Group" )
        urs.itemlist.Columns[2]:SetName( "Limit" )
        for type, types in pairs( xgui.data.URSLimits ) do
            urs.typelist:AddLine( type )
        end
    elseif line:GetValue( 1 ) == "Loadouts" then
        urs.typelist.Columns[1]:SetName( "Group" )
        urs.itemlist.Columns[1]:SetName( "Weapon" )
        urs.itemlist.Columns[2]:SetName( " " )
        for group, groups in pairs( xgui.data.URSLoadouts ) do
            urs.typelist:AddLine( group )
        end
    end
end

urs.typelist.OnRowSelected = function( panel, lineid, line )
    urs.addbutton:SetDisabled( false )
    urs.arg1:SetDisabled( false )
    urs.arg2:SetDisabled( false )
    urs.removebutton:SetDisabled( true )
    urs.itemlist:Clear()
    urs.arg1save = nil
    if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" then
        for type, types in pairs( xgui.data.URSRestrictions ) do
            if type == line:GetValue( 1 ) then
                for target, targets in pairs( types ) do
                    for group, groups in pairs( targets ) do
                        urs.itemlist:AddLine( target, groups )
                    end
                end
            end
        end
    elseif urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Limits" then
        for type, types in pairs( xgui.data.URSLimits ) do
            if type == line:GetValue( 1 ) then
                for group, groups in pairs( types ) do
                    urs.itemlist:AddLine( group, groups )
                end
            end
        end
    elseif urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Loadouts" then
        for group, groups in pairs( xgui.data.URSLoadouts ) do
            if group == line:GetValue( 1 ) then
                urs.arg1:SetText( line:GetValue( 1 ) )
                for weapon, weapons in pairs( xgui.data.URSLoadouts[group] ) do
                    urs.itemlist:AddLine( weapons )
                end
            end
        end
    end
end

urs.itemlist.OnRowSelected = function( self, lineid, line )
    urs.removebutton:SetDisabled( false )
    urs.addbutton:SetDisabled( false )
    urs.arg1:SetDisabled( false )
    urs.arg2:SetDisabled( false )
    if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" or urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Limits" then
        urs.arg2:SetText( line:GetValue( 1 ) )
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------

urs.removebutton.DoClick = function()
    if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" then
        for item, items in pairs( urs.itemlist:GetSelected() ) do
            if not urs.removers[items:GetValue( 1 )] then urs.removers[items:GetValue( 1 )] = { } end
            table.insert( urs.removers[items:GetValue( 1 )], items:GetValue( 2 ) )
        end
        for target, targets in pairs( urs.removers ) do
            LocalPlayer():ConCommand( "ulx unrestrict \"".. urs.typelist:GetSelected()[1]:GetValue( 1 ) .."\" \"".. target .."\" ".. table.concat( urs.removers[target], " " ) )
        end
    elseif urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Limits" then
        for item, items in pairs( urs.itemlist:GetSelected() ) do
            table.insert( urs.removers, urs.itemlist:GetSelected()[item]:GetValue( 2 ) )
        end
        for group, groups in pairs( urs.removers ) do
            RunConsoleCommand( "ulx", "setlimit", urs.typelist:GetSelected()[1]:GetValue( 1 ), urs.itemlist:GetSelected()[group]:GetValue( 1 ), "-1" )
        end
    elseif urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Loadouts" then
        if urs.typelist:GetSelected()[1] then
            for weapon, weapons in pairs( urs.itemlist:GetSelected() ) do
                table.insert( urs.removers, weapons:GetValue( 1 ) )
            end
            LocalPlayer():ConCommand( "ulx loadoutremove \"".. urs.typelist:GetSelected()[1]:GetValue( 1 ) .."\" ".. table.concat( urs.removers, " " ) )
        end
    end
    urs.removebutton:SetDisabled( true )
    urs.removers = {}
end

urs.addbutton.DoClick = function()
    if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" or urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Limits" then
        local cmd
        if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" then cmd = "restrict" else cmd = "setlimit" end

        if urs.arg1:GetValue() and urs.arg2:GetValue() then
            LocalPlayer():ConCommand( "ulx ".. cmd .." \"".. urs.typelist:GetSelected()[1]:GetValue( 1 ) .."\" \"".. ( cmd == "restrict" and urs.arg2:GetValue() or urs.arg1:GetValue() ) .."\" ".. ( cmd == "restrict" and urs.arg1:GetValue() or urs.arg2:GetValue() ) )
        else
            LocalPlayer():ChatPrint( "Missing Argument( s ) ~ Please fill in all text boxes." )
        end
    else
        if urs.arg1:GetValue() and urs.arg2:GetValue() then
            LocalPlayer():ConCommand( "ulx loadoutadd \"".. urs.arg1:GetValue() .."\" ".. urs.arg2:GetValue() )
        else
            LocalPlayer():ChatPrint( "Missing Argument( s ) ~ Please fill in all text boxes." )
        end
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------
function URSRestrictionProcess( t )
    urs.itemlist:Clear()
    if urs.restrictionlist:GetSelectedLine() then
        if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Restrictions" then
            if urs.typelist:GetSelectedLine() then
                for item, items in pairs( xgui.data.URSRestrictions[ urs.typelist:GetSelected()[1]:GetValue( 1 ) ] ) do
                    for group, groups in pairs( items ) do
                        urs.itemlist:AddLine( item, groups )
                    end
                end
            end
        end
    end
end
xgui.hookEvent( "URSRestrictions", "process", URSRestrictionProcess )

function URSLimitsProcess( t )
    urs.itemlist:Clear()
    if urs.restrictionlist:GetSelectedLine() then
        if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Limits" then
            if urs.typelist:GetSelectedLine() then
                for group, groups in pairs( xgui.data.URSLimits[ urs.typelist:GetSelected()[1]:GetValue( 1 ) ] ) do
                    urs.itemlist:AddLine( group, groups )
                end
            end
        end
    end
end
xgui.hookEvent( "URSLimits", "process", URSLimitsProcess )

function URSLoadoutsProcess( t )
    urs.itemlist:Clear()
    if urs.restrictionlist:GetSelectedLine() then
        if urs.restrictionlist:GetSelected()[1]:GetValue( 1 ) == "Loadouts" then
            local selected
            if urs.typelist:GetSelectedLine() then
                selected = urs.typelist:GetSelected()[1]:GetValue( 1 )
                if xgui.data.URSLoadouts[ selected ] then
                    for weapon, weapons in pairs( xgui.data.URSLoadouts[ selected ] ) do
                        urs.itemlist:AddLine( weapons )
                    end
                end
            end
            urs.typelist:Clear()
            for group, groups in pairs( xgui.data.URSLoadouts ) do
                urs.typelist:AddLine( group )
            end
            if selected then
                if urs.typelist["Lines"] then
                    for line, lines in pairs( urs.typelist["Lines"] ) do
                        if lines:GetValue( 1 ) == selected then lines:SetSelected( true ) end
                    end
                end
            end
        end
    end
end
xgui.hookEvent( "URSLoadouts", "process", URSLoadoutsProcess )

xgui.addSettingModule( "URS", urs.back, "icon16/shield.png" )

