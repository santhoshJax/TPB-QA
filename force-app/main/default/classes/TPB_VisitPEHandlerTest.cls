/**************************************************************************************
Apex Class Name:  TPB_VisitPEHandlerTest
Version     : 1.0
Created Date    : 2023-03-24
Function    : TPB_VisitPEHandler Test Class
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description visit trigger handler test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.wu              2023-03-24            Original Version
*************************************************************************************/
@isTest
public with sharing class TPB_VisitPEHandlerTest {
  private static final String TEST_TYPE = 'Normal';
    /**
     * @description prepareData description
     *
     */
    @TestSetup
    static void prepareData() {
        TestDataFactory.ensureVisitTemplate('0001');
        //objTestVisitHour
        OperatingHours objTestVisitHour = new OperatingHours(
            Name = 'Visit Hour',
            TimeZone = 'Europe/Paris'
        );
        insert objTestVisitHour;

        // create time slots
        List<TimeSlot> lstSlots = new List<TimeSlot>();
        lstSlots.add(
            new TimeSlot(
                OperatingHoursId = objTestVisitHour.Id,
                DayOfWeek = 'Monday',
                StartTime = Time.newInstance(8, 0, 0, 0),
                EndTime = Time.newInstance(12, 0, 0, 0),
                Type = TEST_TYPE
            )
        );
        lstSlots.add(
            new TimeSlot(
                OperatingHoursId = objTestVisitHour.Id,
                DayOfWeek = 'Tuesday',
                StartTime = Time.newInstance(14, 0, 0, 0),
                EndTime = Time.newInstance(18, 0, 0, 0),
                Type = TEST_TYPE
            )
        );
        lstSlots.add(
            new TimeSlot(
                OperatingHoursId = objTestVisitHour.Id,
                DayOfWeek = 'Wednesday',
                StartTime = Time.newInstance(8, 0, 0, 0),
                EndTime = Time.newInstance(12, 0, 0, 0),
                Type = TEST_TYPE
            )
        );
        //insert lstSlots
        insert lstSlots;

        // Account Template: ensures Account.Sales_Org = '0001' matches the Visit Template's
        // Sales Org, satisfying the Visit Sales_Org_should_be_same_for_all_lookups validation.
        cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
            cgcloud__Active__c = true,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Description_Language_1__c = 'Customer',
            Name = 'Customer'
        );
        insert accTemplate;

        //create account
        Account objTestAcct = new Account();
        objTestAcct.Name = 'Test account 001';
        objTestAcct.OperatingHoursId = objTestVisitHour.Id;
        //ShippingCity
        objTestAcct.ShippingCity = 'Washington';
        //ShippingCountry
        objTestAcct.ShippingCountry = 'US';
        //ShippingStreet
        objTestAcct.ShippingStreet = '920 Rhode Island Ave NE';
        //ShippingPostalCode
        objTestAcct.ShippingPostalCode = '20001';
        //ShippingState
        objTestAcct.ShippingState = 'DC';
        objTestAcct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Retailer')
            .getRecordTypeId();
        objTestAcct.cgcloud__Account_Template__c = accTemplate.Id;
        //insert objTestAcct
        insert objTestAcct;

        //create Location
        Schema.Location objTestlocation = new Schema.Location(
            Name = 'test Location',
            LocationType = 'Warehouse'
        );
        //insert objTestlocation
        insert objTestlocation;

        // create visit
        Visit objTestVisit = new Visit();
        objTestVisit.Status = 'Planned';
        objTestVisit.PlaceId = objTestlocation.Id;
        objTestVisit.AccountId = objTestAcct.Id;
        objTestVisit.PlannedVisitStartTime = Datetime.newInstance(
            //year
            2022,
            //month
            11,
            //day
            28,
            9,
            0,
            0
        );
        objTestVisit.PlannedVisitEndTime = Datetime.newInstance(
            //year
            2022,
            //month
            11,
            //day
            28,
            10,
            0,
            0
        );
        objTestVisit.VisitorId = UserInfo.getUserId();
        objTestVisit.TPB_WholesaleVisitType__c = 'Sales Appointment';
        //insert objTestVisit
        insert objTestVisit;
        //update acc
        objTestAcct.Last_Completed_Call__c = objTestVisit.Id;
        update objTestAcct;
    }
  /**
   * @description updateHiddenFieldAfterUpdate test
   */
  @isTest
  static void updateHiddenFieldAfterUpdateTest01() {

        //start Test
        Test.startTest();
        //get objVisit
        Visit objVisit = [SELECT Id FROM Visit WHERE Id != NULL LIMIT 1];
        System.assertNotEquals(null, objVisit, 'Visit not found');
        objVisit.ActualVisitEndTime = system.now();
        //update objVisit
        update objVisit;
        //get objAcc
        Account objAcc = [SELECT Id,TPB_Formula_Rollup_Trigger__c FROM Account WHERE Id != NULL LIMIT 1];
        System.assertNotEquals(null, objAcc, 'Account not found');
        Test.stopTest();
        //stop Test

  }
}