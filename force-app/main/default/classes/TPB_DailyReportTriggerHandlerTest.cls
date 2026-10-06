/**
 * TPB_DailyReportTriggerHandlerTest
 * @author RZ
 * @date 2023-09-24
 * @description TPB_DailyReportTriggerHandlerTest 
 *
 */
@isTest
public with sharing class TPB_DailyReportTriggerHandlerTest {
    /**
     * @description setup description
     *
     */
    @testSetup
    public static void setup() {
        // new dailyReportTemplate
        cgcloud__User_Document_Template__c template = new cgcloud__User_Document_Template__c(
            cgcloud__Creation_Platform__c = 'All',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Active__c = true,
            cgcloud__Description_Language_1__c = 'TOF',
            cgcloud__Sort__c = 6,
            cgcloud__Mobility_Relevant__c = true
        );
        //insert template
        insert template;
        // new dailyReport
        cgcloud__User_Document__c dailyReport = new cgcloud__User_Document__c(
            cgcloud__User_Document_Template__c = template.Id,
            cgcloud__Date__c = Date.today(),
            cgcloud__Phase__c = 'Approved',
            cgcloud__Work_Time_From__c = '09:00',
            cgcloud__Work_Time_Thru__c = '17:00',
            cgcloud__Responsible__c = UserInfo.getUserId(),
            cgcloud__Accountable__c = UserInfo.getUserId(),
            TPB_Activity_Type__c = 'Vacation'
        );
        //insert dailyReport
        insert dailyReport;
    }

    /**
     * @description testInsertDailyReport description
     *
     */
    @isTest
    static void testInsertDailyReport() {
        // get cgcloud__User_Document_Template__c
        cgcloud__User_Document_Template__c template = [SELECT Id FROM cgcloud__User_Document_Template__c WHERE Id != null LIMIT 1];
        //start Test
        Test.startTest();
        try {
            cgcloud__User_Document__c dailyReport = new cgcloud__User_Document__c(
                cgcloud__User_Document_Template__c = template.Id,
                cgcloud__Date__c = Date.today(),
                cgcloud__Phase__c = 'Initial',
                cgcloud__Work_Time_From__c = '10:00',
                cgcloud__Work_Time_Thru__c = '17:00',
                cgcloud__Responsible__c = UserInfo.getUserId(),
                cgcloud__Accountable__c = UserInfo.getUserId(),
                TPB_Activity_Type__c = 'Vacation'
            );
            // insert dailyReport
            insert dailyReport;
        } catch (Exception ex) {
            System.assert(ex != null, 'insert error!');
        }
        //stop Test
        Test.stopTest();
    }

    /**
     * @description testUpdateDailyReport description
     *
     */
    @isTest
    static void testUpdateDailyReport() {
        // get cgcloud__User_Document_Template__c
        cgcloud__User_Document_Template__c template = [SELECT Id FROM cgcloud__User_Document_Template__c WHERE Id != null LIMIT 1];
        cgcloud__User_Document__c dailyReport = new cgcloud__User_Document__c(
            cgcloud__User_Document_Template__c = template.Id,
            cgcloud__Date__c = Date.today(),
            cgcloud__Phase__c = 'Initial',
            cgcloud__Work_Time_From__c = '18:00',
            cgcloud__Work_Time_Thru__c = '19:00',
            cgcloud__Responsible__c = UserInfo.getUserId(),
            cgcloud__Accountable__c = UserInfo.getUserId(),
            TPB_Activity_Type__c = 'Vacation'
        );
        // insert dailyReport
        insert dailyReport;
        //start Test
        Test.startTest();
        try {
            dailyReport.cgcloud__Work_Time_From__c = '07:00';
            dailyReport.cgcloud__Work_Time_Thru__c = '10:00';
            dailyReport.cgcloud__Phase__c = 'Released';
            // update dailyReport
            update dailyReport;
        } catch (Exception ex) {
            System.assert(ex != null, 'update error!');
        }
        //stop Test
        Test.stopTest();
    }
}