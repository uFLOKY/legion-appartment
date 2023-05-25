local QBCore = exports['qb-core']:GetCoreObject()

local PlayerData = QBCore.Functions.GetPlayerData()
local Blip = nil
local InsideZones = {}
local poly = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
    end)
end)

function ShowDrawtext(text)
	lib.showTextUI(text, {
		position = "left-center",
	})
end

function HideDrawtext()
	lib.hideTextUI()
end

function Notification(text, type)
    lib.notify({
        description = text,
        type = type
    })
end

function RemoveBoxes()
    for k, v in pairs(InsideZones) do 
        v:remove()
        InsideZones[k] = nil
    end
end

function CreateInsideZones(apart)
    if not apart then return end 
    local apartData = Config.Appartment[apart]
    if not apartData then return end 
    for k, v in pairs(apartData.inSideLocations) do 
        InsideZones[#InsideZones + 1] = lib.zones.box({
            coords = v.coords,
            size = v.size,
            rotation = v.rotation,
            debug = false,
            onEnter = function(_)
                ShowDrawtext(v.text)
            end,
            onExit = function(_)
                HideDrawtext()
            end,
            inside = function(_)
                if IsControlJustReleased(0, 38) then
                    if v.type == 'door' then 
                        TriggerEvent('legion-appartment:client:tpOut', apartData)
                    elseif v.type == 'manage' then 
                        PlayerData = QBCore.Functions.GetPlayerData()
                        exports['qb-menu']:openMenu({
                            {
                                header = "Tower",
                                isMenuHeader = true, -- Set to true to make a nonclickable title
                            },
                            {
                                header = "Password",
                                txt = "Change Door Password",
                                icon = "fa-duotone fa-key",
                                params = {
                                    event = "legion-appartment:client:mPassword",
                                    args = {
                                        Owner = PlayerData.citizenid,
                                        AppartmentID = apartData.AppartmentID
                                    }
                                }
                            },
                            {
                                header = "Visitor",
                                icon = "fa-solid fa-people-line",
                                txt = "Open door for visitor",
                                params = {
                                    event = "legion-appartment:client:allowvisit",
                                    args = {
                                        Owner = PlayerData.citizenid,
                                        AppartmentID = apartData.AppartmentID
                                    }
                                }
                            },
                        })
                    elseif v.type == 'stash' then 
                        if not Config.Appartment[apartData.AppartmentID] then return end
                        TriggerServerEvent("inventory:server:OpenInventory", "stash", "leagon_appartment"..apartData.AppartmentID, {
                            maxweight = 4000000,
                            slots = 45,
                        })
                        TriggerEvent("inventory:client:SetCurrentStash", "leagon_appartment"..apartData.AppartmentID)
                    elseif v.type == 'clothes' then 
                        TriggerEvent('qb-clothing:client:openOutfitMenu')
                    end
                end
            end
        })
    end
end

CreateThread(function()
    Blip = AddBlipForCoord(vec3(104.20128631592,-932.62725830078,29.83136177063))
    SetBlipSprite(Blip, 476)
    SetBlipDisplay(Blip, 4)
    SetBlipScale(Blip, 0.6)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, 66)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName('Leagon Apartment')
    EndTextCommandSetBlipName(Blip)
    Wait(1000)
    exports["qb-target"]:AddBoxZone("leagonappartmenttowermaindoor", vector3(104.47, -932.73, 29.78), 4.0, 1.4, {
        name="leagonappartmenttowermaindoor",
        heading=340,
        --debugPoly=true,
        minZ=28.18,
        maxZ=31.18
        }, {
        options = {
            {
                event = 'legion-appartment:client:lobbymenu',
                icon = "far fa-clipboard",
                label = "Interaction",
            },
        },
        job = {"all"},
        distance = 2.0
    })

    for k, v in pairs(Config.Appartment) do 
        poly[k] = BoxZone:Create(v.poly.coords, v.poly.info1, v.poly.info2, {
            name="leagonappartarea"..v.AppartmentID,
            heading=v.poly.heading,
            debugPoly=false,
            minZ=v.poly.coords.z - 1.0,
            maxZ=v.poly.coords.z + 1.8,
        })
        poly[k]:onPlayerInOut(function(isPointInside)
            if isPointInside then
                TriggerServerEvent('legion-appartment:server:rashidshit', true, v.AppartmentID)
                CreateInsideZones(v.AppartmentID)
            else
                TriggerServerEvent('legion-appartment:server:rashidshit', false, v.AppartmentID)
                HideDrawtext()
                RemoveBoxes()
            end
        end)
    end
end)

