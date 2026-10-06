/**
 * @description TPB_ContentDocumentHandlerTest test class
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
@isTest
public without sharing class TPB_ContentDocumentHandlerTest{
    /*
    * @description set up test data
    */
    @TestSetup
    static void setup() {
        //Create retailer
        Account objRetailer = TPB_TestFactory.createRetailAccount();
        //Create wholesaler
        Account objWholesaler = TPB_TestFactory.createWholesaleAccount();
        //Create related account
        Related_Account__c objRA = TPB_TestFactory.createRelatedAccount(objRetailer, objWholesaler);
        //Create document
        TPB_TestFactory.createWholeSalerDocument(objWholesaler);
    }
    /*
    * @description test document deleted
    */
    @isTest
    static void testDeleteDoc() {
        String strWholesaler = 'Test Wholesale Account';
        List<Account> lstAccount = [SELECT ID FROM ACCOUNT WHERE Name = :strWholesaler ];
        List<ContentDocumentLink> lstLink = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstAccount[0].Id ];
        List<ContentDocument> lstDoc = [SELECT Id FROM ContentDocument WHERE Id = :lstLink[0].ContentDocumentId ];
        //delete document
        delete lstDoc;
        //check result
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c, TPB_FILE__C FROM Related_Account__c WHERE Wholesaler__r.Name = :strWholesaler ];
        System.assertNotEquals(lstRA, null);
    }
}