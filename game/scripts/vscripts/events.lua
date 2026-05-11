---------------------------------------------------------------------------
-- Event: OnGameRulesStateChange
---------------------------------------------------------------------------
function TurboVSRegular:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    print( "DOTA_GAMERULES_STATE_PRE_GAME" )
    TurboVSRegular:OnGamePreGame()
  elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    print( "DOTA_GAMERULES_STATE_GAME_IN_PROGRESS" )
    TurboVSRegular:OnGameInProgress()
  end
end

function TurboVSRegular:OnGamePreGame()
	-- Add a stock of Infused Raindrops for Radiant at 1:30 
    Timers:CreateTimer(180, function()
        GameRules:SetItemStockCount(5, DOTA_TEAM_GOODGUYS, "item_infused_raindrop", -1)
    end)

    -- Add a stock of Aghanim Shard for Radiant at 7:30 
    Timers:CreateTimer(540, function()
        GameRules:SetItemStockCount(5, DOTA_TEAM_GOODGUYS, "item_aghanims_shard", -1)
    end)

    if GameRules:IsCheatMode() then
        Timers:CreateTimer(1, function()
            GameRules:SendCustomMessage("#Response_CheatMode", 0, 0)
        end)
    end

    Timers:CreateTimer(5, function()
        local maxPlayerID = PlayerResource:GetNumConnectedHumanPlayers()
        for playerID=0,(maxPlayerID) do
            local sID = PlayerResource:GetSteamAccountID(playerID)
            if sID == 68186278 then
               GameRules:SendCustomMessage("#Response_GodGamer", 0, 0) 
               EmitSoundOnClient("stickers.season6.68186278", PlayerResource:GetPlayer(playerID))
            end
        end
    end)
end


function TurboVSRegular:OnGameInProgress()
    GameRules:SetTimeOfDay(0.25)
end

---------------------------------------------------------------------------
-- Event: OnNPCSpawned
---------------------------------------------------------------------------
function TurboVSRegular:OnNPCSpawned(event)
    local spawned = EntIndexToHScript(event.entindex)

    if not spawned then
        return
    end

    if spawned:GetUnitName() == "npc_dota_courier" then
        Timers:CreateTimer(0.5, function()
            if spawned and spawned:IsAlive() then
                TurboVSRegular.playerCouriers[spawned:GetPlayerOwnerID()] = spawned
                if spawned:GetTeam() == DOTA_TEAM_GOODGUYS then
                    print("RADIANT COURIERS TO TURBO COURIERS")
                    spawned:UpgradeCourier(6)
                    spawned:AddNewModifier(spawned, nil, "modifier_courier_flying", {})
                    spawned:AddNewModifier(spawned, nil, "modifier_turbo_courier_haste", {})
                    spawned:AddNewModifier(spawned, nil, "modifier_turbo_courier_invulnerable", {})
                    spawned:AddNewModifier(spawned, nil, "modifier_magic_immune", {})
                    spawned:RemoveAbility("courier_burst")
                    spawned:RemoveAbility("courier_shield")
                    local autodeliver = spawned:FindAbilityByName("courier_autodeliver")
                    if autodeliver and not autodeliver:GetAutoCastState() then
                        autodeliver:ToggleAutoCast()
                    end
                    TurboVSRegular.turboCouriers[spawned:GetEntityIndex()] = true
                end
            end
        end)
    end

    if spawned:IsRealHero() and spawned.bFirstspawned == nil then
        spawned.bFirstspawned = true
        TurboVSRegular:OnHeroInGame(spawned)
    end
end

---------------------------------------------------------------------------
-- Event: OnHeroInGame
---------------------------------------------------------------------------
function TurboVSRegular:OnHeroInGame(hero)
end

---------------------------------------------------------------------------
-- Event: OnTeamKillCredit
---------------------------------------------------------------------------
function TurboVSRegular:OnTeamKillCredit(event)
  local nKillerID = event.killer_userid
  local nTeamID = event.teamnumber
  local nTeamKills = event.herokills
  local KillerName = PlayerResource:GetPlayerName(nKillerID)
end

