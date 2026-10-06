/**
 * @description TPB_ContentDocumentLinkHandler test class
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
@isTest
public without sharing class TPB_ContentDocumentLinkHandlerTest{
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
        TPB_TestFactory.createRelatedAccount(objRetailer, objWholesaler);
    }
    /*
    * @description test file uploaded
    */
    @isTest
    static void testFileUpload() {
        String strWholesaler = 'Test Wholesale Account';
        List<Account> lstAccount = [SELECT ID FROM ACCOUNT WHERE Name = :strWholesaler ];
        Id idCotentDocument = TPB_TestFactory.createWholeSalerDocument(lstAccount[0]);
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c, TPB_FILE__C FROM Related_Account__c WHERE Wholesaler__r.Name = :strWholesaler ];
        System.assertNotEquals(lstRA, null);
    }
}