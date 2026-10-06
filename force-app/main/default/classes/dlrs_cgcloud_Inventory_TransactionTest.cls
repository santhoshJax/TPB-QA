/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_cgcloud_Inventory_TransactionTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_cgcloud_Inventory_Transaca4WTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new cgcloud__Inventory_Transaction__c());
    }
}