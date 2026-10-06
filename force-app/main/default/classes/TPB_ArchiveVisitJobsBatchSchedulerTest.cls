@isTest
private class TPB_ArchiveVisitJobsBatchSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        TPB_ArchiveVisitJobsBatchScheduler scheduler = new TPB_ArchiveVisitJobsBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}