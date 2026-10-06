/**************************************************************************************
Apex Class Name:  TPB_ProductPEHandler
Version     : 1.0
Created Date    : 2023-03-24
Function    : platform event handler class on Product to detect field changes on PricebookEntry include fields as below
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description product trigger handler test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.wu              2023-03-24            Original Version
*************************************************************************************/
@isTest
public with sharing class TPB_ProductPEHandlerTest {
    @isTest
    static void updateHiddenFieldAfterUpdateTest01() {

      Product2 prod = new Product2();
      prod.Name = 'Test Product';
      prod.IsActive = true;
      prod.NTC_Item_Classification__c = 'Straight Stock';
      insert prod;

      cgcloud__Product_Condition__c pcRec = new cgcloud__Product_Condition__c();
      pcRec.cgcloud__Product__c = prod.Id;
      insert pcRec;

      Test.startTest();
      prod.NTC_Price_List_Flag__c = True;
      //Datetime dt = system.now();
      update prod;

      cgcloud__Product_Condition__c item = [SELECT Id,TPB_Formula_Rollup_Trigger__c FROM cgcloud__Product_Condition__c WHERE cgcloud__Product__c = :prod.Id];
      Test.stopTest();
      system.assertEquals(true, item!=null,'fail');
    }
}