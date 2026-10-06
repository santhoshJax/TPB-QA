@isTest
public inherited sharing class AppointmentUtilitiesTest {

    public static testMethod void testUtil() {
      Account retailer = TestDataFactory.createRetailAccount();
         Account wholesaler = TestDataFactory.createWholesaleAccount();
       Contact con = TestDataFactory.createContact(retailer.Id);
        Related_Account__c related = TestDataFactory.createRelatedAccount(retailer.Id, wholesaler.Id);

        List<String> omit = new List<String>();
        List<Contact> contacts = new List<Contact>{con};
       List<Related_Account__c> relateds = new List<Related_Account__c>{related};

        test.startTest();
        //List<Map<String,String>> itemTypeMap = AppointmentUtilities.getPicklistVals('WorkOrderLineItem', 'Item_Type__c', omit);
       Boolean deleteRecord = AppointmentUtilities.deleteRecord(retailer.Id);
         String upsertContact = AppointmentUtilities.upsertRecords(JSON.serialize(contacts), 'contacts');
        String upsertRelated = AppointmentUtilities.upsertRecords(JSON.serialize(relateds), 'wholesalers');
        test.stopTest();
     }

}