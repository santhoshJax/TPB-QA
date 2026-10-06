/**
 * @author Mi Li
 * @date 9/26/2023
 * @description CON0001729-1981  MSA Calculated Distribution Updates
 */
@isTest
private class TPB_VisitJobUpdateBatch_Test {
  @testSetup
  static void setup() {
    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();
    //create visit template.
    cgcloud__Visit_Template__c visitTemplate = new cgcloud__Visit_Template__c(
      //insert visit template as active.
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
      cgcloud__Description_Language_1__c = 'Distribution Visit Template',
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
      cgcloud__Sales_Org__c = '0001',
      cgcloud__Sort__c = 5,
      cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User',
      Name = 'Distribution Visit Template'
    );
    //insert visitTemplate
    insert visitTemplate;

    // cgcloud__Product_Template__c
    cgcloud__Product_Template__c productTemplateOne = new cgcloud__Product_Template__c(
      cgcloud__Sales_Org__c = '0001',
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

    //create retail store for visit creating.
    RetailStore rsObject = new RetailStore();
    rsObject.Street = 'U.S. Route 66 ';
    rsObject.City = 'Baltimore';
    rsObject.State = 'DC';
    rsObject.PostalCode = '20001';
    rsObject.Country = 'US';
    rsObject.Name = 'Test';
    //create retail store base on account test data.
    rsObject.AccountId = accObj.Id;
    //insert rsObject
    insert rsObject;

    //create visit test data.
    Visit visitObj = new Visit();
    //set account relationship.
    visitObj.AccountId = accObj.Id;
    visitObj.Account_Name__c = accObj.Name;
    //set actual visit start time as now.
    visitObj.ActualVisitStartTime = system.now();
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
    visitObj.cgcloud__PSI__c = 0;
    visitObj.cgcloud__PSQ_Rate__c = 0;
    visitObj.cgcloud__Responsible__c = UserInfo.getUserId();
    //set visit template.
    visitObj.cgcloud__Visit_Template__c = visitTemplate.Id;
    visitObj.cgcloud__Week__c = 7;
    //set planned start time as now.
    visitObj.PlannedVisitStartTime = Datetime.newInstance(
      //year
      Integer.valueOf(Date.today().year()),
      //month
      Integer.valueOf(Date.today().month()),
      //day
      1,
      9,
      0,
      0
    );
    //set planned end time as now.
    visitObj.PlannedVisitEndTime = Datetime.newInstance(
      //year
      Integer.valueOf(Date.today().year()),
      //month
      Integer.valueOf(Date.today().month()),
      //day
      28,
      9,
      0,
      0
    );
    //PlaceId = rsObject.Id
    visitObj.PlaceId = rsObject.Id;
    visitObj.Quarterly_Base_Call__c = true;
    //insert visitObj
    insert visitObj;

    //create visit job data
    cgcloud__Visit_Job__c visitJobYear = new cgcloud__Visit_Job__c(
      cgcloud__Product__c = productOne.Id,
      cgcloud__Visit__c = visitObj.Id,
      cgcloud__Value__c = 'Distributed',
      cgcloud__Visit_Date__c = date.today().addDays(-1)
    );
    insert visitJobYear;
    //insert visit job data

    visitObj.Status = 'Completed';
    visitObj.cgcloud__Completed_Date__c = System.today().addYears(-1);
    //update visitObj
    update visitObj;
  }

  @isTest
  static void testVisitJobUpdateBatch() {
    //Test startTest
    System.Test.startTest();
    Visit obj = [
      SELECT Id
      FROM Visit
      WHERE
        Status = 'Completed'
        AND Last_Call__c = TRUE
        AND cgcloud__Visit_Template__c != NULL
      LIMIT 1
    ];
    //TPB_VisitJobUpdateBatch
    TPB_VisitJobUpdateBatch batch = new TPB_VisitJobUpdateBatch();
    //execute Batch
    Database.executeBatch(batch);

    //TPB_VisitJobUpdateBatch
    TPB_VisitJobUpdateBatch batch2 = new TPB_VisitJobUpdateBatch(
      new Set<Id>{ obj.Id }
    );
    //execute Batch
    Database.executeBatch(batch2);

    //Test stopTest
    System.Test.stopTest();
    //assert batch job result.
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Calculated_Distribution__c = 'OutOfStock'
      ],
      0
    );
  }
}