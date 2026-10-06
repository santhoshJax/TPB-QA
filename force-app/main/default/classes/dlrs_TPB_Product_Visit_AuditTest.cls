/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_TPB_Product_Visit_AuditTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_TPB_Product_Visit_AuditTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new TPB_Product_Visit_Audit__c());
    }
}