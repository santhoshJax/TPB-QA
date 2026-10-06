public class LeadRoundRobinHandler {

    @InvocableMethod(label='Round Robin Lead Assignment'
                     description='Assigns leads in round-robin order using a locked sequence record')
    public static void assignLeads(List<List<Id>> leadIdBatches) {

        List<Id> leadIds = new List<Id>();

        for (List<Id> batch : leadIdBatches) {
            leadIds.addAll(batch);
        }

        if (leadIds.isEmpty()) {
            return;
        }

        processAssignment(leadIds);
    }

    private static void processAssignment(List<Id> leadIds) {

        // Lock the sequence record
        TPB_Sequence__c seq = [
            SELECT Id, Last_Assigned_User__c
            FROM TPB_Sequence__c
            WHERE Name = 'LEAD_ASSIGNMENT'
            LIMIT 1
            FOR UPDATE
        ];

        // Get active Inside Sales members
        List<GroupMember> members = [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE Group.Name = 'Inside Sales'
            AND UserOrGroupId IN (
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
            )
        ];

        if (members.isEmpty()) {
            System.debug('LeadRoundRobinHandler: No active users found.');
            return;
        }

        // Build user Id set
        Set<Id> memberUserIds = new Set<Id>();

        for (GroupMember gm : members) {
            memberUserIds.add((Id)gm.UserOrGroupId);
        }

        // Get users in deterministic order
        List<User> sortedUsers = [
            SELECT Id
            FROM User
            WHERE Id IN :memberUserIds
            AND IsActive = TRUE
            ORDER BY Name ASC
        ];

        List<Id> userIds = new List<Id>();

        for (User u : sortedUsers) {
            userIds.add(u.Id);
        }

        Integer startIndex = 0;
        String lastUserId = seq.Last_Assigned_User__c;

        if (String.isNotBlank(lastUserId)) {
            for (Integer i = 0; i < userIds.size(); i++) {
                if (userIds[i] == lastUserId) {
                    startIndex = Math.mod(i + 1, userIds.size());
                    break;
                }
            }
        }

        // Query existing leads to capture previous owner
        Map<Id, Lead> existingLeads = new Map<Id, Lead>([
            SELECT Id, OwnerId, Name
            FROM Lead
            WHERE Id IN :leadIds
        ]);

        List<Lead> leadsToUpdate = new List<Lead>();
        List<Lead_Round_Robin_Log__c> logs = new List<Lead_Round_Robin_Log__c>();

        Integer userIndex = startIndex;
        String lastAssignedId = lastUserId;

        for (Lead existingLead : existingLeads.values()) {

            Id assignedUser = userIds[userIndex];

            leadsToUpdate.add(new Lead(
                Id = existingLead.Id,
                OwnerId = assignedUser
            ));

            logs.add(new Lead_Round_Robin_Log__c(
                Lead__c = existingLead.Id,
                Previous_Owner__c = existingLead.OwnerId,
                Current_Owner__c = assignedUser,
                Name = existingLead.name + 'Log',
                Assigned_on__c = System.now()
            ));

            lastAssignedId = assignedUser;
            userIndex = Math.mod(userIndex + 1, userIds.size());
        }

        try {

            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }

            if (!logs.isEmpty()) {
                insert logs;
            }

            seq.Last_Assigned_User__c = lastAssignedId;
            update seq;

        } catch (Exception e) {

            System.debug('Lead Round Robin Error: ' + e.getMessage());

            throw e;
        }
    }
}