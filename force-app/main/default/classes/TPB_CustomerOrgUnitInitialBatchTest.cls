/**
 * TPB_CustomerOrgUnitInitialBatchTest
 *
 * @author Guanshu Wang
 * @date 2023-03-17
 * @description Create Account_Org_Unit__c for QA Account initial (Test Class)
 *
 */
@IsTest
public with sharing class TPB_CustomerOrgUnitInitialBatchTest {
    @TestSetup
    static void setup() {
        // Org Unit
        cgcloud__Org_Unit__c orgUnitOne = new cgcloud__Org_Unit__c(
            cgcloud__Sales_Org__c = '0001',
            Name = 'test1'
        );// Org Unit
        cgcloud__Org_Unit__c orgUnitTwo = new cgcloud__Org_Unit__c(
            cgcloud__Sales_Org__c = '0001',
            Name = 'test2'
        );
        insert orgUnitTwo;
        insert orgUnitOne;
        // TPB_Org_Unit_Mapping__c
        TPB_Org_Unit_Mapping__c orgUnitMappingOne = new TPB_Org_Unit_Mapping__c(
            TPB_Org_Unit__c = orgUnitOne.Id,
            TPB_State_Abbrev__c = 'VA',
            TPB_Zip_Code__c = '24540'
        );
        insert orgUnitMappingOne;
        // Profile
        profile profileOne = [
            SELECT id
            FROM Profile
            WHERE Name = 'CG Cloud Mobile - TSM'
        ];
        // User
        User userOne = new User(
            Firstname = 'test',
            Username = 'dummyuser123@youdontknow.com',
            LastName = 'Test',
            Email = 'guanshu.wang@pwc.com',
            Alias = 'tsmtwo',
            TimeZoneSidKey = 'Asia/Shanghai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = profileOne.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert userOne;
        // cgcloud__Org_Unit_User__c
        cgcloud__Org_Unit_User__c orgUnitUserOne = new cgcloud__Org_Unit_User__c(
            cgcloud__Org_Unit__c = orgUnitOne.Id,
            cgcloud__User__c = userOne.Id
        );
        insert orgUnitUserOne;
            // Account Template
    cgcloud__Account_Template__c accountTemplateOne = new cgcloud__Account_Template__c(
      cgcloud__Sales_Org__c = '0001',
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store'
    );
    insert accountTemplateOne;
            // cgcloud__Job_Definition_List_Template__c
    cgcloud__Job_Definition_List_Template__c jDLTOne = new cgcloud__Job_Definition_List_Template__c(
      Name = 'Distribution Activity Template',
      cgcloud__Consider_Account__c = true,
      cgcloud__Consider_Products__c = true,
       cgcloud__Active__c=true,
        cgcloud__Description_Language_1__c='Distribution Activity Template',
      cgcloud__Sales_Org__c = '0001'
    );
    insert jDLTOne;
    // cgcloud__Visit_Template__c
    cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
      Name = 'Distribution Visit Template',
        cgcloud__Active__c = true,
        cgcloud__Description_Language_1__c='Distribution Visit Template',
      cgcloud__Sales_Org__c = '0001'
    );
    insert vTOne;
        //cgcloud__Job_Template__c
    cgcloud__Job_Template__c jobTemplate = new cgcloud__Job_Template__c(
      cgcloud__Description_Language_1__c = 'Survey',
      cgcloud__Sales_Org__c = '0001',
      cgcloud__Product_Reference__c = true
    );
    insert jobTemplate;
    jobTemplate = [
      SELECT Id
      FROM cgcloud__Job_Template__c
      WHERE cgcloud__Description__c = 'Survey'
    ][0];
        //cgcloud__Data_Type__c
    cgcloud__Data_Type__c dataType = new cgcloud__Data_Type__c(
      cgcloud__Sales_Org__c = '0001',
      Name = 'DomPrdDistributed'
    );
    insert dataType;
    dataType = [
      SELECT Id
      FROM cgcloud__Data_Type__c
      WHERE Name = 'DomPrdDistributed' AND cgcloud__Sales_Org__c = '0001'
    ][0];
            //cgcloud__Job_Definition_Template__c
    cgcloud__Job_Definition_Template__c jDTemplate = new cgcloud__Job_Definition_Template__c(
      cgcloud__Sales_Org__c = '0001',
      cgcloud__Data_Type__c = dataType.Id,
      cgcloud__Job_Template__c = jobTemplate.Id,
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Distribution'
    );
    insert jDTemplate;

        // Account
    Account accountOne = new Account(
      cgcloud__Account_Template__c = accountTemplateOne.Id,
      ShippingCity = 'Danville',
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingPostalCode = '24540',
      ShippingState = 'VA',
      ShippingStateCode = 'VA',
      ShippingStreet = '1234 Mount Cross Road',
      Name = 'Sally Walkers Store #1'
    );
        insert accountOne;

        // cgcloud__Account_Org_Unit__c
        cgcloud__Account_Org_Unit__c accountOrgUnitOne = new cgcloud__Account_Org_Unit__c(
            cgcloud__Account__c = accountOne.Id,
            cgcloud__Org_Unit__c = orgUnitTwo.Id,
      cgcloud__Active__c = true,
      cgcloud__Valid_From__c = system.today().addDays(-1),
      cgcloud__Valid_Thru__c = system.today().addDays(1)
        );
        insert accountOrgUnitOne;

    }

    @isTest
    static void test() {
        ID orgUnitId = [
            SELECT Id
            FROM cgcloud__Org_Unit__c
            WHERE CreatedDate = Today AND Name = 'test1'
            LIMIT 1
        ]
        .Id;
        ID userId = [SELECT Id FROM user WHERE CreatedDate = Today LIMIT 1].Id;
        // Test Start
        //
        Test.startTest();
        TPB_CustomerOrgUnitInitialBatch batch = new TPB_CustomerOrgUnitInitialBatch();
        Database.executeBatch(batch);
        TPB_CustomerOrgUnitInitialBatch batchOne = new TPB_CustomerOrgUnitInitialBatch(
            'SELECT ID,ShippingPostalCode,ShippingState,OwnerId,TPB_Org_Unit_Flag__c FROM Account WHERE cgcloud__Sales_Org__c = \'0001\' AND TPB_Org_Unit_Flag__c = false'
        );
        Database.executeBatch(batchOne);
        // Test Stop
        Test.stopTest();

        // Check Account Org Unit Count()

        System.assertEquals(
            3,
            [
                SELECT COUNT()
                FROM cgcloud__Account_Org_Unit__c
                WHERE CreatedDate = Today
            ],0
        );
        // Check Org Unit Id
        System.assertEquals(
            orgUnitId,
            [
                SELECT cgcloud__Org_Unit__c
                FROM cgcloud__Account_Org_Unit__c
                WHERE CreatedDate = Today
                LIMIT 1
            ]
            .cgcloud__Org_Unit__c,0
        );
    }
}