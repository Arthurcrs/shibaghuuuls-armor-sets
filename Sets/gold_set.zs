import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4) - Passive Absorption
val passiveRegenSeconds as int = 5; 
val combatPauseTicks as int = 1200; // 60 seconds (1200 ticks) pause on regen after taking damage
val maxAbsorptionLevel as int = 3;  // Level 3 is "Absorption IV"
val absorptionDurationTicks as int = 2400; 

// Full Set (4/4) - Exact Absorption Scaling
val damageBonusPerAbsorptionPoint as double = 0.05; // Bonus damage per point

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Gain 1 level of Absorption for every " + passiveRegenSeconds + " seconds you do not take damage (Max Level " + (maxAbsorptionLevel + 1) + "). Taking damage halts regeneration for 60 seconds.";

val bonusDescriptionFull as string = "Gold weapons deal bonus damage scaling directly with the exact amount of Absorption health you currently possess.";

val material as string = "Gold";

val head as string = "minecraft:golden_helmet";
val chest as string = "minecraft:golden_chestplate";
val legs as string = "minecraft:golden_leggings";
val feet as string = "minecraft:golden_boots";

val weapons as string[] = [
    "minecraft:golden_sword",
    "minecraft:golden_axe",
    "spartanweaponry:dagger_gold",
    "spartanweaponry:longsword_gold",
    "spartanweaponry:katana_gold",
    "spartanweaponry:scythe_gold",
    "spartanweaponry:saber_gold",
    "spartanweaponry:rapier_gold",
    "spartanweaponry:greatsword_gold",
    "spartanweaponry:hammer_gold",
    "spartanweaponry:warhammer_gold",
    "spartanweaponry:spear_gold",
    "spartanweaponry:halberd_gold",
    "spartanweaponry:pike_gold",
    "spartanweaponry:lance_gold",
    "spartanweaponry:battleaxe_gold",
    "spartanweaponry:mace_gold",
    "spartanweaponry:glaive_gold",
    "spartanweaponry:staff_gold",
    "spartanweaponry:parrying_dagger_gold",
    "spartanweaponry:boomerang_gold",
    "spartanweaponry:crossbow_gold",
    "spartanweaponry:longbow_gold",
    "spartanweaponry:throwing_knife_gold",
    "spartanweaponry:throwing_axe_gold",
    "spartanweaponry:javelin_gold"
];

// ==========================================
// UNIVERSAL REGISTER BLOCK (DO NOT EDIT)
// ==========================================

val armorSetName as string = material + " Armor Set";
val armorBonusNamePartial as string = material + " Armor Partial Bonus";
val armorBonusNameFull as string = material + " Armor Full Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT (For 2/4 Absorption Regeneration)
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END" && event.player.world.time % 20 == 0) {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNamePartial) == true) {
            
            if (player.onCooldown("gold_combat_pause") == false) {
                if (player.onCooldown("gold_regen_tick") == false) {
                    
                    val currentAmp = player.getPotionAmplifier("minecraft:absorption");
                    var nextAmp = 0;
                    
                    if (currentAmp >= 0) {
                        nextAmp = currentAmp + 1;
                    }
                    
                    if (nextAmp > maxAbsorptionLevel) {
                        nextAmp = maxAbsorptionLevel;
                    }
                    
                    player.applyPotionEffect("minecraft:absorption", absorptionDurationTicks, nextAmp);
                    
                    if (currentAmp < maxAbsorptionLevel) {
                        player.debugMessage(material + " Armor: Gained Absorption Level " + (nextAmp + 1));
                    }
                    
                    player.startCooldown("gold_regen_tick", passiveRegenSeconds * 20);
                }
            }
        }
    }
});

// 2. COMBAT EVENT (For 4/4 Damage Bonus & Timer Reset)
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC (Resetting the timer on hit)
    // ---------------------------------------------------------
    if (targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(defender)) {
            if (defender.hasSetBonus(armorBonusNamePartial) == true) {
                defender.startCooldown("gold_combat_pause", combatPauseTicks);
                defender.startCooldown("gold_regen_tick", passiveRegenSeconds * 20);
                
                defender.debugMessage(material + " Armor: Regeneration paused for " + (combatPauseTicks / 20) + " seconds.");
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC (4/4 + Weapon Check) - True Health Scaling
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker)) {
            if (attacker.hasSetBonus(armorBonusNameFull) == true) {
                
                val heldItem = attacker.mainHandHeldItem;
                
                if (!isNull(heldItem)) {
                    var holdingValidWeapon = false;
                    val heldId = heldItem.definition.id;
                    
                    for wep in weapons {
                        if (heldId == wep) {
                            holdingValidWeapon = true;
                            break;
                        }
                    }
                    
                    if (holdingValidWeapon && event.amount > 0) {
                        
                        val currentAbsorption = attacker.getTrueAbsorptionAmount();
                        
                        if (currentAbsorption > 0.0) {
                            val totalBonus as double = (currentAbsorption as double) * damageBonusPerAbsorptionPoint;
                            
                            attacker.debugMessage(material + " Weapon: +" + ((totalBonus * 100.0) as int) + "% damage from " + currentAbsorption + " Absorption points");
                            event.amount = event.amount * (1.0 + totalBonus);
                        }
                    }
                }
            }
        }
    }
});