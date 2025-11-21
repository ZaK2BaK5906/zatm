# ESX ATM Robbery - Système de Braquage d'ATM avec 5 Méthodes

Un système complet de braquage d'ATM pour ESX Legacy avec 5 méthodes différentes, chacune avec ses propres animations, minijeux et caractéristiques.

## Caractéristiques

- **5 Méthodes de braquage** uniques et configurables
- **Minijeux ox_lib** (Skillcheck) pour chaque méthode
- **Animations et props** réalistes
- **Système d'alerte police** variable selon la méthode
- **Cooldown** par ATM ou global
- **Configuration complète** dans config.lua
- **Intégration ox_target** pour l'interaction
- **Compatible ESX Legacy 1.12.14**

## Dépendances

- [es_extended](https://github.com/esx-framework/esx_core) (ESX Legacy 1.12.14+)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## Installation

1. Téléchargez et placez le dossier `esx_atmrobbery` dans votre dossier `resources`

2. Ajoutez les items dans **ox_inventory** en ajoutant ceci dans `ox_inventory/data/items.lua`:

```lua
-- Items pour les méthodes de braquage d'ATM
['laptop_hacking'] = {
    label = 'Laptop de Hacking',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Laptop configuré pour hacker les ATM'
},

['atm_skimmer'] = {
    label = 'Skimmer ATM',
    weight = 500,
    stack = true,
    close = true,
    description = 'Dispositif pour cloner les cartes bancaires'
},

['c4_explosive'] = {
    label = 'C4 Explosif',
    weight = 2000,
    stack = false,
    close = true,
    description = 'Explosif plastique pour faire sauter les ATM'
},

['blowtorch'] = {
    label = 'Chalumeau',
    weight = 1500,
    stack = false,
    close = true,
    description = 'Chalumeau pour découper le métal'
},

['crowbar'] = {
    label = 'Pied de biche',
    weight = 800,
    stack = false,
    close = true,
    description = 'Levier pour forcer les ouvertures'
},

['drill'] = {
    label = 'Perceuse Industrielle',
    weight = 1800,
    stack = false,
    close = true,
    description = 'Perceuse puissante pour percer les ATM'
},
```

3. Ajoutez le script dans votre `server.cfg`:

```cfg
ensure esx_atmrobbery
```

4. Redémarrez votre serveur

> **Note**: Ce script utilise **ox_inventory** pour la gestion des items. Assurez-vous que ox_inventory est correctement installé et configuré.

## Les 5 Méthodes de Braquage

### 1. Hacking Laptop 💻
- **Item requis**: `laptop_hacking`
- **Caractéristiques**: Le plus technique et discret
- **Difficulté**: Élevée (3x Hard skillcheck)
- **Durée**: 45 secondes
- **Gains**: 3000$ - 5000$
- **Alerte police**: 30% de chance (délai 15s)
- **Police requise**: 1 minimum

### 2. Skimmer ATM 💳
- **Item requis**: `atm_skimmer`
- **Caractéristiques**: Rapide, gain moyen, item consommé
- **Difficulté**: Faible (2x Easy, 1x Medium)
- **Durée**: 20 secondes
- **Gains**: 1500$ - 3000$
- **Alerte police**: 40% de chance (délai 30s)
- **Police requise**: 1 minimum

### 3. C4 Explosif 💣
- **Item requis**: `c4_explosive`
- **Caractéristiques**: BRUYANT, gros gain, explosion, alerte immédiate
- **Difficulté**: Moyenne (2x Medium, 1x Hard)
- **Durée**: 30 secondes + explosion
- **Gains**: 6000$ - 10000$
- **Alerte police**: 100% instantanée
- **Police requise**: 3 minimum
- **Effets spéciaux**: Explosion avec particle effects

### 4. Chalumeau + Pied de biche 🔥🔧
- **Items requis**: `blowtorch` + `crowbar`
- **Caractéristiques**: 2 phases (découpe puis ouverture)
- **Difficulté**: Moyenne
  - Phase 1: 3x Medium (chalumeau)
  - Phase 2: Easy, Medium, Hard (pied de biche)
- **Durée**: 40 secondes total (25s + 15s)
- **Gains**: 4000$ - 7000$
- **Alerte police**: 60% de chance (délai 20s)
- **Police requise**: 2 minimum

### 5. Perceuse (Drill) 🔩
- **Item requis**: `drill`
- **Caractéristiques**: Méthode mystère, perçage progressif
- **Difficulté**: Élevée (4 skillchecks Medium/Hard)
- **Durée**: 40 secondes
- **Gains**: 5000$ - 8000$
- **Alerte police**: 70% de chance (délai 10s)
- **Police requise**: 2 minimum
- **Effets spéciaux**: Son de perceuse

## Configuration

Toute la configuration se trouve dans `config.lua`. Vous pouvez personnaliser:

### Paramètres Généraux
```lua
Config.CooldownTime = 300 -- Cooldown en secondes (5 minutes)
Config.GlobalCooldown = false -- Cooldown global ou par ATM
Config.MinPolice = 2 -- Nombre minimum de policiers
Config.RewardType = 'black_money' -- Type de récompense ('black_money' ou 'money')
```

### Personnaliser une Méthode
Chaque méthode peut être configurée individuellement:

```lua
Config.Methods['laptop'] = {
    enabled = true, -- Activer/désactiver la méthode
    item = 'laptop_hacking', -- Item requis
    removeItem = false, -- Consommer l'item ou non
    minPolice = 1, -- Police requise pour cette méthode
    rewardMin = 3000, -- Gain minimum
    rewardMax = 5000, -- Gain maximum
    -- ... et bien plus
}
```

### Modèles d'ATM Supportés
```lua
Config.ATMs.models = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}
```

## Utilisation

### En jeu
1. Approchez-vous d'un ATM
2. Regardez l'ATM et appuyez sur la touche d'interaction ox_target
3. Sélectionnez "Braquer l'ATM"
4. Choisissez votre méthode (selon les items que vous possédez)
5. Complétez le minijeu skillcheck
6. Récupérez votre récompense

### Commande Admin
```
/giverobberyitem [id] [item] [quantité]
```
Exemple:
```
/giverobberyitem 1 laptop_hacking 1
```

## Système d'Alerte Police

Le système envoie automatiquement des alertes aux policiers selon:
- Le type de méthode utilisée
- Un pourcentage de chance configurable
- Un délai avant l'alerte (sauf C4 qui alerte instantanément)

Les policiers reçoivent:
- Une notification
- Un blip clignotant sur la carte pendant 5 minutes

## Animations et Props

Chaque méthode utilise des animations et props authentiques:
- **Laptop**: Animation de hacking avec laptop
- **Skimmer**: Animation d'installation avec carte
- **C4**: Animation de placement + explosion
- **Chalumeau**: Animation de soudure + levier
- **Drill**: Animation de perçage avec perceuse

## Personnalisation Avancée

### Ajouter une 6ème Méthode
1. Ajoutez la configuration dans `config.lua`:
```lua
Config.Methods['nouvelle_methode'] = {
    enabled = true,
    label = 'Ma Nouvelle Méthode',
    item = 'mon_item',
    -- ... configuration
}
```

2. Créez la fonction dans `client/main.lua`:
```lua
function RobWithNouvelleMethode(atmEntity, atmCoords)
    -- Votre code ici
end
```

3. Ajoutez l'option dans le menu (fonction `OpenRobberyMenu`)

### Intégrer des Logs Discord
Décommentez et configurez la section webhook dans `server/main.lua`:
```lua
local webhookURL = 'VOTRE_WEBHOOK_DISCORD'
```

## Support et Bugs

Si vous rencontrez des problèmes:
1. Vérifiez que toutes les dépendances sont à jour
2. Vérifiez les logs serveur (`F8` console)
3. Assurez-vous que les items sont bien ajoutés dans la base de données

## Crédits

- Développé pour ESX Legacy 1.12.14
- Utilise ox_lib pour les skillchecks
- Utilise ox_target pour l'interaction
- Utilise ox_inventory pour la gestion des items

## Licence

Ce script est fourni tel quel, libre d'utilisation et de modification.

---

**Version**: 1.0.0
**Auteur**: Claude AI
**Compatibilité**: ESX Legacy 1.12.14+
