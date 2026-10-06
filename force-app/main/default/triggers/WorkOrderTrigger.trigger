trigger WorkOrderTrigger on WorkOrder (before insert, after insert, after update) {

    // if(Trigger.isBefore) {
    //     if(Trigger.isInsert) {
    //         WorkOrderHandler.setPricebook(Trigger.new);
    //     }
    // }
    // if(Trigger.isAfter){
    //     if(Trigger.isInsert) {
    //         WorkOrderHandler.defaultLines(Trigger.new);
    //     }
    //     if(Trigger.isUpdate) {
    //         WorkOrderHandler.completionActions(Trigger.new, Trigger.oldMap);
    //     }
    // }

}