/**
 * @author Guanshu Wang
 * @date 6/5/2023
 * @description Create SOV Batch Test
 */
@isTest
public with sharing class TPB_CreateSOVBatchTest {
  private static final String SALESORG = '0001';
  private static final String OOS = 'OutOfStock';
  private static final String DISTRIBUTED = 'Distributed';
    
  /**
   * @description insert Visit
   * @author Guanshu Wang
   * @param  accountOne         Account
   * @param  vTOne              Visit
   * @param  rsObject           Retail Store
   * @param  productTemplateOne Product Template
   * @param  productOne         Product
   */
  public static void insertVisit(
    Account accountOne,
    cgcloud__Visit_Template__c vTOne,
    RetailStore rsObject,
    cgcloud__Product_Template__c productTemplateOne,
    Product2 productOne
  ) {
    Visit visitOne = new Visit(
      AccountId = accountOne.Id,
      PlannedVisitStartTime = system.now().addDays(-1),
      PlannedVisitEndTime = system.now().addDays(-1),
      ActualVisitStartTime = system.now().addDays(-1),
      Account_Name__c = 'Sally Walkers Store #1',
      cgcloud__Accountable__c = UserInfo.getUserId(),
      cgcloud__Creation_Date_and_Time__c = System.now(),
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
      ActualVisitEndTime = system.now().addDays(-1).addSeconds(1),
      PlaceId = rsObject.Id
    );
    insert visitOne;
    List<cgcloud__Visit_Job__c> insertVisitJobList = new List<cgcloud__Visit_Job__c>();
    // cgcloud__Visit_Job__c
    cgcloud__Visit_Job__c visitJobOne = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productOne.Id,
      cgcloud__Visit__c = visitOne.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS
    );
    insertVisitJobList.add(visitJobOne);
    // Product2 #2
    Product2 productTwo = new Product2(
      Name = 'two',
      cgcloud__Description_1_Language_1__c = 'two',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productTwo;
    cgcloud__Visit_Job__c visitJobTwo = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productTwo.Id,
      cgcloud__Visit__c = visitOne.Id,
      TPB_EOV__c = DISTRIBUTED,
      cgcloud__Value__c = DISTRIBUTED
    );
    insertVisitJobList.add(visitJobTwo);
    // Product2 #3
    Product2 productThree = new Product2(
      Name = 'three',
      cgcloud__Description_1_Language_1__c = 'three',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productThree;
    cgcloud__Visit_Job__c visitJobThree = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productThree.Id,
      cgcloud__Visit__c = visitOne.Id,
      TPB_EOV__c = DISTRIBUTED,
      cgcloud__Value__c = DISTRIBUTED
    );
    insertVisitJobList.add(visitJobThree);
    // Product2 #4
    Product2 productFour = new Product2(
      Name = 'four',
      cgcloud__Description_1_Language_1__c = 'four',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productFour;
    cgcloud__Visit_Job__c visitJobFour = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productFour.Id,
      cgcloud__Visit__c = visitOne.Id,
      TPB_EOV__c = DISTRIBUTED,
      cgcloud__Value__c = DISTRIBUTED
    );
    insertVisitJobList.add(visitJobFour);
    // Product2 #5
    Product2 productFive = new Product2(
      Name = 'five',
      cgcloud__Description_1_Language_1__c = 'five',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productFive;
    cgcloud__Visit_Job__c visitJobFive = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productFive.Id,
      cgcloud__Visit__c = visitOne.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS
    );
    insertVisitJobList.add(visitJobFive);
    insert insertVisitJobList;
  }

  @testSetup
  static void setup() {
    // Account Template
    cgcloud__Account_Template__c accountTemplateOne = new cgcloud__Account_Template__c(
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store'
    );
    insert accountTemplateOne;
    OperatingHours accountOperatingHours = new OperatingHours(
      Name = 'one',
      TimeZone = 'America/New_York'
    );
    insert accountOperatingHours;
    // Account
    Account accountOne = new Account(
      cgcloud__Account_Template__c = accountTemplateOne.Id,
      ShippingCity = 'Danville',
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingPostalCode = '24540',
      ShippingState = 'VA',
      ShippingStateCode = 'VA',
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
      cgcloud__Sales_Org__c = SALESORG
    );
    insert jDLTOne;
    // cgcloud__Visit_Template__c
    cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
      Name = 'Distribution Visit Template',
      cgcloud__Sales_Org__c = SALESORG,
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
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__Active__c = true,
      Name = 'one',
      cgcloud__Description_Language_1__c = 'Product',
      cgcloud__Price_Required__c = false
    );
    insert productTemplateOne;
    // Product2
    Product2 productOne = new Product2(
      Name = 'one',
      cgcloud__Description_1_Language_1__c = 'one',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productOne;

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

    // Over 1 Year Visit And Visit Job
    // Account
    Account accountYear = new Account(
      cgcloud__Account_Template__c = accountTemplateOne.Id,
      ShippingCity = 'Danville1',
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingPostalCode = '24540',
      ShippingState = 'VA',
      ShippingStateCode = 'VA',
      ShippingStreet = '14 Mount Cross Road',
      Name = 'year',
      OperatingHoursId = accountOperatingHours.Id
    );
    insert accountYear;
    // Activity
    cgcloud__Job_Definition_List__c activityYear = new cgcloud__Job_Definition_List__c(
      cgcloud__Active__c = true,
      cgcloud__Approval_State__c = 'Not Relevant',
      cgcloud__Consider_History__c = true,
      cgcloud__Consider_Listing__c = false,
      cgcloud__Consider_Products__c = true,
      cgcloud__Default_Management_Type__c = 'Sales',
      cgcloud__Description_Language_1__c = 'year',
      cgcloud__Job_Definition_List_Template__c = jDLTOne.Id,
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__User_Policy__c = 'All',
      cgcloud__Valid_From__c = system.today().addYears(-3).addDays(-1),
      cgcloud__Valid_Thru__c = system.today().addYears(3).addDays(1),
      cgcloud__Visit_Template__c = vTOne.Id
    );
    insert activityYear;
    // cgcloud__Job_Definition_List_Account__c
    cgcloud__Job_Definition_List_Account__c activityAccountYear = new cgcloud__Job_Definition_List_Account__c(
      cgcloud__Job_Definition_List__c = activityYear.Id,
      cgcloud__Account__c = accountYear.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityAccountYear;
    // cgcloud__Job_Definition_List_Product__c
    cgcloud__Job_Definition_List_Product__c activityProductYear = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityYear.Id,
      TPB_OOS_Number__c = null,
      cgcloud__Product__c = productOne.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityProductYear;
    RetailStore rsObjectYear = new RetailStore();
    rsObjectYear.Street = 'U.S. Route 66 ';
    rsObjectYear.City = 'Baltimore';
    rsObjectYear.State = 'DC';
    rsObjectYear.PostalCode = '20001';
    rsObjectYear.Country = 'US';
    rsObjectYear.Name = 'Test';
    //create retailstore base on account test data.
    rsObjectYear.AccountId = accountYear.Id;
    insert rsObjectYear;
    // Visit
    Visit visitYear = new Visit(
      AccountId = accountYear.Id,
      PlannedVisitStartTime = system.now().addYears(-2),
      ActualVisitStartTime = system.now().addYears(-2),
      Account_Name__c = 'year',
      cgcloud__Accountable__c = UserInfo.getUserId(),
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
      PlaceId = rsObjectYear.Id,
      PlannedVisitEndTime = system.now().addYears(-2),
      ActualVisitEndTime = system.now().addYears(-2).addSeconds(1)
    );
    insert visitYear;
    // visitYear = [
    //     SELECT Id
    //     FROM Visit
    //     WHERE Account_Name__c = 'year'
    //     LIMIT 1
    // ][0];
    // Visit Job
    cgcloud__Visit_Job__c visitJobYear = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productOne.Id,
      cgcloud__Visit__c = visitYear.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS
    );
    insert visitJobYear;

    // In Year

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
      cgcloud__Sales_Org__c = SALESORG,
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
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityAccountOne;
    // cgcloud__Job_Definition_List_Product__c
    cgcloud__Job_Definition_List_Product__c activityProductOne = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityOne.Id,
      TPB_OOS_Number__c = 2,
      cgcloud__Product__c = productOne.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityProductOne;
    insertVisit(accountOne, vTOne, rsObject, productTemplateOne, productOne);
  }
  @isTest
  static void testCreateSOVBatch() {
    Test.startTest();
    TPB_CreateSOVBatch batch = new TPB_CreateSOVBatch();
    Database.executeBatch(batch);
    Test.stopTest();
    Account accountYear = [
      SELECT Id
      FROM Account
      WHERE Name = 'year'
      LIMIT 1
    ][0];
    Account accountOne = [
      SELECT Id
      FROM Account
      WHERE Name = 'Sally Walkers Store #1'
    ][0];
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE cgcloud__Visit__r.AccountId = :accountYear.Id
      ],
      0
    );
    System.assertEquals(
      5,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE cgcloud__Visit__r.AccountId = :accountOne.Id
      ],
      0
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Visit
        WHERE AccountId = :accountYear.Id
      ],
      0
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List_Product__c
        WHERE TPB_OOS_Number__c = 1
      ],
      0
    );
    cgcloud__Job_Definition_List__c activityYear = [
      SELECT Id
      FROM cgcloud__Job_Definition_List__c
      WHERE cgcloud__Description_Language_1__c = 'year'
      LIMIT 1
    ][0];
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List_Product__c
        WHERE cgcloud__Job_Definition_List__c = :activityYear.Id
      ],
      0
    );
    cgcloud__Job_Definition_List__c activityOne = [
      SELECT Id
      FROM cgcloud__Job_Definition_List__c
      WHERE cgcloud__Description_Language_1__c = 'Standard Survey Activities1'
      LIMIT 1
    ][0];
    System.assertEquals(
      4,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List_Product__c
        WHERE cgcloud__Job_Definition_List__c = :activityOne.Id
      ],
      0
    );
  }
  @isTest
  static void testCreateSOVScheduler() {
    Test.startTest();
    TPB_CreateSOVScheduler createSOVBatch = new TPB_CreateSOVScheduler();
    createSOVBatch.execute(null);
    TPB_CreateEOVScheduler createEOVBatch = new TPB_CreateEOVScheduler();
    createEOVBatch.execute(null);
    Test.stopTest();
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List_Product__c
        WHERE TPB_OOS_Number__c = 1
      ],
      0
    );
  }
}