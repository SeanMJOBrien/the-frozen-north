// Test: inc_treasuremap.nss bug A (SQL WHERE puzzleid <= vs =)
// Queries with both clauses for puzzleid=2 and prints the results.
// If a puzzle 1 exists with a different minacr than puzzle 2, they will differ
// when the <= bug is present.
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_treasuremap: SQL puzzleid query ===");

    int nTestID = 2;

    string sQueryBug = "SELECT minacr FROM treasuremaps WHERE puzzleid <= " + IntToString(nTestID);
    string sQueryFix = "SELECT minacr FROM treasuremaps WHERE puzzleid = "  + IntToString(nTestID);

    sqlquery sqlBug = SqlPrepareQueryCampaign("tmapsolutions", sQueryBug);
    sqlquery sqlFix = SqlPrepareQueryCampaign("tmapsolutions", sQueryFix);

    int nMinACRBug = -1;
    int nMinACRFix = -1;

    if (SqlStep(sqlBug)) nMinACRBug = SqlGetInt(sqlBug, 0);
    if (SqlStep(sqlFix)) nMinACRFix = SqlGetInt(sqlFix, 0);

    SendMessageToPC(oPC, "puzzleid <= " + IntToString(nTestID) + " -> minacr=" + IntToString(nMinACRBug));
    SendMessageToPC(oPC, "puzzleid =  " + IntToString(nTestID) + " -> minacr=" + IntToString(nMinACRFix));

    if (nMinACRBug == -1 && nMinACRFix == -1)
        SendMessageToPC(oPC, "INFO: No puzzle rows found in tmapsolutions (db may be empty)");
    else if (nMinACRBug == nMinACRFix)
        SendMessageToPC(oPC, "PASS: both queries return same result (either fixed, or only one puzzle exists)");
    else
        SendMessageToPC(oPC, "FAIL: queries differ — bug is present");
}
