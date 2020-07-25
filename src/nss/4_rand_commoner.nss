#include "nwnx_creature"

void main()
{
    switch (d6())
    {
        case 1:
        break;
        case 2:
            SetPortraitResRef(OBJECT_SELF, "po_hu_m_02_");
            SetCreatureAppearanceType(OBJECT_SELF, 226);
            NWNX_Creature_SetSoundset(OBJECT_SELF, 189);
        break;
        case 3:
            NWNX_Creature_SetGender(OBJECT_SELF, GENDER_FEMALE);
            SetPortraitResRef(OBJECT_SELF, "po_hu_f_19_");
            SetCreatureAppearanceType(OBJECT_SELF, 256);
            NWNX_Creature_SetSoundset(OBJECT_SELF, 149);
        break;
        case 4:
            NWNX_Creature_SetGender(OBJECT_SELF, GENDER_FEMALE);
            SetPortraitResRef(OBJECT_SELF, "po_hu_f_02_");
            SetCreatureAppearanceType(OBJECT_SELF, 223);
            NWNX_Creature_SetSoundset(OBJECT_SELF, 166);
        break;
        case 5:
            SetPortraitResRef(OBJECT_SELF, "po_hu_m_29_");
            SetCreatureAppearanceType(OBJECT_SELF, 239);
            NWNX_Creature_SetSoundset(OBJECT_SELF, 124);
        break;
        case 6:
            NWNX_Creature_SetGender(OBJECT_SELF, GENDER_FEMALE);
            SetPortraitResRef(OBJECT_SELF, "po_hu_f_03_");
            SetCreatureAppearanceType(OBJECT_SELF, 240);
            NWNX_Creature_SetSoundset(OBJECT_SELF, 150);
        break;
    }
}
