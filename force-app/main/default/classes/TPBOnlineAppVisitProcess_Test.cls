@IsTest
public class TPBOnlineAppVisitProcess_Test {
    
    public static Id accountId;
    public static Id visitTemplateId;
    public static Id visitId;
    
    @testSetup
    static void setupData() {
        Id gsRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        
        // Id gsRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        Id visitRecordTypeID =  Schema.getGlobalDescribe().get('Visit').getDescribe().getRecordTypeInfosByName().get('Editable').getRecordTypeId();
        // Id visitRecordTypeID = Schema.SObjectType.Visit.getRecordTypeInfosByName().get('Editable').getRecordTypeId();
        Id accTaskRecordTypeID =  Schema.getGlobalDescribe().get('cgcloud__Account_Task__c').getDescribe().getRecordTypeInfosByName().get('Customer Task Editable').getRecordTypeId();
        //Id accTaskRecordTypeID = Schema.SObjectType.cgcloud__Account_Task__c.getRecordTypeInfosByName().get('Customer Task Editable').getRecordTypeId();
        cgcloud__Visit_Template__c visitTemplate = new cgcloud__Visit_Template__c(
            Name = 'Distribution Visit Template',
            cgcloud__Active__c = true,
            cgcloud__Description_Language_1__c = 'Distribution Visit Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert visitTemplate;
        cgcloud__Account_Template__c accTemp = new cgcloud__Account_Template__c();
        accTemp.cgcloud__Active__c = true;
        accTemp.cgcloud__Sales_Org__c = '0001';
        accTemp.cgcloud__Description_Language_1__c = 'Customer';
        accTemp.Name = 'Customer';
        insert accTemp;
        
        
        Account acc = new Account(
            Name = 'RetailTest', 
            Type = 'Retail', 
            Status__c = 'Open',
            RecordTypeId = gsRecordTypeID,
            cgcloud__Account_Template__c = accTemp.Id
        );
        insert acc;
        
        accountId = acc.Id;
        
        cgcloud__Visit_Template__c vt = new cgcloud__Visit_Template__c(Name='Template1', 
                                                                       cgcloud__Active__c=true, 
                                                                       cgcloud__Meta_Type__c ='Call',
                                                                       cgcloud__Sales_Org__c ='0001',
                                                                       cgcloud__Auto_Status__c ='Planned', 
                                                                       cgcloud__Default_Duration__c =30.00);
        insert vt;
        visitTemplateId = vt.Id;
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Default Location';
        loc.LocationType = 'Warehouse';
        insert loc;
        Visit vs = new Visit(AccountId =acc.Id,
                             RecordTypeId = visitRecordTypeID,
                             PlannedVisitStartTime =System.today(),
                             PlannedVisitEndTime =System.today(),
                             PlaceId=loc.Id,cgcloud__Responsible__c =UserInfo.getUserId(),
                             cgcloud__Accountable__c =UserInfo.getUserId(),
                             Status = 'Planned');
        insert vs;
        visitId = vs.Id;
        System.debug('visitId...'+visitId);
        System.debug('accountId...'+accountId);
        cgcloud__Account_Manager__c mgr = new cgcloud__Account_Manager__c(
            cgcloud__Account__c=accountId,
            cgcloud__User__c=UserInfo.getUserId(),
            cgcloud__Active__c=true
        );
        insert mgr;
        
        cgcloud__Data_Type__c  dataType = new cgcloud__Data_Type__c(
            Name='DomAstLocation',
            cgcloud__Sales_Org__c ='0001',
            cgcloud__Manual__c =true,
            cgcloud__Data_Type__c = 'Toggle');
        insert dataType;
        
        cgcloud__Job_Template__c jtc = new cgcloud__Job_Template__c(
            Name = 'Question',
            cgcloud__Sales_Org__c  = '0001',
            cgcloud__Description_Language_1__c = 'test445');
        insert jtc;
        
        cgcloud__Job_Definition_List_Template__c JDLT = new cgcloud__Job_Definition_List_Template__c (
            Name='test',cgcloud__Description_Language_1__c ='test',cgcloud__Sales_Org__c ='0001', cgcloud__User_Policy__c ='All');
        insert JDLT;
        
        // Only set writable fields; do not set read-only fields like Description or Name for managed/custom package objects
        cgcloud__Job_Definition_Template__c tmpl = new cgcloud__Job_Definition_Template__c(
            Name = 'Tmpl', 
            cgcloud__Active__c=true, 
            cgcloud__Sales_Org__c='0001',
            cgcloud__Data_Type__c = dataType.Id,
            cgcloud__Job_Template__c = jtc.Id,
            cgcloud__Description_Language_1__c = 'test',
            cgcloud__Measure_Type__c = 'Store'
        );
        insert tmpl;
        
        // Update tmpl with valid lookup
        tmpl.cgcloud__Data_Type__c = dataType.Id;
        update tmpl;
        cgcloud__Job_Definition_List__c JDL = new cgcloud__Job_Definition_List__c (
            Name ='test',
            cgcloud__Active__c = true,
            cgcloud__Consider_Products__c = false,cgcloud__Job_Definition_List_Template__c =JDLT.Id, 
            cgcloud__Valid_From__c = System.today(),cgcloud__Sales_Org__c = '0001',
            cgcloud__Valid_Thru__c = System.today(),cgcloud__Visit_Template__c =vt.Id,
            cgcloud__Description_Language_1__c  = 'test');
        insert JDL;
        cgcloud__Job_DL_Job_Definition_Template__c jdt = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_Template__c = tmpl.Id,
            cgcloud__Sales_Org__c = '0001', cgcloud__Job_Definition_List__c =JDL.Id
        );
        insert jdt;
        
        // Only set writable fields
        cgcloud__Data_Type_Option__c opt = new cgcloud__Data_Type_Option__c(
            cgcloud__Code__c='OC1', 
            cgcloud__Data_Type__c=dataType.Id,
            cgcloud__Short_Description_Language_1__c ='test'
        );
        insert opt;
        
        cgcloud__Visit_Job__c job = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = vs.Id,
            cgcloud__Job_Definition_Template__c=tmpl.Id,
            cgcloud__Value__c='Answer',
            cgcloud__Job_Definition__c=jdt.Id,
            cgcloud__Data_Type_Option__c=opt.Id
        );
        insert job;
        cgcloud__Account_Task_Template__c accTaskTemplate = new cgcloud__Account_Task_Template__c(
            Name = 'test',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Description_Language_1__c = 'test');
        insert accTaskTemplate;
        
