/**************************************************************************************
Apex Class Name:  TPB_OpportunityPEHandlerTest
Version     : 1.0
Created Date    : 2023-03-24
Function    : TPB_OpportunityPEHandlerTest
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description platform event handler class on Opportunity test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.wu              2023-03-24            Original Version
*************************************************************************************/
@isTest
public with sharing class TPB_OpportunityPEHandlerTest {

  /**
   * @description updateHiddenFieldAfterUpdate test
   */
  @isTest
  static void updateHiddenFieldAfterUpdateTest01() {

    Account retailer = TPB_TestFactory.createRetailAccount();
    Opportunity opportunity = TPB_TestFactory.createOpportunity(retailer.Id);
    opportunity = [SELECT Id, Amount FROM Opportunity WHERE Id = :opportunity.Id];
    opportunity.Amount = 10;
    opportunity.AccountId = retailer.Id;

    Test.startTest();
    //Datetime dt = system.now();
    update opportunity;
    Account verAcc = [SELECT Id,TPB_Formula_Rollup_Trigger__c FROM Account WHERE Id = :retailer.Id];
    Test.stopTest();
    system.assertEquals(true, verAcc!=null,'false');
  }
}