public with sharing class AccountHierarchyController {

    @AuraEnabled
    public static String getAccounts(Id accountId, String recordType, Id parentId) {
        List<AccountHierarchyWrapper> wrapperItems = new List<AccountHierarchyWrapper>();
        List<Account> accounts = new List<Account>();
        String hierarchyAccounts = 'SELECT Id, Name, Owner.Alias, BillingCity, BillingState, Cash_Sales__c, RecordType.Name FROM Account WHERE ';

        if(recordType != 'Wholesaler') {
            if(parentId != null) {
                hierarchyAccounts += '(Id = :accountId OR Id = :parentId OR ParentId = :parentId)';
            }
            else {
                hierarchyAccounts += '(Id = :accountId OR ParentId = :accountId)';
            }
        }
        else {
            hierarchyAccounts += 'Id = :accountId';
        }

        hierarchyAccounts += ' ORDER BY RecordType.Name ASC, Name ASC';

        for(Account acc : Database.query(hierarchyAccounts)) {
            accounts.add(acc);
        }

        List<Related_Account__c> relatedAccounts = [SELECT Wholesaler__c, Wholesaler__r.Name, Wholesaler__r.RecordType.Name, Wholesaler__r.Owner.Alias,
                                                    Wholesaler__r.BillingCity, Wholesaler__r.BillingState, Wholesaler__r.Cash_Sales__c,
                                                    Retailer__c, Retailer__r.Name, Retailer__r.RecordType.Name, Retailer__r.Owner.Alias,
                                                    Retailer__r.BillingCity, Retailer__r.BillingState, Retailer__r.Cash_Sales__c, Type__c
                                                    FROM Related_Account__c WHERE (Retailer__c = :accountId OR Wholesaler__c = :accountId) ORDER BY Type__c ASC];

        for(Related_Account__c related : relatedAccounts) {
            Account acc = new Account();

            if(accountId != related.Retailer__c) {
                acc.Id = related.Retailer__c;
                acc.Name = related.Retailer__r.Name;
                acc.RecordType = new RecordType();
                acc.RecordType.Name = related.Retailer__r.RecordType.Name;
                acc.Owner = new User();
                acc.Owner.Alias = related.Retailer__r.Owner.Alias;
                acc.BillingCity = related.Retailer__r.BillingCity;
                acc.BillingState = related.Retailer__r.BillingState;
                acc.Cash_Sales__c = related.Retailer__r.Cash_Sales__c;
            }
            else {
                acc.Id = related.Wholesaler__c;
                acc.Name = related.Wholesaler__r.Name;
                acc.RecordType = new RecordType();
                acc.RecordType.Name = related.Wholesaler__r.RecordType.Name;
                acc.Owner = new User();
                acc.Owner.Alias = related.Wholesaler__r.Owner.Alias;
                acc.BillingCity = related.Wholesaler__r.BillingCity;
                acc.BillingState = related.Wholesaler__r.BillingState;
                acc.Cash_Sales__c = related.Wholesaler__r.Cash_Sales__c;
                acc.Type = related.Type__c;
            }

            accounts.add(acc);
        }

        AccountHierarchyWrapper wrapper = new AccountHierarchyWrapper(accounts, accountId, recordType);
        wrapperItems.add(wrapper);

        String wrapperJSON = JSON.serialize(wrapperItems, false);
        wrapperJSON = wrapperJSON.replace('"children_RESERVED":', '"_children":');

        return wrapperJSON;
    }

    @AuraEnabled
    public static String updateAccounts(List<Account> accounts) {
        try {
            update accounts;
        }
        catch(DmlException e) {
            return e.getMessage();
        }

        return 'Successfully updated Account(s)';
    }

}