        cgcloud__Account_Task__c accTask = new cgcloud__Account_Task__c( 
            cgcloud__Sales_Org__c = '0001',cgcloud__Priority__c = 'A',
            cgcloud__Classification__c = 'Inquiry',cgcloud__Account_Task_Template__c = accTaskTemplate.Id,
            cgcloud__Description_Language_1__c = 'test',
            cgcloud__Account__c = acc.Id ,RecordTypeId=accTaskRecordTypeID,
            cgcloud__Due_Date__c = System.today(),
            cgcloud__Phase__c = 'Initial',cgcloud__Responsible__c=UserInfo.getUserId(),cgcloud__Accountable__c=UserInfo.getUserId());
        insert accTask;
    }
    
    @IsTest
    static void testGetVisitTemplates() {
        Test.startTest();
        List<cgcloud__Visit_Template__c> templates = TPBOnlineAppVisitProcess.getVisitTemplates();
        System.assert(!templates.isEmpty(), 'Should have at least one active template');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetVisitTypePicklistValues() {
        Test.startTest();
        List<String> types = TPBOnlineAppVisitProcess.getVisitTypePicklistValues();
        System.assert(types != null, 'Picklist values should not be null');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCustomerAccountsAndCreateVisit() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        Test.startTest();
        List<Account> accounts = TPBOnlineAppVisitProcess.getCustomerAccounts(acc.Id);
        //System.assertEquals(1, accounts.size(), 'Should return only mapped account');
        List<Account> accs = TPBOnlineAppVisitProcess.getCustomerAccounts(null);
        //System.assertEquals(1, accs.size());
        
        // Use a valid picklist value from your org for visitType
        System.debug('acc.Id'+acc.Id);
        System.debug('vt.Id'+vt.Id);
        
        try {
            //String result = TPBOnlineAppVisitProcess.createVisit(
            //acc.Id, vt.Id, 'In-Store Visit', '2025-09-01', '14:00'
            //);
            //0013i00001cknYrAAI a6k6T0000011dB3QAI In-Store Visit 2025-09-01 15:54
            String result = TPBOnlineAppVisitProcess.createVisit(
                acc.Id, vt.Id, 'In-Store Visit', '2025-09-01', '15:54'
            );
            System.debug('Result = ' + result);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' -- ' + e.getStackTraceString());
            //System.assert(false, 'createVisit failed: ' + e.getMessage());
            throw e;
        }
        
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetMyVisitsNewAndStartEndVisitUpdate() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        String visitType = 'Retailer';
        //TPBOnlineAppVisitProcess.createVisit(acc.Id, vt.Id, 'In-Store Visit', '2025-09-01', '14:00');
        
        Test.startTest();
        Double lat = 17.37;
        Double lng = 78.56;
        Boolean started = TPBOnlineAppVisitProcess.startvisitUpdate(v.Id, acc.Id, lat, lng);
        // Ensure start is set and earlier than upcoming end time
        Visit startedVisit = [SELECT Id, ActualVisitStartTime, ActualVisitEndTime FROM Visit WHERE Id = :v.Id LIMIT 1];
        startedVisit.ActualVisitStartTime = System.now().addMinutes(-10);
        startedVisit.ActualVisitEndTime = null;
        update startedVisit;
        String ended = TPBOnlineAppVisitProcess.endvisitUpdate(v.Id, lat, lng, acc.Id);
        
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetVisitInfo() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        Test.startTest();
        List<Visit> visits = TPBOnlineAppVisitProcess.getMyVisits('2025-09-01');
        
        List<Visit> visitsNew = TPBOnlineAppVisitProcess.getMyVisits_New();
        List<Visit> info = TPBOnlineAppVisitProcess.getVisitInfo(v.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testSurveyJobWrappers() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        
        
        Test.startTest();
        List<TPBOnlineAppVisitProcess.QuestionWrapper> qWraps = TPBOnlineAppVisitProcess.getVisitQuestions(acc.Id, v.Id);
        //List<TPBOnlineAppVisitProcess.QuestionWrapper> qWrap = TPBOnlineAppVisitProcess.getJobDefinitionTemplate(acc.Id);
        cgcloud__Visit_Job__c vJ = [SELECT Id,cgcloud__Job_Definition__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Value__c='Answer' LIMIT 1];
        vJ.cgcloud__Job_Definition__c = null;
        update vJ;
        List<TPBOnlineAppVisitProcess.QuestionWrapper> qWraps1 = TPBOnlineAppVisitProcess.getVisitQuestions(acc.Id, v.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testSurveyJobsWithFile() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        cgcloud__Job_Definition_Template__c jdt = [SELECT Id FROM cgcloud__Job_Definition_Template__c WHERE Name ='Tmpl' LIMIT 1];
        cgcloud__Job_DL_Job_Definition_Template__c jobdt = [SELECT Id FROM cgcloud__Job_DL_Job_Definition_Template__c LIMIT 1];
        cgcloud__Visit_Job__c VJ = [SELECT Id FROM cgcloud__Visit_Job__c Where cgcloud__Value__c='Answer' LIMIT 1];
        cgcloud__Account_Task__c accTask = [SELECT Id FROM cgcloud__Account_Task__c Where cgcloud__Classification__c = 'Inquiry' LIMIT 1];
        cgcloud__Data_Type_Option__c dto = [SELECT Id FROM cgcloud__Data_Type_Option__c Where cgcloud__Code__c='OC1' LIMIT 1];
        
        
        TPBOnlineAppVisitProcess.SurveyData sd = new TPBOnlineAppVisitProcess.SurveyData();
        sd.questionId = jdt.Id;
        sd.visitJobId = VJ.Id;
        sd.jobDefinitionId = jobdt.Id;
        sd.optiontId = dto.Id;
        sd.visitJobAnswer = 'Test Answer';
        
        List<TPBOnlineAppVisitProcess.SurveyData> sdList = new List<TPBOnlineAppVisitProcess.SurveyData>{sd};
            String jsonSDList = JSON.serialize(sdList);
        System.debug('jsonSDList...'+jsonSDList);
        Test.startTest();
        String result = TPBOnlineAppVisitProcess.createSurveyVisitJobs(v.Id, jsonSDList);
        System.assertEquals('success', result);
        
        String fileName = 'test.pdf';
        Blob fileBody = Blob.valueOf('unit test content');
        String base64Data = EncodingUtil.base64Encode(fileBody);
        String fileResult = TPBOnlineAppVisitProcess.createSurveyVisitJobsWihtFiles(v.Id, jsonSDList, fileName, base64Data);
        System.assertEquals('success', fileResult, 'File upload flow should return success');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testTaskTemplates() {
        cgcloud__Visit_Template__c vt = [SELECT Id FROM cgcloud__Visit_Template__c WHERE Name = 'Template1' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name ='RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId=:acc.Id LIMIT 1];
        cgcloud__Job_Definition_Template__c jdt = [SELECT Id FROM cgcloud__Job_Definition_Template__c WHERE Name ='Tmpl' LIMIT 1];
        cgcloud__Job_DL_Job_Definition_Template__c jobdt = [SELECT Id FROM cgcloud__Job_DL_Job_Definition_Template__c LIMIT 1];
        cgcloud__Visit_Job__c VJ = [SELECT Id FROM cgcloud__Visit_Job__c Where cgcloud__Value__c='Answer' LIMIT 1];
        cgcloud__Account_Task_Template__c accTask = [SELECT Id FROM cgcloud__Account_Task_Template__c Where Name = 'test' LIMIT 1];
        cgcloud__Data_Type_Option__c dto = [SELECT Id FROM cgcloud__Data_Type_Option__c Where cgcloud__Code__c='OC1' LIMIT 1];
        Test.startTest();
        List<cgcloud__Account_Task_Template__c> templates = TPBOnlineAppVisitProcess.getCustomerTaskTemplates();
        System.assertNotEquals(null, templates);
        TPBOnlineAppVisitProcess.createCustomerTask(acc.Id, accTask.Id,String.valueOf(Date.today()), 'test');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCustomerTasksAndPendingByAccount() {
        Test.startTest();
        List<cgcloud__Account_Task__c> tasks = TPBOnlineAppVisitProcess.getCustomerTasks('2025-08-27');
        
        List<cgcloud__Account_Task__c> pendingTasks = TPBOnlineAppVisitProcess.getCustomerTasksPendingByAccount(Date.today(), accountId);
        Test.stopTest();
    }
    
    @IsTest
    static void testEndVisitValidateBranches() {
        Account accountNoTasks = TPB_TestFactory.createAccount();
        Visit visitNoTasks = TPB_TestFactory.createVisit(accountNoTasks);
        
        Test.startTest();
        String validated = TPBOnlineAppVisitProcess.endvisitValidate(visitNoTasks.Id, accountNoTasks.Id, false, false);
        Test.stopTest();
        System.assertEquals('validated', validated, 'When no blockers exist, should return validated');
    }
    
    @IsTest
    static void testEndVisitValidateDistributionPending() {
        Account accountDist = TPB_TestFactory.createAccount();
        Visit visitDist = TPB_TestFactory.createVisit(accountDist);
        Product2 product = TPB_TestFactory.createProduct();
        
        cgcloud__Job_Definition_List_Template__c distTemplate = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Dist Template',
            cgcloud__Consider_Account__c = true,
            cgcloud__Consider_Products__c = true,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__User_Policy__c = 'All'
        );
        insert distTemplate;
        
        cgcloud__Job_Definition_List__c distList = new cgcloud__Job_Definition_List__c(
            Name = 'Dist List',
            cgcloud__Job_Definition_List_Template__c = distTemplate.Id,
            cgcloud__Active__c = true,
            cgcloud__Consider_Products__c = true,
            cgcloud__Approval_State__c = 'Not Relevant',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Valid_From__c = System.today().addDays(-1),
            cgcloud__Valid_Thru__c = System.today().addDays(1),
            cgcloud__Visit_Template__c = visitDist.cgcloud__Visit_Template__c
        );
        insert distList;
        
        cgcloud__Job_Definition_List_Account__c distAccount = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = distList.Id,
            cgcloud__Account__c = accountDist.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert distAccount;
        
        cgcloud__Job_Definition_List_Product__c distProduct = new cgcloud__Job_Definition_List_Product__c(
            cgcloud__Job_Definition_List__c = distList.Id,
            cgcloud__Product__c = product.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert distProduct;
        
        Test.startTest();
        String result = TPBOnlineAppVisitProcess.endvisitValidate(visitDist.Id, accountDist.Id, true, false);
        Test.stopTest();
        
        System.assertEquals('pending_product_distribution', result, 'Missing distribution visit jobs should be flagged');
    }
    
    @IsTest
    static void testEndVisitValidateSurveyPending() {
        Account accountSurvey = TPB_TestFactory.createAccount();
        Visit visitSurvey = TPB_TestFactory.createVisit(accountSurvey);
        
        cgcloud__Job_Definition_List_Template__c surveyTemplate = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Survey Template',
            cgcloud__Consider_Account__c = true,
            cgcloud__Consider_Products__c = false,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__User_Policy__c = 'All'
        );
        insert surveyTemplate;
        
        cgcloud__Job_Definition_List__c surveyList = new cgcloud__Job_Definition_List__c(
            Name = 'Survey List',
            cgcloud__Job_Definition_List_Template__c = surveyTemplate.Id,
            cgcloud__Active__c = true,
            cgcloud__Consider_Products__c = false,
            cgcloud__Approval_State__c = 'Not Relevant',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Valid_From__c = System.today().addDays(-1),
            cgcloud__Valid_Thru__c = System.today().addDays(1),
            cgcloud__Visit_Template__c = visitSurvey.cgcloud__Visit_Template__c
        );
        insert surveyList;
        
        cgcloud__Job_Definition_List_Account__c surveyAccount = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = surveyList.Id,
            cgcloud__Account__c = accountSurvey.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert surveyAccount;
        
        cgcloud__Job_Template__c questionTemplate = [
            SELECT Id FROM cgcloud__Job_Template__c WHERE Name = 'Question' LIMIT 1
        ];
        cgcloud__Data_Type__c dataType = [
            SELECT Id FROM cgcloud__Data_Type__c WHERE cgcloud__Sales_Org__c = '0001' LIMIT 1
        ];
        cgcloud__Job_Definition_Template__c surveyQuestionTemplate = new cgcloud__Job_Definition_Template__c(
            Name = 'Survey Question Pending',
            cgcloud__Active__c = true,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Data_Type__c = dataType.Id,
            cgcloud__Job_Template__c = questionTemplate.Id,
            cgcloud__Description_Language_1__c = 'Survey question',
            cgcloud__Measure_Type__c = 'Store'
        );
        insert surveyQuestionTemplate;
        
        cgcloud__Job_DL_Job_Definition_Template__c surveyQuestion = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_Template__c = surveyQuestionTemplate.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Job_Definition_List__c = surveyList.Id
        );
        insert surveyQuestion;
        
        Test.startTest();
        String result = TPBOnlineAppVisitProcess.endvisitValidate(visitSurvey.Id, accountSurvey.Id, false, true);
        Test.stopTest();
        
        System.assertEquals('pending_survey_questions', result, 'Missing survey visit jobs should be flagged');
    }
    
    @IsTest
    static void testGetDashboardLinks() {
        cgcloud__Mobile_Link__c link = new cgcloud__Mobile_Link__c(
            Name = 'Your Day Link',
            cgcloud__URL__c = 'https://example.com',
            cgcloud__Display_In__c = 'Your Day',
            cgcloud__Active__c = true,
            cgcloud__Sort__c = 1
        );
        insert link;
        
        Test.startTest();
        List<cgcloud__Mobile_Link__c> links = TPBOnlineAppVisitProcess.getDasboardLinks();
        Test.stopTest();
        
        System.assert(!links.isEmpty(), 'Dashboard links should include active Your Day entries');
    }
    
    
    
    @IsTest
static void testCancelVisit() {
    Account acc = [SELECT Id FROM Account WHERE Name = 'RetailTest' LIMIT 1];
    Visit v = [SELECT Id, Status FROM Visit WHERE AccountId = :acc.Id LIMIT 1];
    
    Test.startTest();
    
    // Test successful cancel
    TPBOnlineAppVisitProcess.cancelVisit(v.Id);
    Visit cancelled = [SELECT Id, Status FROM Visit WHERE Id = :v.Id];
    System.assertEquals('Abandoned', cancelled.Status, 'Visit status should be Abandoned');
    
    // Test cancel on already Abandoned visit — should throw
    try {
        TPBOnlineAppVisitProcess.cancelVisit(v.Id);
        System.assert(false, 'Expected AuraHandledException for already abandoned visit');
    } catch (AuraHandledException e) {
        System.assert(true, 'Exception expected for abandoned visit');
    }
    
    // Test null visitId — should throw
    try {
        TPBOnlineAppVisitProcess.cancelVisit(null);
        System.assert(false, 'Expected AuraHandledException for null visit Id');
    } catch (AuraHandledException e) {
        System.assert(true, 'Exception expected for null visit Id');
    }
    
    Test.stopTest();
}

   @IsTest
static void testGetParentAccountHQAttachments() {

    cgcloud__Account_Template__c accTemp = [SELECT Id FROM cgcloud__Account_Template__c LIMIT 1];

    Id retailerRecordTypeId = Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Retailer')
        .getRecordTypeId();

    Id wholesalerRecordTypeId = Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Wholesaler')
        .getRecordTypeId();

    // Parent Account (must satisfy ParentId filter)
    Account parentAcc = new Account(
        Name = 'Parent HQ Account',
        RecordTypeId = wholesalerRecordTypeId,
        cgcloud__Account_Template__c = accTemp.Id
    );
    insert parentAcc;

    // Child Account
    Account childAcc = new Account(
        Name = 'Child Retailer Account',
        RecordTypeId = retailerRecordTypeId,
        cgcloud__Account_Template__c = accTemp.Id,
        ParentId = parentAcc.Id
    );
    insert childAcc;

    // Create file
    ContentVersion cv = new ContentVersion(
        Title = 'Test HQ Doc',
        PathOnClient = 'TestHQDoc.pdf',
        VersionData = Blob.valueOf('HQ attachment content'),
        TPB_IsHQAttachment__c = true
    );
    insert cv;

    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    insert new ContentDocumentLink(
        LinkedEntityId = parentAcc.Id,
        ContentDocumentId = cv.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );

    Test.startTest();
   List<ContentDocumentLink> results =
        TPBOnlineAppVisitProcess.getParentAccountHQAttachments(childAcc.Id);
    Test.stopTest();

    System.assertEquals(1, results.size());
}

    @IsTest
    static void testVisitFileUploadGetAndDeleteFlow() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('visit-file-content'));

        Test.startTest();
        TPBOnlineAppVisitProcess.uploadVisitFile(v.Id, 'visit-proof.pdf', base64Data, 'application/pdf');
        List<TPBOnlineAppVisitProcess.VisitFileWrapper> files = TPBOnlineAppVisitProcess.getVisitFiles(v.Id);
        Test.stopTest();

        System.assert(files.size() > 0, 'Uploaded file should be returned for the visit');
        Id contentDocumentId = Id.valueOf(files[0].contentDocumentId);

        TPBOnlineAppVisitProcess.deleteVisitFile(v.Id, contentDocumentId);
        List<TPBOnlineAppVisitProcess.VisitFileWrapper> afterDelete = TPBOnlineAppVisitProcess.getVisitFiles(v.Id);
        System.assertEquals(0, afterDelete.size(), 'File should be removed after delete');
    }

    @IsTest
    static void testVisitFileValidationBranches() {
        System.assertEquals(0, TPBOnlineAppVisitProcess.getVisitFiles(null).size(), 'Null visit id should return empty list');

        Account acc = [SELECT Id FROM Account WHERE Name = 'RetailTest' LIMIT 1];
        Visit v = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];
        Boolean uploadErrorThrown = false;
        try {
            TPBOnlineAppVisitProcess.uploadVisitFile(v.Id, 'bad.txt', 'invalid-base64###', 'text/plain');
        } catch (AuraHandledException ex) {
            uploadErrorThrown = true;
        }
        System.assert(uploadErrorThrown, 'Invalid base64 should throw AuraHandledException');

        Boolean deleteErrorThrown = false;
        try {
            TPBOnlineAppVisitProcess.deleteVisitFile(null, null);
        } catch (AuraHandledException ex) {
            deleteErrorThrown = true;
        }
        System.assert(deleteErrorThrown, 'Null ids should throw AuraHandledException');
    }

    @IsTest
    static void testParentAccountAttachmentsNoParentBranch() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'RetailTest' LIMIT 1];
        List<ContentDocumentLink> noParent = TPBOnlineAppVisitProcess.getParentAccountHQAttachments(acc.Id);
        System.assertEquals(0, noParent.size(), 'Account without parent should return empty list');
    }

}