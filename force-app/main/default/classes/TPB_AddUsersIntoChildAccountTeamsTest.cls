/**
 * TPB_AddUsersIntoChildAccountTeamsTest
 * @author RZ
 * @date 2023-09-21
 * @description Create AddUsersIntoChildAccountTeams by flow
 *
 */
@isTest
public with sharing class TPB_AddUsersIntoChildAccountTeamsTest {
    /**
     * @description setup description
     *
     */
    @testSetup
    public static void setup() {
        Id retailerAccountTemplateId = TestDataFactory.ensureRetailerAutomationPrereqs();
        // new headquarter
        Account headquarter = new Account(
            ShippingCountry = 'US',
            ShippingCountryCode = 'US',
            ShippingLatitude = 38.90996,
            ShippingLongitude = -77.01893,
            ShippingPostalCode = '20001',
            ShippingState = 'DC',
            ShippingStreet = 'U.S. Route 66 ',
            ShippingCity = 'Baltimore',
            ShippingStateCode = 'DC'
        );
        // headquarter name
        headquarter.Name = 'Test Headquarter';
        // headquarter record type
        headquarter.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        // insert headquarter
        insert headquarter;

        // new retailer
        Account retailer = new Account(
            ShippingCountry = 'US',
            ShippingCountryCode = 'US',
            ShippingLatitude = 38.90996,
            ShippingLongitude = -77.01893,
            ShippingPostalCode = '20001',
            ShippingState = 'DC',
            ShippingStreet = 'U.S. Route 66 ',
            ShippingCity = 'Baltimore',
            ShippingStateCode = 'DC'
        );
        // retailer name
        retailer.Name = 'Test Retailer';
        retailer.cgcloud__Account_Template__c = retailerAccountTemplateId;
        // retailer record type
        retailer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        // retailer parent
        retailer.ParentId = headquarter.Id;
        // insert retailer
        insert retailer;
    }

    /**
     * @description testChangeHeadquarterWoner description
     *
     */
    @isTest
    static void testChangeHeadquarterWoner() {
        // get headquarter
        Account headquarter = [SELECT Id, Name, OwnerId, BillingCity, BillingState, Cash_Sales__c, RecordTypeId, RecordType.Name FROM Account WHERE RecordType.Name = 'Headquarter'];
        System.assertNotEquals(headquarter, null, 'Account not found');
        // new account member
        AccountTeamMember member = new AccountTeamMember(
            UserId = headquarter.OwnerId,
            AccountId = headquarter.Id,
            AccountAccessLevel = 'Edit',
            TeamMemberRole = 'Account Manager'
        );
        // TPB_AddUsersIntoChildAccountTeams InputParameters
        TPB_AddUsersIntoChildAccountTeams.InputParameters parameter = new TPB_AddUsersIntoChildAccountTeams.InputParameters();
        parameter.accountTeamMember = member;
        List<TPB_AddUsersIntoChildAccountTeams.InputParameters> inputs = new List<TPB_AddUsersIntoChildAccountTeams.InputParameters>();
        inputs.add(parameter);
        // addUsersIntoChildAccountTeams
        TPB_AddUsersIntoChildAccountTeams.addUsersIntoChildAccountTeams(inputs);
    }
}