public with sharing class DynamicRelatedListController {
    
    /**
     * Retrieves the configuration for a given config name
     */
    @AuraEnabled(cacheable=true)
    public static ConfigWrapper getConfiguration(String configName) {
        try {
            // Query the configuration
            List<Dynamic_Related_List_Config__mdt> configs = [
                SELECT Id, 
                       MasterLabel,
                       DeveloperName,
                       Object_API_Name__c,
                       Parent_Field_API_Name__c,
                       Component_Title__c,
                       Icon_Name__c,
                       Sort_Field__c,
                       Sort_Direction__c,
                       Active__c
                FROM Dynamic_Related_List_Config__mdt
                WHERE DeveloperName = :configName
                  AND Active__c = true
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new AuraHandledException('Configuration not found: ' + configName);
            }
            
            Dynamic_Related_List_Config__mdt config = configs[0];
            
            // Query the fields for this configuration
            List<Dynamic_Related_List_Field__mdt> fields = [
                SELECT Id,
                       Field_API_Name__c,
                       Field_Label__c,
                       Field_Type__c,
                       Editable__c,
                       Sort_Order__c,
                       Initial_Width__c,
                       Wrap_Text__c
                FROM Dynamic_Related_List_Field__mdt
                WHERE Config__r.DeveloperName = :configName
                ORDER BY Sort_Order__c ASC
            ];
            
            if (fields.isEmpty()) {
                throw new AuraHandledException('No fields configured for: ' + configName);
            }
            
            // Build the configuration wrapper
            ConfigWrapper wrapper = new ConfigWrapper();
            wrapper.objectApiName = config.Object_API_Name__c;
            wrapper.parentFieldApiName = config.Parent_Field_API_Name__c;
            wrapper.title = String.isNotBlank(config.Component_Title__c) 
                ? config.Component_Title__c 
                : config.MasterLabel;
            wrapper.iconName = String.isNotBlank(config.Icon_Name__c) 
                ? config.Icon_Name__c 
                : 'standard:record';
            wrapper.sortField = String.isNotBlank(config.Sort_Field__c) 
                ? config.Sort_Field__c 
                : 'CreatedDate';
            wrapper.sortDirection = String.isNotBlank(config.Sort_Direction__c) 
                ? config.Sort_Direction__c 
                : 'ASC';
            
            // Build field list and column definitions
            wrapper.fields = new List<String>();
            wrapper.columns = new List<ColumnDefinition>();
            
            // Always include Id and parent field
            wrapper.fields.add('Id');
            if (!wrapper.fields.contains(wrapper.parentFieldApiName)) {
                wrapper.fields.add(wrapper.parentFieldApiName);
            }
            
            for (Dynamic_Related_List_Field__mdt field : fields) {
                // Add to field list for SOQL
                if (!wrapper.fields.contains(field.Field_API_Name__c)) {
                    wrapper.fields.add(field.Field_API_Name__c);
                }
                
                // Build column definition
                ColumnDefinition col = new ColumnDefinition();
                col.fieldName = field.Field_API_Name__c;
                col.label = String.isNotBlank(field.Field_Label__c) 
                    ? field.Field_Label__c 
                    : getFieldLabel(config.Object_API_Name__c, field.Field_API_Name__c);
                col.type = field.Field_Type__c;
                col.editable = field.Editable__c;
                col.sortable = true;
                
                if (field.Initial_Width__c != null) {
                    col.initialWidth = Integer.valueOf(field.Initial_Width__c);
                }
                
                if (field.Wrap_Text__c) {
                    col.wrapText = true;
                }
                
                // Add type attributes based on field type
                if (field.Field_Type__c == 'date') {
                    col.typeAttributes = new Map<String, Object>{
                        'year' => 'numeric',
                        'month' => '2-digit',
                        'day' => '2-digit'
                    };
                } else if (field.Field_Type__c == 'datetime') {
                    col.typeAttributes = new Map<String, Object>{
                        'year' => 'numeric',
                        'month' => '2-digit',
                        'day' => '2-digit',
                        'hour' => '2-digit',
                        'minute' => '2-digit'
                    };
                } else if (field.Field_Type__c == 'currency') {
                    col.typeAttributes = new Map<String, Object>{
                        'currencyCode' => 'USD',
                        'minimumFractionDigits' => 2
                    };
                } else if (field.Field_Type__c == 'percent') {
                    col.typeAttributes = new Map<String, Object>{
                        'minimumFractionDigits' => 2,
                        'maximumFractionDigits' => 2
                    };
                }
                
                // Add cell attributes for alignment
                if (field.Field_Type__c == 'number' || 
                    field.Field_Type__c == 'currency' || 
                    field.Field_Type__c == 'percent') {
                    col.cellAttributes = new Map<String, Object>{
                        'alignment' => 'left'
                    };
                }
                
                wrapper.columns.add(col);
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading configuration: ' + e.getMessage());
        }
    }
    
    /**
     * Retrieves records based on configuration
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String configName, Id parentRecordId) {
        try {
            if (parentRecordId == null) {
                throw new AuraHandledException('Parent Record Id is required');
            }
            
            // Get configuration
            ConfigWrapper config = getConfiguration(configName);
            
            // Build dynamic SOQL query
            String soql = 'SELECT ' + String.join(config.fields, ', ') +
                         ' FROM ' + config.objectApiName +
                         ' WHERE ' + config.parentFieldApiName + ' = :parentRecordId' +
                         ' WITH SECURITY_ENFORCED' +
                         ' ORDER BY ' + config.sortField + ' ' + config.sortDirection;
            
            System.debug('Dynamic SOQL: ' + soql);
            
            return Database.query(soql);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving records: ' + e.getMessage());
        }
    }
    
    /**
     * Updates multiple records
     */
    @AuraEnabled
    public static Boolean updateRecords(List<SObject> recordsToUpdate) {
        try {
            if (recordsToUpdate == null || recordsToUpdate.isEmpty()) {
                throw new AuraHandledException('No records to update');
            }
            
            // Strip inaccessible fields
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                recordsToUpdate
            );
            
            // Perform the update
            Database.SaveResult[] results = Database.update(decision.getRecords(), false);
            
            // Check for errors
            List<String> errors = new List<String>();
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error error : results[i].getErrors()) {
                        errors.add('Record ' + recordsToUpdate[i].Id + ': ' + error.getMessage());
                    }
                }
            }
            
            if (!errors.isEmpty()) {
                throw new AuraHandledException('Update failed: ' + String.join(errors, '; '));
            }
            
            return true;
            
        } catch (DmlException e) {
            throw new AuraHandledException('DML Error: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to get field label from describe
     */
    @TestVisible
    private static String getFieldLabel(String objectApiName, String fieldApiName) {
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType == null) {
                return fieldApiName;
            }
            
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            Schema.SObjectField field = fieldMap.get(fieldApiName);
            if (field == null) {
                return fieldApiName;
            }
            
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            return fieldDescribe.getLabel();
            
        } catch (Exception e) {
            return fieldApiName;
        }
    }
    
    /**
     * Wrapper class for configuration
     */
    public class ConfigWrapper {
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String parentFieldApiName { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String iconName { get; set; }
        @AuraEnabled public String sortField { get; set; }
        @AuraEnabled public String sortDirection { get; set; }
        @AuraEnabled public List<String> fields { get; set; }
        @AuraEnabled public List<ColumnDefinition> columns { get; set; }
    }
    
    /**
     * Wrapper class for column definition
     */
    public class ColumnDefinition {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Boolean editable { get; set; }
        @AuraEnabled public Boolean sortable { get; set; }
        @AuraEnabled public Integer initialWidth { get; set; }
        @AuraEnabled public Boolean wrapText { get; set; }
        @AuraEnabled public Map<String, Object> typeAttributes { get; set; }
        @AuraEnabled public Map<String, Object> cellAttributes { get; set; }
    }
}