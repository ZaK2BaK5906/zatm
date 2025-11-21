local ESX = nil

-- Initialisation ESX
CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Wait(0)
    end

    -- Fonction pour compter les policiers en ligne
    function GetPoliceCount()
        local count = 0
        local xPlayers = ESX.GetExtendedPlayers()

        for _, xPlayer in pairs(xPlayers) do
            if xPlayer.job.name == 'police' then
                count = count + 1
            end
        end

        return count
    end

    -- Callback: Vérifier si le joueur peut braquer
    ESX.RegisterServerCallback('esx_atmrobbery:canRob', function(source, cb, method)
        local xPlayer = ESX.GetPlayerFromId(source)

        if not xPlayer then
            cb(false)
            return
        end

        local methodConfig = Config.Methods[method]

        if not methodConfig or not methodConfig.enabled then
            cb(false)
            return
        end

        -- Vérifier le nombre de policiers
        if Config.RequirePolice or methodConfig.requirePolice then
            local policeCount = GetPoliceCount()
            local minPolice = methodConfig.minPolice or Config.MinPolice

            if policeCount < minPolice then
                TriggerClientEvent('esx:showNotification', source,
                    string.format(Config.Messages['not_enough_police'], policeCount, minPolice))
                cb(false)
                return
            end
        end

        -- Vérifier si le joueur possède l'item principal (ox_inventory)
        local hasItem = exports.ox_inventory:GetItem(source, methodConfig.item, nil, true)
        if not hasItem or hasItem < 1 then
            TriggerClientEvent('esx:showNotification', source,
                string.format(Config.Messages['missing_item'], methodConfig.item))
            cb(false)
            return
        end

        -- Vérifier l'item secondaire (pour blowtorch)
        if methodConfig.secondaryItem then
            local hasSecondaryItem = exports.ox_inventory:GetItem(source, methodConfig.secondaryItem, nil, true)
            if not hasSecondaryItem or hasSecondaryItem < 1 then
                TriggerClientEvent('esx:showNotification', source,
                    string.format(Config.Messages['missing_item'], methodConfig.secondaryItem))
                cb(false)
                return
            end
        end

        cb(true)
    end)

    -- Callback: Récupérer les items du joueur (ox_inventory)
    ESX.RegisterServerCallback('esx_atmrobbery:getPlayerItems', function(source, cb)
        local items = {}

        -- Vérifier chaque méthode
        for methodName, methodConfig in pairs(Config.Methods) do
            if methodConfig.enabled then
                -- Vérifier item principal avec ox_inventory
                local itemCount = exports.ox_inventory:GetItem(source, methodConfig.item, nil, true)
                if itemCount and itemCount > 0 then
                    items[methodConfig.item] = true
                end

                -- Vérifier item secondaire
                if methodConfig.secondaryItem then
                    local secondaryItemCount = exports.ox_inventory:GetItem(source, methodConfig.secondaryItem, nil, true)
                    if secondaryItemCount and secondaryItemCount > 0 then
                        items[methodConfig.secondaryItem] = true
                    end
                end
            end
        end

        cb(items)
    end)

    -- Event: Récompenser le joueur
    RegisterNetEvent('esx_atmrobbery:rewardPlayer')
    AddEventHandler('esx_atmrobbery:rewardPlayer', function(method, rewardMin, rewardMax, removeItem)
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(_source)

        if not xPlayer then return end

        local methodConfig = Config.Methods[method]
        if not methodConfig then return end

        -- Calculer la récompense
        local reward = math.random(rewardMin, rewardMax)

        -- Donner l'argent
        if Config.RewardType == 'black_money' then
            xPlayer.addAccountMoney('black_money', reward)
        else
            xPlayer.addMoney(reward)
        end

        -- Retirer l'item si nécessaire (ox_inventory)
        if removeItem then
            exports.ox_inventory:RemoveItem(_source, methodConfig.item, 1)
        end

        -- Notification
        TriggerClientEvent('esx:showNotification', _source,
            string.format(Config.Messages['robbery_success'], reward))

        -- Log (optionnel - pour système de logs Discord par exemple)
        print(string.format('[ZATM ATM ROBBERY] %s (%s) a braqué un ATM avec la méthode %s et a reçu $%s',
            xPlayer.getName(), xPlayer.identifier, method, reward))
    end)

    -- Event: Retirer un item (en cas d'échec) - ox_inventory
    RegisterNetEvent('esx_atmrobbery:removeItem')
    AddEventHandler('esx_atmrobbery:removeItem', function(itemName, shouldRemove)
        local _source = source

        if not shouldRemove then return end

        exports.ox_inventory:RemoveItem(_source, itemName, 1)
    end)

    -- Event: Alerter la police
    RegisterNetEvent('esx_atmrobbery:alertPolice')
    AddEventHandler('esx_atmrobbery:alertPolice', function(coords)
        local _source = source
        local xPlayers = ESX.GetExtendedPlayers()

        -- Envoyer l'alerte à tous les policiers
        for _, xPlayer in pairs(xPlayers) do
            if xPlayer.job.name == 'police' then
                TriggerClientEvent('esx_atmrobbery:policeAlert', xPlayer.source, coords)
            end
        end

        -- Log
        print(string.format('[ZATM ATM ROBBERY] Alerte police déclenchée aux coordonnées: %s, %s, %s',
            coords.x, coords.y, coords.z))
    end)

    -- Commande admin pour donner des items de braquage (optionnel)
    ESX.RegisterCommand('giverobberyitem', 'admin', function(xPlayer, args, showError)
        local targetId = tonumber(args.id)
        local itemName = args.item
        local amount = tonumber(args.amount) or 1

        local xTarget = ESX.GetPlayerFromId(targetId)

        if not xTarget then
            TriggerClientEvent('esx:showNotification', xPlayer.source, 'Joueur non trouvé')
            return
        end

        -- Vérifier si l'item existe dans les méthodes
        local itemExists = false
        for _, method in pairs(Config.Methods) do
            if method.item == itemName or method.secondaryItem == itemName then
                itemExists = true
                break
            end
        end

        if not itemExists then
            TriggerClientEvent('esx:showNotification', xPlayer.source, 'Item invalide')
            return
        end

        -- Utiliser ox_inventory pour ajouter l'item
        exports.ox_inventory:AddItem(targetId, itemName, amount)
        TriggerClientEvent('esx:showNotification', xPlayer.source,
            string.format('Vous avez donné %sx %s à %s', amount, itemName, xTarget.getName()))
        TriggerClientEvent('esx:showNotification', xTarget.source,
            string.format('Vous avez reçu %sx %s', amount, itemName))
    end, true, {
        help = 'Donner un item de braquage à un joueur',
        validate = true,
        arguments = {
            {name = 'id', help = 'ID du joueur', type = 'player'},
            {name = 'item', help = 'Nom de l\'item', type = 'string'},
            {name = 'amount', help = 'Quantité (optionnel)', type = 'number'}
        }
    })

    print('[ZATM ATM ROBBERY] Script chargé avec succès ! Full OX sous ESX')
end)

-- Webhook Discord pour les logs (optionnel)
-- Décommentez et configurez si vous voulez des logs Discord
--[[
local webhookURL = 'YOUR_DISCORD_WEBHOOK_URL'

function SendDiscordLog(title, description, color)
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color,
            ['footer'] = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S')
            }
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST',
        json.encode({username = 'ATM Robbery Logs', embeds = embed}),
        {['Content-Type'] = 'application/json'})
end

-- Exemple d'utilisation:
-- SendDiscordLog('Braquage ATM', 'Player X a braqué un ATM', 16711680)
--]]
