local ESX = nil
local PlayerData = {}
local isRobbing = false
local robbedATMs = {}
local currentProp = nil

-- Initialisation ESX
CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Fonction de notification
function ShowNotification(message, type)
    if Config.NotificationType == 'ox_lib' then
        lib.notify({
            title = 'ATM Robbery',
            description = message,
            type = type or 'info'
        })
    else
        ESX.ShowNotification(message)
    end
end

-- Fonction pour vérifier si l'ATM est en cooldown
function IsATMOnCooldown(atmEntity)
    if Config.GlobalCooldown then
        return robbedATMs['global'] and (GetGameTimer() - robbedATMs['global']) < (Config.CooldownTime * 1000)
    else
        return robbedATMs[atmEntity] and (GetGameTimer() - robbedATMs[atmEntity]) < (Config.CooldownTime * 1000)
    end
end

-- Fonction pour définir le cooldown d'un ATM
function SetATMCooldown(atmEntity)
    if Config.GlobalCooldown then
        robbedATMs['global'] = GetGameTimer()
    else
        robbedATMs[atmEntity] = GetGameTimer()
    end
end

-- Fonction pour charger les animations et modèles
function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(1)
    end
end

function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
end

-- Fonction pour attacher un prop au joueur
function AttachPropToPlayer(prop, bone, x, y, z, xR, yR, zR)
    local ped = PlayerPedId()
    local boneIndex = GetPedBoneIndex(ped, bone)

    AttachEntityToEntity(prop, ped, boneIndex, x, y, z, xR, yR, zR, true, true, false, true, 1, true)
    return prop
end

-- Fonction pour créer et attacher un prop
function CreateProp(model, bone, offset)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    LoadModel(model)

    local prop = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z + 0.2, true, true, true)
    currentProp = prop

    AttachPropToPlayer(prop, bone, offset.x, offset.y, offset.z, offset.rotX, offset.rotY, offset.rotZ)

    return prop
end

-- Fonction pour supprimer le prop
function RemoveProp()
    if currentProp then
        DeleteObject(currentProp)
        currentProp = nil
    end
end

