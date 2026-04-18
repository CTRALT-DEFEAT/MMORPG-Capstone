# MMORPG-Capstone
> The projects goal was to create a MySQL database modeled after a
> massively multiplayer online role-playing game (MMORPG).

## The Business Needs:
* Players create characters that belong to their account.
    * Players may have multiple characters.
    * Characters have attributes like race, class, level, experience, and           specialization.
        * Specialization is like a “class upgrade”. Not all characters will             have one, but the ones they’re allowed to select are dependent on             their class.
        * Characters may only have up to one specialization.
        * There is some specialization overlap. Characters with the “Hunter”            or “Warrior” class are both allowed to choose the “Ranger”                    specialization, but Hunters aren’t allowed to choose the                      “Berserker” specialization because it’s only available to Warriors.
* Characters can belong to a guild.
    * Guilds have names, messages of the day, and ranks.
    * All guilds have a “Guild leader” rank, which can only be held by one          member.
    * The other ranks are “Officer”, “Member”, and “Recruit”. Any number of         guild members can have these ranks.
    * Guild membership and rank history should be preserved.
* Characters gain experience points (XP) through game play, which is used to    determine their level.
    * Each level has a fixed amount of XP required to attain the next level.
    * XP is earned through quests and combat.
    * Each XP-gaining activity should be tracked as a timestamped event for         auditing purposes.
* Quests can be accepted and completed by characters.
    * (For purposes of simplicity, you may assume that the only possible            quest states are “unaccepted”, “accepted”, and “completed”. If you want       to expand that list to include others such as “failed”, “repeatable”,         or others, you may but there’s no extra credit for it.)
    * Quests have names and descriptions.
    * To accept a quest, the character may have had to complete one or more         other quests first.
    * All quests are dispensed by a Non-Player-Character (NPC).
        * NPCs have names and coordinates for their location.
    * Quests may have rewards (XP and/or gold and/or items).

* Characters collect and equip items.
    * Items may be equipped into specific “equipment slots”, such as “head”,        “chest”, “legs”, or “main hand”.
    * Items have a current and maximum durability. The current durability may       never exceed the maximum. Current durability is consumed through item         usage (such as combat).
    * Items may have one or more requirements and/or restrictions to equip,         such as having a specific race, class, specialization, minimum or             maximum level.
    * Sample requirement: “Pendant of Avarice” may only be equipped by              characters of the Goblin race.
    * Sample restriction: “Holy Sword” may not be equipped by players with          the Necromancer class or Death Knight specialization.
      Items cannot be equipped if they have zero current durability.
* Items can be traded between characters or sold to NPCs.
    * All items have a fixed price that an NPC will pay for it. All NPCs pay        the same amount.
    * The game stores a complete record of trade history for all items: an          items’ entire ownership history should be traceable from its creation         to its disappearance.
    * Items can come from quests as rewards, from slain enemies as loot, or         purchased from NPCs.
* Gold is a currency in the game. It is a non-negative whole number.
    * Players may earn it from quest rewards, slain monster loot, or trade.
    * Players may spend it on item repairs or trade.
    * All transactions must be recorded.
* Players may send chat messages.
    * Chat messages may be direct from player to player or sent to multi-           player channels such as “guild chat” or “everyone currently in the city       of Urdia”.
    * A complete history of chat messages must be kept and easily searchable        for offensive or abusive content.

## The ERD:
> With the set of business needs as a guide our first task was to design and
> create an ERD to base our database off of.

![ERD](/docs/ERD/ERD.png)

> [!NOTE]
> We chose to color code the ERD for improved readability, with the color of
> lines being the same as the parent tables.
>
> The groups of the ERD
> | Color     | Group              |
> | --------- | -------------- | 
> | Light Pink | Guilds | 
> | Purple | Chats |  
> | Dark Green | NPC's/Mobs/Quests | 
> | Light Green | Regions/Zones/Factions |
> | Gold | Items/Loot_Tables/Rewards |  
> | Orange | Trades |
> | Brown | Restrictions | 
> | Light Purple | Modifiers | 
> | Turquoise | Combat | 
> | Blue |Accounts/Characters/Character_Attributes |
>

## Generation Script:
[The Generation Script](scripts/gen.sql)

> The generaction script starts by creating the database
> then creates all 51 tables.
> next we create all 42 procedures for randomly generating data
> The last section of the generation script is calling all the procedures
> as well as adding insert statements for data that isnt randomly generated
> (i.e. classes, races etc)

ADD HIGHLIGHTED SECTIONS




