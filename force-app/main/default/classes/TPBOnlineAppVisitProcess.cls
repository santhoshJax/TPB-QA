public class TPBOnlineAppVisitProcess {

    @AuraEnabled(cacheable=true)
    public static List<cgcloud__Visit_Template__c>  getVisitTemplates() {
        
            return [
                SELECT Id, Name 
                FROM cgcloud__Visit_Template__c 
                WHERE cgcloud__Active__c = true
            ];
    }
     
    @AuraEnabled(cacheable=true)
    public static List<String> getVisitTypePicklistValues() {
        List<String> picklistValues = new List<String>();
        
        // Describe the Visit__c object
        Schema.DescribeSObjectResult visitDescribe = Schema.getGlobalDescribe().get('Visit').getDescribe();
        
        // Get all fields of Visit__c
        Map<String, Schema.SObjectField> fieldMap = visitDescribe.fields.getMap();

        // Get the describe result of the TPB_Visit_Type__c field
        Schema.DescribeFieldResult fieldResult = fieldMap.get('TPB_Visit_Type__c').getDescribe();

        // Loop through picklist values and add them to the list
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                picklistValues.add(entry.getLabel()); // Use getValue() if you want the API value
            }
        }

        return picklistValues;
    }

    @AuraEnabled
    public static List<Account> getCustomerAccounts(String accountId) {
        System.debug('accountId...'+ accountId);
        System.debug('userId...'+ UserInfo.getUserId());
        List<cgcloud__Account_Manager__c> userAccountsList= [SELECT cgcloud__Account__c FROM cgcloud__Account_Manager__c WHERE cgcloud__User__c =:UserInfo.getUserId() AND cgcloud__Active__c = true];
        Set<Id> accountIds = new Set<Id>();
        for(cgcloud__Account_Manager__c userAccount:userAccountsList){
            accountIds.add(userAccount.cgcloud__Account__c);
        }
        System.debug('accountIds...'+ accountIds);
        // If accountId parameter is provided and not empty, filter by it only
        if (accountId != null && accountId != '') {
            // If the passed accountId is in user's accountIds, filter by that one else return empty list
            if (accountIds.contains(accountId)) {
                return [
                    SELECT Id, Name, Type, Industry, Phone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Account_Number_old__c
                    FROM Account
                    WHERE Id = :accountId and RecordType.Name = 'Retailer'
                    ORDER BY Name ASC
                ];
            } else {
                // Passed accountId is not accessible by user, return empty list or handle as needed
                return new List<Account>();
            }
        } else {
            // No accountId provided, return all accounts in user's accountIds
            if (accountIds.isEmpty()) {
                return new List<Account>();
            }
            return [
                SELECT Id, Name, Type, Industry, Phone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Account_Number_old__c
                FROM Account
                WHERE Id IN :accountIds and RecordType.Name = 'Retailer'
                ORDER BY Name ASC
            ];
        }
       
    }

    @AuraEnabled
    public static String createVisit(Id customerId, Id visitTemplateId , String visitType, String visitDateStr,String visitTimeStr) {
        
        try {
            // Query RecordTypeId dynamically using DeveloperName
            Id rtId = [SELECT Id FROM RecordType 
                    WHERE SObjectType = 'Visit' 
                    AND DeveloperName = 'Editable' 
                    LIMIT 1].Id;

            Id placeId = [SELECT Id FROM Location 
                    WHERE Name = 'Default Location' 
                    LIMIT 1].Id;
            String combinedStr = visitDateStr + ' ' + visitTimeStr + ':00'; 
            DateTime dt = DateTime.valueOfGMT(combinedStr);
            DateTime endDateTime = dt.addMinutes(30);
            List<Visit> visitList = new List<Visit>();
            Visit visit = new visit();
            //visit.RecordTypeId='0126T000001h2sFQAQ';
            visit.RecordTypeId = rtId;
            visit.cgcloud__Creation_Mode__c='Manually';
            visit.TPB_WholesaleVisitType__c='Van Stock';
            visit.AccountId=customerId;
            visit.cgcloud__Responsible__c=UserInfo.getUserId();
            visit.cgcloud__Accountable__c=UserInfo.getUserId();
            visit.cgcloud__Visit_Template__c=visitTemplateId;
            visit.PlaceId = placeId;
            //visit.PlaceId='1316T000000XbQrQAK';
            visit.PlannedVisitStartTime =dt;
            visit.PlannedVisitEndTime =endDateTime;
            visit.TPB_Visit_Type__c=visitType;
            visit.cgcloud__Creation_Date_and_Time__c=DateTime.now();
            visit.VisitorId=UserInfo.getUserId();
            visitList.add(visit);
            System.debug('visitList++'+visitList);
            if(visitList.size() > 0){
            insert visitList;
            }
            
            return 'Successfully created the visit for this accountId: '+customerId+' and visitTemplateId:';
       
        } catch (Exception e) { System.debug('error visit++'+e.getStackTraceString()+'...'+e.getMessage());
              throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }
    
   @AuraEnabled(cacheable=true)
   public static List<Visit> getMyVisits(String selectedDate){
       System.debug('selectedDate++'+selectedDate);

        List<Visit> todayvisitList = new List<Visit>();
        try {
            if (String.isNotEmpty(selectedDate) && selectedDate.contains('T')) {
                selectedDate = selectedDate.split('T')[0];
            }
        
            Date filterDate = String.isNotEmpty(selectedDate) 
                ? Date.valueOf(selectedDate) 
                : Date.today();
            
            System.debug('Formatted selectedDate: ' + selectedDate);
            System.debug('filterDate: ' + filterDate);
            
            //Query Visit records using the formatted filterDate
            todayVisitList = [
                SELECT Id, Name, cgcloud__Visit_Template__r.Name, TPB_VisitType__c, AccountId,
                    cgcloud__Account_Street__c, cgcloud__Account_City__c, Account_Name__c, TPB_InProgress__c,Status,
                    PlannedVisitStartTime,ActualVisitEndTime,Account.Type
                FROM Visit
                WHERE Status IN ('Planned','Completed')
                AND DAY_ONLY(PlannedVisitStartTime) = :filterDate
                AND cgcloud__Responsible__c = :UserInfo.getUserId()
                AND cgcloud__Accountable__c = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC
            ];
            return todayvisitList;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    
   }
   @AuraEnabled(cacheable=true)
   public static List<Visit> getVisitInfo(Id visitId){
        List<Visit> visitDataList = new List<Visit>();
        try {
            visitDataList = [
                SELECT Id, cgcloud__Responsible__r.Name,cgcloud__Note__c,PlannedVisitStartTime,TPB_InProgress__c,Product_Distribution_Accessed__c
                FROM Visit
                WHERE Id = :visitId
            ];
            return visitDataList; 
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
   }
   public static List<Visit> getMyVisits_New(){

        List<Visit> todayvisitList = new List<Visit>();
        try {
            List<Visit> allVisits = [SELECT Id, Name, cgcloud__Visit_Template__r.Name, TPB_VisitType__c, AccountId,
                                    cgcloud__Account_Street__c, cgcloud__Account_City__c, Account_Name__c, TPB_InProgress__c,Status
                                    FROM Visit
                                    WHERE Status IN ('Planned','Completed')
                                    //AND DAY_ONLY(PlannedVisitStartTime) = :filterDate
                                    AND cgcloud__Responsible__c = :UserInfo.getUserId()
                                    AND cgcloud__Accountable__c = :UserInfo.getUserId()
                                    LIMIT 100];

            List<Visit> plannedInProgress = new List<Visit>();
            List<Visit> plannedNotInProgress = new List<Visit>();
            List<Visit> completed = new List<Visit>();

            for (Visit visit : allVisits) {
                if (visit.Status == 'Planned' && visit.TPB_InProgress__c) {
                    plannedInProgress.add(visit);
                } else if (visit.Status == 'Planned') {
                    plannedNotInProgress.add(visit);
                } else if (visit.Status == 'Completed') {
                    completed.add(visit);
                }
            }
            todayvisitList.addAll(plannedInProgress);
            todayvisitList.addAll(plannedNotInProgress);
            todayvisitList.addAll(completed);
            System.debug('todayvisitList '+todayvisitList);
            return todayvisitList;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
   }
    
    @AuraEnabled
    public static Boolean startvisitUpdate(Id visitId, Id accountId, Double startVisitLatitude, Double startVisitLongitude){
        List<Visit> inProgressVisits = [SELECT Id,TPB_InProgress__c,cgcloud__Responsible__r.Name FROM Visit WHERE TPB_InProgress__c = true AND cgcloud__Responsible__c =:UserInfo.getUserId() AND Status = 'Planned' AND Account.RecordType.Name =  'Retailer'];
        //AccountId  =: accountId AND 
        System.debug('inProgressVisits.size()++'+inProgressVisits.size());
        if(inProgressVisits.size() > 0){
            return false;
        }else{
            List<Visit> todayvisitList = new List<Visit>();
            Visit visit = new visit();
            visit.Id=visitId;
            //visit.Status='In Progress';
            visit.TPB_InProgress__c=true;
            visit.ActualVisitStartTime=DateTime.now();
            visit.Start_Visit_Location__Latitude__s = startVisitLatitude;
            visit.Start_Visit_Location__Longitude__s = startVisitLongitude;
            visit.Start_Visit_Online__c = true;
            todayvisitList.add(visit);
            if(todayvisitList.size()>0){
                update todayvisitList;
            }
            return true;
        }
    }
    @AuraEnabled
    public static String endvisitValidate(Id visitId,  Id accountId, Boolean validateEndVisitDistribution, Boolean validateEndVisitSurvey){
        List<cgcloud__Order__c> visitOrdersStatusList = [SELECT Id,cgcloud__Phase__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c  =: visitId];
        Boolean openOrders = false;
        for(cgcloud__Order__c visitOrdersStatus : visitOrdersStatusList){
            if(visitOrdersStatus.cgcloud__Phase__c == 'Initial'){
                openOrders = true;
            }
        }
        Date currentDate = Date.today();
        List<cgcloud__Account_Task__c> customerTasksPendingToday= getCustomerTasksPendingByAccount(currentDate,accountId);
        Boolean openCustomerTasks = false;
        if(customerTasksPendingToday.size()>0){
            openCustomerTasks = true;
        }

        // Product Distribution validation
        Boolean productDistributionPending = false;
        if(validateEndVisitDistribution){
            Set<Id> activityCustomerIds = TPB_OnlineAppController.getActivityProducts(accountId); 
            System.debug('activityCustomerIds data...'+ activityCustomerIds);

            List<cgcloud__Job_Definition_List_Product__c> activityProducts = [
                SELECT Id, cgcloud__Product__c
                FROM cgcloud__Job_Definition_List_Product__c
                WHERE cgcloud__Job_Definition_List__c IN :activityCustomerIds
            ];

            if(!activityProducts.isEmpty()){
                Set<Id> activityProductIds = new Set<Id>();
                for (cgcloud__Job_Definition_List_Product__c p : activityProducts){
                    if (p.cgcloud__Product__c != null) {
                        activityProductIds.add(p.cgcloud__Product__c);
                    }
                }

                List<cgcloud__Visit_Job__c> productDistVisitJobs = [
                    SELECT Id, cgcloud__Product__c
                    FROM cgcloud__Visit_Job__c
                    WHERE cgcloud__Visit__c = :visitId
                    AND cgcloud__Product__c IN :activityProductIds
                ];
                //and cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.cgcloud__Description__c = 'Survey']; //Need to check later if needed

                Set<Id> visitedProductIds = new Set<Id>();
                for (cgcloud__Visit_Job__c job : productDistVisitJobs){
                    if (job.cgcloud__Product__c != null) {
                        visitedProductIds.add(job.cgcloud__Product__c);
                    }
                }

                if (visitedProductIds.size() < activityProductIds.size()){
                    productDistributionPending = true;
                }
            }
        }

        Visit visit = [SELECT ID, TPB_Visit_Type__c FROM Visit WHERE ID = : visitId];
        if(visit.TPB_Visit_Type__c == 'Virtual' || visit.TPB_Visit_Type__c == 'Admin Update'){
            validateEndVisitSurvey = false;
        }
        Boolean surevyQuestionsPending = false;
        if(validateEndVisitSurvey){
            Set<Id> activityCustomerIds = getActivitySurveys(accountId); 
            System.debug('activityCustomerIds data...'+ activityCustomerIds);

            List<cgcloud__Job_DL_Job_Definition_Template__c> activityQuestionList = [
                SELECT Id, cgcloud__Job_Definition_Template__c
                FROM cgcloud__Job_DL_Job_Definition_Template__c
                WHERE cgcloud__Job_Definition_List__c IN :activityCustomerIds
                ORDER BY cgcloud__Sort__c ASC
            ];

            if(!activityQuestionList.isEmpty()){
                Set<Id> templateIds = new Set<Id>();
                for (cgcloud__Job_DL_Job_Definition_Template__c t : activityQuestionList){
                    if (t.cgcloud__Job_Definition_Template__c != null) {
                        templateIds.add(t.cgcloud__Job_Definition_Template__c);
                    }
                }

                List<cgcloud__Visit_Job__c> surveyVisitJobs = [
                    SELECT Id, cgcloud__Job_Definition_Template__c
                    FROM cgcloud__Visit_Job__c
                    WHERE cgcloud__Visit__c = :visitId
                    AND cgcloud__Job_Definition_Template__c IN :templateIds
                ];
                //and cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.cgcloud__Description__c = 'Question']; //Need to check later if needed

                //Below code If we want to check every survey question is answered
                // Set<Id> answeredTemplateIds = new Set<Id>();
                // for (cgcloud__Visit_Job__c job : surveyVisitJobs){
                //     if (job.cgcloud__Job_Definition_Template__c != null){
                //         answeredTemplateIds.add(job.cgcloud__Job_Definition_Template__c);
                //     }
                // }

                // if (answeredTemplateIds.size() < templateIds.size()){

                if (surveyVisitJobs.isEmpty()){
                    surevyQuestionsPending = true;
                }
            }
        }
        
        //End

        // Query RecordTypeId dynamically using DeveloperName
        

        if(openOrders){
            return 'open_orders';
        }else if(openCustomerTasks){
            return 'open_customerTasks';
        }else if(productDistributionPending){
            return 'pending_product_distribution';
        }else if(surevyQuestionsPending){
            return 'pending_survey_questions';
        }else{
            return 'validated';
        }
    }
    @AuraEnabled
    public static String endvisitUpdate(Id visitId, Double endVisitLatitude, Double endVisitLongitude,Id accountId){

        TPB_OnlineAppController.ensureVisitJobsExist(accountId, visitId);
        
        // Query RecordTypeId dynamically using DeveloperName
        Id rtId = [SELECT Id FROM RecordType 
                WHERE SObjectType = 'Visit' 
                AND DeveloperName = 'Read_Only' 
                LIMIT 1].Id;
        List<Visit> todayvisitList = new List<Visit>();
        if(visitId != null && accountId != null){
            Visit visit = new visit();
            visit.Id=visitId;
            visit.cgcloud__Geolocation__Latitude__s = endVisitLatitude;
            visit.cgcloud__Geolocation__Longitude__s = endVisitLongitude;
            visit.RecordTypeId = rtId;
            //visit.RecordTypeId = '0126T000001h2sGQAQ';
            visit.Status = 'Completed';
            visit.ActualVisitEndTime = DateTime.now();
            visit.cgcloud__Completed_Date__c = Date.today();
            visit.End_Visit_Online__c = true;
            visit.TPB_InProgress__c=false;
            todayvisitList.add(visit);
        }
        if(todayvisitList.size()>0){
            update todayvisitList;
        }
        return visitId;
    }
    @AuraEnabled(cacheable=true)
    public static List<QuestionWrapper> getVisitQuestions(Id customerId,Id visitId) {
        List<cgcloud__Visit_Job__c> visitJobsList = [
            SELECT Id, cgcloud__Job_Definition_Template__c, cgcloud__Visit__c,cgcloud__Value__c,cgcloud__Job_Definition__c,cgcloud__Data_Type_Option__c,cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c,cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__r.cgcloud__Data_Type__c,cgcloud__Job_Definition_Template__r.cgcloud__Description__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c = :visitId AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = 'Question' AND cgcloud__Job_Definition_Template__r.cgcloud__Active__c =true and cgcloud__Job_Definition_Template__r.cgcloud__Sales_Org__c ='0001' ];
            // AND cgcloud__Job_Definition_Template__r.cgcloud__Active__c = true
        Map<Id, cgcloud__Visit_Job__c> visitJobIdMap = new Map<Id, cgcloud__Visit_Job__c>();
        if(!visitJobsList.isEmpty()){
            for(cgcloud__Visit_Job__c job : visitJobsList){
                if(job.cgcloud__Job_Definition__c != null){
                    visitJobIdMap.put(job.cgcloud__Job_Definition_Template__c, job);
                }
            }
        }
        System.debug('customerId++'+customerId);
        // Step 1: Get Job Definition List Accounts
        //Getting the Activity Customer records
        List<cgcloud__Job_Definition_List_Account__c> customerActivityList = [
            SELECT Id, Name, cgcloud__Account__c, cgcloud__Job_Definition_List__c
            FROM cgcloud__Job_Definition_List_Account__c
            WHERE cgcloud__Account__c = :customerId
            AND cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c = false
            AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true 
            AND (cgcloud__Job_Definition_List__r.cgcloud__Valid_From__c <=: System.today() AND cgcloud__Job_Definition_List__r.cgcloud__Valid_Thru__c >=: System.today())
        ];
        //Ended the Activity Customer records.

        //Getting the Activity Customer set accounts activity records
        List<cgcloud__Account_Set_Account__c> accSetAccountList =[SELECT Id,cgcloud__Account_Set__c,cgcloud__Account_Set_Account__c FROM cgcloud__Account_Set_Account__c where cgcloud__Account_Set_Account__c =: customerId ];
        Set<Id> accountSetIds = new Set<Id>();

        if(accSetAccountList.size()>0){
            for (cgcloud__Account_Set_Account__c actSet : accSetAccountList) {
                accountSetIds.add(actSet.cgcloud__Account_Set__c);
            }
        }
        Set<Id> jobDefinitionListIds = new Set<Id>();
        List<cgcloud__Job_Definition_List_Account_Set__c> customerActivitySetList = [SELECT id,name,cgcloud__Job_Definition_List__c FROM cgcloud__Job_Definition_List_Account_Set__c WHERE cgcloud__Account_Set__c =: accountSetIds AND cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c = false
        AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true 
        AND (cgcloud__Job_Definition_List__r.cgcloud__Valid_From__c <=: System.today() AND cgcloud__Job_Definition_List__r.cgcloud__Valid_Thru__c >=: System.today())];
        
        if(customerActivitySetList.size()>0){
            for(cgcloud__Job_Definition_List_Account_Set__c JbaccSet : customerActivitySetList){
                jobDefinitionListIds.add(JbaccSet.cgcloud__Job_Definition_List__c);
            }
        }
        //Ended the Customer set accounts activity records.

        for (cgcloud__Job_Definition_List_Account__c act : customerActivityList) {
            jobDefinitionListIds.add(act.cgcloud__Job_Definition_List__c);
        }
        System.debug('jobDefinitionListIds++'+jobDefinitionListIds);

        // Step 2: Get Job Definition Templates (questions)
        List<cgcloud__Job_DL_Job_Definition_Template__c> activityQuestionList = [
            SELECT Id, Name, cgcloud__Job_Definition_List__c, cgcloud__Job_Definition_Template__c,cgcloud__Job_Definition_List__r.Name
            FROM cgcloud__Job_DL_Job_Definition_Template__c
            WHERE cgcloud__Job_Definition_List__c IN :jobDefinitionListIds
            ORDER BY cgcloud__Sort__c ASC
        ];

        Set<Id> templateIds = new Set<Id>();
        for (cgcloud__Job_DL_Job_Definition_Template__c q : activityQuestionList) {
            templateIds.add(q.cgcloud__Job_Definition_Template__c);
        }
        System.debug('templateIds++'+templateIds);
        // Step 3: Get Question templates
        Map<Id, cgcloud__Job_Definition_Template__c> templateMap = new Map<Id, cgcloud__Job_Definition_Template__c>(
            [SELECT Id, Name,cgcloud__Description__c, cgcloud__Data_Type__c,cgcloud__Data_Type__r.cgcloud__Data_Type__c,cgcloud__Picture_Taking__c
            FROM cgcloud__Job_Definition_Template__c WHERE cgcloud__Job_Template__r.Name = 'Question' AND cgcloud__Active__c =true and cgcloud__Sales_Org__c ='0001']
        );

        Set<Id> dataTypeIds = new Set<Id>();
        for (cgcloud__Job_Definition_Template__c temp : templateMap.values()) {
            if (temp.cgcloud__Data_Type__c != null) {
                dataTypeIds.add(temp.cgcloud__Data_Type__c);
            }
        }

        // Step 4: Get Options for each data type
        Map<Id, List<OptionWrapper>> optionsByDataType = new Map<Id, List<OptionWrapper>>();
        for (cgcloud__Data_Type_Option__c opt : [
            SELECT Id, Name, cgcloud__Description__c, cgcloud__Code__c, cgcloud__Data_Type__c
            FROM cgcloud__Data_Type_Option__c
            WHERE cgcloud__Data_Type__c IN :dataTypeIds
        ]) {
            if (!optionsByDataType.containsKey(opt.cgcloud__Data_Type__c)) {
                optionsByDataType.put(opt.cgcloud__Data_Type__c, new List<OptionWrapper>());
            }

              
            optionsByDataType.get(opt.cgcloud__Data_Type__c).add(
                new OptionWrapper(opt.Id, opt.Name, opt.cgcloud__Code__c, opt.cgcloud__Description__c)
            );
        }
        // Step 5: Construct wrapper data
        List<QuestionWrapper> qWrapList = new List<QuestionWrapper>();
        for (cgcloud__Job_DL_Job_Definition_Template__c question : activityQuestionList) {
            cgcloud__Job_Definition_Template__c template = templateMap.get(question.cgcloud__Job_Definition_Template__c);
            if (template == null) continue;
            QuestionWrapper qWrap = new QuestionWrapper();
            qWrap.questionId = template.Id;
            qWrap.questionName = template.cgcloud__Description__c;
            qWrap.dataType = template.cgcloud__Data_Type__r.cgcloud__Data_Type__c;
            qWrap.activityName = question.cgcloud__Job_Definition_List__r.Name;
            qWrap.pictureTaking = template.cgcloud__Picture_Taking__c;

            

            if(visitJobIdMap.containsKey(template.Id)){
                qWrap.questionId = visitJobIdMap.get(template.Id).cgcloud__Job_Definition_Template__c;
                qWrap.visitJobId = visitJobIdMap.get(template.Id).Id;
                qWrap.visitJobAnswer = visitJobIdMap.get(template.Id).cgcloud__Value__c;
                qWrap.jobDefinationId = visitJobIdMap.get(template.Id).cgcloud__Job_Definition__c;
                qWrap.optionId = visitJobIdMap.get(template.Id).cgcloud__Data_Type_Option__c;
            }else{
                qWrap.jobDefinationId = question.Id;
            }
            qWrap.options = new List<OptionWrapper>();
            if (optionsByDataType.containsKey(template.cgcloud__Data_Type__c)) {
                qWrap.options.addAll(optionsByDataType.get(template.cgcloud__Data_Type__c));
            }

            qWrapList.add(qWrap);
        }
        if(!visitJobsList.isEmpty()){
            for(cgcloud__Visit_Job__c job : visitJobsList){
                if(Job.cgcloud__Job_Definition__c == null){

                    QuestionWrapper qWrap = new QuestionWrapper();
                    qWrap.questionId = job.cgcloud__Job_Definition_Template__c;
                    qWrap.visitJobId = job.Id;
                    qWrap.visitJobAnswer = job.cgcloud__Value__c;
                    qWrap.jobDefinationId = job.cgcloud__Job_Definition__c;
                    qWrap.optionId = job.cgcloud__Data_Type_Option__c;
                    qWrap.activityName ='Misc.';
                    qWrap.dataType = job.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__r.cgcloud__Data_Type__c;
                    qWrap.questionName = job.cgcloud__Job_Definition_Template__r.cgcloud__Description__c;

                    qWrap.options = new List<OptionWrapper>();
                    if (optionsByDataType.containsKey(job.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c)) {
                        qWrap.options.addAll(optionsByDataType.get(job.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c));
                    }
                    qWrapList.add(qWrap);
                }
            }
        }

        return qWrapList;
    }
    public static Set<Id> getActivitySurveys(String accountId){
        try {
            Map<Id, cgcloud__Job_Definition_List_Account__c> activityCustomersMap = new Map<Id, cgcloud__Job_Definition_List_Account__c>([SELECT Id,name,cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c, cgcloud__Job_Definition_List__r.cgcloud__Active__c,cgcloud__Job_Definition_List__c
                FROM cgcloud__Job_Definition_List_Account__c 
                WHERE cgcloud__Account__c  =: accountId AND cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c = false 
                AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true 
                AND (cgcloud__Job_Definition_List__r.cgcloud__Valid_From__c <=: System.today() AND cgcloud__Job_Definition_List__r.cgcloud__Valid_Thru__c >=: System.today())]);
            //return activityCustomersMap.keySet();
            Set<Id> activityIds = new Set<Id>();
            for(cgcloud__Job_Definition_List_Account__c activityCustomer : activityCustomersMap.values()){
                activityIds.add(activityCustomer.cgcloud__Job_Definition_List__c);
            }
            return activityIds;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string createSurveyVisitJobs(String visitId, String visitJobWrapper){
        try {
            system.debug('visitJobWrapper'+visitJobWrapper);
            List<SurveyData> visitJobWrapperList = (List<SurveyData>)JSON.deserialize(visitJobWrapper, List<SurveyData>.class);
            system.debug('visitJobWrapperList'+visitJobWrapperList);
            
            List<cgcloud__Visit_Job__c> visitJobsToCreate = new List<cgcloud__Visit_Job__c>();
            for(SurveyData job : visitJobWrapperList){
                cgcloud__Visit_Job__c jobRecord = new cgcloud__Visit_Job__c();
                
                if(job.visitJobId == null || job.visitJobId == ''){
                    
                    jobRecord.cgcloud__Visit__c = visitId;
                }else{
                    jobRecord.Id = job.visitJobId;
                }
                jobRecord.cgcloud__Data_Type_Option__c = job.optiontId;
                jobRecord.cgcloud__Job_Definition__c = job.jobDefinitionId;
                jobRecord.cgcloud__Job_Definition_Template__c = job.questionId;
                //jobRecord.cgcloud__Done__c = true;
                jobRecord.cgcloud__Value__c = job.visitJobAnswer;
                visitJobsToCreate.add(jobRecord);
            }
            upsert visitJobsToCreate;
            return 'success';
        } catch (Exception e) { system.debug('e.getMessage()'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string createSurveyVisitJobsWihtFiles(Id visitId, String visitJobWrapper, String fileName, String base64Data){
        try {
            system.debug('visitJobWrapper'+visitJobWrapper);
            List<SurveyData> visitJobWrapperList = (List<SurveyData>)JSON.deserialize(visitJobWrapper, List<SurveyData>.class);
            system.debug('visitJobWrapperList'+visitJobWrapperList);
            
            List<cgcloud__Visit_Job__c> visitJobsToCreate = new List<cgcloud__Visit_Job__c>();
            for(SurveyData job : visitJobWrapperList){
                cgcloud__Visit_Job__c jobRecord = new cgcloud__Visit_Job__c();
                
                if(job.visitJobId == null || job.visitJobId == ''){
                    
                    jobRecord.cgcloud__Visit__c = visitId;
                }else{
                    jobRecord.Id = job.visitJobId;
                }
                jobRecord.cgcloud__Data_Type_Option__c = job.optiontId;
                jobRecord.cgcloud__Job_Definition__c = job.jobDefinitionId;
                jobRecord.cgcloud__Job_Definition_Template__c = job.questionId;
                //jobRecord.cgcloud__Done__c = true;
                //jobRecord.cgcloud__Value__c = job.visitJobAnswer;
                visitJobsToCreate.add(jobRecord);
            }
            upsert visitJobsToCreate;

            Blob fileBody = EncodingUtil.base64Decode(base64Data);

           ContentVersion cv = new ContentVersion();
           cv.Title = fileName;
           cv.PathOnClient = '/' + fileName;
           cv.VersionData = fileBody;
           insert cv;

          // Query ContentDocumentId from inserted ContentVersion
          cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

          // Create the link to the Job__c record (or whatever object)
          ContentDocumentLink link = new ContentDocumentLink();
          link.ContentDocumentId = cv.ContentDocumentId;
          link.LinkedEntityId = visitJobsToCreate[0].Id; // e.g., Job__c.Id
          link.ShareType = 'V'; // Viewer permission
          link.Visibility = 'AllUsers';
          insert link;

            return 'success';
        } catch (Exception e) { system.debug('e.getMessage()'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

    }
    @AuraEnabled(cacheable=true)
    public static List<cgcloud__Account_Task_Template__c> getCustomerTaskTemplates(){
        try {
            return [SELECT ID, cgcloud__Description__c FROM cgcloud__Account_Task_Template__c WHERE cgcloud__Active__c = true ORDER BY cgcloud__Sort__c ASC];
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<cgcloud__Account_Task__c> getCustomerTasks(String selectedDate){
        try {
            if (String.isNotEmpty(selectedDate) && selectedDate.contains('T')) {
                selectedDate = selectedDate.split('T')[0];
            }

            Date filterDate = String.isNotEmpty(selectedDate)
                ? Date.valueOf(selectedDate)
                : Date.today();

            List<Visit> allVisits = [
                SELECT Id, AccountId
                FROM Visit
                WHERE Status IN ('Planned')
                AND DAY_ONLY(PlannedVisitStartTime) = :filterDate
                AND cgcloud__Responsible__c = :UserInfo.getUserId()
                AND cgcloud__Accountable__c = :UserInfo.getUserId()
            ];
            Set<Id> accountIds = new Set<Id>();
            for(Visit visit : allVisits) {
                if (visit.AccountId != null) {
                    accountIds.add(visit.AccountId);
                }
            }
            if (accountIds.isEmpty()) {
                return new List<cgcloud__Account_Task__c>();
            }
            return [
                SELECT ID, Name, cgcloud__Account__c, cgcloud__Account__r.name, cgcloud__Description_Language_1__c, cgcloud__Due_Date__c
                FROM cgcloud__Account_Task__c
                WHERE cgcloud__Phase__c = 'Initial'
                AND cgcloud__Account__c IN :accountIds
                ORDER BY cgcloud__Due_Date__c ASC, CreatedDate DESC
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
        
    }
    @AuraEnabled(cacheable=true)
    public static List<cgcloud__Account_Task__c> getCustomerTasksPendingByAccount(Date currentDate,Id accountId){
        try {
            return [SELECT ID, Name,cgcloud__Account__c, cgcloud__Account__r.name,cgcloud__Description_Language_1__c,cgcloud__Due_Date__c FROM cgcloud__Account_Task__c WHERE cgcloud__Phase__c = 'Initial' AND cgcloud__Account__c =: accountId AND cgcloud__Due_Date__c <= :currentDate];
            
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
        
    }
     @AuraEnabled
    public static String createCustomerTask(String customerId, Id customerTaskTemplateId , String dueDateStr, String descriptionStr) {
        try {
            // Query RecordTypeId dynamically using DeveloperName
            Id rtId = [SELECT Id FROM RecordType 
                    WHERE SObjectType = 'cgcloud__Account_Task__c' 
                    AND DeveloperName = 'Customer_Task_Editable' 
                    LIMIT 1].Id;
            Date dueDate = Date.valueOf(dueDateStr); // Convert to Apex Date
            List<cgcloud__Account_Task__c> customerTaskList = new List<cgcloud__Account_Task__c>();
            cgcloud__Account_Task__c customerTask = new cgcloud__Account_Task__c();
            //customerTask.RecordTypeId='0126T000001h2qhQAA';
            customerTask.RecordTypeId = rtId;
            customerTask.cgcloud__Account__c = customerId;
            customerTask.cgcloud__Account_Task_Template__c = customerTaskTemplateId;
            customerTask.cgcloud__Due_Date__c = dueDate;
            customerTask.cgcloud__Phase__c = 'Initial';
            customerTask.cgcloud__Responsible__c=UserInfo.getUserId();
            customerTask.cgcloud__Accountable__c=UserInfo.getUserId();
            customerTask.cgcloud__Description_Language_1__c = descriptionStr;
            customerTask.cgcloud__Sales_Org__c = '0001';
            customerTask.cgcloud__Priority__c = 'A';
            customerTask.cgcloud__Classification__c = 'Inquiry';
            customerTaskList.add(customerTask);
            if(customerTaskList.size() > 0){
            insert customerTaskList;
            }
            System.debug('visitList++'+customerTaskList);
            return 'Successfully created the visit for this accountId: '+customerId+' and visitTemplateId:';
       
        } catch (Exception e) {System.debug('error custom++'+e.getStackTraceString()+'...'+e.getMessage());
              throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<cgcloud__Mobile_Link__c> getDasboardLinks(){
        try {
            return [SELECT ID,cgcloud__Description__c, cgcloud__URL__c FROM cgcloud__Mobile_Link__c WHERE cgcloud__Active__c = true AND cgcloud__Display_In__c INCLUDES ('Your Day') ORDER BY cgcloud__Sort__c ASC];
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void cancelVisit(Id visitId) {
        if (visitId == null) {
            throw new AuraHandledException('Visit Id is required');
        }

        // Fetch Visit
        Visit visit = [
            SELECT Id, Status
            FROM Visit
            WHERE Id = :visitId
            LIMIT 1
        ];

        // Validate Visit status
        if (visit.Status == 'Completed' || visit.Status == 'Abandoned') {
            throw new AuraHandledException('Visit cannot be abandoned in its current status');
        }

        // 🔹 Delete related Visit Jobs
        List<cgcloud__Visit_Job__c> visitJobs = [
            SELECT Id
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c = :visitId
        ];

        if (!visitJobs.isEmpty()) {
            delete visitJobs;
        }

        // 🔹 Update Visit status
        visit.Status = 'Abandoned';
        update visit;
    }
    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getParentAccountHQAttachments(Id recordId) {

        // 1️⃣ Get Parent Account
        Account acc = [
            SELECT ParentId
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
        System.debug('acc.ParentId: ' + acc.ParentId);

        if (acc.ParentId == null) {
            return new List<ContentDocumentLink>();
        }

        // 2️⃣ Get all ContentDocumentIds linked to Parent Account
        List<ContentDocumentLink> parentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.ParentId
        ];
        System.debug('parentLinks: ' + parentLinks);

        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : parentLinks) {
            documentIds.add(cdl.ContentDocumentId);
        }
        System.debug('documentIds: ' + documentIds);
        if (documentIds.isEmpty()) {
            return new List<ContentDocumentLink>();
        }

        // 3️⃣ Filter documents using ContentVersion
        Set<Id> validDocumentIds = new Set<Id>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
            AND IsLatest = true
            AND TPB_IsHQAttachment__c = true
            AND FileExtension IN ('pdf', 'jpg', 'jpeg', 'png', 'docx', 'doc', 'ppt', 'pptx')
        ]) {
            validDocumentIds.add(cv.ContentDocumentId);
        }
        System.debug('validDocumentIds: ' + validDocumentIds);
        if (validDocumentIds.isEmpty()) {
            return new List<ContentDocumentLink>();
        }


        List<ContentDocumentLink> result = [
            SELECT ContentDocumentId,
                ContentDocument.Title,
                ContentDocument.FileType,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.ContentSize,
                ContentDocument.CreatedDate,
                ContentDocument.CreatedBy.Name
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.ParentId
            AND ContentDocumentId IN :validDocumentIds
            AND ContentDocument.FileType != 'SNOTE'
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        System.debug('result: ' + result);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<VisitFileWrapper> getVisitFiles(Id visitId) {
        if (visitId == null) {
            return new List<VisitFileWrapper>();
        }
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                ContentDocument.Title,
                ContentDocument.FileType,
                ContentDocument.ContentSize,
                ContentDocument.CreatedDate,
                ContentDocument.CreatedBy.Name
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :visitId
            AND ContentDocument.FileType != 'SNOTE'
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        List<VisitFileWrapper> files = new List<VisitFileWrapper>();
        for (ContentDocumentLink link : links) {
            VisitFileWrapper file = new VisitFileWrapper();
            file.contentDocumentId = String.valueOf(link.ContentDocumentId);
            file.title = link.ContentDocument.Title;
            file.fileType = link.ContentDocument.FileType;
            file.contentSize = link.ContentDocument.ContentSize;
            file.createdDate = link.ContentDocument.CreatedDate;
            file.createdByName = link.ContentDocument.CreatedBy != null ? link.ContentDocument.CreatedBy.Name : null;
            files.add(file);
        }
        return files;
    }

    @AuraEnabled
    public static void deleteVisitFile(Id visitId, Id contentDocumentId) {
        if (visitId == null || contentDocumentId == null) {
            throw new AuraHandledException('Visit Id and File Id are required.');
        }

        List<ContentDocumentLink> linksToDelete = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :visitId
            AND ContentDocumentId = :contentDocumentId
        ];

        if (!linksToDelete.isEmpty()) {
            delete linksToDelete;
        }

        Integer remainingLinks = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ];
        if (remainingLinks == 0) {
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
        }
    }

    @AuraEnabled
    public static void uploadVisitFile(Id visitId, String fileName, String base64Data, String contentType) {
        if (visitId == null || String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('Visit Id and file data are required.');
        }

        Blob fileBody;
        try {
            fileBody = EncodingUtil.base64Decode(base64Data);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid file payload.');
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = fileBody;
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        ContentDocumentLink visitLink = new ContentDocumentLink();
        visitLink.ContentDocumentId = contentDocumentId;
        visitLink.LinkedEntityId = visitId;
        visitLink.ShareType = 'V';
        visitLink.Visibility = 'AllUsers';
        insert visitLink;
    }

    // Wrapper to hold Question with Options
    public class QuestionWrapper {
        @AuraEnabled public String questionId;
        @AuraEnabled public String questionName;
        @AuraEnabled public String dataType;
        @AuraEnabled public List<OptionWrapper> options;
        @AuraEnabled public String visitJobId;
        @AuraEnabled public String visitJobAnswer;
        @AuraEnabled public String jobDefinationId;
        @AuraEnabled public String optionId;
        @AuraEnabled public String activityName;
        @auraEnabled public Boolean pictureTaking;
    }

    // Wrapper to hold Option info
    public class OptionWrapper {
        @AuraEnabled public String optionId;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public String description;
        public OptionWrapper(String optionId, String name, String code, String description) {
            this.optionId = optionId;
            this.name = name;
            this.code = code;
            this.description = description;
        }
    }

    public class SurveyData{
        @AuraEnabled public String visitJobId;
        @AuraEnabled public String optiontId;
        @AuraEnabled public String jobDefinitionId;
        @AuraEnabled public String questionId;
        @AuraEnabled public String visitJobAnswer;
    }

    public class VisitFileWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Integer contentSize;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;
    }

    
}