// Test: inc_adventurer.nss bug (SelectAdventurerPath path-1 bias)
// Simulates 3 paths with weights 60/110/150 (total=320) 1000 times
// and shows the distribution under both the old and fixed algorithms.
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_adventurer: path selection (1000 runs) ===");
    SendMessageToPC(oPC, "Paths: w1=60 w2=110 w3=150 expect ~188/344/469");

    int n1Bug=0, n2Bug=0, n3Bug=0, nXBug=0;
    int n1Fix=0, n2Fix=0, n3Fix=0, nXFix=0;
    int w1=60, w2=110, w3=150;
    int nTotal = 320;
    int i, nRandom, nPath;

    for (i = 0; i < 1000; i++)
    {
        // Buggy algorithm: skips when nRandom==0, biases path 1
        nRandom = Random(nTotal);
        int j = 0;
        if (nRandom > 0) { nRandom -= w1; j++; }
        if (nRandom > 0) { nRandom -= w2; j++; }
        if (nRandom > 0) { nRandom -= w3; j++; }
        nPath = j + 1;
        if      (nPath == 1) n1Bug++;
        else if (nPath == 2) n2Bug++;
        else if (nPath == 3) n3Bug++;
        else                 nXBug++;

        // Fixed algorithm: subtract then break on negative
        nRandom = Random(nTotal);
        j = 0;
        nRandom -= w1; if (nRandom < 0) { j = 0; }
        else { nRandom -= w2; if (nRandom < 0) { j = 1; }
        else { nRandom -= w3; if (nRandom < 0) { j = 2; }
        else                                   { j = 3; } } }
        nPath = j + 1;
        if      (nPath == 1) n1Fix++;
        else if (nPath == 2) n2Fix++;
        else if (nPath == 3) n3Fix++;
        else                 nXFix++;
    }

    SendMessageToPC(oPC, "BUGGY  path1:" + IntToString(n1Bug) + " path2:" + IntToString(n2Bug)
        + " path3:" + IntToString(n3Bug) + " invalid:" + IntToString(nXBug));
    SendMessageToPC(oPC, "FIXED  path1:" + IntToString(n1Fix) + " path2:" + IntToString(n2Fix)
        + " path3:" + IntToString(n3Fix) + " invalid:" + IntToString(nXFix));

    int bPass = (n1Fix > 130 && n1Fix < 250 && n2Fix > 270 && n3Fix > 370 && nXFix == 0);
    SendMessageToPC(oPC, "RESULT: " + (bPass ? "PASS" : "FAIL"));
}
