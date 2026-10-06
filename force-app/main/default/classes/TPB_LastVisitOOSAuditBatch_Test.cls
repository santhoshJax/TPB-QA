/**
 * @date 2026-08-20
 * @description Test class for TPB_LastVisitOOSAuditBatch. Sets up one account with 4 products
 *              exercising the 4 possible classifications: OK, MISMATCH, LEGITIMATELY_DELETED,
 *              NEVER_EXISTED.
 */
@isTest
public with sharing class TPB_LastVisitOOSAuditBatch_Test {
  private static final String SALESORG = '0001';
  private static final String OOS = 'OutOfStock';
  private static final String DISTRIBUTED = 'Distributed';

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
      Name = 'Audit Test Store',
      OperatingHoursId = accountOperatingHours.Id,
      // avoid the "Retailer" default record type, which triggers the
      // "TPB Automate Creation of Customer Extension & Visit Setting Records" flow
      // and its Sales Org validation - irrelevant to this test.
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Wholesaler')
        .getRecordTypeId()
    );
    insert accountOne;

    cgcloud__Job_Definition_List_Template__c jDLTOne = new cgcloud__Job_Definition_List_Template__c(
      Name = 'Distribution Activity Template',
      cgcloud__Consider_Account__c = true,
      cgcloud__Consider_Products__c = true,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert jDLTOne;

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

    cgcloud__Product_Template__c productTemplateOne = new cgcloud__Product_Template__c(
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__Active__c = true,
      Name = 'AuditProdTemplate',
      cgcloud__Description_Language_1__c = 'Product',
      cgcloud__Price_Required__c = false
    );
    insert productTemplateOne;

    // Product - will end up MISMATCH
    Product2 productMismatch = new Product2(
      Name = 'mismatch',
      cgcloud__Description_1_Language_1__c = 'mismatch',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productMismatch;
    // Product - will end up NEVER_EXISTED
    Product2 productNeverExisted = new Product2(
      Name = 'neverexisted',
      cgcloud__Description_1_Language_1__c = 'neverexisted',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productNeverExisted;
    // Product - will end up LEGITIMATELY_DELETED
    Product2 productDeleted = new Product2(
      Name = 'legitdeleted',
      cgcloud__Description_1_Language_1__c = 'legitdeleted',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productDeleted;
    // Product - will end up OK
    Product2 productOk = new Product2(
      Name = 'ok',
      cgcloud__Description_1_Language_1__c = 'ok',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateOne.Id
    );
    insert productOk;

    RetailStore rsObject = new RetailStore();
    rsObject.Street = 'U.S. Route 66 ';
    rsObject.City = 'Baltimore';
    rsObject.State = 'DC';
    rsObject.PostalCode = '20001';
    rsObject.Country = 'US';
    rsObject.Name = 'Test';
    rsObject.AccountId = accountOne.Id;
    insert rsObject;

    cgcloud__Job_Definition_List__c activityOne = new cgcloud__Job_Definition_List__c(
      cgcloud__Active__c = true,
      cgcloud__Approval_State__c = 'Not Relevant',
      cgcloud__Consider_History__c = true,
      cgcloud__Consider_Listing__c = false,
      cgcloud__Consider_Products__c = true,
      cgcloud__Default_Management_Type__c = 'Sales',
      cgcloud__Description_Language_1__c = 'Audit Test Activity',
      cgcloud__Job_Definition_List_Template__c = jDLTOne.Id,
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__User_Policy__c = 'All',
      cgcloud__Valid_From__c = System.today().addDays(-1),
      cgcloud__Valid_Thru__c = System.today().addDays(1),
      cgcloud__Visit_Template__c = vTOne.Id
    );
    insert activityOne;

    // Activity Customer - the account<->activity link
    cgcloud__Job_Definition_List_Account__c activityAccountOne = new cgcloud__Job_Definition_List_Account__c(
      cgcloud__Job_Definition_List__c = activityOne.Id,
      cgcloud__Account__c = accountOne.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityAccountOne;

    // Activity Product - exists but says Distributed (-> MISMATCH)
    cgcloud__Job_Definition_List_Product__c apMismatch = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityOne.Id,
      TPB_Account__c = accountOne.Id,
      cgcloud__Product__c = productMismatch.Id,
      TPB_EOV__c = DISTRIBUTED,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert apMismatch;

    // Activity Product - exists and already says OutOfStock (-> OK)
    cgcloud__Job_Definition_List_Product__c apOk = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityOne.Id,
      TPB_Account__c = accountOne.Id,
      cgcloud__Product__c = productOk.Id,
      TPB_EOV__c = OOS,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert apOk;

    // Activity Product created then deleted, simulating the 3-strike delist rule (-> LEGITIMATELY_DELETED)
    cgcloud__Job_Definition_List_Product__c apDeleted = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityOne.Id,
      TPB_Account__c = accountOne.Id,
      cgcloud__Product__c = productDeleted.Id,
      TPB_EOV__c = OOS,
      TPB_OOS_Number__c = 3,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert apDeleted;
    delete apDeleted;
    // No Activity Product at all is created for productNeverExisted (-> NEVER_EXISTED)

    // Visit - the account's most recent completed visit
    Visit visitOne = new Visit(
      AccountId = accountOne.Id,
      PlannedVisitStartTime = System.now().addDays(-1),
      PlannedVisitEndTime = System.now().addDays(-1),
      ActualVisitStartTime = System.now().addDays(-1),
      Account_Name__c = 'Audit Test Store',
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
      ActualVisitEndTime = System.now().addDays(-1).addSeconds(1),
      PlaceId = rsObject.Id
    );
    insert visitOne;

    List<cgcloud__Visit_Job__c> visitJobs = new List<cgcloud__Visit_Job__c>();
    visitJobs.add(
      new cgcloud__Visit_Job__c(
        cgcloud__Product__c = productMismatch.Id,
        cgcloud__Visit__c = visitOne.Id,
        TPB_EOV__c = OOS,
        cgcloud__Value__c = OOS
      )
    );
    visitJobs.add(
      new cgcloud__Visit_Job__c(
        cgcloud__Product__c = productNeverExisted.Id,
        cgcloud__Visit__c = visitOne.Id,
        TPB_EOV__c = OOS,
        cgcloud__Value__c = OOS
      )
    );
    visitJobs.add(
      new cgcloud__Visit_Job__c(
        cgcloud__Product__c = productDeleted.Id,
        cgcloud__Visit__c = visitOne.Id,
        TPB_EOV__c = OOS,
        cgcloud__Value__c = OOS
      )
    );
    visitJobs.add(
      new cgcloud__Visit_Job__c(
        cgcloud__Product__c = productOk.Id,
        cgcloud__Visit__c = visitOne.Id,
        TPB_EOV__c = OOS,
        cgcloud__Value__c = OOS
      )
    );
    insert visitJobs;
  }

  @isTest
  static void testAuditBatchClassifiesCorrectly() {
    TPB_LastVisitOOSAuditBatch batch = new TPB_LastVisitOOSAuditBatch('qa-test@example.com');

    Test.startTest();
    Database.executeBatch(batch, 50);
    Test.stopTest();

    System.assertEquals(
      4,
      TPB_LastVisitOOSAuditBatch.testTotalOosVisitJobsChecked,
      'All 4 OOS visit jobs should be checked'
    );
    System.assertEquals(1, TPB_LastVisitOOSAuditBatch.testTotalOk, 'One product should be correctly synced (OK)');
    System.assertEquals(1, TPB_LastVisitOOSAuditBatch.testTotalMismatch, 'One product should be a mismatch');
    System.assertEquals(
      1,
      TPB_LastVisitOOSAuditBatch.testTotalLegitimatelyDeleted,
      'One product should be legitimately deleted'
    );
    System.assertEquals(
      1,
      TPB_LastVisitOOSAuditBatch.testTotalNeverExisted,
      'One product should have never existed'
    );
    // header row + 3 exception rows (OK is intentionally excluded from the report)
    System.assertEquals(
      4,
      TPB_LastVisitOOSAuditBatch.testReportRows.size(),
      'Report should contain header + 3 exception rows'
    );
  }

  @isTest
  static void testMultipleRecipients() {
    TPB_LastVisitOOSAuditBatch batch = new TPB_LastVisitOOSAuditBatch(
      'a@example.com,b@example.com'
    );

    Test.startTest();
    Database.executeBatch(batch, 50);
    Test.stopTest();

    System.assertEquals(
      4,
      TPB_LastVisitOOSAuditBatch.testTotalOosVisitJobsChecked,
      'Batch should complete successfully with multiple recipients'
    );
  }

  /**
   * @description Fully self-contained (own account/visit/products - not the shared
   * @testSetup data, to avoid disturbing the exact-count assertions above). Exercises 3 of
   * the 4 MismatchReason outcomes: an Activity Product synced from an older visit, a
   * Calculated_Distribution__c override, and a genuinely unexplained case. (The 4th,
   * CASH_SALE_OR_FREE_ITEM_OVERRIDE, is a simple key lookup against Order/Order Item data
   * that isn't exercised here, since building a valid Order in this org's test context
   * requires unrelated Delivery Recipient/role setup outside this fix's scope.)
   */
  @isTest
  static void testMismatchReasonClassification() {
    // Account
    cgcloud__Account_Template__c accountTemplateMR = new cgcloud__Account_Template__c(
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store'
    );
    insert accountTemplateMR;
    OperatingHours mrOperatingHours = new OperatingHours(
      Name = 'mr',
      TimeZone = 'America/New_York'
    );
    insert mrOperatingHours;
    Account accountMR = new Account(
      cgcloud__Account_Template__c = accountTemplateMR.Id,
      ShippingCity = 'Danville',
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingPostalCode = '24540',
      ShippingState = 'VA',
      ShippingStateCode = 'VA',
      ShippingStreet = '77 Mismatch Reason Road',
      Name = 'Mismatch Reason Test Store',
      OperatingHoursId = mrOperatingHours.Id,
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Wholesaler')
        .getRecordTypeId()
    );
    insert accountMR;

    cgcloud__Job_Definition_List_Template__c jDLTMR = new cgcloud__Job_Definition_List_Template__c(
      Name = 'MR Activity Template',
      cgcloud__Consider_Account__c = true,
      cgcloud__Consider_Products__c = true,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert jDLTMR;

    cgcloud__Visit_Template__c vTMR = new cgcloud__Visit_Template__c(
      Name = 'MR Visit Template',
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
    insert vTMR;

    cgcloud__Product_Template__c productTemplateMR = new cgcloud__Product_Template__c(
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__Active__c = true,
      Name = 'MRProdTemplate',
      cgcloud__Description_Language_1__c = 'Product',
      cgcloud__Price_Required__c = false
    );
    insert productTemplateMR;

    Product2 productOlderVisit = new Product2(
      Name = 'olderVisitProduct',
      cgcloud__Description_1_Language_1__c = 'olderVisitProduct',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateMR.Id
    );
    insert productOlderVisit;
    Product2 productCalcDist = new Product2(
      Name = 'calcDistProduct',
      cgcloud__Description_1_Language_1__c = 'calcDistProduct',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateMR.Id
    );
    insert productCalcDist;
    Product2 productUnexplained = new Product2(
      Name = 'unexplainedProduct',
      cgcloud__Description_1_Language_1__c = 'unexplainedProduct',
      IsActive = true,
      cgcloud__Product_Template__c = productTemplateMR.Id
    );
    insert productUnexplained;

    RetailStore rsMR = new RetailStore();
    rsMR.Street = '77 Mismatch Reason Road';
    rsMR.City = 'Baltimore';
    rsMR.State = 'DC';
    rsMR.PostalCode = '20001';
    rsMR.Country = 'US';
    rsMR.Name = 'MRTest';
    rsMR.AccountId = accountMR.Id;
    insert rsMR;

    cgcloud__Job_Definition_List__c activityMR = new cgcloud__Job_Definition_List__c(
      cgcloud__Active__c = true,
      cgcloud__Approval_State__c = 'Not Relevant',
      cgcloud__Consider_History__c = true,
      cgcloud__Consider_Listing__c = false,
      cgcloud__Consider_Products__c = true,
      cgcloud__Default_Management_Type__c = 'Sales',
      cgcloud__Description_Language_1__c = 'MR Activity',
      cgcloud__Job_Definition_List_Template__c = jDLTMR.Id,
      cgcloud__Sales_Org__c = SALESORG,
      cgcloud__User_Policy__c = 'All',
      cgcloud__Valid_From__c = System.today().addDays(-10),
      cgcloud__Valid_Thru__c = System.today().addDays(10),
      cgcloud__Visit_Template__c = vTMR.Id
    );
    insert activityMR;
    cgcloud__Job_Definition_List_Account__c activityAccountMR = new cgcloud__Job_Definition_List_Account__c(
      cgcloud__Job_Definition_List__c = activityMR.Id,
      cgcloud__Account__c = accountMR.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert activityAccountMR;

    // An OLDER visit, used only to give productOlderVisit's Activity Product a
    // "last-synced" Visit Job that is NOT the current visit's own Visit Job.
    Visit olderVisit = new Visit(
      AccountId = accountMR.Id,
      PlannedVisitStartTime = System.now().addDays(-30),
      PlannedVisitEndTime = System.now().addDays(-30),
      ActualVisitStartTime = System.now().addDays(-30),
      Account_Name__c = 'Mismatch Reason Test Store',
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
      cgcloud__Visit_Template__c = vTMR.Id,
      cgcloud__Week__c = 7,
      ActualVisitEndTime = System.now().addDays(-30).addSeconds(1),
      PlaceId = rsMR.Id
    );
    insert olderVisit;
    cgcloud__Visit_Job__c olderVisitJob = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productOlderVisit.Id,
      cgcloud__Visit__c = olderVisit.Id,
      TPB_EOV__c = DISTRIBUTED,
      cgcloud__Value__c = DISTRIBUTED
    );
    insert olderVisitJob;

    // The current visit - the account's most recent completed visit
    Visit currentVisit = new Visit(
      AccountId = accountMR.Id,
      PlannedVisitStartTime = System.now().addDays(-1),
      PlannedVisitEndTime = System.now().addDays(-1),
      ActualVisitStartTime = System.now().addDays(-1),
      Account_Name__c = 'Mismatch Reason Test Store',
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
      cgcloud__Visit_Template__c = vTMR.Id,
      cgcloud__Week__c = 7,
      ActualVisitEndTime = System.now().addDays(-1).addSeconds(1),
      PlaceId = rsMR.Id
    );
    insert currentVisit;

    // Raw answer is OutOfStock for all 3 - each Visit Job differs only in what
    // makes its eventual MISMATCH explainable (or not).
    cgcloud__Visit_Job__c vjOlderVisit = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productOlderVisit.Id,
      cgcloud__Visit__c = currentVisit.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS
    );
    cgcloud__Visit_Job__c vjCalcDist = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productCalcDist.Id,
      cgcloud__Visit__c = currentVisit.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS,
      Calculated_Distribution__c = DISTRIBUTED
    );
    cgcloud__Visit_Job__c vjUnexplained = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productUnexplained.Id,
      cgcloud__Visit__c = currentVisit.Id,
      TPB_EOV__c = OOS,
      cgcloud__Value__c = OOS
    );
    insert new List<cgcloud__Visit_Job__c>{ vjOlderVisit, vjCalcDist, vjUnexplained };

    // 3 Activity Products, each already showing Distributed (mismatched vs the raw
    // OutOfStock answer). Only their TPB_Visit_Job__c pointer differs.
    cgcloud__Job_Definition_List_Product__c apOlderVisit = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityMR.Id,
      TPB_Account__c = accountMR.Id,
      cgcloud__Product__c = productOlderVisit.Id,
      TPB_EOV__c = DISTRIBUTED,
      TPB_Visit_Job__c = olderVisitJob.Id, // points to the OLD visit's job, not the current one
      cgcloud__Sales_Org__c = SALESORG
    );
    cgcloud__Job_Definition_List_Product__c apCalcDist = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityMR.Id,
      TPB_Account__c = accountMR.Id,
      cgcloud__Product__c = productCalcDist.Id,
      TPB_EOV__c = DISTRIBUTED,
      TPB_Visit_Job__c = vjCalcDist.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    cgcloud__Job_Definition_List_Product__c apUnexplained = new cgcloud__Job_Definition_List_Product__c(
      cgcloud__Job_Definition_List__c = activityMR.Id,
      TPB_Account__c = accountMR.Id,
      cgcloud__Product__c = productUnexplained.Id,
      TPB_EOV__c = DISTRIBUTED,
      TPB_Visit_Job__c = vjUnexplained.Id,
      cgcloud__Sales_Org__c = SALESORG
    );
    insert new List<cgcloud__Job_Definition_List_Product__c>{
      apOlderVisit,
      apCalcDist,
      apUnexplained
    };

    Test.startTest();
    TPB_LastVisitOOSAuditBatch batch = new TPB_LastVisitOOSAuditBatch('qa-test@example.com');
    Database.executeBatch(batch, 50);
    Test.stopTest();

    // Scope assertions to THIS test's own account rows only - the shared @testSetup
    // data (accountOne's "mismatch" product, present in every test method's
    // transaction) is also picked up by this batch's account-wide scan, so the
    // global static counters above aren't safe to assert on directly here.
    Integer olderVisitCount = 0;
    Integer calcDistCount = 0;
    Integer unexplainedCount = 0;
    for (String row : TPB_LastVisitOOSAuditBatch.testReportRows) {
      if (!row.contains(accountMR.Id)) {
        continue;
      }
      if (row.startsWith('MISMATCH,OLDER_VISIT_PROCESSED_LATER,')) {
        olderVisitCount++;
      } else if (row.startsWith('MISMATCH,CALCULATED_DISTRIBUTION_FIELD_OVERRIDE,')) {
        calcDistCount++;
      } else if (row.startsWith('MISMATCH,UNEXPLAINED,')) {
        unexplainedCount++;
      }
    }
    System.assertEquals(
      1,
      olderVisitCount,
      'One mismatch should be explained by an older visit having been synced instead'
    );
    System.assertEquals(
      1,
      calcDistCount,
      'One mismatch should be explained by a populated, differing Calculated_Distribution__c'
    );
    System.assertEquals(1, unexplainedCount, 'One mismatch should remain genuinely unexplained');
  }
}