public with sharing class AppointmentUtilities {

    @AuraEnabled
    public static List<Map<String,String>> getPicklistVals(String objectName, String fieldName, List<String> valuesToOmit) {
        Schema.SObjectType currentObj = ((SObject)(Type.forName('Schema.' + objectName).newInstance())).getSObjectType();
        Schema.SObjectField currentField = currentObj.getDescribe().fields.getMap().get(fieldName);
        List<Schema.PicklistEntry> entries = currentField.getDescribe().getPicklistValues();
        List<Map<String,String>> itemMap = new List<Map<String,String>>();
        itemMap.add(new Map<String,String>{'label' => '--None--','value' => ''});

        for(Integer i=0; i < entries.size(); i++) {
            Schema.PicklistEntry entry = entries[i];
            if(entry.isActive() && !valuesToOmit.contains(entry.getValue())) {
                itemMap.add(new Map<String,String>{'label' => entry.getLabel(),'value' => entry.getValue()});
            }
        }

        return itemMap;
    }

    @AuraEnabled
    public static Boolean deleteRecord(Id recordId) {
        sObject record = recordId.getSobjectType().newSObject(recordId);

        try {
            delete record;
        }
        catch(DmlException e) {
            return false;
        }

        return true;
    }

    @AuraEnabled
    public static String upsertRecords(String records, String sObjectType) {
        List<SObject> sObjectList;

        switch on sObjectType {
            when 'wholesalers' {
                sObjectList = (List<Related_Account__c>)JSON.deserialize(records, List<Related_Account__c>.class);
            }
            when 'contacts' {
                sObjectList = (List<Contact>)JSON.deserialize(records, List<Contact>.class);
            }
        }

        try {
            upsert sObjectList;
        }
        catch(DmlException e) {
            return e.getMessage();
        }

        return JSON.serialize(sObjectList);
    }

}