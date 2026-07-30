# System GDD: Loot, Items & Equipment

Status: Planned for Batch 3  
ID: SYS-07

ItemDefinition owns stable identity, slot, rarity weights, base stats, affix pool, tags, set and art reference. ItemInstance owns a unique ID, rolled rarity/affixes, acquired source, lock state and equipped state. UI never duplicates combat totals; it asks the profile/modifier service for before/after values.

Initial slots: pháp kiếm, hộ tâm kính, đạo bào and linh giới. Rarity: Phàm, Linh, Huyền, Địa, Thiên. Encounter tier, elite/boss flag, stage difficulty and first-clear state select a loot table. Drops animate in world, are collected into the run reward bundle, then become durable only on the result screen.

Required actions: inspect, compare, equip, unequip, sort/filter and salvage. Salvage returns Huyền Thiết; it never silently destroys a locked/equipped item. Items must change combat through the shared modifier/tag contract before their menu can be considered complete.