RegisterNetEvent('legion-appartment:client:allowvisit', function(data)
    if not data then return end
    if not Config.Appartment[data.AppartmentID] then return end
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
        local amount = 0
        for k, v in pairs(Config.Appartment[data.AppartmentID].Rings) do 
            amount = amount + 1
        end
        if amount > 0 then 
            local menu = {}
            for k, v in pairs(Config.Appartment[data.AppartmentID].Rings) do 
                menu[#menu + 1] = {
                    header = "Visitor ",
                    txt = "Name: "..v.name.."",
                    params = {
                        isServer = true,
                        event = "legion-appartment:server:allowvisit",
                        args = {
                            AppartmentID = data.AppartmentID,
                            visitor = v.cid,
                            checkDis = Config.Appartment[data.AppartmentID].TpFrom
                        }
                    }
                }
            end
            if #menu <= 0 then 
                return 
            end
            exports['qb-menu']:openMenu(menu)
        else
            QBCore.Functions.Notify('No one has ringed the door', 'error', 7500)
        end
    end)
end)

RegisterNetEvent('legion-appartment:client:ringdoorBill', function()
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
end)

RegisterNetEvent('legion-appartment:server:allowvisitsec', function(AppartmentID)
    if not Config.Appartment[AppartmentID] then return end
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), Config.Appartment[AppartmentID].TpTo)
    SetEntityHeading(PlayerPedId(), Config.Appartment[AppartmentID].hTo)
    Wait(500)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('legion-appartment:client:lobbysecmenu', function(data)
    PlayerData = QBCore.Functions.GetPlayerData()
    local cid = PlayerData.citizenid
    if not data then return end
    local menu = {}
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
        if data.action == 1 then 
            for k, v in pairs(Config.Appartment) do 
                if v.Tower == data.Tower then 
                    if v.isOwned then 
                        menu[#menu + 1] = {
                            header = "Tower "..v.Tower,
                            icon = "fa-light fa-building",
                            txt = "Apartment #: "..v.AppartmentID.."",
                            params = {
                                isServer = false,
                                event = "legion-appartment:client:enterappartment",
                                args = {
                                    AppartmentID = v.AppartmentID
                                }
                            }
                        }
                    end
                end
            end
            if #menu <= 0 then 
                QBCore.Functions.Notify('No apartment found', 'error', 7500)
                return 
            end
            menu[#menu + 1] = {
                header = "Exit",
                icon = "fa-regular fa-circle-xmark",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(menu)
        elseif data.action == 2 then 
            for k, v in pairs(Config.Appartment) do 
                if v.Tower == data.Tower then 
                    if v.isOwned then 
                        menu[#menu + 1] = {
                            header = "Apartment ",
                            icon = "fa-light fa-building",
                            txt = "Apartment #: "..v.AppartmentID.."",
                            params = {
                                isServer = false,
                                event = "legion-appartment:client:ringdooe",
                                args = {
                                    AppartmentID = v.AppartmentID
                                }
                            }
                        }
                    end
                end
            end
            if #menu <= 0 then 
                QBCore.Functions.Notify('No apartment found', 'error', 7500)
                return 
            end
            menu[#menu + 1] = {
                header = "Exit",
                icon = "fa-regular fa-circle-xmark",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(menu)
        end
    end)
end)

RegisterNetEvent('legion-appartment:client:ringdooe', function(data)
    if not data then return end
    if not Config.Appartment[data.AppartmentID] then return end
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
        local amount = 0
        for k, v in pairs(Config.Appartment[data.AppartmentID].inAppartAmount) do 
            amount = amount + 1
        end
        if amount > 0 then 
            TriggerServerEvent('legion-appartment:server:ringdooe', data.AppartmentID)
        else
            QBCore.Functions.Notify('No one in this apartment', 'error', 7500)
        end
    end)
end)

RegisterNetEvent('legion-appartment:client:mPassword', function(data)
    if not data then return end
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
        if not Config.Appartment[data.AppartmentID] then return end
        PlayerData = QBCore.Functions.GetPlayerData()
        local cid = PlayerData.citizenid
        if Config.Appartment[data.AppartmentID].Owner == cid then 

            local input = lib.inputDialog('New Password', {
                { type = "input", label = "Password", password = true, icon = 'lock' },
            })
        
            if input then 
                if input[1] then 
                    local pss = tonumber(input[1])
                    if type(pss) == 'number' then 
                        if pss and tonumber(pss) > 0 then 
                            local appInfo = {
                                AppartmentID = data.AppartmentID,
                                pasword = pss,
                                owner = cid
                            }
                            TriggerServerEvent('legion-appartment:server:mPassword', appInfo)
                        else
                            QBCore.Functions.Notify("Wrong Password", "error", 3500)
                        end
                    else
                        QBCore.Functions.Notify('Numbers only', 'error', 7500)
                    end
                end
            end
        else
            QBCore.Functions.Notify("You are not the owner", "error", 3500)
        end
    end)
