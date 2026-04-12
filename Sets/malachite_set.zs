import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4) - Target Effect Damage Scaling
val damageBonusPerEffect as double = 0.05;

// Full Set (4/4) - Random Target Debuffs
val debuffProcChance as double = 0.25;
val debuffDurationTicks as int = 100;
val debuffAmplifier as int = 0; // Level 1 (0 = I, 1 = II)

// The pool of possible debuffs (Vanilla + Potion Core)
val malachiteDebuffs as string[] = [
    "minecraft:slowness",
    "minecraft:mining_fatigue",
    "minecraft:nausea",
    "minecraft:blindness",
    "minecraft:hunger",
    "minecraft:weakness",
    "minecraft:poison",
    "minecraft:wither",
    "minecraft:levitation",
    "minecraft:glowing",
    "potioncore:broken_armor",
    "potioncore:broken_magic_shield",
    "potioncore:weight",
    "potioncore:vulnerable",
    "potioncore:rust",
    "potioncore:klutz",
    "potioncore:spin",
    "potioncore:perplexity"
];

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Deal " + ((damageBonusPerEffect * 100.0) as int) + "% bonus damage for EVERY active potion effect on your target.";

val bonusDescriptionFull as string = "Malachite weapons have a " + ((debuffProcChance * 100.0) as int) + "% chance to inflict a random negative Potion Effect on the enemy when attacking.";

val material as string = "Malachite";

val head as string = "shinygear:malachite_helmet";
val chest as string = "shinygear:malachite_chestplate";
val legs as string = "shinygear:malachite_leggings";
val feet as string = "shinygear:malachite_boots";

val weapons as string[] = [
    "shinygear:malachite_battleaxe",
    "shinygear:malachite_sword",
    "shinygear:malachite_axe",
    "shinygear:malachite_dagger",
    "shinygear:malachite_katana",
    "shinygear:malachite_warhammer",
    "shinygear:malachite_greatsword",
    "shinygear:malachite_halberd",
    "shinygear:malachite_spear",
    "shinygear:malachite_hammer",
    "shinygear:malachite_lance",
    "shinygear:malachite_crossbow",
    "shinygear:malachite_saber",
    "shinygear:malachite_rapier",
    "shinygear:malachite_longbow",
    "shinygear:malachite_longsword",
    "shinygear:malachite_pike",
    "shinygear:malachite_throwing_knife",
    "shinygear:malachite_throwing_axe",
    "shinygear:malachite_javelin",
    "shinygear:malachite_mace"
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
            // Partial Set (2/4) - Target Effect Damage Scaling
            // ---------------------------------------------------------
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                // Get all active potion effects on the TARGET
                val activeEffects = targetEntity.activePotionEffects;
                
                if (!isNull(activeEffects)) {
                    val effectCount = activeEffects.length;
                    
                    if (effectCount > 0) {
                        // Explicitly cast to double to prevent primitive coercion rounding bugs
                        val totalBonus as double = (effectCount as double) * damageBonusPerEffect;
                        
                        attacker.debugMessage(material + " Armor: +" + ((totalBonus * 100.0) as int) + "% damage from " + effectCount + " effects on target.");
                        event.amount = event.amount * (1.0 + totalBonus);
                    }
                }
            }
            
            // ---------------------------------------------------------
            // Full Set (4/4 + Weapon Check) - Random Target Debuff
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
                                // Roll the dice for the chance to apply
                                if (rand.nextFloat() <= debuffProcChance) {
                                    
                                    // Pick a random debuff from the array
                                    val debuffIndex = rand.nextInt(malachiteDebuffs.length);
                                    val chosenDebuff = malachiteDebuffs[debuffIndex];
                                    
                                    attacker.debugMessage(material + " Weapon: Inflicted " + chosenDebuff + " on target!");
                                    
                                    // Apply the debuff to the TARGET using your custom Java expansion
                                    targetEntity.applyPotionEffect(chosenDebuff, debuffDurationTicks, debuffAmplifier);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
});