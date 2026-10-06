/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_cgcloud_User_DocumentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_cgcloud_User_DocumentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new cgcloud__User_Document__c());
    }
}