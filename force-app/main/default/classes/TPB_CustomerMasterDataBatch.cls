/**
 * @author: Zeen Liu
 * date:2/21/2023
 * @description cgcloud__Account_Extension__c,cgcloud__Account_Visit_Setting__c generation.
 */
public with sharing class TPB_CustomerMasterDataBatch {
  //   String query;
  //   cgcloud__Account_Template__c accTemplate = null;
  //   cgcloud__Visit_Template__c distributeVisitTemplate = null;
  //   cgcloud__Sales_Organization__c salesOrg = null;
  //   {
  //     List<cgcloud__Account_Template__c> lst = new List<cgcloud__Account_Template__c>();
  //     //query and initialize default Sales Org.
  //     salesOrg = [
  //       SELECT ID
  //       FROM cgcloud__Sales_Organization__c
  //       WHERE cgcloud__Sales_Org_Value__c = '0001'
  //       LIMIT 1
  //     ];
  //     //query and initialize Customer Account Template.
  //     accTemplate = [
  //       SELECT Id
  //       FROM cgcloud__Account_Template__c
  //       WHERE Name = 'Customer'
  //       LIMIT 1
  //     ];
  //     for (cgcloud__Account_Template__c temp : [
  //       SELECT id, cgcloud__Active__c
  //       FROM cgcloud__Account_Template__c
  //       WHERE Id != :accTemplate.Id
  //     ]) {
  //       temp.cgcloud__Active__c = false;
  //       lst.add(temp);
  //     }
  //     //Inactive Account Templates except 'Customer'
  //     update lst;
  //     distributeVisitTemplate = new cgcloud__Visit_Template__c();
  //     distributeVisitTemplate.cgcloud__Active__c = true;
  //     distributeVisitTemplate.cgcloud__Add_Job_Policy__c = true;
  //     distributeVisitTemplate.cgcloud__Auto_Status__c = 'Planned';
  //     distributeVisitTemplate.cgcloud__Cancel_Reason_Required__c = false;
  //     distributeVisitTemplate.cgcloud__Capture_Proceeding_Time__c = true;
  //     distributeVisitTemplate.cgcloud__Check_Overlap__c = false;
  //     distributeVisitTemplate.cgcloud__Company_Required__c = 'Mandatory';
  //     distributeVisitTemplate.cgcloud__Consider_POS_Check__c = true;
  //     distributeVisitTemplate.cgcloud__Creation_Platform__c = 'Both';
  //     distributeVisitTemplate.cgcloud__Default_Duration__c = 30;
  //     distributeVisitTemplate.cgcloud__Delete_Allowed__c = true;
  //     distributeVisitTemplate.cgcloud__Description_Language_1__c = 'Distribution Visit Template';
  //     distributeVisitTemplate.cgcloud__Display_Promotions__c = true;
  //     distributeVisitTemplate.cgcloud__Historical_Products__c = 'No';
  //     distributeVisitTemplate.cgcloud__KPI_Relevant__c = 'All';
  //     distributeVisitTemplate.cgcloud__Loc_Capture_During_Cancel__c = true;
  //     distributeVisitTemplate.cgcloud__Loc_Capture_During_Complete__c = true;
  //     distributeVisitTemplate.cgcloud__Max_Pictures__c = 10;
  //     distributeVisitTemplate.cgcloud__Meta_Type__c = 'Call';
  //     distributeVisitTemplate.cgcloud__Mobility_Color__c = '6688BB';
  //     distributeVisitTemplate.cgcloud__Mobility_Relevant__c = true;
  //     distributeVisitTemplate.cgcloud__Mobility_User_Guidance__c = 'Sales';
  //     distributeVisitTemplate.cgcloud__Promotion_Finding_Lead_Time__c = 365;
  //     distributeVisitTemplate.cgcloud__Sales_Org__c = '0001';
  //     distributeVisitTemplate.cgcloud__Sort__c = 5;
  //     distributeVisitTemplate.cgcloud__Sync_Options__c = 'CompleteCancelCall';
  //     distributeVisitTemplate.cgcloud__Tag_Media_Date_Time__c = false;
  //     distributeVisitTemplate.cgcloud__Tag_Media_Geo_Location__c = false;
  //     distributeVisitTemplate.cgcloud__Update_Planned_Times__c = false;
  //     distributeVisitTemplate.cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User';
  //     distributeVisitTemplate.Name = 'Distribution Visit Template';
  //     //create new Visit Template 'Distribution Visit Template'
  //     insert distributeVisitTemplate;
  //     List<cgcloud__Visit_Template__c> visitTempLst = new List<cgcloud__Visit_Template__c>();
  //     for (cgcloud__Visit_Template__c obj : [
  //       SELECT ID, cgcloud__Active__c
  //       FROM cgcloud__Visit_Template__c
  //       WHERE Id != :distributeVisitTemplate.Id
  //     ]) {
  //       obj.cgcloud__Active__c = false;
  //       visitTempLst.add(obj);
  //     }
  //     //Inactive Visit Templates except 'Distribution Visit Template'
  //     update visitTempLst;
  //   }

  //   /**
  //    * @description start description
  //    * @param   bc     description
  //    * @return  return description
  //    */
  //   public Database.QueryLocator start(Database.BatchableContext bc) {
  //     return Database.getQueryLocator(query);
  //   }

  //   /**
  //    * @description Constructor class
  //    * @param  query statement
  //    */
  //   public TPB_CustomerMasterDataBatch(String query) {
  //     this.query = query;
  //   }

  //   /**
  //    * @description execute description
  //    * @param  bc           description
  //    * @param  lstAccountList  description
  //    */
  //   public void execute(
  //     Database.BatchableContext bc,
  //     List<Account> lstAccountList
  //   ) {
  //     List<Account> accUpdateLst = new List<Account>();
  //     List<cgcloud__Account_Extension__c> accExtLst = new List<cgcloud__Account_Extension__c>();
  //     List<cgcloud__Account_Visit_Setting__c> accVisitSettingLst = new List<cgcloud__Account_Visit_Setting__c>();
  //     for (Account acc : lstAccountList) {
  //       //Assign Account Template to every Account.
  //       acc.cgcloud__Account_Template__c = accTemplate.Id;
  //       acc.TPB_Shipping_Street_Filter__c = acc.TPB_Address_Filter__c;
  //       accUpdateLst.add(acc);
  //       //Build Customer Extension for every Account.
  //       cgcloud__Account_Extension__c customerExt = new cgcloud__Account_Extension__c();
  //       customerExt.cgcloud__Account__c = acc.Id;
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Bill_To_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Bill_To_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Class_Of_Trade__c = 'ConvenienceStores';
  //       customerExt.cgcloud__Consider_Modules__c = false;
  //       customerExt.cgcloud__Customer_Role_Price_List_type__c = 'Wholesaler';
  //       customerExt.cgcloud__Customer_Role_Price_Type__c = 'factory';
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Customer_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Customer_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Decreasing_PSI__c = false;
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Delivery_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Delivery_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Distribution_Issue__c = false;
  //       customerExt.cgcloud__Invoice_Document_Transaction_Type__c = 'InvoiceCashInvoice';
  //       customerExt.cgcloud__Last_Visit_Date__c = system.today().addDays(-1);
  //       customerExt.cgcloud__OOS_Issue__c = true;
  //       customerExt.cgcloud__Order_Document_Transaction_Type__c = 'CashOrder';
  //       customerExt.cgcloud__Order_Role_Orderer_Type__c = 'Direct';
  //       customerExt.cgcloud__Order_Role_Order_Template_Blocked__c = '0';
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Order_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Order_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Payer_Role_Credit_Block__c = false;
  //       customerExt.cgcloud__Payer_Role_Credit_Rating__c = 'A';
  //       customerExt.cgcloud__Payer_Role_Document_Transaction_Type__c = 'CashInvoice';
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Payer_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Payer_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Payment_Mode__c = 'Cash';
  //       customerExt.cgcloud__Phase__c = '1';
  //       customerExt.cgcloud__Pricing_Type__c = '2';
  //       customerExt.cgcloud__Priority__c = 'A - Priority';
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Promotion_Valid_From__c = system.today().addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Promotion_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       customerExt.cgcloud__Sales_Organization__c = salesOrg.Id;
  //       customerExt.cgcloud__Sales_Relevant__c = true;
  //       customerExt.cgcloud__State__c = '010';
  //       //set the start time as yesterday.
  //       customerExt.cgcloud__Store_Role_Valid_From__c = system.today()
  //         .addDays(-1);
  //       //set the end time as 100 years later.
  //       customerExt.cgcloud__Store_Role_Valid_Thru__c = system.today()
  //         .addYears(100);
  //       accExtLst.add(customerExt);
  //       //Build Visit Setting for every Account.
  //       cgcloud__Account_Visit_Setting__c accVisitSetting = new cgcloud__Account_Visit_Setting__c();
  //       accVisitSetting.cgcloud__Account__c = acc.Id;
  //       accVisitSetting.cgcloud__Active__c = true;
  //       accVisitSetting.cgcloud__Day_Of_Week__c = 'mon';
  //       accVisitSetting.cgcloud__Duration__c = 30;
  //       accVisitSetting.cgcloud__Frequency__c = 1;
  //       accVisitSetting.cgcloud__Initial_Year__c = '2015';
  //       accVisitSetting.cgcloud__Management_Type__c = 'Sales';
  //       accVisitSetting.cgcloud__Overdue_Check__c = false;
  //       accVisitSetting.cgcloud__Planning_Mode__c = 'StartWeek';
  //       accVisitSetting.cgcloud__Start_Week__c = 1;
  //       accVisitSetting.cgcloud__Time_Of_Day__c = '10:00';
  //       //set the start time as yesterday.
  //       accVisitSetting.cgcloud__Valid_From__c = system.today().addDays(-1);
  //       //set the end time as 100 years later.
  //       accVisitSetting.cgcloud__Valid_Thru__c = system.today().addYears(100);
  //       accVisitSetting.cgcloud__Visit_Template__c = distributeVisitTemplate.Id;
  //       accVisitSettingLst.add(accVisitSetting);
  //     }
  //     //Update Account Template on Account.
  //     update accUpdateLst;
  //     //Insert Customer Extension.
  //     insert accExtLst;
  //     //Insert Visit Setting.
  //     insert accVisitSettingLst;
  //   }

  //   /**
  //    * @description finish description
  //    * @param  bc bc description
  //    */
  //   public void finish(Database.BatchableContext bc) {
  //     query = '';
  //   }
}