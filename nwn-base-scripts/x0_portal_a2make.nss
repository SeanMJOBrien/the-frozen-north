//::///////////////////////////////////////////////
//:: x0_portal_a2make
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Creates this anchor.
*/
//:://////////////////////////////////////////////
//:: Created By:
//:: Created On:
//:://////////////////////////////////////////////
#include "x0_inc_portal"

void main()
{
    PortalCreateAnchor(2, OBJECT_SELF);
        PortalTakeRogueStone(GetPCSpeaker());
}