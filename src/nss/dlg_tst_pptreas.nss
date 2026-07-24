// Test: pptreas_open.nss bug (reversed quantity comparisons)
// Simulates 1000 rolls with both the old and fixed logic, prints distribution
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== pptreas_open: quantity distribution (1000 rolls) ===");

    int bChanceTwo   = 75;
    int bChanceThree = 50;
    int bChanceFour  = 25;

    int n1Old=0, n2Old=0, n3Old=0, n4Old=0;
    int n1Fix=0, n2Fix=0, n3Fix=0, n4Fix=0;
    int i;
    for (i = 0; i < 1000; i++)
    {
        int r = d100();

        // Old (buggy) logic
        if      (bChanceFour  <= r) n4Old++;
        else if (bChanceThree <= r) n3Old++;
        else if (bChanceTwo   <= r) n2Old++;
        else                        n1Old++;

        // Fixed logic (nested ifs, <= comparisons)
        if (r <= bChanceTwo)
        {
            if (r <= bChanceThree)
            {
                if (r <= bChanceFour) n4Fix++;
                else                  n3Fix++;
            }
            else n2Fix++;
        }
        else n1Fix++;
    }

    SendMessageToPC(oPC, "BUGGY  — 1:" + IntToString(n1Old) + " 2:" + IntToString(n2Old)
        + " 3:" + IntToString(n3Old) + " 4:" + IntToString(n4Old)
        + " (expect ~240/0/0/760 if bug present)");
    SendMessageToPC(oPC, "FIXED  — 1:" + IntToString(n1Fix) + " 2:" + IntToString(n2Fix)
        + " 3:" + IntToString(n3Fix) + " 4:" + IntToString(n4Fix)
        + " (expect ~250/250/250/250)");

    int bPass = (n4Old > 650 && n2Old < 50 && n3Old < 50 &&
                 n2Fix > 150 && n3Fix > 150 && n4Fix > 150);
    SendMessageToPC(oPC, "RESULT: " + (bPass ? "PASS (bug confirmed, fix verified)" : "UNEXPECTED — check numbers"));
}
