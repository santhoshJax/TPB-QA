@IsTest
public class TPB_AccountManagerOnCreateHandlerTest {
    @testSetup
    static void setupData() {
        TestDataFactory.ensureRetailerAutomationPrereqs();
    }

    private static Account buildAccount(Boolean fromOnline) {
        Id rtId = Schema.getGlobalDescribe().get('Account').getDescribe()
            .getRecordTypeInfosByName().get('Retailer').getRecordTypeId();

        return new Account(
            Name = fromOnline ? 'Online App Account' : 'Regular Account',
            Type = 'Retail',
            Status__c = 'Open',
            RecordTypeId = rtId,
            cgcloud__Account_Template__c = TestDataFactory.ensureRetailerAutomationPrereqs(),
            Created_from_Online_App__c = fromOnline
        );
    }

    @IsTest
    static void createsManagerForOnlineAppAccount() {
        Account acc = buildAccount(true);
        insert acc;

        List<cgcloud__Account_Manager__c> mgrs = [
            SELECT cgcloud__Account__c, cgcloud__User__c, cgcloud__Active__c
            FROM cgcloud__Account_Manager__c
            WHERE cgcloud__Account__c = :acc.Id
        ];
        System.assertEquals(1, mgrs.size(), 'Expected one account manager for online app account.');
        System.assertEquals(UserInfo.getUserId(), mgrs[0].cgcloud__User__c, 'Account manager user should be creator.');
        System.assertEquals(true, mgrs[0].cgcloud__Active__c, 'Account manager should be active.');
    }

    @IsTest
    static void doesNotCreateManagerWhenFlagFalse() {
        Account acc = buildAccount(false);
        insert acc;

        Integer mgrCount = [
            SELECT COUNT()
            FROM cgcloud__Account_Manager__c
            WHERE cgcloud__Account__c = :acc.Id
        ];
        System.assertEquals(0, mgrCount, 'No account manager should be created when flag is false.');
    }
}