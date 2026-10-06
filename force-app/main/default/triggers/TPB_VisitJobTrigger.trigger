/**
 * @description cgcloud__Visit_Job__c description
 * @param  update update description
 * Author: Evonne
 * Date: 2023-08-14
 */
trigger TPB_VisitJobTrigger on cgcloud__Visit_Job__c (after update) {
    new SDF_TGF_MetadataTriggerHandler().run();
}