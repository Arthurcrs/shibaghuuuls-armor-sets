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

// Partial Set (2/4)
val healthThresholdPercent as double = 0.5; // Triggers when at or below
val diamondSkinDurationTicks as int = 200;
val diamondSkinAmplifier as int = 2; // Diamond Skin II each level is 4 points
val cooldownName as string = "Diamond Armor Cooldown";
val cooldownSeconds as int = 60;

// Full Set + Weapon
val percentDamageBonusPerToughness as double = 0.02;

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "When health drops below 50% gain Diamond Skin for " + (diamondSkinDurationTicks/20) + " seconds. Cooldown: " + cooldownSeconds + "s.";

val bonusDescriptionFull as string = "Diamond weapons deal " + ((percentDamageBonusPerToughness * 100.0) as int) + "% bonus damage for every point of Armor Toughness you possess.";

val material as string = "Diamond";

val head as string = "minecraft:diamond_helmet";
val chest as string = "minecraft:diamond_chestplate";
val legs as string = "minecraft:diamond_leggings";
val feet as string = "minecraft:diamond_boots";

val weapons as string[] = [
    "minecraft:diamond_sword",
    "minecraft:diamond_axe",
    "spartanweaponry:rapier_diamond",
    "spartanweaponry:saber_diamond",
    "spartanweaponry:scythe_diamond",
    "spartanweaponry:longsword_diamond",
    "spartanweaponry:parrying_dagger_diamond",
    "spartanweaponry:dagger_diamond",
    "spartanweaponry:katana_diamond",
    "spartanweaponry:greatsword_diamond",
    "spartanweaponry:hammer_diamond",
    "spartanweaponry:warhammer_diamond",
    "spartanweaponry:spear_diamond",
    "spartanweaponry:halberd_diamond",
    "spartanweaponry:pike_diamond",
    "spartanweaponry:lance_diamond",
    "spartanweaponry:mace_diamond",
    "spartanweaponry:battleaxe_diamond",
    "spartanweaponry:glaive_diamond",
    "spartanweaponry:staff_diamond",
    "spartanweaponry:boomerang_diamond",
    "spartanweaponry:crossbow_diamond",
    "spartanweaponry:longbow_diamond",
    "spartanweaponry:throwing_knife_diamond",
    "spartanweaponry:throwing_axe_diamond",
    "spartanweaponry:javelin_diamond"
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

    // ---------------------------------------------------------
    // DEFENDER LOGIC: Partial Set (2/4) - Diamond Skin Proc
    // ---------------------------------------------------------
    if (!isNull(targetEntity) && targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();

        if (defender.hasSetBonus(armorBonusNamePartial) == true) {
            // Check health threshold
            if (defender.getHealthPercentage() <= healthThresholdPercent) {
                // Check cooldown
                if (defender.onCooldown(cooldownName) == false) {
                    defender.debugMessage(material + " Armor: Critical health! Hardening skin.");
                    defender.startCooldown(cooldownName, cooldownSeconds * 20);
                    defender.applyPotionEffect("potioncore:diamond_skin", diamondSkinDurationTicks, diamondSkinAmplifier);
                }
            }
        }
    }

    // ---------------------------------------------------------
    // ATTACKER LOGIC: Full Set (4/4 + Weapon) - Toughness Scaling
    // ---------------------------------------------------------
    if (!isNull(attackerEntity) && attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();

        if (attacker.hasSetBonus(weaponBonusName) == true) {
            // Fetch current armor toughness
            val currentToughness = attacker.getAttributeValue("generic.armorToughness", 0.0);

            if (currentToughness > 0.0) {
                // Calculate percentage increase
                val percentageIncrease = currentToughness * percentDamageBonusPerToughness;

                attacker.debugMessage(material + " Weapon: +" + ((percentageIncrease * 100.0) as int) + "% damage from " + currentToughness + " Armor Toughness");

                // Apply bonus damage
                event.amount = event.amount * (1.0 + percentageIncrease);
            }
        }
    }
});