import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import mods.mahzenutils.Stacks; // <-- YOUR CUSTOM MOD IMPORT

// ==========================================
// BALANCING
// ==========================================

val healthThreshold as double = 0.50; // 50% health threshold for both bonuses
val copperStackId as string = "copper_fury_stacks";

// Partial Set (2/4) - Berserker Stacks
val maxCopperStacks as int = 10;
val mitigationPerStack as double = 0.02; // 2% less damage taken per stack (20% Max)
val damageBoostPerStack as double = 0.03; // 3% more damage dealt per stack (30% Max)

// Full Set (4/4 + Weapon) - Overclocked Strikes
val flatWeaponBonus as double = 0.25; // 25% flat damage boost for using Copper
val recoilPercentage as double = 0.15; // 15% of damage dealt is taken as recoil when above 50% health

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "While below " + ((healthThreshold * 100.0) as int) + "% health gain 1 stack of Fury every second (Max " + maxCopperStacks + "). Each stack grants " + ((mitigationPerStack * 100.0) as int) + "% damage reduction and " + ((damageBoostPerStack * 100.0) as int) + "% bonus damage. Healing above the threshold removes 1 stack per second.";

val bonusDescriptionFull as string = "Copper weapons deal " + ((flatWeaponBonus * 100.0) as int) + "% bonus damage. If your health is above " + ((healthThreshold * 100.0) as int) + "% attacking drains your life force dealing recoil damage equal to " + ((recoilPercentage * 100.0) as int) + "% of your damage dealt. This recoil cannot drop you below the health threshold.";

val material as string = "Copper";

// Ice and Fire Armor
val head as string = "iceandfire:armor_copper_metal_helmet";
val chest as string = "iceandfire:armor_copper_metal_chestplate";
val legs as string = "iceandfire:armor_copper_metal_leggings";
val feet as string = "iceandfire:armor_copper_metal_boots";

// Ice and Fire + Spartan Weaponry
val weapons as string[] = [
    "iceandfire:copper_sword",
    "iceandfire:copper_axe",
    "spartanweaponry:dagger_copper",
    "spartanweaponry:longsword_copper",
    "spartanweaponry:katana_copper",
    "spartanweaponry:scythe_copper",
    "spartanweaponry:saber_copper",
    "spartanweaponry:rapier_copper",
    "spartanweaponry:greatsword_copper",
    "spartanweaponry:hammer_copper",
    "spartanweaponry:warhammer_copper",
    "spartanweaponry:spear_copper",
    "spartanweaponry:halberd_copper",
    "spartanweaponry:pike_copper",
    "spartanweaponry:lance_copper",
    "spartanweaponry:battleaxe_copper",
    "spartanweaponry:mace_copper",
    "spartanweaponry:glaive_copper",
    "spartanweaponry:staff_copper",
    "spartanweaponry:parrying_dagger_copper",
    "spartanweaponry:boomerang_copper",
    "spartanweaponry:crossbow_copper",
    "spartanweaponry:longbow_copper",
    "spartanweaponry:throwing_knife_copper",
    "spartanweaponry:throwing_axe_copper",
    "spartanweaponry:javelin_copper"
];

// ==========================================
// UNIVERSAL REGISTER BLOCK
// ==========================================

val armorSetName as string = material + " Armor Set";
val weaponSetName as string = material + " Weapon Set";

val armorBonusNamePartial as string = material + " Armor Partial Bonus";
val armorBonusNameFull as string = material + " Armor Full Bonus";
val weaponBonusName as string = material + " Weapon Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

SB.addEquipToSet(weaponSetName, "mainhand", weapons);

SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// STACK REGISTRY
// ==========================================

// Registering the stack so the backend accepts modifications
Stacks.registerStack(copperStackId, maxCopperStacks, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT (For 2/4 Stack Generation/Clearing)
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END") {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNamePartial) == true) {
            
            if (player.onCooldown("copper_regen_tick") == false) {
                
                val currentPercentage as double = (player.health as double) / (player.maxHealth as double);
                val currentStacks = player.getStacks(copperStackId);
                
                if (currentPercentage <= (healthThreshold + 0.005)) {
                    if (currentStacks < maxCopperStacks) {
                        
                        player.addStacks(copperStackId, 1);
                        player.debugMessage(material + " Armor: Gained Fury stack (" + (currentStacks + 1) + "/" + maxCopperStacks + ")");
                    }
                } else {
                    if (currentStacks > 0) {
                        player.removeStacks(copperStackId, 1);
                        player.debugMessage(material + " Armor: Health stabilized. Lost 1 Fury stack (" + (currentStacks - 1) + " remaining).");
                    }
                }
                
                player.startCooldown("copper_regen_tick", 20);
            }
        }
    }
});

// 2. COMBAT EVENT
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(targetEntity)) {
        return; 
    }
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC (2/4 - Stack Mitigation)
    // ---------------------------------------------------------
    if (targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(defender) && defender.hasSetBonus(armorBonusNamePartial) == true) {
            val stacks = defender.getStacks(copperStackId);
            
            if (stacks > 0) {
                val reduction as double = (stacks as double) * mitigationPerStack;
                event.amount = event.amount * (1.0 - reduction);
                defender.debugMessage(material + " Armor: Mitigated " + ((reduction * 100.0) as int) + "% incoming damage.");
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (!isNull(attackerEntity) && attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            // Apply 2/4 Stack Damage Boost universally if active
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                val stacks = attacker.getStacks(copperStackId);
                
                if (stacks > 0) {
                    val boost as double = (stacks as double) * damageBoostPerStack;
                    event.amount = event.amount * (1.0 + boost);
                    attacker.debugMessage(material + " Armor: +" + ((boost * 100.0) as int) + "% fury damage boost.");
                }
            }
            
            // INTERSECTION BONUS: 4/4 + Weapon Logic
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                // 1. Apply Flat Weapon Bonus
                event.amount = event.amount * (1.0 + flatWeaponBonus);
                
                // 2. Recoil Logic
                val currentHealth as float = attacker.health;
                val maximumHealth as float = attacker.maxHealth;
                val currentPercentage as double = (currentHealth as double) / (maximumHealth as double);
                
                if (currentPercentage > healthThreshold) {
                    
                    val proposedRecoil as float = event.amount * (recoilPercentage as float);
                    val targetHealthFloor as float = maximumHealth * (healthThreshold as float);
                    val availableHealthToBurn as float = currentHealth - targetHealthFloor;
                    
                    if (availableHealthToBurn > 0.0) {
                        var actualRecoil = proposedRecoil;
                        
                        // Clamp recoil so it never pushes health below the 50% line
                        if (actualRecoil > availableHealthToBurn) {
                            actualRecoil = availableHealthToBurn;
                        }
                        
                        attacker.health = currentHealth - actualRecoil;
                        attacker.debugMessage(material + " Weapon: Suffered " + actualRecoil + " recoil damage.");
                    }
                }
            }
        }
    }
});