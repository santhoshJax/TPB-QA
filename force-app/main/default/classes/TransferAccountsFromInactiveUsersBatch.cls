global without sharing class TransferAccountsFromInactiveUsersBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Integer accountsTransferred = 0;
    global Integer accountsFailed = 0;
    global List<String> failedAccountIds = new List<String>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Account
            WHERE Owner.IsActive = FALSE
            AND RecordType.DeveloperName IN ('Headquarter', 'Wholesaler')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {

        Set<Id> ownerIds = new Set<Id>();

        for (Account acc : scope) {
            if (acc.OwnerId != null) {
                ownerIds.add(acc.OwnerId);
            }
        }

        Map<Id, User> ownerMap = new Map<Id, User>([
            SELECT
                Id,
                ManagerId,
                Custom_Delegated_Approver__c 
            FROM User
            WHERE Id IN :ownerIds
        ]);

        Set<Id> delegatedApproverIds = new Set<Id>();

        for (User u : ownerMap.values()) {
            if (u.Custom_Delegated_Approver__c  != null) {
                delegatedApproverIds.add(u.Custom_Delegated_Approver__c );
            }
        }

        Map<Id, User> delegatedApproverMap = new Map<Id, User>();

        if (!delegatedApproverIds.isEmpty()) {
            delegatedApproverMap = new Map<Id, User>([
                SELECT
                    Id,
                    IsActive
                FROM User
                WHERE Id IN :delegatedApproverIds
            ]);
        }

        //  need the owner's direct manager Id to start
        Set<Id> directManagerIds = new Set<Id>();

        for (User u : ownerMap.values()) {
            if (u.ManagerId != null) {
                directManagerIds.add(u.ManagerId);
            }
        }

        Map<Id, User> level1ManagerMap = new Map<Id, User>();

        if (!directManagerIds.isEmpty()) {
            level1ManagerMap = new Map<Id, User>([
                SELECT
                    Id,
                    IsActive,
                    ManagerId
                FROM User
                WHERE Id IN :directManagerIds
            ]);
        }

        // Second level: the direct manager's manager
        Set<Id> skipManagerIds = new Set<Id>();

        for (User mgr : level1ManagerMap.values()) {
            if (mgr.ManagerId != null) {
                skipManagerIds.add(mgr.ManagerId);
            }
        }

        Map<Id, User> level2ManagerMap = new Map<Id, User>();

        if (!skipManagerIds.isEmpty()) {
            level2ManagerMap = new Map<Id, User>([
                SELECT
                    Id,
                    IsActive
                FROM User
                WHERE Id IN :skipManagerIds
            ]);
        }

        User connieHill;

        List<User> connieHillUsers = [
            SELECT
                Id,
                IsActive
            FROM User
            WHERE Name = 'Connie Hill'
            LIMIT 1
        ];

        if (!connieHillUsers.isEmpty()) {
            connieHill = connieHillUsers[0];
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : scope) {

            User inactiveOwner = ownerMap.get(acc.OwnerId);

            if (inactiveOwner == null) {
                continue;
            }

            Id newOwnerId = null;

            if (inactiveOwner.Custom_Delegated_Approver__c != null) {

                User delegatedApprover =
                    delegatedApproverMap.get(
                        inactiveOwner.Custom_Delegated_Approver__c
                    );

                if (
                    delegatedApprover != null &&
                    delegatedApprover.IsActive
                ) {
                    newOwnerId = delegatedApprover.Id;
                }
            }

            // Direct manager, then direct manager's manager, then Connie
            if (newOwnerId == null) {

                User directManager = level1ManagerMap.get(inactiveOwner.ManagerId);

                if (directManager != null && directManager.IsActive) {
                    newOwnerId = directManager.Id;
                } else if (directManager != null && directManager.ManagerId != null) {

                    User skipManager = level2ManagerMap.get(directManager.ManagerId);

                    if (skipManager != null && skipManager.IsActive) {
                        newOwnerId = skipManager.Id;
                    }
                }
            }

            if (
                newOwnerId == null &&
                connieHill != null &&
                connieHill.IsActive
            ) {
                newOwnerId = connieHill.Id;
            }

            if (newOwnerId == null) {
                continue;
            }

            acc.OwnerId = newOwnerId;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {

            Database.SaveResult[] results =
                Database.update(accountsToUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {

                if (results[i].isSuccess()) {
                    accountsTransferred++;
                } else {
                    accountsFailed++;
                    failedAccountIds.add(accountsToUpdate[i].Id);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

        AsyncApexJob job = [
            SELECT
                Id,
                Status,
                NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems,
                CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        if (job.CreatedBy.Email != null && accountsFailed > 0) {

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { job.CreatedBy.Email });
            mail.setSubject('TransferAccountsFromInactiveUsersBatch completed with failures');
            mail.setPlainTextBody(
                'Transferred: ' + accountsTransferred +
                '\nFailed: ' + accountsFailed +
                '\nFailed Account Ids: ' + String.join(failedAccountIds, ', ')
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}