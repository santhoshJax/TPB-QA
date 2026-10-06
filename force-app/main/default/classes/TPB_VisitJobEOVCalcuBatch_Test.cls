@isTest
/**
* @author: Zeen Liu
* date:2/7/2023
* @description test class for TPB_VisitJobEOVCalcuBatch.
*/
private class TPB_VisitJobEOVCalcuBatch_Test {
    private static final String SALESORG = '0001';
    @testSetup
    static void setup() {
        //create Product for test.
        Product2 proObj = TPB_TestFactory.createProduct();
        //create Account for test.
        Account accObj = TPB_TestFactory.createAccount();
        //create Visit for test.
        Visit visitObj = TPB_TestFactory.createVisit(accObj);
        visitObj.ActualVisitStartTime = System.now().addDays(-1).addHours(-1);
        visitObj.ActualVisitEndTime = System.now().addDays(-1);
        visitObj.Status = 'Completed';
        update visitObj;
        //create Visit Job for test.
        TPB_TestFactory.createVisitJob(visitObj, proObj);
        //create Order for test.
        cgcloud__Order__c orderObj = TPB_TestFactory.createAdOrder(visitObj);
        orderObj.cgcloud__Delivery_Recipient__c = accObj.Id;
        orderObj.cgcloud__Phase__c = 'Released';
        update orderObj;
        //create Order Item for test.
        TPB_TestFactory.createAdOrderItem(orderObj, proObj);
        //create Order Item for new Visit Job
        // cgcloud__Product_Template__c
        cgcloud__Product_Template__c productTemplateOne = new cgcloud__Product_Template__c(
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Active__c = true,
            Name = 'one',
            cgcloud__Description_Language_1__c = 'Product',
            cgcloud__Price_Required__c = false
        );
        insert productTemplateOne;
        productTemplateOne = [
            SELECT Id, RecordTypeId
            FROM cgcloud__Product_Template__c
            WHERE Name = 'one'
            LIMIT 1
        ][0];
        // Product2
        Product2 productOne = new Product2(
            Name = 'one',
            cgcloud__Description_1_Language_1__c = 'one',
            IsActive = true,
            cgcloud__Product_Template__c = productTemplateOne.Id,
            cgcloud__Competitive_Product__c = false,
            cgcloud__Consumer_Goods_Product_Code__c = '0011'
        );
        insert productOne;
        productOne = [SELECT Id FROM Product2 WHERE Name = 'one' LIMIT 1][0];
        TPB_TestFactory.createAdOrderItem(orderObj, productOne);
        // cgcloud__Visit_Template__c
        cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
            Name = 'Distribution Visit Template',
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Active__c = true,
            cgcloud__Add_Job_Policy__c = true,
            cgcloud__Auto_Status__c = 'Planned',
            cgcloud__Cancel_Reason_Required__c = false,
            cgcloud__Capture_Proceeding_Time__c = true,
            cgcloud__Check_Overlap__c = false,
            cgcloud__Company_Required__c = 'Mandatory',
            cgcloud__Consider_POS_Check__c = true,
            cgcloud__Creation_Platform__c = 'Both',
            cgcloud__Default_Duration__c = 30,
            cgcloud__Delete_Allowed__c = true,
            cgcloud__Display_Promotions__c = true,
            cgcloud__Historical_Products__c = 'No',
            cgcloud__KPI_Relevant__c = 'All',
            cgcloud__Loc_Capture_During_Cancel__c = true,
            cgcloud__Loc_Capture_During_Complete__c = true,
            cgcloud__Max_Pictures__c = 10,
            cgcloud__Meta_Type__c = 'Call',
            cgcloud__Mobility_Color__c = '6688BB',
            cgcloud__Mobility_Relevant__c = true,
            cgcloud__Mobility_User_Guidance__c = 'Sales',
            cgcloud__Promotion_Finding_Lead_Time__c = 365,
            cgcloud__Sort__c = 5,
            cgcloud__User_Roles__c = 'CGCloud_Sales_User;CGCloud_Supervisor;CGCloud_Tour_User'
        );
        insert vTOne;
        vTOne = [
            SELECT Id
            FROM cgcloud__Visit_Template__c
            WHERE Name = 'Distribution Visit Template'
            LIMIT 1
        ][0];
        // cgcloud__Job_Definition_List_Template__c
        cgcloud__Job_Definition_List_Template__c jDLTOne = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Distribution Activity Template',
            cgcloud__Consider_Account__c = true,
            cgcloud__Consider_Products__c = true,
            cgcloud__Sales_Org__c = SALESORG
        );
        insert jDLTOne;
        jDLTOne = [
            SELECT Id
            FROM cgcloud__Job_Definition_List_Template__c
            WHERE Name = 'Distribution Activity Template'
        ][0];
        //cgcloud__Job_Definition_List__c
        cgcloud__Job_Definition_List__c activity = new cgcloud__Job_Definition_List__c(
            Name = accObj.Name,
            cgcloud__Job_Definition_List_Template__c = jDLTOne.Id,
            cgcloud__Visit_Template__c = vTOne.Id,
            cgcloud__Sales_Org__c = SALESORG
        );
        insert activity;
        activity = [
            SELECT Id
            FROM cgcloud__Job_Definition_List__c
            WHERE Name = :accObj.Name
        ][0];
        //cgcloud__Job_Definition_List_Account__c
        cgcloud__Job_Definition_List_Account__c activityAccount = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = activity.Id,
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Account__c = accObj.Id
        );
        insert activityAccount;
        //cgcloud__Data_Type__c
        cgcloud__Data_Type__c dataType = new cgcloud__Data_Type__c(
            cgcloud__Sales_Org__c = SALESORG,
            Name = 'DomPrdDistributed'
        );
        insert dataType;
        dataType = [
            SELECT Id
            FROM cgcloud__Data_Type__c
            WHERE Name = 'DomPrdDistributed' AND cgcloud__Sales_Org__c = '0001'
        ][0];
        //cgcloud__Job_Template__c
        cgcloud__Job_Template__c jobTemplate = new cgcloud__Job_Template__c(
            cgcloud__Description_Language_1__c = 'Survey',
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Product_Reference__c = true
        );
        insert jobTemplate;
        jobTemplate = [
            SELECT Id
            FROM cgcloud__Job_Template__c
            WHERE cgcloud__Description__c = 'Survey'
        ][0];
        //cgcloud__Job_Definition_Template__c
        cgcloud__Job_Definition_Template__c jDTemplate = new cgcloud__Job_Definition_Template__c(
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Data_Type__c = dataType.Id,
            cgcloud__Job_Template__c = jobTemplate.Id,
            cgcloud__Active__c = true,
            cgcloud__Description_Language_1__c = 'Distribution'
        );
        insert jDTemplate;
        jDTemplate = [
            SELECT Id
            FROM cgcloud__Job_Definition_Template__c
            WHERE cgcloud__Description__c = 'Distribution'
        ][0];
        //cgcloud__Job_DL_Job_Definition_Template__c
        cgcloud__Job_DL_Job_Definition_Template__c question = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Sales_Org__c = SALESORG,
            cgcloud__Job_Definition_Template__c = jDTemplate.Id,
            cgcloud__Job_Definition_List__c = activity.Id
        );
        insert question;
        //cgcloud__Data_Type_Option__c
        cgcloud__Data_Type_Option__c dataTypeOption = new cgcloud__Data_Type_Option__c(
            cgcloud__Description_Language_1__c = 'Distributed',
            cgcloud__Data_Type__c = dataType.Id,
            cgcloud__Code__c = '1',
            cgcloud__Short_Description_Language_1__c = 'Distributed'
        );
        insert dataTypeOption;
    }
    
    @isTest
    static void testEOVCalcu() {
        System.Test.startTest();
        TPB_VisitJobEOVCalcuBatch batch = new TPB_VisitJobEOVCalcuBatch();
        Database.executeBatch(batch);
        System.Test.stopTest();
        //assert batch job result.
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM cgcloud__Visit_Job__c
                WHERE TPB_EOV__c = 'Distributed'
            ],
            0
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM cgcloud__Visit_Job__c
                WHERE
                cgcloud__Visit_Date__c = NULL
                OR cgcloud__Value__c = NULL
                OR cgcloud__Job_Definition_Template__c = NULL
            ],
            0
        );
        // SAL-281b: setup visit is offline (End_Visit_Online__c = false) and order items are
        // not scanned -> origin = Offline Manual (no Online App, no Offline Scanner)
        System.assertEquals(
            0,
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Online App'],
            'SAL-281: offline visit must not be stamped Online App'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Offline Scanner'],
            'SAL-281b: unscanned offline lines must not be stamped Offline Scanner'
        );
        System.assert(
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Offline Manual'] > 0,
            'SAL-281b: unscanned offline visit VJs should be stamped Offline Manual'
        );
    }

    @isTest
    static void testEOVCalcuOnlineApp() {
        // SAL-281: flip the visit to an online-app visit before the EOV calc runs
        Visit v = [SELECT Id FROM Visit LIMIT 1];
        v.End_Visit_Online__c = true;
        update v;

        System.Test.startTest();
        Database.executeBatch(new TPB_VisitJobEOVCalcuBatch());
        System.Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Offline Manual'],
            'SAL-281: online visit must not be stamped Offline Manual'
        );
        System.assert(
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Online App'] > 0,
            'SAL-281: online visit VJs should be stamped Online App'
        );
    }

    @isTest
    static void testEOVCalcuOfflineScanner() {
        // SAL-281b: visit stays offline (End_Visit_Online__c = false from setup); flag every
        // order item as scanner-added. Both VJ paths must stamp 'Offline Scanner':
        //   - proObj has a pre-planned product VJ  -> matched-existing-VJ override branch
        //   - productOne has no VJ                 -> new order-derived VJ create
        List<cgcloud__Order_Item__c> orderItems = [
            SELECT Id, TPB_Via_Scanner__c FROM cgcloud__Order_Item__c
        ];
        for (cgcloud__Order_Item__c oi : orderItems) {
            oi.TPB_Via_Scanner__c = true;
        }
        update orderItems;

        System.Test.startTest();
        Database.executeBatch(new TPB_VisitJobEOVCalcuBatch());
        System.Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Offline Scanner'] >= 2,
            'SAL-281b: scanned offline lines should stamp Offline Scanner on both the new-create and matched-existing paths'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM cgcloud__Visit_Job__c WHERE Distribution_Source__c = 'Offline Manual'],
            'SAL-281b: no Offline Manual when every offline line was scanned'
        );
    }
}