/**************************************************************************************
Apex Class Name:  TPB_GTMOppStatusUpdateBatchTest
Version     : 1.0
Created Date    : 2023-08-14
Function    : Test class for GTM Opp Status Update
OwnerId     :
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Evonne              2023-08-14           Original Version
*************************************************************************************/
@isTest
public with sharing class TPB_GTMOppStatusUpdateBatchTest {
    @TestSetup
    static void setup(){
        TestDataFactory.ensureVisitTemplate('0001');
        String strOrgUnit = '0001';
        String strOne = 'one';
        String strOutOfStock = 'OutOfStock';
        // Org Unit
        cgcloud__Org_Unit__c orgUnitOne = new cgcloud__Org_Unit__c(
            cgcloud__Sales_Org__c = strOrgUnit,
            Name = 'test1'
        );
        insert orgUnitOne;
        // Account Template
        cgcloud__Account_Template__c accountTemplateOne = new cgcloud__Account_Template__c(
            cgcloud__Sales_Org__c = strOrgUnit,
            cgcloud__Active__c = true,
            cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
            cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store'
        );
        insert accountTemplateOne;
        //accountOperatingHours
        OperatingHours accountOperatingHours = new OperatingHours(
            Name = strOne,
            TimeZone = 'America/New_York'
        );
        insert accountOperatingHours;
        // Account
        Account accountOne = new Account(
            cgcloud__Account_Template__c = accountTemplateOne.Id,
            ShippingCity = 'Danville',
            ShippingCountry = 'US',
            // ShippingCountryCode = 'US',
            ShippingPostalCode = '24540',
            ShippingState = 'VA',
            // ShippingStateCode = 'VA',
            ShippingStreet = '1234 Mount Cross Road',
            Name = 'Sally Walkers Store #1',
            OperatingHoursId = accountOperatingHours.Id
        );
        insert accountOne;
        // cgcloud__Job_Definition_List_Template__c
        cgcloud__Job_Definition_List_Template__c jDLTOne = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Distribution Activity Template',
            cgcloud__Consider_Account__c = true,
            cgcloud__Consider_Products__c = true,
            cgcloud__Sales_Org__c = strOrgUnit
        );
        insert jDLTOne;
        // cgcloud__Visit_Template__c
        cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
            Name = 'Distribution Visit Template',
            cgcloud__Sales_Org__c = strOrgUnit,
            cgcloud__Active__c = true,
            cgcloud__Add_Job_Policy__c = true,
            cgcloud__Auto_Status__c = 'Planned',
            cgcloud__Cancel_Reason_Required__c = false,
            cgcloud__Capture_Proceeding_Time__c = true,
            cgcloud__Check_Overlap__c = false,
            cgcloud__Company_Required__c = 'Mandatory',
            cgcloud__Consider_POS_Check__c = true,
            cgcloud__Creation_Platform__c = 'Both',
            cgcloud__Default_Duration__c = 30,
            cgcloud__Delete_Allowed__c = true,
            cgcloud__Display_Promotions__c = true,
            cgcloud__Historical_Products__c = 'No',
            cgcloud__KPI_Relevant__c = 'All',
            cgcloud__Loc_Capture_During_Cancel__c = true,
            cgcloud__Loc_Capture_During_Complete__c = true,
            cgcloud__Max_Pictures__c = 10,
            cgcloud__Meta_Type__c = 'Call',
            cgcloud__Mobility_Color__c = '6688BB',
            cgcloud__Mobility_Relevant__c = true,
            cgcloud__Mobility_User_Guidance__c = 'Sales',
            cgcloud__Promotion_Finding_Lead_Time__c = 365,
            cgcloud__Sort__c = 5,
            cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User'
        );
        insert vTOne;
        // cgcloud__Product_Template__c
        cgcloud__Product_Template__c productTemplateOne = new cgcloud__Product_Template__c(
            cgcloud__Sales_Org__c = strOrgUnit,
            cgcloud__Active__c = true,
            Name = strOne,
            cgcloud__Description_Language_1__c = 'Product',
            cgcloud__Price_Required__c = false
        );
        insert productTemplateOne;

        //Product Parent
        Product2 productParent = new Product2(
            Name = 'parent',
            cgcloud__Description_1_Language_1__c = 'parent',
            IsActive = true,
            cgcloud__Product_Template__c = productTemplateOne.Id,
            cgcloud__Product_Level__c = 'Package'
        );
        insert productParent;
        // Product2
        Product2 productOne = new Product2(
            Name = strOne,
            cgcloud__Description_1_Language_1__c = strOne,
            IsActive = true,
            cgcloud__Product_Template__c = productTemplateOne.Id,
            cgcloud__Criterion_5_Product__c = productParent.Id
        );
        insert productOne;

        Product2 productTwo = new Product2(
            Name = 'two',
            cgcloud__Description_1_Language_1__c = 'two',
            IsActive = true,
            cgcloud__Product_Template__c = productTemplateOne.Id,
            cgcloud__Criterion_5_Product__c = productParent.Id
        );
        insert productTwo;

        RetailStore rsObject = new RetailStore();
        rsObject.Street = 'U.S. Route 66 ';
        rsObject.City = 'Baltimore';
        rsObject.State = 'DC';
        rsObject.PostalCode = '20001';
        rsObject.Country = 'US';
        rsObject.Name = 'Test';
        //create retailstore base on account test data.
        rsObject.AccountId = accountOne.Id;
        insert rsObject;

        // cgcloud__Job_Definition_List__c
        cgcloud__Job_Definition_List__c activityOne = new cgcloud__Job_Definition_List__c(
            cgcloud__Active__c = true,
            cgcloud__Approval_State__c = 'Not Relevant',
            cgcloud__Consider_History__c = true,
            cgcloud__Consider_Listing__c = false,
            cgcloud__Consider_Products__c = true,
            cgcloud__Default_Management_Type__c = 'Sales',
            cgcloud__Description_Language_1__c = 'Standard Survey Activities1',
            cgcloud__Job_Definition_List_Template__c = jDLTOne.Id,
            cgcloud__Sales_Org__c = strOrgUnit,
            cgcloud__User_Policy__c = 'All',
            cgcloud__Valid_From__c = system.today().addDays(-1),
            cgcloud__Valid_Thru__c = system.today().addDays(1),
            cgcloud__Visit_Template__c = vTOne.Id
        );
        insert activityOne;
        // cgcloud__Job_Definition_List_Account__c
        cgcloud__Job_Definition_List_Account__c activityAccountOne = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = activityOne.Id,
            cgcloud__Account__c = accountOne.Id,
            cgcloud__Sales_Org__c = strOrgUnit
        );
        insert activityAccountOne;
        // cgcloud__Job_Definition_List_Product__c
        cgcloud__Job_Definition_List_Product__c activityProductOne = new cgcloud__Job_Definition_List_Product__c(
            cgcloud__Job_Definition_List__c = activityOne.Id,
            TPB_OOS_Number__c = 2,
            cgcloud__Product__c = productOne.Id,
            cgcloud__Sales_Org__c = strOrgUnit
        );
        insert activityProductOne;
        // Visit Base
        Visit visitBase = new Visit(
            AccountId = accountOne.Id,
            PlannedVisitStartTime = system.now().addDays(-2),
            PlannedVisitEndTime = system.now().addDays(-2),
            ActualVisitStartTime = system.now().addDays(-2),
            Account_Name__c = 'Sally Walkers Store #1',
            cgcloud__Accountable__c = UserInfo.getUserId(),
            cgcloud__Creation_Date_and_Time__c = System.now().addSeconds(-1),
            cgcloud__Creation_Mode__c = 'Manually',
            cgcloud__Distribution_Issues__c = false,
            cgcloud__Distribution_Rate_All__c = 100,
            cgcloud__Distribution_Rate_Focus__c = 0,
            cgcloud__Distribution_Relevant__c = true,
            cgcloud__Duration_Effective__c = 0,
            cgcloud__Fixed_Visit_Date__c = '0',
            cgcloud__Geolocation__Latitude__s = 0,
            cgcloud__Geolocation__Longitude__s = 0,
            cgcloud__IsAllDayEvent__c = false,
            cgcloud__OOS_Issues__c = true,
            cgcloud__OOS_Rate_All__c = 50,
            cgcloud__OOS_Rate_Focus__c = 0,
            cgcloud__PSI__c = 0,
            cgcloud__PSQ_Rate__c = 0,
            cgcloud__Responsible__c = UserInfo.getUserId(),
            cgcloud__Visit_Template__c = vTOne.Id,
            cgcloud__Week__c = 7,
            ActualVisitEndTime = system.now().addDays(-2).addSeconds(1),
            PlaceId = rsObject.Id,
            Status = 'Completed',
            Quarterly_Base_Call__c = true
        );
        insert visitBase;
        // cgcloud__Visit_Job__c for Base Visit
        cgcloud__Visit_Job__c visitJobOneBase = new cgcloud__Visit_Job__c(
            cgcloud__Product__c = productOne.Id,
            cgcloud__Visit__c = visitBase.Id,
            Calculated_Distribution__c = strOutOfStock,
            cgcloud__Value__c = strOutOfStock,
            cgcloud__Visit_Date__c = date.today().addDays(-1)
        );
        insert visitJobOneBase;
        // Visit
        Visit visitOne = new Visit(
            AccountId = accountOne.Id,
            PlannedVisitStartTime = system.now().addDays(-1),
            PlannedVisitEndTime = system.now().addDays(-1),
            ActualVisitStartTime = system.now().addDays(-1),
            ActualVisitEndTime = system.now().addDays(-1).addSeconds(1),
            PlaceId = rsObject.Id,
            Status = 'Completed',
            Quarterly_Base_Call__c = false
        );
        insert visitOne;
        // cgcloud__Visit_Job__c
        cgcloud__Visit_Job__c visitJobOne = new cgcloud__Visit_Job__c(
            cgcloud__Product__c = productOne.Id,
            cgcloud__Visit__c = visitOne.Id,
            Calculated_Distribution__c = 'Distributed',
            cgcloud__Value__c = 'Distributed',
            cgcloud__Visit_Date__c = date.today()
        );
        insert visitJobOne;

        cgcloud__Visit_Job__c visitJobTwo = new cgcloud__Visit_Job__c(
            cgcloud__Product__c = productTwo.Id,
            cgcloud__Visit__c = visitOne.Id,
            Calculated_Distribution__c = strOutOfStock,
            cgcloud__Value__c = strOutOfStock,
            cgcloud__Visit_Date__c = date.today()
        );
        insert visitJobTwo;

        // Query the start date and end date of current quarter
        List<Period> lstPeriod = [
            SELECT StartDate, EndDate, FullyQualifiedLabel, Number
            FROM Period
            WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY
            ORDER BY StartDate DESC
            LIMIT 1
        ];

        //TPB_Opportunity__c
        TPB_Opportunity__c objTPBOpp = new TPB_Opportunity__c(
            Name = 'Test',
            TPB_Product_ID__c = productParent.Id,
            TPB_Quarter__c = String.valueOf(lstPeriod[0].Number),
            TPB_Year__c = lstPeriod[0].FullyQualifiedLabel.right(4)
        );
        insert objTPBOpp;

        //TPB_GTM_Opportunity__c
        TPB_GTM_Opportunity__c objGTMOppNewDistribution = new TPB_GTM_Opportunity__c(
            TPB_Account_ID__c = accountOne.Id,
            TPB_Opportunity_Name__c = 'test GTMOpp New Distribution',
            TPB_Type__c = 'New Distribution',
            TPB_Active__c = true,
            TPB_Opportunity__c = objTPBOpp.Id
        );
        insert objGTMOppNewDistribution;

        TPB_GTM_Opportunity__c objGTMSKU = new TPB_GTM_Opportunity__c(
            TPB_Account_ID__c = accountOne.Id,
            TPB_Opportunity_Name__c = 'test GTMOpp SKU Expansion',
            TPB_Type__c = 'SKU Expansion',
            TPB_Active__c = true,
            TPB_Opportunity__c = objTPBOpp.Id
        );
        insert objGTMSKU;

    }

    @isTest
    static void testGTMOppStatusUpdate() {
        Test.startTest();
        Database.executeBatch(new TPB_GTMOppStatusUpdateBatch(), 200);
        Test.stopTest();
        TPB_GTM_Opportunity__c objNewDistribution = [
            SELECT Id, TPB_Status__c FROM TPB_GTM_Opportunity__c WHERE TPB_Opportunity_Name__c = 'test GTMOpp New Distribution'
        ][0];
        System.assertEquals('Achieved', objNewDistribution.TPB_Status__c, '');

    }

    @isTest
    static void testGTMOppStatusUpdate2() {
        // Query the start date and end date of current quarter
        List<Period> lstPeriod = [
            SELECT StartDate, EndDate, FullyQualifiedLabel, Number
            FROM Period
            WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY
            ORDER BY StartDate DESC
            LIMIT 1
        ];

        Test.startTest();
        Database.executeBatch(new TPB_GTMOppStatusUpdateBatch(lstPeriod[0].FullyQualifiedLabel.right(4) + ' ' + String.valueOf(lstPeriod[0].Number)), 200);
        Test.stopTest();
        TPB_GTM_Opportunity__c objSKUExpansion = [
            SELECT Id, TPB_Status__c FROM TPB_GTM_Opportunity__c WHERE TPB_Opportunity_Name__c = 'test GTMOpp SKU Expansion'
        ][0];
        System.assertEquals('Achieved', objSKUExpansion.TPB_Status__c, '');
    }

    @isTest
    static void testGTMOppStatusUpdate3() {
        Test.startTest();
        cgcloud__Visit_Job__c visitJobTwo = [
            SELECT Id, Calculated_Distribution__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Product__r.name = 'two'
        ][0];
        visitJobTwo.Calculated_Distribution__c = 'Distributed';
        update visitJobTwo;
        Test.stopTest();

        TPB_GTM_Opportunity__c objNewDistribution = [
            SELECT Id, TPB_Status__c FROM TPB_GTM_Opportunity__c WHERE TPB_Opportunity_Name__c = 'test GTMOpp New Distribution'
        ][0];
        System.assertEquals('Achieved', objNewDistribution.TPB_Status__c, '');
    }

}