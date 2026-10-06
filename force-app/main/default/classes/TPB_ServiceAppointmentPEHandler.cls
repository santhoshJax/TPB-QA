/**************************************************************************************
Apex Class Name:  TPB_ServiceAppointmentPEHandler
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event handler class on ServiceAppointment to detect field changes on Account include fields as below
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description serviceAppointment trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_ServiceAppointmentPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        // updateHiddenFieldAfterUpdate((List<ServiceAppointment>)Trigger.new, (Map<Id,ServiceAppointment>)Trigger.oldMap);
    }
    
    /**
     * @description updateHiddenFieldAfterUpdate 
     * Create the method for integration to update hidden fields,
     * so that integrations can merge formula fields in ADW 
     * @param  serviceAppointmentNewList serviceAppointmentNewList description
     * @param  serviceAppointmentOldMap  serviceAppointmentOldMap description
     */ 
/*    private void updateHiddenFieldAfterUpdate(List<ServiceAppointment> serviceAppointmentNewList, 
    Map<Id,ServiceAppointment> serviceAppointmentOldMap) {
        Set<Id> sAppointIdAccount = new Set<Id>();

        for(ServiceAppointment item : serviceAppointmentNewList){
            ServiceAppointment oldSAppoint = serviceAppointmentOldMap.get(item.Id);
            if(oldSAppoint.ActualEndTime != item.ActualEndTime){
            	//detect fields changes on ServiceAppointment: ActualEndTime
                sAppointIdAccount.add(item.Id);
            }
        }

        if(sAppointIdAccount !=null && sAppointIdAccount.size() > 0){
        	//ServiceAppointment change related Account list
            List<Account> accList = [SELECT Id, Days_Since_Last_Completed_Visit__c, Last_Completed_Visit_Date_Time__c FROM Account WHERE Last_Completed_Visit__c IN : sAppointIdAccount];

            if(accList!=null && accList.size() > 0){
                for(Account item : accList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update accList;

            }
        }

    }*/
}