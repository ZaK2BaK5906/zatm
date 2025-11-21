local ESX = nil
local PlayerData = {}
local isRobbing = false
local robbedATMs = {}
local currentProp = nil
local moneyBags = {} -- Sacs d'argent au sol

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

-- Fonction pour afficher du texte 3D
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Fonction pour créer un sac d'argent au sol
function CreateMoneyBag(coords, amount)
    local bagModel = 'prop_money_bag_01'
    LoadModel(bagModel)

    local bag = CreateObject(GetHashKey(bagModel), coords.x, coords.y, coords.z - 0.5, true, true, false)
    PlaceObjectOnGroundProperly(bag)
    FreezeEntityPosition(bag, true)

    local bagId = #moneyBags + 1
    moneyBags[bagId] = {
        object = bag,
        coords = vector3(coords.x, coords.y, coords.z),
        amount = amount
    }

    -- Ajouter ox_target sur le sac
    exports.ox_target:addLocalEntity(bag, {
        {
            name = 'pickup_money_bag_' .. bagId,
            icon = 'fas fa-hand-holding-usd',
            label = 'Ramasser le sac d\'argent',
            distance = 2.0,
            onSelect = function()
                PickupMoneyBag(bagId)
            end
        }
    })

    -- Thread pour afficher le texte 3D
    CreateThread(function()
        while DoesEntityExist(bag) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local bagCoords = GetEntityCoords(bag)
            local distance = #(playerCoords - bagCoords)

            if distance < 10.0 then
                Draw3DText(bagCoords.x, bagCoords.y, bagCoords.z + 0.5, '~g~$' .. amount)
            end

            Wait(0)
        end
    end)

    return bagId
end

-- Fonction pour ramasser un sac d'argent
function PickupMoneyBag(bagId)
    local bag = moneyBags[bagId]
    if not bag then return end

    local ped = PlayerPedId()
    local bagCoords = GetEntityCoords(bag.object)
    local playerCoords = GetEntityCoords(ped)

    if #(playerCoords - bagCoords) > 3.0 then
        ShowNotification('Vous êtes trop loin du sac', 'error')
        return
    end

    -- Animation de ramassage
    LoadAnimDict('pickup_object')
    TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 1500, 0, 0, false, false, false)

    Wait(1500)

    -- Donner l'argent au joueur
    TriggerServerEvent('esx_atmrobbery:pickupMoneyBag', bag.amount)

    -- Supprimer le sac
    if DoesEntityExist(bag.object) then
        exports.ox_target:removeLocalEntity(bag.object, 'pickup_money_bag_' .. bagId)
        DeleteObject(bag.object)
    end

    moneyBags[bagId] = nil

    ShowNotification('Vous avez ramassé $' .. bag.amount, 'success')
end

