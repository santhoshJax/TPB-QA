public with sharing class AppointmentAccountSectionController {

    // @AuraEnabled
    // public static Map<String,String> getWorkOrder(Id accountId) {
    //     //Returns total completed work orders AND the most recent objective
    //     String callObjective = '';
    //     Integer completedCount = 0;

    //     for(WorkOrder wo : [SELECT Id, Next_Call_Objective__c, Status FROM WorkOrder WHERE AccountId = :accountId ORDER BY LastModifiedDate DESC]) {
    //         if(completedCount == 0) {
    //             callObjective = wo.Next_Call_Objective__c;
    //         }

    //         if(wo.status == 'Completed') {
    //             completedCount++;
    //         }
    //     }

    //     return new Map<String,String>{
    //         'objective' => callObjective,
    //         'count' => String.valueOf(completedCount)
    //     };
    // }

    // @AuraEnabled
    // public static List<Contact> getContactList(Id accountId) {
    //     return [SELECT Id, FirstName, LastName, Phone, OtherPhone, Contact_Note__c, Email, Days_of_the_Week__c, Title2__c, Decision_Maker__c
    //             FROM Contact WHERE AccountId = :accountId ORDER BY CreatedDate ASC];
    // }

    // @AuraEnabled
    // public static List<Related_Account__c> getWholesalerList(Id accountId) {
    //     return [SELECT Id, Wholesaler__r.Name, Wholesaler__r.Clearing_House_Participant__c, Type__c, Supplier_Id__c
    //             FROM Related_Account__c WHERE Retailer__c = :accountId ORDER BY CreatedDate ASC];
    // }

    // @AuraEnabled
    // public static List<Account> searchWholesalers(String input) {
    //     String name = '%' + input + '%';
    //     return [SELECT Id, Name, Clearing_House_Participant__c FROM Account
    //             WHERE Name LIKE :name AND RecordType.Name = 'Wholesaler' ORDER BY Name ASC LIMIT 10];
    // }

}