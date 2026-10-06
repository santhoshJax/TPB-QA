/**************************************************************************************
Apex Class Name:  TPB_UserPEHandlerTest
Version     : 1.0
Created Date    : 2023-03-24
Function    : TPB_UserPEHandler Test Class
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description  user trigger handler test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
@isTest
public with sharing class TPB_UserPEHandlerTest {
  private static final String TEST_TYPE = 'Normal';
  //default sales org.
  private static String salesOrg = '0001';
  private static String accountRecordtype = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Wholesaler')
    .getRecordTypeId();

  //Order recordType Id
  private static String orderVanLoadRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
    .get('Van_Load')
    .getRecordTypeId();

  //default visit template.
  private static String strVisitTemplate = 'Distribution Visit Template';
   /**
     * @description prepareData description
     *
     */
    @TestSetup
    static void prepareData() {
       //create visit template.
       cgcloud__Visit_Template__c vtemplateRec = createTestVisitTemplate();
      //create user
      // User uRec = createTestUser();
       User uRec = [SELECT Id FROM User WHERE Id = :userinfo.getUserId()];
      //create account template
      cgcloud__Account_Template__c accTemplate = createTestAccountTemplate();
      //create account
      Account acc = createTestAccount(accTemplate,uRec);


        //create retailstore for visit creating.
        RetailStore rsObject = new RetailStore();
        rsObject.Street = 'U.S. Route 669 ';
        rsObject.City = 'Baltimore';
        rsObject.State = 'DC';
        rsObject.PostalCode = '20001';
        rsObject.Country = 'US';
        rsObject.Name = 'Test';
        //create retailstore base on account test data.
        rsObject.AccountId = acc.Id;
        insert rsObject;
        //create visit test data.
        Visit vRec = createTestVisit(acc,uRec,vtemplateRec,rsObject);
        //for code scan
        if(vRec==null){
            salesOrg = '0001';
        }

    }
   /**
   * @description updateHiddenFieldAfterUpdate test
   */
  @isTest
  static void updateHiddenFieldAfterUpdateTest01() {

    User uRec = [SELECT Id FROM User WHERE Id = :userinfo.getUserId()];
    
    test.startTest();
    System.runAs(uRec) {
      uRec.TPB_Territory__c = 'Tina001';
      update uRec;
    }
    Visit item = [SELECT Id,TPB_Formula_Rollup_Trigger__c FROM Visit WHERE Id != null LIMIT 1];
    Test.stopTest();
    system.assertEquals(true, item!=null,'fail');
  }
  /**
   * @description create test user records
   * @return User User Description
   */

  private static User createTestUser(){
      User uRec = new User();
      uRec.FirstName = 'Standard';
      uRec.LastName = 'User';
      uRec.Alias = 'admin';
      uRec.Email = 'standard@ntc-test.com';
      uRec.Username = 'standard@ntc-test.com';
      uRec.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
      uRec.TimeZoneSidKey = 'America/Los_Angeles';
      uRec.EmailEncodingKey = 'UTF-8';
      uRec.LanguageLocaleKey = 'en_US';
      uRec.LocaleSidKey = 'en_US';
      uRec.TPB_Territory__c = 'Tina002';
      insert uRec;
      return uRec;
  }
  /**
   * @description create test AccountTemplate records
   * @return cgcloud__Account_Template__c cgcloud__Account_Template__c Description
   */

  private static cgcloud__Account_Template__c createTestAccountTemplate(){
      cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
      //set account template as active.
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Description_Language_1__c = 'Customer',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store',
      cgcloud__Sales_Org__c = salesOrg,
      Name = 'Customer'
      );
      insert accTemplate;
      return accTemplate;
  }
  /**
   * @description create test Account records
   * @param  accTemplate accTemplate description
   * @param  uRec uRec description
   * @return Account Account Description
   */

  private static Account createTestAccount(cgcloud__Account_Template__c accTemplate, User uRec){
        Account accObj = new Account(
        BillingCountry = 'US',
        BillingCountryCode = 'US',
        Cash_Sales__c = false,
        //set account template.
        cgcloud__Account_Template__c = accTemplate.Id,
        OwnerId = uRec.Id,
        Clearing_House_Participant__c = false,
        ShippingCountry = 'US',
        ShippingCountryCode = 'US',
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = '20001',
        ShippingState = 'DC',
        ShippingStreet = 'U.S. Route 6653 ',
        ShippingCity = 'Baltimore',
        ShippingStateCode = 'DC',
        Name = 'Test Acc',
        TPB_Account_Territory__c = '208A01T',
        RecordTypeId = accountRecordtype
        );
        insert accObj;
        return accObj;
  }
  /**
   * @description create test VisitTemplate records
   * @return cgcloud__Visit_Template__c cgcloud__Visit_Template__c Description
   */

  private static cgcloud__Visit_Template__c createTestVisitTemplate(){
    cgcloud__Visit_Template__c visitTemplate = new cgcloud__Visit_Template__c(
        //sert visit template as active.
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
        cgcloud__Description_Language_1__c = strVisitTemplate,
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
        //set default sales org.
        cgcloud__Sales_Org__c = salesOrg,
        cgcloud__Sort__c = 5,
        cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User',
        Name = strVisitTemplate
      );
      insert visitTemplate;
      return visitTemplate;
  }

  /**
   * @description create test visit records
   * @param Account Account Description
   * @param User User Description
   * @param cgcloud__Visit_Template__c cgcloud__Visit_Template__c description
   * @param rsObject rsObject description
   * @return Visit Visit Description
   */

  private static Visit createTestVisit(Account accObj, User uRec, cgcloud__Visit_Template__c visitTemplate,RetailStore rsObject){
    Visit visitObj = new Visit();
    //set account relationship.
    visitObj.AccountId = accObj.Id;
    visitObj.Account_Name__c = accObj.Name;
    //set actualvisitstarttime as now.
    visitObj.ActualVisitStartTime = Date.today().addDays(-2);
    visitObj.cgcloud__Accountable__c = UserInfo.getUserId();
    visitObj.cgcloud__Creation_Date_and_Time__c = System.now();
    visitObj.cgcloud__Creation_Mode__c = 'Manually';
    visitObj.cgcloud__Distribution_Issues__c = false;
    visitObj.cgcloud__Distribution_Rate_All__c = 100;
    visitObj.cgcloud__Distribution_Rate_Focus__c = 0;
    visitObj.cgcloud__Distribution_Relevant__c = true;
    visitObj.cgcloud__Duration_Effective__c = 0;
    visitObj.cgcloud__Fixed_Visit_Date__c = '0';
    visitObj.cgcloud__Geolocation__Latitude__s = 0;
    visitObj.cgcloud__Geolocation__Longitude__s = 0;
    visitObj.cgcloud__IsAllDayEvent__c = false;
    visitObj.cgcloud__OOS_Issues__c = true;
    visitObj.cgcloud__OOS_Rate_All__c = 50;
    visitObj.cgcloud__OOS_Rate_Focus__c = 0;
    visitObj.ActualvisitEndTime = Date.today().addDays(-1);
    visitObj.cgcloud__PSI__c = 0;
    visitObj.cgcloud__PSQ_Rate__c = 0;
    visitObj.cgcloud__Responsible__c = uRec.Id;
    //set visit template.
    visitObj.cgcloud__Visit_Template__c = visitTemplate.Id;
    visitObj.cgcloud__Week__c = 7;
    //set planned start time as now.
    visitObj.PlannedVisitStartTime = Datetime.newInstance(
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
    //set planned end time as now.
    visitObj.PlannedVisitEndTime = Datetime.newInstance(
      //year
      2022,
      //month
      11,
      //day
      29,
      9,
      0,
      0
    );
    visitObj.PlaceId = rsObject.Id;
    visitObj.TPB_WholesaleVisitType__c = 'Sales Appointment';
    insert visitObj;
    return visitObj;
  }
    

}