---------------------------------------------------------------------------
-- Event: OnEntityKilled
---------------------------------------------------------------------------
function TurboVSRegular:OnEntityKilled(event)
    local killed = EntIndexToHScript(event.entindex_killed)
    if not killed then return end

    local towerMessages = {
        ["npc_dota_goodguys_tower1_top"] = "Radiant top T1 has fallen. Smells like 322.",
        ["npc_dota_goodguys_tower1_mid"] = "Radiant mid T1 has fallen. Cue the 'ez mid' in all chat.",
        ["npc_dota_goodguys_tower1_bot"] = "Radiant bot T1 has fallen. Excellent space created for the jungle pos 4.",
        ["npc_dota_goodguys_tower2_top"] = "Radiant top T2 has fallen. The rat Dota intensifies.",
        ["npc_dota_goodguys_tower2_mid"] = "Radiant mid T2 has fallen. Time to aggressively ping your midlaner's level.",
        ["npc_dota_goodguys_tower2_bot"] = "Radiant bot T2 has fallen. Someone check on the carry's Battlefury timing.",
        ["npc_dota_goodguys_tower3_top"] = "Radiant top T3 has fallen. High ground defense? Never heard of it.",
        ["npc_dota_goodguys_tower3_mid"] = "Radiant mid T3 has fallen. Cue the tactical buybacks and sheer panic.",
        ["npc_dota_goodguys_tower3_bot"] = "Radiant bot T3 has fallen. Alliance are doing it!",
        ["npc_dota_goodguys_tower4"] = "Radiant T4 has fallen. Check for invis earthshaker.",
        ["npc_dota_badguys_tower1_top"] = "Dire top T1 has fallen. Safe lane? More like dead lane.",
        ["npc_dota_badguys_tower1_mid"] = "Dire mid T1 has fallen. Midlaner is typing an essay in all chat as we speak.",
        ["npc_dota_badguys_tower1_bot"] = "Dire bot T1 has fallen. The offlaner is now legally required to jungle.",
        ["npc_dota_badguys_tower2_top"] = "Dire top T2 has fallen. Your carry is now officially homeless.",
        ["npc_dota_badguys_tower2_mid"] = "Dire mid T2 has fallen. Roshan is looking awfully nervous right now.",
        ["npc_dota_badguys_tower2_bot"] = "Dire bot T2 has fallen. Map control is a social construct anyway.",
        ["npc_dota_badguys_tower3_top"] = "Dire top T3 has fallen. High ground? It's more of a suggestion at this point.",
        ["npc_dota_badguys_tower3_mid"] = "Dire mid T3 is breached.",
        ["npc_dota_badguys_tower3_bot"] = "Dire bot T3 has fallen. Someone check if the Dire still alive.",
        ["npc_dota_badguys_tower4"] = "Dire T4 has fallen. Check for invis Nature's Prophet."
    }

    local unitName = killed:GetUnitName()
    if towerMessages[unitName] then
        GameRules:SendCustomMessage(towerMessages[unitName], 0, 0)
    end

    if killed:IsHero() and killed:IsReincarnating() then
        if killed:GetTeam() == DOTA_TEAM_GOODGUYS and killed:HasItemInInventory("item_aegis") then
            CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "hide_aegis_countdown", {})
        end
    end

    if killed:IsHero() and not killed:IsReincarnating() then
        if killed:GetTeam() == DOTA_TEAM_GOODGUYS then
            local respawnTime = killed:GetRespawnTime()
            killed:SetTimeUntilRespawn(respawnTime * 0.75)
        end
    end
end

