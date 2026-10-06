@isTest
public class TPB_CreateCampaignOpptysTest {

    @isTest
    static void testCreateOppAndOppProd() {
        
        
         Account headquarter = new Account();
        headquarter.Name = 'Test Headquarter';
        headquarter.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        insert headquarter;
        
        

        Contact con = new Contact(FirstName = 'first', LastName = 'test', AccountId = headquarter.Id);
        insert con;
        Campaign campaign = new Campaign(Name = 'Test Campaign',Type='New Item Intro (HQ)', StartDate=System.Today(), EndDate=System.Today().addDays(5), Description='Red Supreme $2.39 in select wholesalers');
        insert campaign;
        
        
        CampaignMember member = new CampaignMember(
            AccountId = headquarter.Id,
            Status = 'sent',
            CampaignId = campaign.Id
        ); 
		insert member;
        
        //Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(campaign.Type).getRecordTypeId();
        RecordType rec = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = : campaign.Type LIMIT 1];
        
        // Create Opportunities
        Opportunity oppty1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = headquarter.Id,
            RecordTypeId = rec.Id,
            TPB_Origin__c = 'Auto-created by Campaign',
            TPB_Created_by_Admin__c = false,
            TPB_Created_by_Campaign__c = true,
            TPB_Created_by_Self__c = false,
            Order_URL__c='www.test.com',
            Zig_Zag_Wholesale_Customer_ID__c='12345'
        );

        Opportunity oppty2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = headquarter.Id,
            RecordTypeId = rec.Id,
            TPB_Origin__c = 'Auto-created by Campaign',
            TPB_Created_by_Admin__c = false,
            TPB_Created_by_Campaign__c = true,
            TPB_Created_by_Self__c = false,
            Order_URL__c='www.test.com',
            Zig_Zag_Wholesale_Customer_ID__c='12345'
        );

        Opportunity oppToDeactivate = new Opportunity(
            Name = 'Test Opportunity 3',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = headquarter.Id,
            RecordTypeId = rec.Id,
            TPB_Origin__c = 'Auto-created by Campaign',
            TPB_Created_by_Admin__c = false,
            TPB_Created_by_Campaign__c = true,
            TPB_Created_by_Self__c = false,
            Order_URL__c='www.test.com',
            Zig_Zag_Wholesale_Customer_ID__c='12345'
        );

        insert new List<Opportunity>{oppty1, oppty2, oppToDeactivate};

        // Create Campaign Products
        Product2 prod = new Product2();
        prod.Name = 'Test Product2';
        prod.IsActive = true;
        prod.NTC_Item_Classification__c = 'Straight Stock';
        prod.cgcloud__Product_Level__c = 'Flavor';
        insert prod;

        TPB_Campaign_Product__c campaignProduct = new TPB_Campaign_Product__c(
            TPB_Campaign__c = campaign.Id,
            TPB_Product__c = prod.Id
        );
        insert campaignProduct;

        // Prepare input parameters
        TPB_CreateCampaignOpptys.InputParameters input = new TPB_CreateCampaignOpptys.InputParameters();
        input.campaignId = campaign.Id;
        input.recordTypeId = rec.Id;
        input.oppsToDeactivate = new List<Opportunity>{oppToDeactivate};

        Test.startTest();
        // Call the method
        TPB_CreateCampaignOpptys.createOppAndOppProd(new List<TPB_CreateCampaignOpptys.InputParameters>{input});
        Test.stopTest();

    }
}