-- Méthode 1: Hacking Laptop
function RobWithLaptop(atmEntity, atmCoords)
    local method = Config.Methods['laptop']

    if not method.enabled then
        ShowNotification('Cette méthode est désactivée', 'error')
        isRobbing = false
        return
    end

    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Messages d'immersion pendant le hacking
    CreateThread(function()
        Wait(500)
        if isRobbing then
            ShowNotification('Connexion au système...', 'info')
        end
        Wait(1000)
        if isRobbing then
            ShowNotification('Bypass des protocoles de sécurité...', 'info')
        end
    end)

    -- Progressbar
    local progressCompleted = lib.progressBar({
        duration = method.duration,
        label = 'Hacking de l\'ATM...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if progressCompleted then
        -- Skillcheck
        local success = lib.skillCheck(method.skillcheck.difficulty, method.skillcheck.keys)

        -- Nettoyer animation et prop
        ClearPedTasks(ped)
        RemoveProp()

        if success then
            -- Succès - Retirer l'item et donner récompense
            TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'laptop', method.rewardMin, method.rewardMax, method.removeItem)
            SetATMCooldown(atmEntity)

            -- Alerte police
            if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                Wait(method.policeAlert.delay)
                TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
            end
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            -- En cas d'échec, retirer quand même l'item si removeItem est true
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end
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
        isRobbing = false
        return
    end

    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Progressbar
    local progressCompleted = lib.progressBar({
        duration = method.duration,
        label = 'Installation du skimmer...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if progressCompleted then
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
            -- Le skimmer est perdu même en cas d'échec
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end
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
        isRobbing = false
        return
    end

    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Progressbar
    local progressCompleted = lib.progressBar({
        duration = method.duration,
        label = 'Placement du C4...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if progressCompleted then
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

            -- Créer un sac d'argent au sol au lieu de donner directement
            local rewardAmount = math.random(method.rewardMin, method.rewardMax)

            -- Calculer la position DEVANT l'ATM (pas dedans!)
            local atmForward = GetEntityForwardVector(atmEntity)
            local bagCoords = vector3(
                atmCoords.x + atmForward.x * 1.0, -- 1 mètre devant
                atmCoords.y + atmForward.y * 1.0,
                atmCoords.z - 0.5 -- Un peu plus bas pour être au sol
            )

            CreateMoneyBag(bagCoords, rewardAmount)

            ShowNotification('Le sac d\'argent est tombé au sol ! Ramassez-le rapidement !', 'success')

            -- Retirer l'item C4
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end

            SetATMCooldown(atmEntity)
        else
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            -- Le C4 est perdu même en cas d'échec
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end
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
        isRobbing = false
        return
    end

    local ped = PlayerPedId()

    -- Phase 1: Chalumeau
    LoadAnimDict(method.phase1.animation.dict)
    local prop1 = CreateProp(method.phase1.prop.model, method.phase1.prop.bone, method.phase1.prop.offset)

    TaskPlayAnim(ped, method.phase1.animation.dict, method.phase1.animation.anim, 8.0, -8.0, -1, method.phase1.animation.flag, 0, false, false, false)

    local phase1Completed = lib.progressBar({
        duration = method.phase1.duration,
        label = 'Découpe au chalumeau...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if phase1Completed then
        local success1 = lib.skillCheck(method.phase1.skillcheck.difficulty, method.phase1.skillcheck.keys)

        ClearPedTasks(ped)
        RemoveProp()

        if success1 then
            Wait(500)

            -- Phase 2: Pied de biche
            LoadAnimDict(method.phase2.animation.dict)
            local prop2 = CreateProp(method.phase2.prop.model, method.phase2.prop.bone, method.phase2.prop.offset)

            TaskPlayAnim(ped, method.phase2.animation.dict, method.phase2.animation.anim, 8.0, -8.0, -1, method.phase2.animation.flag, 0, false, false, false)

            local phase2Completed = lib.progressBar({
                duration = method.phase2.duration,
                label = 'Ouverture avec le pied de biche...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                }
            })

            if phase2Completed then
                local success2 = lib.skillCheck(method.phase2.skillcheck.difficulty, method.phase2.skillcheck.keys)

                ClearPedTasks(ped)
                RemoveProp()

                if success2 then
                    -- Succès des 2 phases
                    TriggerServerEvent('esx_atmrobbery:rewardPlayer', 'blowtorch', method.rewardMin, method.rewardMax, method.removeItem)
                    SetATMCooldown(atmEntity)

                    -- Alerte police
                    if method.policeAlert.enabled and math.random(100) <= method.policeAlert.chance then
                        Wait(method.policeAlert.delay)
                        TriggerServerEvent('esx_atmrobbery:alertPolice', atmCoords)
                    end
                else
                    ShowNotification(Config.Messages['robbery_failed'], 'error')
                    -- Échec phase 2
                    if method.removeItem then
                        TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
                    end
                end
            else
                -- Phase 2 annulée
                ClearPedTasks(ped)
                RemoveProp()
                ShowNotification(Config.Messages['robbery_cancelled'], 'error')
            end
        else
            -- Échec phase 1
            ShowNotification(Config.Messages['robbery_failed'], 'error')
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end
        end
    else
        -- Phase 1 annulée
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
        isRobbing = false
        return
    end

    local ped = PlayerPedId()

    -- Charger animation et prop
    LoadAnimDict(method.animation.dict)
    local prop = CreateProp(method.prop.model, method.prop.bone, method.prop.offset)

    -- Jouer animation
    TaskPlayAnim(ped, method.animation.dict, method.animation.anim, 8.0, -8.0, -1, method.animation.flag, 0, false, false, false)

    -- Messages d'immersion pendant le perçage
    CreateThread(function()
        Wait(300)
        if isRobbing then
            ShowNotification('Positionnement de la perceuse...', 'info')
        end
        Wait(1000)
        if isRobbing then
            ShowNotification('Perçage du blindage...', 'info')
        end
    end)

    -- Progressbar
    local progressCompleted = lib.progressBar({
        duration = method.duration,
        label = 'Perçage de l\'ATM...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    if progressCompleted then
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
            if method.removeItem then
                TriggerServerEvent('esx_atmrobbery:removeItemOnly', method.item)
            end
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
                            isRobbing = true
                            RobWithLaptop(atmEntity, atmCoords)
                        else
                            isRobbing = false
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
                            isRobbing = true
                            RobWithSkimmer(atmEntity, atmCoords)
                        else
                            isRobbing = false
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
                            isRobbing = true
                            RobWithC4(atmEntity, atmCoords)
                        else
                            isRobbing = false
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
                            isRobbing = true
                            RobWithBlowtorch(atmEntity, atmCoords)
                        else
                            isRobbing = false
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
                            isRobbing = true
                            RobWithDrill(atmEntity, atmCoords)
                        else
                            isRobbing = false
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