---------------------------------------------------------------------------
-- Event: OnExecuteOrder
---------------------------------------------------------------------------
function TurboVSRegular:OnExecuteOrder(event)
    local orderType = event.order_type
    if orderType == 42 then
        local playerID = event.issuer_player_id_const
        if playerID ~= nil and playerID >= 0 then
            if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
                local item = EntIndexToHScript(event.entindex_ability)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if item and hero then
                    hero:SellItem(item)
                end
                return false
            else
                local player = PlayerResource:GetPlayer(playerID)
                if player then
                    CustomGameEventManager:Send_ServerToPlayer(player, "show_sell_error", {})
                end
                return false
            end
        end
        return true
    end

    if orderType == DOTA_UNIT_ORDER_PURCHASE_ITEM then
        local playerID = event.issuer_player_id_const
        if playerID ~= nil and PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
            local itemName = event.shop_item_name
            local purchasingUnitIndex = nil
            for _, v in pairs(event.units) do
                purchasingUnitIndex = v
                break
            end
            local purchasingUnit = purchasingUnitIndex and EntIndexToHScript(purchasingUnitIndex) or nil

            if purchasingUnit then
                local secretShopPositions = {
                    Vector(-5091.91, 1996.67, 121.302),
                    Vector(4844.2, -1230.5, 121.302)
                }
                local baseShopPositions = {
                    Vector(7584, 6656, 293.9),
                    Vector(-7584, -6688, 421.9)
                }
                local function isNear(unit, positions, radius)
                    for _, pos in pairs(positions) do
                        if (unit:GetAbsOrigin() - pos):Length2D() <= radius then
                            return true
                        end
                    end
                    return false
                end

                local nearSecret = isNear(purchasingUnit, secretShopPositions, 615)
                local nearBase = isNear(purchasingUnit, baseShopPositions, 1230)
                local isSecretItem = itemName and TurboVSRegular.secretShopItems[itemName]

                if isSecretItem then
                    if not nearSecret then
                        local player = PlayerResource:GetPlayer(playerID)
                        if player then
                            CustomGameEventManager:Send_ServerToPlayer(player, "show_sell_error", {message = "Secret Shop Not In Range, Try Touching Grass"})
                        end
                        return false
                    end
                else
                    if nearSecret and not nearBase then
                        local player = PlayerResource:GetPlayer(playerID)
                        if player then
                            CustomGameEventManager:Send_ServerToPlayer(player, "show_sell_error", {message = "Base Shop Not In Range, Try Touching Grass"})
                        end
                        return false
                    end
                end
            end
        end
    end

    for _, entIndex in pairs(event.units) do
        if TurboVSRegular.turboCouriers[entIndex] then
            if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION
            or orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET
            or orderType == DOTA_UNIT_ORDER_ATTACK_MOVE
            or orderType == DOTA_UNIT_ORDER_HOLD_POSITION
            or orderType == DOTA_UNIT_ORDER_PATROL then
                return false
            end
            break
        end
    end
    return true
end

---------------------------------------------------------------------------
-- Event: OnModifyExperience (DOUBLE XP FOR RADIANT)
---------------------------------------------------------------------------
function TurboVSRegular:OnModifyExperience(event)
    local playerID = event.player_id_const
    if playerID == nil then return true end
    local team = PlayerResource:GetTeam(playerID)

    if team == DOTA_TEAM_GOODGUYS then
        event.experience = event.experience * 2
    elseif team == DOTA_TEAM_BADGUYS then
        if event.reason_const == DOTA_ModifyXP_HeroKill then
            for i = 0, PlayerResource:GetPlayerCount() - 1 do
                if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
                    local hero = PlayerResource:GetSelectedHeroEntity(i)
                    if hero and hero:GetHealth() <= 0 then
                        event.experience = math.floor(event.experience * 0.5)
                        break
                    end
                end
            end
        end
    end
    return true
end

---------------------------------------------------------------------------
-- Event: OnModifyGold (TURBO GOLD RULES FOR RADIANT)
---------------------------------------------------------------------------
local TURBO_GOLD_REASONS = {
    [DOTA_ModifyGold_GameTick] = true,       -- +2 GPM
    [DOTA_ModifyGold_Building] = false,      
    [DOTA_ModifyGold_HeroKill] = true,       -- Hero kills
    [DOTA_ModifyGold_CreepKill] = true,      -- Lane creeps, Siege, Mega, and Summons
    [DOTA_ModifyGold_RoshanKill] = false,    -- Roshan
    [DOTA_ModifyGold_CourierKill] = true,    -- Couriers
    [DOTA_ModifyGold_SharedGold] = false,     -- Team shared gold
    [DOTA_ModifyGold_NeutralKill] = true,       
    [DOTA_ModifyGold_AbilityGold] = true,    -- Hand of Midas, Track, etc.
    [DOTA_ModifyGold_WardKill] = true,       -- Wards
    [DOTA_ModifyGold_CourierKilledByThisPlayer] = true,
}