end)

RegisterNetEvent('legion-appartment:client:tpOut', function(data)
    if not data then return end
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), data.TpFrom)
    SetEntityHeading(PlayerPedId(), data.hFrom)
    Wait(500)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('legion-appartment:client:lobbymenu', function(data)
    exports['qb-menu']:openMenu({
        {
            header = "Tower",
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = "Tower",
            icon = "fa-regular fa-1",
            txt = "1",
            params = {
                event = "legion-appartment:client:lobbymenuT",
                args = {
                    action = 1,
                    Tower = 1
                }
            }
        },
        {
            header = "Tower",
            icon = "fa-regular fa-2",
            txt = "2",
            params = {
                event = "legion-appartment:client:lobbymenuT",
                args = {
                    action = 1,
                    Tower = 2
                }
            }
        },
        {
            header = "Tower",
            icon = "fa-regular fa-3",
            txt = "3",
            params = {
                event = "legion-appartment:client:lobbymenuT",
                args = {
                    action = 1,
                    Tower = 3
                }
            }
        },
        {
            header = "Exit",
            icon = "fa-regular fa-circle-xmark",
            params = {
                event = "qb-menu:closeMenu",
            }
        },
    })
end)

RegisterNetEvent('legion-appartment:client:lobbymenuT', function(data)
    exports['qb-menu']:openMenu({
        {
            header = "Appartment",
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = "Enter",
            icon = "fa-solid fa-person-shelter",
            txt = "Enter owned appartment",
            params = {
                event = "legion-appartment:client:lobbysecmenu",
                args = {
                    action = 1,
                    Tower = data.Tower
                }
            }
        },
        {
            header = "Visit",
            icon = "fa-solid fa-people-line",
            txt = "Visit appartment",
            params = {
                event = "legion-appartment:client:lobbysecmenu",
                args = {
                    action = 2,
                    Tower = data.Tower
                }
            }
        },
        {
            header = "Exit",
            icon = "fa-regular fa-circle-xmark",
            params = {
                event = "qb-menu:closeMenu",
            }
        },
    })
end)

RegisterNetEvent('legion-appartment:client:enterappartment', function(data)
    if not data then return end
    if not Config.Appartment[data.AppartmentID] then return end

    local input = lib.inputDialog('Password', {
        { type = "input", label = "Password", password = true, icon = 'lock' },
    })

    if input then 
        if input[1] then 
            local pss = tonumber(input[1])
            if type(pss) == 'number' then 
                if pss and tonumber(pss) == Config.Appartment[data.AppartmentID].Password then 
                    DoScreenFadeOut(500)
                    Wait(500)
                    SetEntityCoords(PlayerPedId(), Config.Appartment[data.AppartmentID].TpTo)
                    SetEntityHeading(PlayerPedId(), Config.Appartment[data.AppartmentID].hTo)
                    Wait(500)
                    DoScreenFadeIn(500)
                else
                    QBCore.Functions.Notify("Wrong Password", "error", 3500)
                end
            else
                QBCore.Functions.Notify('Numbers only', 'error', 7500)
            end
        end
    end
end)

RegisterNetEvent('legion-appartment:client:menu', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    local cid = PlayerData.citizenid
    local menu = {}
    QBCore.Functions.TriggerCallback('legion-appartment:GetConfig', function(GG)
        Config = GG
        for k, v in pairs(Config.Appartment) do 
            if not v.isOwned then 
                menu[#menu + 1] = {
                    header = "Apartment "..k.."",
                    icon = "fa-light fa-building",
                    txt = "Tower: "..v.Tower.."<br>Buy this apartment for $ "..v.Price.."",
                    params = {
                        isServer = false,
                        event = "legion-appartment:client:Buy",
                        args = {
                            AppartmentID = v.AppartmentID,
                            Tower = v.Tower
                        }
                    }
                }
            end
        end
        if #menu <= 0 then 
            QBCore.Functions.Notify('All appartment have been sold', 'error', 7500)
            return 
        end
        menu[#menu + 1] = {
            header = "Exit",
            icon = "fa-regular fa-circle-xmark",
            params = {
                event = "qb-menu:closeMenu",
            }
        }
        exports['qb-menu']:openMenu(menu)
    end)
end)

RegisterNetEvent('legion-appartment:client:Buy', function(data)
    if not data then return end 
    local alert = lib.alertDialog({
        header = 'Confirmation',
        content = 'Are you sure you want to buy this apartment # '..data.AppartmentID..' at tower #'..data.Tower..'',
        centered = true,
        cancel = true
    })
    if alert then 
        if alert == 'confirm' then 
            TriggerServerEvent("legion-appartment:server:Buy", data)
        end
    end
end)