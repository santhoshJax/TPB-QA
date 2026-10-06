public with sharing class AppointmentTaskSection {
    
    @AuraEnabled
    public static List<Task> getTasks(Id accountId) {
        return [SELECT Id, Subject, Description, ActivityDate, Status, IsClosed, CompletedDateTime FROM Task
                WHERE WhatId = :accountId AND OwnerId = :UserInfo.getUserId() AND In_Store__c = true
                ORDER BY ActivityDate ASC NULLS LAST];
    }

    @AuraEnabled
    public static Boolean completeTask(Task taskRecord) {
        try {
            taskRecord.Status = 'Completed';
            update taskRecord;
        }
        catch(DmlException e) {
            return false;
        }

        return true;
    }

}