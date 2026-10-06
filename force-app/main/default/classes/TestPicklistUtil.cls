@isTest
public class TestPicklistUtil {
	
    public static List<String> getPicklistValues(String objName, String fieldName) {
       	SObjectType currentObj = ((SObject)(Type.forName('Schema.'+ objName).newInstance())).getSObjectType();
        SObjectField currentField = currentObj.getDescribe().fields.getMap().get(fieldName);
        List<String> entries = new List<String>();
        
        for(Schema.PicklistEntry entry : currentField.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                entries.add(entry.getValue());
            }
        }

		return entries;
    }
    
}