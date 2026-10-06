/**
 * @description cgcloud__User_Document__c description
 * @param  insert insert description
 * @param  update update description
 *
 */ 
trigger TPB_DailyReportTrigger on cgcloud__User_Document__c (before insert, before update) {
    //initial Trigger handler
    new SDF_TGF_MetadataTriggerHandler().run();
}