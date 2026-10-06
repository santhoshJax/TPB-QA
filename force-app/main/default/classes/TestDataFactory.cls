@isTest
public inherited sharing class TestDataFactory {

    private static final String RETAILER_TEST_SALES_ORG = '0001';
    private static final String RETAILER_ACCOUNT_TEMPLATE_NAME = 'Customer';
    private static final String RETAILER_VISIT_TEMPLATE_NAME = 'Distribution Visit Template';

    public static User createTSM() {
        User tsm = new User();
        tsm.FirstName = 'Standard';
        tsm.LastName = 'User';
        tsm.Alias = 'admin';
        tsm.Email = 'standard@ntc-test.com';
        tsm.Username = 'standard@ntc-test.com';
        tsm.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Mobile' LIMIT 1].Id;
        tsm.TimeZoneSidKey = 'America/Los_Angeles';
        tsm.EmailEncodingKey = 'UTF-8';
        tsm.LanguageLocaleKey = 'en_US';
        tsm.LocaleSidKey = 'en_US';
        insert tsm;

        return tsm;
    }

    public static Id ensureRetailerAutomationPrereqs() {
        ensureDistributionVisitTemplate();
        return ensureRetailAccountTemplate();
    }

    public static Id ensureRetailAccountTemplate() {
        List<cgcloud__Account_Template__c> templates = [
            SELECT Id, cgcloud__Active__c
            FROM cgcloud__Account_Template__c
            WHERE Name = :RETAILER_ACCOUNT_TEMPLATE_NAME
            AND cgcloud__Sales_Org__c = :RETAILER_TEST_SALES_ORG
            LIMIT 1
        ];

        if (!templates.isEmpty()) {
            if (!templates[0].cgcloud__Active__c) {
                templates[0].cgcloud__Active__c = true;
                update templates[0];
            }
            return templates[0].Id;
        }

        cgcloud__Account_Template__c template = new cgcloud__Account_Template__c(
            cgcloud__Active__c = true,
            cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
            cgcloud__Description_Language_1__c = RETAILER_ACCOUNT_TEMPLATE_NAME,
            cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store',
            cgcloud__Sales_Org__c = RETAILER_TEST_SALES_ORG,
            Name = RETAILER_ACCOUNT_TEMPLATE_NAME
        );
        insert template;

        return template.Id;
    }

    public static Id ensureDistributionVisitTemplate() {
        List<cgcloud__Visit_Template__c> templates = [
            SELECT Id, cgcloud__Active__c
            FROM cgcloud__Visit_Template__c
            WHERE Name = :RETAILER_VISIT_TEMPLATE_NAME
            AND cgcloud__Sales_Org__c = :RETAILER_TEST_SALES_ORG
            LIMIT 1
        ];

        if (!templates.isEmpty()) {
            if (!templates[0].cgcloud__Active__c) {
                templates[0].cgcloud__Active__c = true;
                update templates[0];
            }
            return templates[0].Id;
        }

        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(
            Name = RETAILER_VISIT_TEMPLATE_NAME,
            cgcloud__Active__c = true,
            cgcloud__Description_Language_1__c = RETAILER_VISIT_TEMPLATE_NAME,
            cgcloud__Sales_Org__c = RETAILER_TEST_SALES_ORG
        );
        insert template;

        return template.Id;
    }

    public static void ensureVisitTemplate(String salesOrg) {
        List<cgcloud__Visit_Template__c> templates = [
            SELECT Id, cgcloud__Active__c
            FROM cgcloud__Visit_Template__c
            WHERE Name = :RETAILER_VISIT_TEMPLATE_NAME
            AND cgcloud__Sales_Org__c = :salesOrg
            LIMIT 1
        ];

        if (!templates.isEmpty()) {
            if (!templates[0].cgcloud__Active__c) {
                templates[0].cgcloud__Active__c = true;
                update templates[0];
            }
            return;
        }

        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(
            Name = RETAILER_VISIT_TEMPLATE_NAME,
            cgcloud__Active__c = true,
            cgcloud__Description_Language_1__c = RETAILER_VISIT_TEMPLATE_NAME,
            cgcloud__Sales_Org__c = salesOrg
        );
        insert template;
    }

    public static Account createRetailAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        insert acc;

        return acc;
    }

    public static Account createWholesaleAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Clearing_House_Participant__c = true;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Wholesaler').getRecordTypeId();
        insert acc;
        
        return acc;
    }

    public static Account createHeadquarterAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        insert acc;
        
        return acc;
    }

    public static Related_Account__c createRelatedAccount(Id retailerId, Id wholesalerId) {
        Related_Account__c related = new Related_Account__c();
        related.Wholesaler__c = wholesalerId;
        related.Retailer__c = retailerId;
        related.Type__c = 'Primary';
        insert related;
        
        return related;
    }

    public static Contact createContact(Id accId) {
        Contact con = new Contact();
        con.AccountId = accId;
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.Email = 'test@ntc.com';
        insert con;
        
        return con;
    }

    public static Opportunity createOpportunity(Id accId) {
        Opportunity opp = new Opportunity();
        opp.AccountId = accId;
        opp.StageName = 'Qualification';
        opp.CloseDate = date.today().addDays(30);
        opp.Name = 'Test Opp';
        insert opp;

        return opp;
    }

    public static Display_Group__c createDisplayGroup() {
        Display_Group__c display = new Display_Group__c();
        display.Display_Group__c = 'BLUNT WRAP';
        display.Sort_Order__c = 1;
        insert display;

        return display;
    }

    public static Product2 createProduct() {
        Product2 prod = new Product2();
        prod.Name = 'Test Product';
        prod.IsActive = true;
        prod.Display_Group__c = TestPicklistUtil.getPicklistValues('Product2', 'Display_Group__c')[0];
        prod.NTC_Item_Classification__c = 'Straight Stock';
        insert prod;

        return prod;
    }

    public static Product_Code__c createProductCode(Id productId) {
        Product_Code__c code = new Product_Code__c();
        code.UPC__c = '541345345';
        code.Product__c = productId;
        insert code;

        return code;
    }

    public static Product_Code__c createProductCode2(Id productId) {
        Product_Code__c code = new Product_Code__c();
        code.UPC__c = '765745326';
        code.Product__c = productId;
        insert code;

        return code;
    }

    public static PricebookEntry createPricebookEntry(Id productId) {
        Pricebookentry entry = new Pricebookentry();
        entry.Pricebook2Id = test.getStandardPricebookId();
        entry.Product2Id = productId;
        entry.IsActive = true;
        entry.UnitPrice = 100;
        insert entry;

        return entry;
    }

    public static OpportunityLineItem createOpportunityLineItem(Id oppId, Id pbeId) {
        OpportunityLineItem line = new OpportunityLineItem();
        line.UnitPrice = 100;
        line.PricebookEntryId = pbeId;
        line.OpportunityId = oppId;
        line.Quantity = 1;
        insert line;

        return line;
    }

    public static Ideal_Kit__c createIdealKit(Id accountId, Id productId) {
        Ideal_Kit__c kit = new Ideal_Kit__c();
        kit.Account__c = accountId;
        kit.Product__c = productId;
        insert kit;

        return kit;
    }

    public static Account_Product__c createAccountProduct(Id accId, Id productId) {
        Account_Product__c accProd = new Account_Product__c();
        accProd.Account__c = accId;
        accProd.Product__c = productId;
        accProd.SKU__c = '123';
        insert accProd;

        return accProd;
    }

    public static Schema.Location createLocation() {
        Schema.Location locationObj = new Schema.Location();
        locationObj.Name = 'Test Location';
        locationObj.IsInventoryLocation = true;
        insert locationObj;

        return locationObj;
    }

    public static ProductItem createProductItem(Id locationId, Id productId) {
        ProductItem item = new ProductItem();
        item.Product2Id = productId;
        item.LocationId = locationId;
        item.Price__c = 100;
        item.QuantityOnHand = 1;
        insert item;

        return item;
    }

    // public static WorkOrder createWorkOrder(Id accId, Id locationId) {
    //     WorkOrder wOrder = new WorkOrder();
    //     wOrder.AccountId = accId;
    //     wOrder.Status = 'New';
    //     wOrder.Next_Call_Objective__c = 'Test';
    //     wOrder.Status = 'Completed';
    //     wOrder.LocationId = locationId;
    //     wOrder.StartDate = system.now().addDays(-2);
    //     wOrder.EndDate = system.now().addDays(-1);
    //     wOrder.ServiceReportTemplateId = [SELECT Id FROM ServiceReportLayout LIMIT 1].Id;
    //     wOrder.Pricebook2Id = test.getStandardPricebookId();
    //     insert wOrder;
        
    //     return wOrder;
    // }

    // public static WorkOrder createOpenWorkOrder(Id accId, Id locationId) {
    //     WorkOrder wOrder = new WorkOrder();
    //     wOrder.AccountId = accId;
    //     wOrder.Status = 'New';
    //     wOrder.Next_Call_Objective__c = 'Test';
    //     wOrder.Status = 'In Progress';
    //     wOrder.LocationId = locationId;
    //     wOrder.StartDate = system.now().addDays(-2);
    //     wOrder.EndDate = system.now().addDays(-1);
    //     wOrder.Pricebook2Id = test.getStandardPricebookId();
    //     insert wOrder;
        
    //     return wOrder;
    // }

    // public static WorkOrderLineItem createWorkOrderLineItem(Id workOrderId, Id entryId) {
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = workOrderId;
    //     line.PricebookEntryId = entryId;
    //     line.Item_Type__c = 'Cash Sale';
    //     line.Origin__c = 'Ideal Kit';
    //     line.UnitPrice = 0;
    //     line.Shelf_Price__c = 100;
    //     line.PODRIA_Status__c = 'I';
    //     insert line;

    //     return line;
    // }

    // public static WorkOrderLineItem createWorkOrderLineItemNoShelf(Id workOrderId, Id entryId) {
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = workOrderId;
    //     line.PricebookEntryId = entryId;
    //     line.Item_Type__c = 'Cash Sale';
    //     insert line;

    //     return line;
    // }

    // public static OperatingHours createOperatingHours() {
    //     OperatingHours hours = new OperatingHours();
    //     hours.Name = 'Test Hours';
    //     hours.TimeZone = 'America/Los_Angeles';
    //     insert hours;

    //     return hours;
    // }

    // public static ServiceResource createServiceResource(Id userId) {
    //     ServiceResource resource = new ServiceResource();
    //     resource.IsActive = true;
    //     resource.Name = 'Test Resource';
    //     resource.RelatedRecordId = userId;
    //     insert resource;

    //     return resource;
    // }

    // public static ServiceTerritory createServiceTerritory(Id operatingHoursId) {
    //     ServiceTerritory territory = new ServiceTerritory();
    //     territory.Name = 'Test Territory';
    //     territory.IsActive = true;
    //     territory.OperatingHoursId = operatingHoursId;
    //     insert territory;

    //     return territory;
    // }

    // public static ServiceTerritoryMember createServiceTerritoryMember(Id territoryId, Id resourceId) {
    //     ServiceTerritoryMember member = new ServiceTerritoryMember();
    //     member.ServiceTerritoryId = territoryId;
    //     member.ServiceResourceId = resourceId;
    //     member.TerritoryType = 'P';
    //     member.EffectiveStartDate = date.today();
    //     insert member;

    //     return member;
    // }

    // public static ServiceAppointment createServiceAppointment(Id workOrderId, Id serviceTerritoryId) {
    //     ServiceAppointment appointment = new ServiceAppointment();
    //     appointment.ServiceTerritoryId = serviceTerritoryId;
    //     appointment.ParentRecordId = workOrderId;
    //     appointment.SchedStartTime = system.now();
    //     appointment.SchedEndTime = system.now().addHours(2);
    //     appointment.Status = 'Dispatched';
    //     appointment.Call_Type__c = 'In-Store Visit';
    //     appointment.ActualStartTime = system.now();
    //     insert appointment;

    //     return appointment;
    // }

    // public static AssignedResource createAssignedResource(Id resourceId, Id appointmentId) {
    //     AssignedResource resource = new AssignedResource();
    //     resource.ServiceAppointmentId = appointmentId;
    //     resource.ServiceResourceId = resourceId;
    //     insert resource;

    //     return resource;
    // }

    // public static ServiceReport createServiceReport(Id workOrderId, Id templateId) {
    //     ServiceReport report = new ServiceReport();
    //     report.DocumentBody = blob.valueOf('Content');
    //     report.DocumentName = 'File.pdf';
    //     report.DocumentContentType = 'application/pdf';
    //     report.Template = templateId;
    //     report.ParentId = workOrderId;
    //     insert report;

    //     return report;
    // }

    public static Task createTask(Id parentId) {
        Task newTask = new Task();
        newTask.Status = 'Open';
        newTask.Subject = 'Test Subject';
        newTask.WhatId = parentId;
        newTask.OwnerId = UserInfo.getUserId();
        newTask.In_Store__c = true;
        insert newTask;

        return newTask;
    }

    public static Coverage_Plan__c createAnnualCoverage() {
        Coverage_Plan__c plan = new Coverage_Plan__c();
        plan.Name = 'Annual';
        insert plan;

        Coverage_Period__c period = new Coverage_Period__c();
        period.Coverage_Plan__c = plan.Id;
        period.Start_Date__c = Date.newInstance(Date.today().year(), 01, 01);
        period.End_Date__c = Date.newInstance(Date.today().year(), 01, 01).addYears(1).addDays(-1);
        insert period;

        return plan;
    }

    public static Goals__c createGoals() {
        Goals__c goals = new Goals__c();
        goals.Quarterly_Visits__c = 300;
        insert goals;

        return goals;
    }

}