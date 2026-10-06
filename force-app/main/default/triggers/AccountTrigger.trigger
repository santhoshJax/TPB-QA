trigger AccountTrigger on Account (after insert, after update, after delete) {

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            AccountTriggerHandler.childCount(Trigger.new, null);
            AccountTriggerHandler.updateFlagDownToStoresThatAreLinkedToHQ(Trigger.new, new Map<Id, Account>());
        }
        if(Trigger.isUpdate) {
            AccountTriggerHandler.childCount(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.updateFlagDownToStoresThatAreLinkedToHQ(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete) {
            AccountTriggerHandler.childCount(Trigger.old, null);
        }
    }

}