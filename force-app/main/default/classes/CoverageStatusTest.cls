@isTest
public inherited sharing class CoverageStatusTest {

    public static testMethod void testYesCoverageStatus() {
        Coverage_Plan__c plan = TestDataFactory.createAnnualCoverage();

        Account retailer = TestDataFactory.createRetailAccount();
        retailer.Coverage_Plan__c = plan.Id;
        retailer.Coverage_Completed__c = 'No';
        update retailer;

        Schema.Location locationObj = TestDataFactory.createLocation();
        //WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
        //ServiceAppointment appointment = TestDataFactory.createServiceAppointment(wOrder.Id, null);

        //wOrder.Completed_Sales_Appointment__c = appointment.Id;
        //update wOrder;

        test.startTest();
        CoverageStatusScheduler scheduledJob = new CoverageStatusScheduler();
        scheduledJob.execute(null);
        test.stopTest();

        Integer count = [SELECT count() FROM Account WHERE Coverage_Completed__c = 'Yes'];
        //system.assertEquals(1, count);
    }

    public static testMethod void testNoCoverageStatus() {
        Coverage_Plan__c plan = TestDataFactory.createAnnualCoverage();

        Account retailer = TestDataFactory.createRetailAccount();
        retailer.Coverage_Plan__c = plan.Id;
        retailer.Coverage_Completed__c = 'Yes';
        update retailer;

        test.startTest();
        CoverageStatusScheduler scheduledJob = new CoverageStatusScheduler();
        scheduledJob.execute(null);
        test.stopTest();

        Integer count = [SELECT count() FROM Account WHERE Coverage_Completed__c = 'No'];
        //system.assertEquals(1, count);
    }

}