Config = {}

-- Paramètres généraux
Config.Locale = 'fr'
Config.CooldownTime = 300 -- Secondes (5 minutes par défaut)
Config.GlobalCooldown = false -- Si true, tous les ATMs partagent le même cooldown

-- Notification système (ox_lib ou esx)
Config.NotificationType = 'ox_lib' -- 'ox_lib' ou 'esx'

-- Police (MODE TEST - DÉSACTIVÉ)
Config.RequirePolice = false -- Si true, nécessite un minimum de police en ligne
Config.MinPolice = 0 -- Nombre minimum de policiers requis

-- Récompenses
Config.RewardType = 'black_money' -- 'black_money' ou 'money'

-- Méthodes de braquage
Config.Methods = {
    -- Méthode 1: Hacking Laptop (Discret, Technique)
    ['laptop'] = {
        enabled = true,
        label = 'Hacking Laptop',
        item = 'laptop_hacking', -- Ou 'advanced_laptop'
        removeItem = false, -- Si true, l'item est consommé
        requirePolice = false, -- MODE TEST
        minPolice = 0, -- MODE TEST

        -- Animation (sans props)
        animation = {
            dict = 'anim@heists@ornate_bank@hack',
            anim = 'hack_loop',
            flag = 16 -- Flag 16 permet l'animation répétée et le mouvement des mains
        },

        -- Minigeu datacrack (MODE TEST - FACILE)
        datacrackDifficulty = 1, -- 1 = facile, 2 = moyen, 3 = difficile

        duration = 3000, -- 3 secondes (MODE TEST)

        -- Récompenses
        rewardMin = 3000,
        rewardMax = 5000,

        -- Alerte police
        policeAlert = {
            enabled = true,
            chance = 30, -- 30% de chance d'alerter la police
            delay = 15000 -- Délai avant l'alerte (15 secondes)
        }
    },

    -- Méthode 2: Skimmer ATM (Rapide, Gain moyen) - DÉSACTIVÉ
    ['skimmer'] = {
        enabled = false,
        label = 'ATM Skimmer',
        item = 'atm_skimmer', -- Ou 'card_skimmer'
        removeItem = true, -- Le skimmer est installé et perdu
        requirePolice = false, -- MODE TEST
        minPolice = 0, -- MODE TEST

        -- Animation
        animation = {
            dict = 'amb@prop_human_atm@male@idle_a',
            anim = 'idle_b',
            flag = 49
        },
        prop = {
            model = 'prop_ld_card',
            bone = 60309,
            offset = {x = 0.06, y = 0.04, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
        },

        -- Minijeu ox_lib (MODE TEST - FACILE)
        skillcheck = {
            difficulty = {'easy', 'easy', 'easy'},
            keys = {'1', '2', '3'}
        },

        duration = 3000, -- 3 secondes (MODE TEST)

        -- Récompenses
        rewardMin = 1500,
        rewardMax = 3000,

        -- Alerte police
        policeAlert = {
            enabled = true,
            chance = 40,
            delay = 30000 -- 30 secondes
        }
    },

    -- Méthode 3: C4 Explosif (Bruyant, Gros gain)
    ['c4'] = {
        enabled = true,
        label = 'C4 Explosif',
        item = 'c4_explosive',
        removeItem = true,
        requirePolice = false, -- MODE TEST
        minPolice = 0, -- MODE TEST

        -- Animation
        animation = {
            dict = 'anim@heists@ornate_bank@thermal_charge',
            anim = 'thermal_charge',
            flag = 49
        },
        prop = {
            model = 'prop_c4_final',
            bone = 60309,
            offset = {x = 0.06, y = 0.04, z = 0.0, rotX = 90.0, rotY = 0.0, rotZ = 0.0}
        },

        -- Minijeu ox_lib (MODE TEST - FACILE)
        skillcheck = {
            difficulty = {'easy', 'easy', 'easy'},
            keys = {'1', '2', '3'}
        },

        duration = 3000, -- 3 secondes (MODE TEST)

        -- Explosion
        explosion = {
            enabled = true,
            explosionType = 2, -- Type d'explosion
            damageScale = 2.0, -- Dégâts augmentés
            isAudible = true,
            isInvisible = false,
            cameraShake = 2.5 -- Secousse de caméra augmentée
        },

        -- Récompenses
        rewardMin = 6000,
        rewardMax = 10000,

        -- Alerte police
        policeAlert = {
            enabled = true,
            chance = 100, -- Alerte instantanée
            delay = 0 -- Immédiat
        }
    },

    -- Méthode 4: Chalumeau + Pied de biche (Temps moyen) - DÉSACTIVÉ
    ['blowtorch'] = {
        enabled = false,
        label = 'Chalumeau & Pied de biche',
        item = 'blowtorch', -- Nécessite aussi 'crowbar'
        secondaryItem = 'crowbar',
        removeItem = false,
        requirePolice = false, -- MODE TEST
        minPolice = 0, -- MODE TEST

        -- Phase 1: Chalumeau
        phase1 = {
            animation = {
                dict = 'amb@world_human_welding@male@base',
                anim = 'base',
                flag = 49
            },
            prop = {
                model = 'prop_weld_torch',
                bone = 28422, -- IK_L_Hand
                offset = {x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
            },
            skillcheck = {
                difficulty = {'easy', 'easy', 'easy'},
                keys = {'1', '2', '3'}
            },
            duration = 3000 -- 3 secondes (MODE TEST)
        },

        -- Phase 2: Pied de biche
        phase2 = {
            animation = {
                dict = 'amb@prop_human_bum_bin@idle_b',
                anim = 'idle_d',
                flag = 49
            },
            prop = {
                model = 'prop_tool_crowbar',
                bone = 28422,
                offset = {x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
            },
            skillcheck = {
                difficulty = {'easy', 'easy', 'easy'},
                keys = {'1', '2', '3'}
            },
            duration = 3000 -- 3 secondes (MODE TEST)
        },

        -- Récompenses
        rewardMin = 4000,
        rewardMax = 7000,

        -- Alerte police
        policeAlert = {
            enabled = true,
            chance = 60,
            delay = 20000 -- 20 secondes
        }
    },

    -- Méthode 5: Perceuse (Drill) - Méthode mystère
    ['drill'] = {
        enabled = true,
        label = 'Perceuse Industrielle',
        item = 'drill',
        removeItem = false,
        requirePolice = false, -- MODE TEST
        minPolice = 0, -- MODE TEST

        -- Animation
        animation = {
            dict = 'anim@heists@fleeca_bank@drilling',
            anim = 'drill_straight_idle',
            flag = 49
        },
        prop = {
            model = 'hei_prop_heist_drill',
            bone = 28422,
            offset = {x = 0.14, y = 0.0, z = 0.03, rotX = 90.0, rotY = 0.0, rotZ = 0.0} -- Mèche vers l'avant
        },

        -- Minijeu ox_lib (MODE TEST - FACILE)
        skillcheck = {
            difficulty = {'easy', 'easy', 'easy'},
            keys = {'1', '2', '3'}
        },

        duration = 3000, -- 3 secondes (MODE TEST)

        -- Sons
        sound = {
            enabled = true,
            soundName = 'Drill',
            soundSet = 'DLC_HEIST_FLEECA_SOUNDSET'
        },

        -- Récompenses
        rewardMin = 5000,
        rewardMax = 8000,

        -- Alerte police
        policeAlert = {
            enabled = true,
            chance = 70,
            delay = 10000 -- 10 secondes
        }
    }
}

-- Configuration des ATMs
Config.ATMs = {
    enabled = true,
    distance = 2.0, -- Distance d'interaction ox_target

    -- Modèles d'ATM
    models = {
        `prop_atm_01`,
        `prop_atm_02`,
        `prop_atm_03`,
        `prop_fleeca_atm`
    }
}

-- Messages
Config.Messages = {
    ['not_enough_police'] = 'Pas assez de policiers en ville (%s/%s)',
    ['atm_cooldown'] = 'Cet ATM a déjà été braqué récemment',
    ['missing_item'] = 'Il vous manque: %s',
    ['robbery_started'] = 'Braquage en cours...',
    ['robbery_success'] = 'Vous avez récupéré $%s !',
    ['robbery_failed'] = 'Le braquage a échoué !',
    ['robbery_cancelled'] = 'Braquage annulé',
    ['police_alert'] = 'Alerte: Braquage d\'ATM en cours !',
    ['already_robbing'] = 'Un braquage est déjà en cours'
}
