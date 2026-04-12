import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.potions.IPotion;
import crafttweaker.potions.IPotionEffect;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set
val waitTimeSeconds as int = 3;
val percentDamageBonusForWaiting as double = 0.75; 
val cooldownName as string = "Wait Time Cooldown";

// Weapon Bonus
val fullHealthPercentDamageBonus as double = 0.75;

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "After not dealing damage for " + waitTimeSeconds + " seconds, the next melee attack will deal " + ((percentDamageBonusForWaiting * 100.0) as int) + "% bonus damage.";

val bonusDescriptionFull as string = "Iron and steel weapons deal " + ((fullHealthPercentDamageBonus * 100.0) as int) + "% bonus damage to enemies with full health.";

val material as string = "Iron";

val head as string = "minecraft:iron_helmet";
val chest as string = "minecraft:iron_chestplate";
val legs as string = "minecraft:iron_leggings";
val feet as string = "minecraft:iron_boots";

val weapons as string[] = [
    // Iron Weapons
    "minecraft:iron_sword",
    "spartanweaponry:rapier_iron",
    "spartanweaponry:saber_iron",
    "spartanweaponry:scythe_iron",
    "spartanweaponry:longsword_iron",
    "spartanweaponry:parrying_dagger_iron",
    "minecraft:iron_axe",
    "spartanweaponry:dagger_iron",
    "spartanweaponry:katana_iron",
    "spartanweaponry:greatsword_iron",
    "spartanweaponry:hammer_iron",
    "spartanweaponry:warhammer_iron",
    "spartanweaponry:spear_iron",
    "spartanweaponry:halberd_iron",
    "spartanweaponry:pike_iron",
    "spartanweaponry:lance_iron",
    "spartanweaponry:mace_iron",
    "spartanweaponry:battleaxe_iron",
    "spartanweaponry:glaive_iron",
    "spartanweaponry:staff_iron",
    "spartanweaponry:boomerang_iron",
    "spartanweaponry:crossbow_iron",
    "spartanweaponry:longbow_iron",
    "spartanweaponry:throwing_knife_iron",
    "spartanweaponry:throwing_axe_iron",
    "spartanweaponry:javelin_iron",
    
    // Steel Weapons
    "spartanweaponry:dagger_steel",
    "spartanweaponry:longsword_steel",
    "spartanweaponry:katana_steel",
    "spartanweaponry:scythe_steel",
    "spartanweaponry:saber_steel",
    "spartanweaponry:rapier_steel",
    "spartanweaponry:greatsword_steel",
    "spartanweaponry:hammer_steel",
    "spartanweaponry:warhammer_steel",
    "spartanweaponry:spear_steel",
    "spartanweaponry:halberd_steel",
    "spartanweaponry:pike_steel",
    "spartanweaponry:lance_steel",
    "spartanweaponry:battleaxe_steel",
    "spartanweaponry:mace_steel",
    "spartanweaponry:glaive_steel",
    "spartanweaponry:staff_steel",
    "spartanweaponry:parrying_dagger_steel",
    "spartanweaponry:boomerang_steel",
    "spartanweaponry:crossbow_steel",
    "spartanweaponry:longbow_steel",
    "spartanweaponry:throwing_knife_steel",
    "spartanweaponry:throwing_axe_steel",
    "spartanweaponry:javelin_steel"
];

// ==========================================
// REGISTER
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

// 2 pieces of armor for partial
SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
// 4 pieces of armor for full description
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName);
// 4 pieces of armor + 1 weapon for weapon bonus
SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    // Ensure the damage comes from a valid entity (prevents crash from fall/fire damage)
    if (isNull(attackerEntity)) {
        return;
    }
    
    // ATTACKER LOGIC
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (isNull(attacker) == false) {
            
            // ---------------------------------------------------------
            // Partial Set (2/4) - Patient Strike
            // ---------------------------------------------------------
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                // Only trigger on melee attacks
                if (damageSource.isProjectile() == false) {
                    
                    // If the cooldown is completely finished, apply the massive damage bonus
                    if (attacker.onCooldown(cooldownName) == false) {
                        attacker.debugMessage(material + " Armor: Cooldown finished! Bonus damage applied.");
                        event.amount = event.amount * (1.0 + percentDamageBonusForWaiting);
                    }

                    // Regardless of whether they got the bonus or not, hitting someone resets the timer
                    attacker.startCooldown(cooldownName, waitTimeSeconds * 20);
                }
            }
            
            // ---------------------------------------------------------
            // Full Set (4/4 + Weapon) - Full Health Executioner
            // ---------------------------------------------------------
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                // Check if target is at exactly maximum health
                if (!isNull(targetEntity) && targetEntity.health == targetEntity.maxHealth) {
                    attacker.debugMessage(material + " Weapon: Target at full health! Execution damage applied.");
                    event.amount = event.amount * (1.0 + fullHealthPercentDamageBonus);
                }
            }
        }
    }
});