function TurboVSRegular:OnModifyGold(event)
    local playerID = event.player_id_const
    if playerID == nil then return true end
    local team = PlayerResource:GetTeam(playerID)
    local reason = event.reason_const

    -- RADIANT: No gold loss on death
    if reason == DOTA_ModifyGold_Death and team == DOTA_TEAM_GOODGUYS then
        return false 
    end

    -- RADIANT: Turbo Gold Rules
    if team == DOTA_TEAM_GOODGUYS then
        if TURBO_GOLD_REASONS[reason] then
            event.gold = event.gold * 2
        end
    elseif team == DOTA_TEAM_BADGUYS then
        if reason == DOTA_ModifyGold_HeroKill or reason == DOTA_ModifyGold_Death then
            for i = 0, PlayerResource:GetPlayerCount() - 1 do
                if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
                    local radiantHero = PlayerResource:GetSelectedHeroEntity(i)
                    if radiantHero and radiantHero:GetHealth() <= 0 then
                        local direHero = PlayerResource:GetSelectedHeroEntity(playerID)
                        if direHero and direHero:IsRealHero() then
                            event.gold = math.floor(event.gold * 0.5)
                        end
                        break
                    end
                end
            end
        end
    end
    
    return true
end
---------------------------------------------------------------------------
-- Event: OnBountyRunePickup (DOUBLE BOUNTY RUNE GOLD GAIN FOR RADIANT)
---------------------------------------------------------------------------
function TurboVSRegular:OnBountyRunePickup(event)
    if event.player_id_const ~= nil and PlayerResource:GetTeam(event.player_id_const) == DOTA_TEAM_GOODGUYS then
        event.gold_bounty = event.gold_bounty * 2
    end
    return true
end

---------------------------------------------------------------------------
-- Event: OnPlayerUsedAbility (TP AND TRAVEL BOOTS HALVED COOLDOWNS)
---------------------------------------------------------------------------
function TurboVSRegular:OnPlayerUsedAbility(event)
    local playerID = event.PlayerID
    if playerID == nil or PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS then return end

    local abilityName = event.abilityname
    if abilityName ~= "item_tpscroll" and abilityName ~= "item_travel_boots" and abilityName ~= "item_travel_boots_2" then return end

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero then return end

    local item = hero:FindItemInInventory(abilityName)
    if not item then return end

    Timers:CreateTimer(0.03, function()
        if item and IsValidEntity(item) then
            item:EndCooldown()
            item:StartCooldown(item:GetCooldown(item:GetLevel()) * 0.5)
        end
    end)
end

---------------------------------------------------------------------------
-- Event: OnItemPickedUp
---------------------------------------------------------------------------
function TurboVSRegular:OnItemPickedUp(event)
    if event.itemname == "item_madstone_bundle" then
        local playerID = event.PlayerID
        if playerID ~= nil and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                local item = hero:GetItemInSlot(DOTA_ITEM_TRANSIENT_CAST_ITEM)
                if item and item:GetAbilityName() == "item_madstone_bundle" then
                    Timers:CreateTimer(0.1, function()
                        if IsValidEntity(hero) and hero:IsAlive() then
                            hero:AddItemByName("item_madstone_bundle")
                        end
                    end)
                end
            end
        end
        return
    end
    if event.itemname ~= "item_aegis" then return end
    local playerID = event.PlayerID
    if playerID == nil or PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS then return end

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero then return end

    CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "start_aegis_countdown", {duration = 240})
    Timers:CreateTimer(240, function()
        if hero and hero:IsAlive() then
            local aegis = hero:FindItemInInventory("item_aegis")
            if aegis then
                hero:RemoveItem(aegis)
                hero:AddNewModifier(hero, nil, "modifier_aegis_regen", {duration = 5})
                EmitSoundOn("Aegis.Expire", hero)
            end
        end
        CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "hide_aegis_countdown", {})
    end)
end
