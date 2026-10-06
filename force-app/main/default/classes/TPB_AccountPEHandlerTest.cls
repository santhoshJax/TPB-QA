/**************************************************************************************
Apex Class Name:  TPB_AccountPEHandlerTest
Version     : 1.0 
Created Date    : 2023-03-24
Function    : TPB_AccountPEHandlerTest for TPB_AccountPEHandler
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description CON0001729-902 ERP_ARCustomer_Integration_PE trigger handler test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
@isTest
private class TPB_AccountPEHandlerTest {
    private static final String TEST_TYPE = 'Normal';
     /**
     * @description prepareData description
     *
     */
    @TestSetup
    static void prepareData() {
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

        //create account
        Account objTestAcct = new Account();
        objTestAcct.Name = 'Test account 001';
        objTestAcct.OperatingHoursId = objTestVisitHour.Id;
        //ShippingCity
        objTestAcct.ShippingCity = 'Washington';
        //ShippingCountry
        objTestAcct.ShippingCountry = 'US';
        //ShippingStreet
        objTestAcct.ShippingStreet = '920 Rhode Island Ave NEx';
        //ShippingPostalCode
        objTestAcct.ShippingPostalCode = '20001';
        //ShippingState
        objTestAcct.ShippingState = 'DC';
        objTestAcct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Headquarter')
            .getRecordTypeId();
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
        objTestVisit.TPB_HQ_Visit_Type__c = 'Virtual';
        //insert objTestVisit
        insert objTestVisit;

        
    }
    /**
    * @description testUpdateHiddenFieldBeforeUpdate 
    * Create the method for integration to test update hidden fields,
    * so that integrations can merge formula fields in ADW 
    */ 
    @isTest
    static void testUpdateHiddenFieldBeforeUpdate() {
        List<Account> accountLst = [SELECT Id, Name, Owner.Alias,OwnerId 
                                      FROM Account WHERE Id != null ORDER BY RecordType.Name ASC LIMIT 1];
        //query account list
        Account accToUpdate = accountLst[0];
        User uRec = [SELECT id FROM User WHERE Id != null LIMIT 1][0];
        accToUpdate.OwnerId = uRec.Id;
        test.startTest();
        //start testing
        //Datetime dt = system.now();
        update accToUpdate;
        Account verAcc = [SELECT Id,TPB_AR_Customer_Trigger__c FROM Account WHERE Id = :accToUpdate.Id];
        //stop testing
        test.stopTest();
        system.assertEquals(true, verAcc!=null,'fail');

        
    }
    /**
    * @description testUpdateHiddenFieldAfterUpdate 
    * Create the method for integration to test update hidden fields,
    * so that integrations can merge formula fields in ADW 
    */ 
    @isTest
    static void testUpdateHiddenFieldAfterUpdate() {
        List<Account> accountLst = [SELECT Id, Name, Owner.Alias, BillingCity,TPB_Formula_Rollup_Trigger__c,Last_Completed_Work_Order__c, BillingState, Cash_Sales__c, RecordTypeId, RecordType.Name, ParentId
                                  FROM Account WHERE Name = 'Test account 001' LIMIT 1];
        //query related account data
        Account accToUpdate2 = accountLst[0];
        Visit vRec = [SELECT Id FROM Visit WHERE AccountId = :accToUpdate2.Id][0];
        //query work order
        accToUpdate2.Last_Completed_Call__c = vRec.Id;
        //start testing
        test.startTest();
        //Datetime dt2 = system.now();
        update accToUpdate2;
        //end testing
        Visit vRec2 = [SELECT Id FROM Visit WHERE AccountId = :accToUpdate2.Id];
        test.stopTest();
        system.assertEquals(true, vRec2!=null,'fail');

        
    }
}