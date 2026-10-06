/**
 * @author Zeen Liu
 * @date 2023-02-24
 * @description This class is used to create test data used in test classes
 */
public with sharing class TPB_TestFactory {
  // result data
  public static final String RTN_KEY_OK = 'OK';
  public static final String RTN_KEY_NG = 'NG';
  public static final String RTN_KEY_RESULT = 'result';
  public static final String RTN_KEY_DATA = 'data';
  public static final String RTN_KEY_ERR_MSG = 'errorMessage';

  //Order Item Unit: Carton, UoM: Carton
  public static final String CONSUMERUNITEACH = 'ConsumerUnit';
  public static final String SALESUNITCARTON = 'SalesUnit';
  public static final String LAYERCASE = 'Layer';

  //status active type
  public static final String STATUS_ACTIVE = 'Active';

  //cgcloud__Inventory_Transaction_Template__c name type
  public static final String INVENTORY_TRANSACTION_TEMPLATE_ADD = 'TPB Transaction Template (Add)';
  public static final String INVENTORY_TRANSACTION_TEMPLATE_CASHSALE = 'TPB Transaction Template (Cashsale)';

  //Inventory_Control_Template name type
  public static final String INVENTORY_CONTROL_TEMPLATE = 'TPB Control Template';

  // Permission sharing for attachments such as files
  public static final String CONTENT_DOCUMENT_LINK_SHARETYPE = 'I';
  public static final String CONTENT_DOCUMENT_LINK_VISIBILITY = 'AllUsers';

  //default sales org.
  public static String salesOrg = '0001';
  public static String accountRecordtype = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Wholesaler')
    .getRecordTypeId();

  //Order recordType Id
  public static String orderVanLoadRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
    .get('Van_Load')
    .getRecordTypeId();

  public static String orderMassPrebookRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
    .get('Mass_Prebook')
    .getRecordTypeId();

  //TPB_Promotion_Allocation_Item__c Org_Unit recordType Id
  public static String proAllocationItemOrgRecordTypeId = Schema.SObjectType.TPB_Promotion_Allocation_Item__c.getRecordTypeInfosByDeveloperName()
    .get('Org_Unit')
    .getRecordTypeId();

  public static String proAllocationItemStoreRecordTypeId = Schema.SObjectType.TPB_Promotion_Allocation_Item__c.getRecordTypeInfosByDeveloperName()
    .get('Store_Allocations')
    .getRecordTypeId();

  //default visit template.
  public static String strVisitTemplate = 'Distribution Visit Template';
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create test product test data.
   * @return Product2
   */
  public static Product2 createProduct() {
    //create product template.
    cgcloud__Product_Template__c proTemplate = new cgcloud__Product_Template__c(
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Product',
      cgcloud__Price_Required__c = false,
      //set sales org on product template.
      cgcloud__Sales_Org__c = salesOrg,
      Name = 'Product'
    );
    insert proTemplate;
    //create product for test.
    Product2 proObj = new Product2(
      Budget_Code__c = '3352-68-185',
      cgcloud__Competitive_Product__c = false,
      cgcloud__Consumer_Goods_Product_Code__c = '001',
      //set the start date as yesterday.
      cgcloud__Delivery_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Delivery_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Description_1_Language_1__c = 'NICOTINE CHEW - TPR',
      //set the start date as yesterday.
      cgcloud__Field_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Field_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__Fund_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Fund_Valid_Thru__c = system.today().addDays(1),
      cgcloud__GTIN__c = '00001',
      cgcloud__Is_Bill_Of_Material__c = false,
      //set the start date as yesterday.
      cgcloud__KAM_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__KAM_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__New_Item_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__New_Item_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Order_Ability__c = 2,
      cgcloud__Power_Supply_Connected__c = false,
      cgcloud__Product_Level__c = 'Product',
      cgcloud__Product_Template__c = proTemplate.Id,
      cgcloud__Product_Type__c = 'Commodity',
      cgcloud__Rounding_Rule_Validation__c = 2,
      cgcloud__Short_Description_Language_1__c = 'NICOTINE CHEW - TPR',
      cgcloud__State__c = '4',
      Clearing_House_Flag__c = false,
      Current_Shiplist_Item__c = false,
      Cycle_Group__c = 'NA',
      Default_Zone__c = '2',
      Discount__c = false,
      Display_Group__c = 'COMPETITIVE',
      IsActive = true,
      Item_ID__c = '0000',
      Name = 'NICOTINE CHEW - TPR'
    );
    insert proObj;
    return proObj;
  }

  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create product template.
   * @return Id
   */
  public static Id createProductTemplate() {
    //create product template.
    cgcloud__Product_Template__c proTemplate = new cgcloud__Product_Template__c(
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Product',
      cgcloud__Price_Required__c = false,
      //set sales org on product template.
      cgcloud__Sales_Org__c = salesOrg,
      Name = 'Product'
    );
    insert proTemplate;
    return proTemplate.Id;
  }

  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @param   name    product name
   * @param   templateId    product template Id
   * @description This method is used to create product.
   * @return Product2
   */
  public static Product2 createProduct(String name, Id templateId) {
    Product2 proObj = new Product2(
      Budget_Code__c = '3352-68-185',
      cgcloud__Competitive_Product__c = false,
      //set the start date as yesterday.
      cgcloud__Delivery_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Delivery_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Description_1_Language_1__c = name,
      //set the start date as yesterday.
      cgcloud__Field_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Field_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__Fund_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Fund_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Is_Bill_Of_Material__c = false,
      //set the start date as yesterday.
      cgcloud__KAM_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__KAM_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__New_Item_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__New_Item_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Order_Ability__c = 2,
      cgcloud__Power_Supply_Connected__c = false,
      cgcloud__Product_Level__c = 'Product',
      cgcloud__Product_Template__c = templateId,
      cgcloud__Product_Type__c = 'Commodity',
      cgcloud__Rounding_Rule_Validation__c = 2,
      cgcloud__Short_Description_Language_1__c = name,
      cgcloud__State__c = '4',
      Clearing_House_Flag__c = false,
      Current_Shiplist_Item__c = false,
      Cycle_Group__c = 'NA',
      Default_Zone__c = '2',
      Discount__c = false,
      Display_Group__c = 'COMPETITIVE',
      IsActive = true,
      Name = name
    );
    insert proObj;
    return proObj;
  }

  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create visit template test data.
   */
  public static void createVisitTemplate() {
    //create visit template.
    cgcloud__Visit_Template__c distributeVisitTemplate = new cgcloud__Visit_Template__c();
    //set template as active
    distributeVisitTemplate.cgcloud__Active__c = true;
    distributeVisitTemplate.cgcloud__Add_Job_Policy__c = true;
    distributeVisitTemplate.cgcloud__Auto_Status__c = 'Planned';
    distributeVisitTemplate.cgcloud__Cancel_Reason_Required__c = false;
    distributeVisitTemplate.cgcloud__Capture_Proceeding_Time__c = true;
    distributeVisitTemplate.cgcloud__Check_Overlap__c = false;
    distributeVisitTemplate.cgcloud__Company_Required__c = 'Mandatory';
    distributeVisitTemplate.cgcloud__Consider_POS_Check__c = true;
    distributeVisitTemplate.cgcloud__Creation_Platform__c = 'Both';
    distributeVisitTemplate.cgcloud__Default_Duration__c = 30;
    distributeVisitTemplate.cgcloud__Delete_Allowed__c = true;
    //set description.
    distributeVisitTemplate.cgcloud__Description_Language_1__c = strVisitTemplate;
    distributeVisitTemplate.cgcloud__Display_Promotions__c = true;
    distributeVisitTemplate.cgcloud__Historical_Products__c = 'No';
    distributeVisitTemplate.cgcloud__KPI_Relevant__c = 'All';
    distributeVisitTemplate.cgcloud__Loc_Capture_During_Cancel__c = true;
    distributeVisitTemplate.cgcloud__Loc_Capture_During_Complete__c = true;
    distributeVisitTemplate.cgcloud__Max_Pictures__c = 10;
    distributeVisitTemplate.cgcloud__Meta_Type__c = 'Call';
    distributeVisitTemplate.cgcloud__Mobility_Color__c = '6688BB';
    distributeVisitTemplate.cgcloud__Mobility_Relevant__c = true;
    distributeVisitTemplate.cgcloud__Mobility_User_Guidance__c = 'Sales';
    distributeVisitTemplate.cgcloud__Promotion_Finding_Lead_Time__c = 365;
    //set default sales org.
    distributeVisitTemplate.cgcloud__Sales_Org__c = salesOrg;
    distributeVisitTemplate.cgcloud__Sort__c = 5;
    distributeVisitTemplate.cgcloud__Sync_Options__c = 'CompleteCancelCall';
    distributeVisitTemplate.cgcloud__Tag_Media_Date_Time__c = false;
    distributeVisitTemplate.cgcloud__Tag_Media_Geo_Location__c = false;
    distributeVisitTemplate.cgcloud__Update_Planned_Times__c = false;
    distributeVisitTemplate.cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User';
    //set default name
    distributeVisitTemplate.Name = strVisitTemplate;
    insert distributeVisitTemplate;
  }
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create account test data.
   * @return   Account
   */
  public static Account createAccount() {
    //create account template
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
    //create account
    Account accObj = new Account(
      BillingCountry = 'US',
      BillingCountryCode = 'US',
      Cash_Sales__c = false,
      //set account template.
      cgcloud__Account_Template__c = accTemplate.Id,
      Clearing_House_Participant__c = false,
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingLatitude = 38.90996,
      ShippingLongitude = -77.01893,
      ShippingPostalCode = '20001',
      ShippingState = 'DC',
      ShippingStreet = 'U.S. Route 66 ',
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
   * @author Zeen Liu
   * @date 2023-02-24
   * @description  This method is used to create visit test data.
   * @param   accObj    Account
   * @return  Visit
   */
  public static Visit createVisit(Account accObj) {
    //create visit template.
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
    //create retailstore for visit creating.
    RetailStore rsObject = new RetailStore();
    rsObject.Street = 'U.S. Route 66 ';
    rsObject.City = 'Baltimore';
    rsObject.State = 'DC';
    rsObject.PostalCode = '20001';
    rsObject.Country = 'US';
    rsObject.Name = 'Test';
    //create retailstore base on account test data.
    rsObject.AccountId = accObj.Id;
    insert rsObject;
    //create visit test data.
    Visit visitObj = new Visit();
    //set account relationship.
    visitObj.AccountId = accObj.Id;
    visitObj.Account_Name__c = accObj.Name;
    //set actualvisitstarttime as now.
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
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create visit job test data.
   * @param   visitObj    Visit
   * @param   proObj    Product2
   */
  public static void createVisitJob(Visit visitObj, Product2 proObj) {
    //create data type.
    cgcloud__Data_Type__c dataType = new cgcloud__Data_Type__c();
    dataType.Name = 'DomPrdDistributed';
    insert dataType;
    //create job template.
    cgcloud__Job_Template__c jobTemplateObj = new cgcloud__Job_Template__c();
    jobTemplateObj.Name = 'Survey';
    jobTemplateObj.cgcloud__Product_Reference__c = true;
    insert jobTemplateObj;
    //create job definition template.
    cgcloud__Job_Definition_Template__c jobTemplate = new cgcloud__Job_Definition_Template__c();
    jobTemplate.cgcloud__Active__c = true;
    //set data type.
    jobTemplate.cgcloud__Data_Type__c = dataType.Id;
    //set job template.
    jobTemplate.cgcloud__Job_Template__c = jobTemplateObj.Id;
    jobTemplate.cgcloud__Consider_Max_Value__c = false;
    jobTemplate.cgcloud__Consider_Min_Value__c = false;
    jobTemplate.cgcloud__Description_Language_1__c = 'Distributed';
    jobTemplate.cgcloud__Measure_Type__c = 'Store';
    jobTemplate.cgcloud__Max_Value__c = 0;
    jobTemplate.cgcloud__Min_Value__c = 0;
    jobTemplate.cgcloud__Perfect_Store_Question__c = false;
    //set sales org.
    jobTemplate.cgcloud__Sales_Org__c = salesOrg;
    insert jobTemplate;
    //create vist job.
    cgcloud__Visit_Job__c visitJob = new cgcloud__Visit_Job__c();
    visitJob.cgcloud__Done__c = true;
    //set job definition template.
    visitJob.cgcloud__Job_Definition_Template__c = jobTemplate.Id;
    visitJob.cgcloud__Manually__c = true;
    visitJob.cgcloud__Number_of_Pictures__c = 0;
    //set product.
    visitJob.cgcloud__Product__c = proObj.Id;
    visitJob.cgcloud__Value__c = 'OutOfStock';
    //set visit date as today.
    visitJob.cgcloud__Visit_Date__c = system.today();
    //set visit.
    visitJob.cgcloud__Visit__c = visitObj.Id;
    insert visitJob;
  }
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create order test data.
   * @param   visitObj    Visit
   * @return  cgcloud__Order__c
   */
  public static cgcloud__Order__c createAdOrder(Visit visitObj) {
    //create order template.
    cgcloud__Order_Template__c orderTemplate = new cgcloud__Order_Template__c();
    orderTemplate.cgcloud__Active__c = true;
    orderTemplate.Name = 'Test';
    insert orderTemplate;
    //create order.
    cgcloud__Order__c orderObj = new cgcloud__Order__c();
    orderObj.cgcloud__Accountable__c = UserInfo.getUserId();
    //set delivery date as today.
    orderObj.cgcloud__Delivery_Date__c = system.today();
    orderObj.cgcloud__Document_Type__c = 'OrderEntry';
    //set initiation date as today.
    orderObj.cgcloud__Initiation_Date__c = system.today();
    //set order template.
    orderObj.cgcloud__Order_Template__c = orderTemplate.Id;
    //set visit.
    orderObj.cgcloud__Visit__c = visitObj.Id;
    insert orderObj;
    return orderObj;
  }
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description  This method is used to create order item test data.
   * @param   orderObj  cgcloud__Order__c
   * @param   proObj    Product2
   * @return  cgcloud__Order_Item__c
   */
  public static cgcloud__Order_Item__c createAdOrderItem(
    cgcloud__Order__c orderObj,
    Product2 proObj
  ) {
    //create order item template.
    cgcloud__Order_Item_Template__c orderItemTemplate = new cgcloud__Order_Item_Template__c();
    //set template as active.
    orderItemTemplate.cgcloud__Active__c = true;
    orderItemTemplate.Name = 'Cash Sale';
    insert orderItemTemplate;
    //create order item.
    cgcloud__Order_Item__c orderItemObj = new cgcloud__Order_Item__c();
    //set product.
    orderItemObj.cgcloud__Product__c = proObj.Id;
    //set order.
    orderItemObj.cgcloud__Order__c = orderObj.Id;
    //set order item template.
    orderItemObj.cgcloud__Order_Item_Template__c = orderItemTemplate.Id;
    orderItemObj.cgcloud__Value__c = 10;
    orderItemObj.cgcloud__Quantity__c = 1;
    insert orderItemObj;
    return orderItemObj;
  }
  /**
   * @author Zeen Liu
   * @date 2023-02-24
   * @description This method is used to create order item test data.
   * @return  return cgcloud__Sales_Organization__c
   */
  public static cgcloud__Sales_Organization__c createSalesOrg() {
    //create sales org.
    cgcloud__Sales_Organization__c salesOrgObj = new cgcloud__Sales_Organization__c();
    salesOrgObj.cgcloud__Account_Number__c = '444-4444-4444';
    salesOrgObj.cgcloud__Account_Product_List_Type__c = 'timedependent';
    salesOrgObj.cgcloud__APM_Product_List_Relevant_Measures__c = 'BASP';
    salesOrgObj.cgcloud__Automatic_Promotion_Push__c = false;
    salesOrgObj.cgcloud__Available_Trade_Calendar_Color_Schemas__c = '1;2';
    salesOrgObj.cgcloud__Bank_Code__c = '3456';
    salesOrgObj.cgcloud__BIN__c = '123';
    salesOrgObj.cgcloud__City__c = 'New York';
    salesOrgObj.cgcloud__Country__c = 'United States';
    salesOrgObj.cgcloud__Currency__c = 'USD';
    salesOrgObj.cgcloud__Default_Mobility_Visit_Color__c = '0176D3';
    salesOrgObj.cgcloud__Description_Language_1__c = 'USA Sales Org';
    salesOrgObj.cgcloud__Distance_Unit__c = 'miles';
    salesOrgObj.cgcloud__DMR_Product_List_Relevant_Measures__c = 'SHIP';
    salesOrgObj.cgcloud__Enable_Account_Set_Search_in_TPC__c = false;
    salesOrgObj.cgcloud__Enable_Acc_Cat_WDS_Profile__c = true;
    salesOrgObj.cgcloud__Enable_Auto_Tactic_Fund_Assignment__c = false;
    salesOrgObj.cgcloud__Enable_Payment_Overwrite__c = false;
    salesOrgObj.cgcloud__Enable_Subperiod_Writeback__c = false;
    salesOrgObj.cgcloud__Enable_Subset_Load_Optimization__c = false;
    salesOrgObj.cgcloud__Enable_Sub_Account_Search_In_TPC__c = false;
    salesOrgObj.cgcloud__Enable_Tactic_Condition_Creation__c = false;
    salesOrgObj.cgcloud__First_Day_Of_Week__c = '2';
    salesOrgObj.cgcloud__First_Week_Of_Year__c = '2';
    salesOrgObj.cgcloud__Global_Sales_Org__c = false;
    salesOrgObj.cgcloud__Has_Activated_Business_Years__c = true;
    salesOrgObj.cgcloud__Language_1__c = 'en';
    salesOrgObj.cgcloud__Language_2__c = 'de';
    salesOrgObj.cgcloud__No__c = '34';
    salesOrgObj.cgcloud__Phone__c = '5678 345 234';
    salesOrgObj.cgcloud__PMR_Product_List_Relevant_Measures__c = 'PIV;PTV';
    salesOrgObj.cgcloud__PM_Product_List_Relevant_Measures__c = 'COGS';
    salesOrgObj.cgcloud__Promotion_Access_Definition_Policy__c = 'Combined_Anchors';
    salesOrgObj.cgcloud__Promotion_Aggregation_Level__c = 'Brand';
    salesOrgObj.cgcloud__Sales_Organization_Cluster__c = 'NA';
    salesOrgObj.cgcloud__Sales_Org_Value__c = salesOrg;
    salesOrgObj.cgcloud__Street__c = 'Alford Street';
    salesOrgObj.cgcloud__Tax_Jurisdiction_Code__c = '99900088843';
    salesOrgObj.cgcloud__Used_Reference_Date__c = 'dynamic';
    salesOrgObj.cgcloud__Visit_Start_Time__c = '08:30';
    salesOrgObj.cgcloud__Volume_Unit__c = 'l';
    salesOrgObj.cgcloud__Weight_Unit__c = 'kg';
    salesOrgObj.cgcloud__WMI_Product_List_Relevant_Measures__c = 'CONS;BSL';
    salesOrgObj.cgcloud__Zip_Code__c = '24678';
    salesOrgObj.Name = salesOrg;
    insert salesOrgObj;
    return salesOrgObj;
  }

  /**
   * @author Tina Wu
   * @date 2023-04-14
   * @description This method is used to create Retail Account test data.
   * @return  return Account
   */
  /**
   * Ensures one active Visit Template named 'Distribution Visit Template' exists.
   * Safe to call multiple times — inserts only if absent. Required before inserting
   * any Retailer Account because the flow looks up this record and a validation rule
   * rejects a null lookup.
   */
  public static void ensureVisitTemplate() {
    List<cgcloud__Visit_Template__c> existing = [
      SELECT Id FROM cgcloud__Visit_Template__c
      WHERE Name = 'Distribution Visit Template'
      AND cgcloud__Active__c = true
      LIMIT 1
    ];
    if (existing.isEmpty()) {
      cgcloud__Visit_Template__c vt = new cgcloud__Visit_Template__c();
      vt.Name = 'Distribution Visit Template';
      vt.cgcloud__Active__c = true;
      insert vt;
    }
  }

  public static Account createRetailAccount() {
    ensureVisitTemplate();
    Account acc = new Account();
    acc.Name = 'Test Account';
    acc.ShippingState = 'NM';
    acc.ShippingCity = 'Baltimore';
    acc.ShippingStreet = 'U.S. Route 66 ';
    acc.ShippingPostalCode = '21201';
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Retailer')
      .getRecordTypeId();
    insert acc;

    return acc;
  }

  /**
   * @author Tina Wu
   * @date 2023-04-14
   * @description This method is used to create Opportunity test data.
   * @param   accId  AccountId
   * @return  return Opportunity
   */
  public static Opportunity createOpportunity(Id accId) {
    Opportunity opp = new Opportunity();
    opp.AccountId = accId;
    opp.StageName = 'Qualification';
    opp.CloseDate = date.today().addDays(30);
    opp.Name = 'Test Opp';
    insert opp;

    return opp;
  }

  /**
   * @author Mi Li
   * @date 2023-5-31
   * @description This method is used to create Inventory test data.
   * @param   strUserId     String
   * @param   strProductId  String
   * @return  return cgcloud__Inventory__c
   */
  public static cgcloud__Inventory__c createInventory(
    String strUserId,
    String strProductId
  ) {
    cgcloud__Trigger_Setting__c customset = new cgcloud__Trigger_Setting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Name = 'InventoryTrigger',
      cgcloud__Deactivate__c = true
    );
    insert customset;

    //create CP_Key_Type  With Sate
    cgcloud__CP_Key_Type__c objKeyTypeWithSate = new cgcloud__CP_Key_Type__c();
    objKeyTypeWithSate.Name = 'PS101';
    objKeyTypeWithSate.cgcloud__Consider_Product_Hierarchy__c = true;
    objKeyTypeWithSate.cgcloud__Sales_Org__c = '0001';
    //insert KeyType
    insert objKeyTypeWithSate;

    objKeyTypeWithSate = new cgcloud__CP_Key_Type__c();
    objKeyTypeWithSate.Name = 'PS102';
    objKeyTypeWithSate.cgcloud__Consider_Product_Hierarchy__c = true;
    objKeyTypeWithSate.cgcloud__Sales_Org__c = '0001';
    //insert KeyType
    insert objKeyTypeWithSate;

    // cgcloud__Warehouse__c
    cgcloud__Warehouse__c warehouseOne = new cgcloud__Warehouse__c(
      Name = 'testWarehouse1',
      cgcloud__Sales_Org__c = salesOrg,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set state
      cgcloud__State__c = 'NY'
    );
    insert warehouseOne;

    //cgcloud__Tour_Template__c
    cgcloud__Tour_Template__c tourTemplateOne = new cgcloud__Tour_Template__c(
      Name = 'testTourTemplate1',
      cgcloud__Sales_Org__c = salesOrg,
      //set description
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1'
    );
    insert tourTemplateOne;
    //cgcloud__Tour__c
    cgcloud__Tour__c tourOne = new cgcloud__Tour__c(
      Name = 'testTour3',
      cgcloud__Sales_Org__c = salesOrg,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set default driver
      cgcloud__Default_Driver__c = strUserId,
      cgcloud__Tour_Template__c = tourTemplateOne.Id,
      cgcloud__Status__c = 'initial',
      //set warehouse to get state
      cgcloud__Start_Warehouse__c = warehouseOne.Id,
     cgcloud__End_Warehouse__c = warehouseOne.Id 
        
    );
    insert tourOne;

    //cgcloud__Inventory__c
    cgcloud__Inventory__c inv = new cgcloud__Inventory__c();
    inv.TPB_AvgPrice__c = 2;
    inv.cgcloud__Phase__c = STATUS_ACTIVE;
    inv.TPB_Current_C_Fund_Balance__c = 1;
    inv.cgcloud__Initial_Inventory__c = 1000;
    inv.cgcloud__Valid_From__c = Date.today();
    inv.cgcloud__Valid_Thru__c = Date.today() + 1;
    inv.cgcloud__User__c = strUserId;
    inv.cgcloud__Product__c = strProductId;
    inv.cgcloud__Tour__c = tourOne.Id;
    insert inv;

    return inv;
  }

  /**
   * @author Mi Li
   * @date 2023-6-5
   * @description This method is used to create Inventory Transaction Template test data.
   */
  public static void createInventoryTransactionTemplate() {
    List<cgcloud__Inventory_Transaction_Template__c> lstTransactionTemplate = new List<cgcloud__Inventory_Transaction_Template__c>();
    cgcloud__Inventory_Transaction_Template__c objTransactionTemplateAdd = new cgcloud__Inventory_Transaction_Template__c();
    objTransactionTemplateAdd.Name = INVENTORY_TRANSACTION_TEMPLATE_ADD;
    objTransactionTemplateAdd.cgcloud__Active__c = true;
    lstTransactionTemplate.add(objTransactionTemplateAdd);

    cgcloud__Inventory_Transaction_Template__c objTransactionTemplateCashsale = new cgcloud__Inventory_Transaction_Template__c();
    objTransactionTemplateCashsale.Name = INVENTORY_TRANSACTION_TEMPLATE_CASHSALE;
    objTransactionTemplateCashsale.cgcloud__Active__c = true;
    lstTransactionTemplate.add(objTransactionTemplateCashsale);

    insert lstTransactionTemplate;
  }

  /**
   * @author Mi Li
   * @date 2023-6-5
   * @description This method is used to create Inventory Control Template test data.
   */
  public static void createInventoryControlTemplate() {
    cgcloud__Inventory_Control_Template__c objInventoryControlTemplate = new cgcloud__Inventory_Control_Template__c();
    objInventoryControlTemplate.Name = INVENTORY_CONTROL_TEMPLATE;
    objInventoryControlTemplate.cgcloud__Active__c = true;
    insert objInventoryControlTemplate;
  }

  /**
   * @author Mi Li
   * @date 2023-6-5
   * @description This method is used to createv Wholesale Account test data.
   * @return  acc Account
   */
  public static Account createWholesaleAccount() {
    Account acc = new Account();
    acc.Name = 'Test Wholesale Account';
    acc.ShippingState = 'IL';
    acc.ShippingCity = 'Granite City';
    acc.ShippingStreet = 'U.S. Route 66 er 2167 Madison Ave';
    acc.ShippingPostalCode = '62040';
    acc.Clearing_House_Participant__c = true;
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Wholesaler')
      .getRecordTypeId();
    insert acc;

    return acc;
  }

  /**
   * @author Mi Li
   * @date 2023-6-5
   * @param   productId  Id
   * @description This method is used to create a test book entry.
   * @return  PricebookEntry
   */
  public static PricebookEntry createPricebookEntry(Id productId) {
    Pricebookentry entry = new Pricebookentry();
    entry.Pricebook2Id = test.getStandardPricebookId();
    entry.Product2Id = productId;
    entry.IsActive = true;
    entry.UnitPrice = 100;
    insert entry;
    return entry;
  }

  /**
   * @param   accId  Id
   * @param   productId  Id
   * @description This method is create Account Product.
   * @return  Account_Product__c
   */
  public static Account_Product__c createAccountProduct(
    Id accId,
    Id productId
  ) {
    Account_Product__c accProd = new Account_Product__c();
    accProd.Account__c = accId;
    accProd.Product__c = productId;
    accProd.SKU__c = '123';
    insert accProd;

    return accProd;
  }

  /**
   * @description This method is create TSM User.
   * @return  User
   */
  public static User createTSM() {
    User tsm = new User();
    tsm.FirstName = 'Standard';
    tsm.LastName = 'User';
    tsm.Alias = 'admin';
    tsm.Email = 'standard@ntc-test.com';
    tsm.Username = 'standard@ntc-test.com';
    tsm.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Mobile' LIMIT 1].Id;
    tsm.TimeZoneSidKey = 'America/Los_Angeles';
    tsm.EmailEncodingKey = 'UTF-8';
    tsm.LanguageLocaleKey = 'en_US';
    tsm.LocaleSidKey = 'en_US';
    insert tsm;

    return tsm;
  }

  /**
   * @description This method is create related account.
   * @param   objRetailer  Retailer Account
   * @param   objWholesaler  Wholesaler Account
   * @return  Related_Account__c
   */
  public static Related_Account__c createRelatedAccount(
    Account objRetailer,
    Account objWholesaler
  ) {
    Related_Account__c objRA = new Related_Account__c();
    objRA.Retailer__c = objRetailer.Id;
    objRA.Wholesaler__c = objWholesaler.Id;
    insert objRA;
    return objRA;
  }

  /**
   * @description This method is create related account.
   * @param   objRetailer  Retailer Account
   * @param   objWholesaler  Wholesaler Account
   * @return  Related_Account__c
   */
  public static Id createWholeSalerDocument(Account objWholesaler) {
    ContentVersion objContentVersion = new ContentVersion(
      VersionData = Blob.valueOf('test'),
      PathOnClient = 'test.pdf',
      Title = 'test'
    );
    insert objContentVersion;
    //create ContentDocumentLink for test.
    List<ContentVersion> lstContentVersion = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :objContentVersion.Id
    ];
    insert new ContentDocumentLink(
      LinkedEntityId = objWholesaler.Id,
      ContentDocumentId = lstContentVersion[0].ContentDocumentId
    );
    return lstContentVersion[0].ContentDocumentId;
  }
  
  /**
   * @description This method is create admin user.
   * @return  User admin
   */
  public static User createAdminUser() {
    User uRec = new User();
    uRec.FirstName = 'Admin';
    uRec.LastName = 'User';
    uRec.Alias = 'admin';
    uRec.Email = 'standard@ntc-test.com';
    uRec.Username = 'standard@ntc-test.com';
    uRec.ProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ][0]
    .Id;
    uRec.TimeZoneSidKey = 'America/Los_Angeles';
    uRec.EmailEncodingKey = 'UTF-8';
    uRec.LanguageLocaleKey = 'en_US';
    uRec.LocaleSidKey = 'en_US';
    insert uRec;
    return uRec;
  }
}