-- Méthode 1: Hacking Laptop
function RobWithLaptop(atmEntity, atmCoords)
    local method = Config.Methods['laptop']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        return
    end

    isRobbing = true
    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Progressbar
    if lib.progressBar({
        duration = method.duration,
        label = 'Hacking de l\'ATM...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Skillcheck
        local success = lib.skillCheck(method.skillcheck.difficulty, method.skillcheck.keys)

        -- Nettoyer animation et prop
        ClearPedTasks(ped)
        RemoveProp()

        if success then
            -- Succès
            TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'laptop', method.rewardMin, method.rewardMax, method.removeItem)
            SetATMCooldown(atmEntity)

            -- Alerte police
            if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                Wait(method.policeAlert.delay)
                TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
            end
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            TriggerServerEvent('esx_atmrobbery:removeItem', method.item, method.removeItem)
        end
    else
        -- Annulé
        ClearPedTasks(ped)
        RemoveProp()
        ShowNotification(Config.Messages['robbery_cancelled'], 'error')
    end

    isRobbing = false
end

-- Méthode 2: Skimmer ATM
function RobWithSkimmer(atmEntity, atmCoords)
    local method = Config.Methods['skimmer']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        return
    end

    isRobbing = true
    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Progressbar
    if lib.progressBar({
        duration = method.duration,
        label = 'Installation du skimmer...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Skillcheck
        local success = lib.skillCheck(method.skillcheck.difficulty, method.skillcheck.keys)

        -- Nettoyer animation et prop
        ClearPedTasks(ped)
        RemoveProp()

        if success then
            -- Succès
            TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'skimmer', method.rewardMin, method.rewardMax, method.removeItem)
            SetATMCooldown(atmEntity)

            -- Alerte police
            if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                Wait(method.policeAlert.delay)
                TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
            end
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            TriggerServerEvent('esx_atmrobbery:removeItem', method.item, method.removeItem)
        end
    else
        -- Annulé
        ClearPedTasks(ped)
        RemoveProp()
        ShowNotification(Config.Messages['robbery_cancelled'], 'error')
    end

    isRobbing = false
end

-- Méthode 3: C4 Explosif
function RobWithC4(atmEntity, atmCoords)
    local method = Config.Methods['c4']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        return
    end

    isRobbing = true
    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Progressbar
    if lib.progressBar({
        duration = method.duration,
        label = 'Placement du C4...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Skillcheck
        local success = lib.skillCheck(method.skillcheck.difficulty, method.skillcheck.keys)

        -- Nettoyer animation et prop
        ClearPedTasks(ped)
        RemoveProp()

        if success then
            -- Alerte police immédiate
            if method.policeAlert.enabled then
                TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
            end

            -- Reculer
            ShowNotification('Reculez ! Explosion dans 5 secondes...', 'warning')
            Wait(5000)

            -- Explosion
            if method.explosion.enabled then
                AddExplosion(atmCoords.x, atmCoords.y, atmCoords.z, method.explosion.explosionType,
                    method.explosion.damageScale, method.explosion.isAudible, method.explosion.isInvisible,
                    method.explosion.cameraShake)
            end

            -- Succès
            TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'c4', method.rewardMin, method.rewardMax, method.removeItem)
            SetATMCooldown(atmEntity)
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            TriggerServerEvent('esx_atmrobbery:removeItem', method.item, method.removeItem)
        end
    else
        -- Annulé
        ClearPedTasks(ped)
        RemoveProp()
        ShowNotification(Config.Messages['robbery_cancelled'], 'error')
    end

    isRobbing = false
end

-- Méthode 4: Chalumeau + Pied de biche (2 phases)
function RobWithBlowtorch(atmEntity, atmCoords)
    local method = Config.Methods['blowtorch']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        return
    end

    isRobbing = true
    local ped = PlayerPedId()

    -- Phase 1: Chalumeau
    LoadAnimDict(method.phase1.animation.dict)
    local prop1 = CreateProp(method.phase1.prop.model, method.phase1.prop.bone, method.phase1.prop.offset)

    TaskPlayAnim(ped, method.phase1.animation.dict, method.phase1.animation.anim, 8.0, -8.0, -1, method.phase1.animation.flag, 0, false, false, false)

    if lib.progressBar({
        duration = method.phase1.duration,
        label = 'Découpe au chalumeau...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        local success1 = lib.skillCheck(method.phase1.skillcheck.difficulty, method.phase1.skillcheck.keys)

        ClearPedTasks(ped)
        RemoveProp()

        if success1 then
            Wait(500)

            -- Phase 2: Pied de biche
            LoadAnimDict(method.phase2.animation.dict)
            local prop2 = CreateProp(method.phase2.prop.model, method.phase2.prop.bone, method.phase2.prop.offset)

            TaskPlayAnim(ped, method.phase2.animation.dict, method.phase2.animation.anim, 8.0, -8.0, -1, method.phase2.animation.flag, 0, false, false, false)

            if lib.progressBar({
                duration = method.phase2.duration,
                label = 'Ouverture avec le pied de biche...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                }
            }) then
                local success2 = lib.skillCheck(method.phase2.skillcheck.difficulty, method.phase2.skillcheck.keys)

                ClearPedTasks(ped)
                RemoveProp()

                if success2 then
                    -- Succès
                    TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'blowtorch', method.rewardMin, method.rewardMax, method.removeItem)
                    SetATMCooldown(atmEntity)

                    -- Alerte police
                    if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                        Wait(method.policeAlert.delay)
                        TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
                    end
                else
                    ShowNotification(Config.Messages['robbery_failed'], 'error')
                end
            else
                ClearPedTasks(ped)
                RemoveProp()
                ShowNotification(Config.Messages['robbery_cancelled'], 'error')
            end
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            TriggerServerEvent('esx_atmrobbery:removeItem', method.item, method.removeItem)
        end
    else
        ClearPedTasks(ped)
        RemoveProp()
        ShowNotification(Config.Messages['robbery_cancelled'], 'error')
    end

    isRobbing = false
end

-- Méthode 5: Perceuse (Drill)
function RobWithDrill(atmEntity, atmCoords)
    local method = Config.Methods['drill']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        return
    end

    isRobbing = true
    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Son de perceuse
    if method.sound.enabled then
        -- Note: Le son peut ne pas fonctionner si le soundset n'est pas chargé
        -- Vous pouvez utiliser un soundId personnalisé ou le désactiver
    end

    -- Progressbar
    if lib.progressBar({
        duration = method.duration,
        label = 'Perçage de l\'ATM...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Skillcheck (plusieurs phases)
        local success = lib.skillCheck(method.skillcheck.difficulty, method.skillcheck.keys)

        -- Nettoyer animation et prop
        ClearPedTasks(ped)
        RemoveProp()

        if success then
            -- Succès
            TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'drill', method.rewardMin, method.rewardMax, method.removeItem)
            SetATMCooldown(atmEntity)

            -- Alerte police
            if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                Wait(method.policeAlert.delay)
                TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
            end
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            TriggerServerEvent('esx_atmrobbery:removeItem', method.item, method.removeItem)
        end
    else
        -- Annulé
        ClearPedTasks(ped)
        RemoveProp()
        ShowNotification(Config.Messages['robbery_cancelled'], 'error')
    end

    isRobbing = false
end

-- Menu principal pour choisir la méthode
function OpenRobberyMenu(atmEntity, atmCoords)
    if isRobbing then
        ShowNotification(Config.Messages['already_robbing'], 'error')
        return
    end

    if IsATMOnCooldown(atmEntity) then
        ShowNotification(Config.Messages['atm_cooldown'], 'error')
        return
    end

    -- Vérifier les items du joueur via le serveur
    ESX.TriggerServerCallback('esx_atmrobbery:getPlayerItems', function(items)
        local menuOptions = {}

        -- Méthode 1: Laptop
        if Config.Methods['laptop'].enabled and items[Config.Methods['laptop'].item] then
            table.insert(menuOptions, {
                title = Config.Methods['laptop'].label,
                description = 'Hacking technique et discret',
                icon = 'laptop',
                onSelect = function()
                    ESX.TriggerServerCallback('esx_atmrobbery:canRob', function(canRob)
                        if canRob then
                            RobWithLaptop(atmEntity, atmCoords)
                        end
                    end, 'laptop')
                end
            })
        end

        -- Méthode 2: Skimmer
        if Config.Methods['skimmer'].enabled and items[Config.Methods['skimmer'].item] then
            table.insert(menuOptions, {
                title = Config.Methods['skimmer'].label,
                description = 'Installation rapide, gain moyen',
                icon = 'credit-card',
                onSelect = function()
                    ESX.TriggerServerCallback('esx_atmrobbery:canRob', function(canRob)
                        if canRob then
                            RobWithSkimmer(atmEntity, atmCoords)
                        end
                    end, 'skimmer')
                end
            })
        end

        -- Méthode 3: C4
        if Config.Methods['c4'].enabled and items[Config.Methods['c4'].item] then
            table.insert(menuOptions, {
                title = Config.Methods['c4'].label,
                description = 'BRUYANT ! Gros gain, alerte immédiate',
                icon = 'bomb',
                onSelect = function()
                    ESX.TriggerServerCallback('esx_atmrobbery:canRob', function(canRob)
                        if canRob then
                            RobWithC4(atmEntity, atmCoords)
                        end
                    end, 'c4')
                end
            })
        end

        -- Méthode 4: Blowtorch
        if Config.Methods['blowtorch'].enabled and items[Config.Methods['blowtorch'].item] and items[Config.Methods['blowtorch'].secondaryItem] then
            table.insert(menuOptions, {
                title = Config.Methods['blowtorch'].label,
                description = 'Découpe et ouverture en 2 phases',
                icon = 'fire',
                onSelect = function()
                    ESX.TriggerServerCallback('esx_atmrobbery:canRob', function(canRob)
                        if canRob then
                            RobWithBlowtorch(atmEntity, atmCoords)
                        end
                    end, 'blowtorch')
                end
            })
        end

        -- Méthode 5: Drill
        if Config.Methods['drill'].enabled and items[Config.Methods['drill'].item] then
            table.insert(menuOptions, {
                title = Config.Methods['drill'].label,
                description = 'Perçage progressif, méthode mystère',
                icon = 'screwdriver',
                onSelect = function()
                    ESX.TriggerServerCallback('esx_atmrobbery:canRob', function(canRob)
                        if canRob then
                            RobWithDrill(atmEntity, atmCoords)
                        end
                    end, 'drill')
                end
            })
        end

        if #menuOptions == 0 then
            ShowNotification('Vous n\'avez aucun équipement pour braquer cet ATM', 'error')
            return
        end

        lib.registerContext({
            id = 'atm_robbery_menu',
            title = 'Braquage d\'ATM',
            options = menuOptions
        })

        lib.showContext('atm_robbery_menu')
    end)
end

-- Initialisation ox_target pour les ATMs
CreateThread(function()
    if not Config.ATMs.enabled then return end

    exports.ox_target:addModel(Config.ATMs.models, {
        {
            name = 'atm_robbery',
            icon = 'fas fa-user-secret',
            label = 'Braquer l\'ATM',
            distance = Config.ATMs.distance,
            onSelect = function(data)
                local atmEntity = data.entity
                local atmCoords = GetEntityCoords(atmEntity)
                OpenRobberyMenu(atmEntity, atmCoords)
            end
        }
    })
end)

-- Event pour les alertes police (côté client)
RegisterNetEvent('esx_atmrobbery:policeAlert')
AddEventHandler('esx_atmrobbery:policeAlert', function(coords)
    if PlayerData.job and PlayerData.job.name == 'police' then
        -- Notification pour la police
        ShowNotification(Config.Messages['police_alert'], 'error')

        -- Blip sur la carte
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 1.2)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, false)
        SetBlipFlashes(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Braquage d\'ATM')
        EndTextCommandSetBlipName(blip)

        -- Supprimer le blip après 5 minutes
        Wait(300000)
        RemoveBlip(blip)
    end
end)
