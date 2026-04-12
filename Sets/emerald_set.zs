import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4) - Potion Damage Scaling
val damageBonusPerPotion as double = 0.05;

// Full Set (4/4) - Random Self-Buffs
val buffProcChance as double = 0.20;
val buffDurationTicks as int = 200;
val buffAmplifier as int = 0;        // Level 1 (0 = I, 1 = II)

// The pool of possible buffs (Vanilla + Potion Core)
val emeraldBuffs as string[] = [
    "minecraft:speed",
    "minecraft:haste",
    "minecraft:strength",
    "minecraft:jump_boost",
    "minecraft:regeneration",
    "minecraft:resistance",
    "minecraft:fire_resistance",
    "minecraft:water_breathing",
    "minecraft:invisibility",
    "minecraft:night_vision",
    "minecraft:health_boost",
    "minecraft:absorption",
    "minecraft:glowing",
    "minecraft:luck",
    "potioncore:diamond_skin",
    "potioncore:iron_skin",
    "potioncore:magic_focus",
    "potioncore:step_up",
    "potioncore:reach"
];

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Deal " + ((damageBonusPerPotion * 100.0) as int) + "% bonus damage for EVERY active potion effect you have.";

val bonusDescriptionFull as string = "Emerald weapons have a " + ((buffProcChance * 100.0) as int) + "% chance to grant a random positive Potion Effect when attacking.";

val material as string = "Emerald";

val head as string = "shinygear:emerald_helmet";
val chest as string = "shinygear:emerald_chestplate";
val legs as string = "shinygear:emerald_leggings";
val feet as string = "shinygear:emerald_boots";

val weapons as string[] = [
    "shinygear:emerald_battleaxe",
    "shinygear:emerald_sword",
    "shinygear:emerald_axe",
    "shinygear:emerald_dagger",
    "shinygear:emerald_katana",
    "shinygear:emerald_warhammer",
    "shinygear:emerald_greatsword",
    "shinygear:emerald_halberd",
    "shinygear:emerald_spear",
    "shinygear:emerald_hammer",
    "shinygear:emerald_lance",
    "shinygear:emerald_crossbow",
    "shinygear:emerald_saber",
    "shinygear:emerald_rapier",
    "shinygear:emerald_longbow",
    "shinygear:emerald_longsword",
    "shinygear:emerald_pike",
    "shinygear:emerald_throwing_knife",
    "shinygear:emerald_throwing_axe",
    "shinygear:emerald_javelin",
    "shinygear:emerald_mace"
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
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // ATTACKER LOGIC
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker)) {
            
            // ---------------------------------------------------------
            // Partial Set (2/4) - Infinite Potion Damage Scaling
            // ---------------------------------------------------------
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                // Get all active potion effects on the attacker
                val activeEffects = attacker.activePotionEffects;
                
                if (!isNull(activeEffects)) {
                    val effectCount = activeEffects.length;
                    
                    if (effectCount > 0) {
                        val totalBonus as double = (effectCount as double) * damageBonusPerPotion;
                        
                        attacker.debugMessage(material + " Armor: +" + ((totalBonus * 100.0) as int) + "% damage from " + effectCount + " potions.");
                        event.amount = event.amount * (1.0 + totalBonus);
                    }
                }
            }
            
            // ---------------------------------------------------------
            // Full Set (4/4 + Weapon Check) - Random Self Buff
            // ---------------------------------------------------------
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
                        
                        val world = attacker.world;
                        if (!isNull(world)) {
                            val rand = world.getRandom();
                            
                            if (!isNull(rand)) {
                                // Roll the dice for the 20% chance
                                if (rand.nextFloat() <= buffProcChance) {
                                    
                                    // Pick a random buff from the array
                                    val buffIndex = rand.nextInt(emeraldBuffs.length);
                                    val chosenBuff = emeraldBuffs[buffIndex];
                                    
                                    attacker.debugMessage(material + " Weapon: Granted " + chosenBuff + " buff!");
                                    attacker.applyPotionEffect(chosenBuff, buffDurationTicks, buffAmplifier);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
});