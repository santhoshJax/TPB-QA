/**
 * @description TPB_RelatedAccountHandler test class
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
@isTest
public without sharing class TPB_RelatedAccountHandlerTest{
    /*
    * @description setup data
    */
    @TestSetup
    static void setup() {
        //Create retailer
        TPB_TestFactory.createRetailAccount();
        //Create wholesaler
        Account objWholesaler = TPB_TestFactory.createWholesaleAccount();
        //Create document
        TPB_TestFactory.createWholeSalerDocument(objWholesaler);
    }
    /*
    * @description test file exist when create related account
    */
    @isTest
    static void testFileExist() {
        String strRetailer = 'Test Account';
        String strWholesaler = 'Test Wholesale Account';
        List<Account> lstWholeAccount = [SELECT ID FROM ACCOUNT WHERE Name = :strWholesaler ];
        List<Account> lstRetailAccount = [SELECT ID FROM ACCOUNT WHERE Name = :strRetailer ];
        //Create related account
        TPB_TestFactory.createRelatedAccount(lstRetailAccount[0], lstWholeAccount[0]);
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE TPB_Wholesaler_File__c = null AND Wholesaler__c =:strWholesaler ];
        System.assertEquals(lstRA.size(), 0);
    }
}