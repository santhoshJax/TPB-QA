public with sharing class AppointmentEndSectionController {
   /* 
    @AuraEnabled
    public static Integer distributionCounter(Id workOrderId) {
    return [SELECT count() FROM WorkOrderLineItem WHERE Close_Stock__c != true
                AND WorkOrderId = :workOrderId
                AND Origin__c = 'Previous WO'
                AND PricebookEntry.Product2.NTC_Item_Classification__c = 'Straight Stock']; 
    }

   // @AuraEnabled
   // public static String createAppointment(Id oldAppointmentId, String schedStart, String schedEnd) {
       /* ServiceAppointment appointment = new ServiceAppointment();
        List<AssignedResource> resources = new List<AssignedResource>();

        for(ServiceAppointment sa : [SELECT Id, ParentRecordId, Street, City, State, PostalCode, ServiceTerritoryId, EarliestStartTime, DueDate, Subject, Description, AccountId,
                                     (SELECT ServiceResourceId FROM ServiceResources) FROM ServiceAppointment WHERE Id = :oldAppointmentId]) {
            appointment.ParentRecordId = sa.ParentRecordId;
            appointment.Street = sa.Street;
            appointment.City = sa.City;
            appointment.State = sa.State;
            appointment.PostalCode = sa.PostalCode;
            appointment.ServiceTerritoryId = sa.ServiceTerritoryId;
            appointment.EarliestStartTime = sa.EarliestStartTime;
            appointment.DueDate = sa.DueDate;
            appointment.Subject = sa.Subject;
            appointment.Description = sa.Description;
            appointment.SchedStartTime = DateTime.valueOf(schedStart.replace('T', ' '));
            appointment.SchedEndTime = DateTime.valueOf(schedEnd.replace('T', ' '));
        }

        try {
            insert appointment;
        }
        catch(DmlException e) {
            return e.getMessage();
        }

       
    }  return 'SUCCESS';*/

}