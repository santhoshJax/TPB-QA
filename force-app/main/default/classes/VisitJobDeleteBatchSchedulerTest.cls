@isTest
private class VisitJobDeleteBatchSchedulerTest {
    @isTest
    static void testSchedulerRunsBatch() {
        Test.startTest();
        VisitJobDeleteBatchScheduler scheduler = new VisitJobDeleteBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}