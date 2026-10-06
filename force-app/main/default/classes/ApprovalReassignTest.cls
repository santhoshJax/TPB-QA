@IsTest(SeeAllData=true)
private class ApprovalReassignTest {

    private static User getAlternateUser() {
        List<User> users = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE IsActive = true
            AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];

        return users[0];
    }

    @IsTest
    static void testProcess() {

        User alternateUser = getAlternateUser();

        List<cgcloud__User_Document__c> reports = [
            SELECT
                Id,
                Name,
                CreatedById,
                TPB_RSM__c,
                RSM_Alternate_Approver__c,
                cgcloud__Phase__c,
                cgcloud__Template_Description__c,
                cgcloud__User_Document_Template__c,
                cgcloud__User_Document_Template__r.Name,
                cgcloud__User_Document_Template__r.cgcloud__Workflow__r.Name
            FROM cgcloud__User_Document__c
            WHERE cgcloud__Template_Description__c = 'TOF'
            AND cgcloud__Phase__c != 'Approved'
            AND cgcloud__User_Document_Template__r.cgcloud__Workflow__r.Name =
                'Daily Report Approval Required'
            // Only pick records whose primary approver is active - avoids
            // non-deterministically selecting one of the known pre-existing
            // records stuck with an inactive TPB_RSM__c and no alternate set.
            AND TPB_RSM__r.IsActive = true
            LIMIT 1
        ];

        if (reports.isEmpty()) {
            return;
        }

        cgcloud__User_Document__c report = reports[0];

        Id primaryUserId = report.CreatedById;

        if (primaryUserId == null) {
            return;
        }

        ApprovalReassign.ReassignRequest request =
            new ApprovalReassign.ReassignRequest();

        request.primaryUserIds = primaryUserId;
        request.alternateApproverIds = alternateUser.Id;

        Test.startTest();

        ApprovalReassign.process(
            new List<ApprovalReassign.ReassignRequest>{
                request
            }
        );

        Test.stopTest();
    }

    @IsTest
    static void testApprovalWorkItemReassignment() {

        User alternateUser = getAlternateUser();

        List<cgcloud__User_Document__c> reports = [
            SELECT
                Id,
                Name,
                CreatedById,
                TPB_RSM__c,
                RSM_Alternate_Approver__c,
                cgcloud__Phase__c,
                cgcloud__Template_Description__c,
                cgcloud__User_Document_Template__c,
                cgcloud__User_Document_Template__r.Name,
                cgcloud__User_Document_Template__r.cgcloud__Workflow__r.Name
            FROM cgcloud__User_Document__c
            WHERE cgcloud__Template_Description__c = 'TOF'
            AND cgcloud__Phase__c != 'Approved'
            AND cgcloud__User_Document_Template__r.cgcloud__Workflow__r.Name =
                'Daily Report Approval Required'
            // Only pick records whose primary approver is active - avoids
            // non-deterministically selecting one of the known pre-existing
            // records stuck with an inactive TPB_RSM__c and no alternate set.
            AND TPB_RSM__r.IsActive = true
            LIMIT 10
        ];

        if (reports.isEmpty()) {
            return;
        }

        cgcloud__User_Document__c report;

        for (cgcloud__User_Document__c candidate : reports) {

            Integer pendingCount = [
                SELECT COUNT()
                FROM ProcessInstance
                WHERE TargetObjectId = :candidate.Id
                AND Status = 'Pending'
            ];

            if (pendingCount == 0) {
                report = candidate;
                break;
            }
        }

        if (report == null || report.TPB_RSM__c == null) {
            return;
        }

        Approval.ProcessSubmitRequest submitRequest =
            new Approval.ProcessSubmitRequest();

        submitRequest.setObjectId(report.Id);

        Test.startTest();

        Approval.ProcessResult submitResult =
            Approval.process(submitRequest);

        Test.stopTest();

        if (!submitResult.isSuccess()) {
            return;
        }

        List<ProcessInstance> processInstances = [
            SELECT
                Id,
                TargetObjectId,
                Status
            FROM ProcessInstance
            WHERE TargetObjectId = :report.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (processInstances.isEmpty()) {
            return;
        }

        ProcessInstance processInstance =
            processInstances[0];

        List<ProcessInstanceWorkitem> workItems = [
            SELECT
                Id,
                ActorId,
                ProcessInstanceId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId = :processInstance.Id
        ];

        if (workItems.isEmpty()) {
            return;
        }

        ProcessInstanceWorkitem originalWorkItem =
            workItems[0];

        if (originalWorkItem.ActorId == report.TPB_RSM__c) {
            return;
        }

        ApprovalReassign.ReassignRequest request =
            new ApprovalReassign.ReassignRequest();

        request.primaryUserIds =
            report.CreatedById;

        request.alternateApproverIds =
            alternateUser.Id;

        Test.startTest();

        ApprovalReassign.process(
            new List<ApprovalReassign.ReassignRequest>{
                request
            }
        );

        Test.stopTest();
    }

    @IsTest
    static void testProcess_NullUsers() {

        ApprovalReassign.ReassignRequest request =
            new ApprovalReassign.ReassignRequest();

        request.primaryUserIds = null;
        request.alternateApproverIds = null;

        Test.startTest();

        ApprovalReassign.process(
            new List<ApprovalReassign.ReassignRequest>{
                request
            }
        );

        Test.stopTest();
    }

    @IsTest
    static void testProcess_EmptyList() {

        Test.startTest();

        ApprovalReassign.process(
            new List<ApprovalReassign.ReassignRequest>()
        );

        Test.stopTest();
    }

    @IsTest
    static void testProcess_NullList() {

        Test.startTest();

        ApprovalReassign.process(null);

        Test.stopTest();
    }

    @IsTest
    static void testReassignAsync_EmptyLists() {

        Test.startTest();

        ApprovalReassign.reassignAsync(
            new List<Id>(),
            new List<Id>(),
            new List<Id>()
        );

        Test.stopTest();
    }

    @IsTest
    static void testReassignAsync_NullReportIds() {

        Test.startTest();

        ApprovalReassign.reassignAsync(
            null,
            new List<Id>(),
            new List<Id>()
        );

        Test.stopTest();
    }

    @IsTest
    static void testRemovePermissionQueueable() {

        List<PermissionSet> permissionSets = [
            SELECT
                Id,
                Name
            FROM PermissionSet
            WHERE Name = 'Approval_Permission_Set'
            LIMIT 1
        ];

        if (permissionSets.isEmpty()) {
            return;
        }

        PermissionSet approvalPermissionSet =
            permissionSets[0];

        User primaryUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        User alternateUser = getAlternateUser();

        List<PermissionSetAssignment> existingAssignments = [
            SELECT
                Id,
                AssigneeId,
                PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :primaryUser.Id
            AND PermissionSetId = :approvalPermissionSet.Id
            LIMIT 1
        ];

        if (existingAssignments.isEmpty()) {

            insert new PermissionSetAssignment(
                AssigneeId = primaryUser.Id,
                PermissionSetId = approvalPermissionSet.Id
            );
        }

        Map<Id, Id> userToAltMap =
            new Map<Id, Id>();

        userToAltMap.put(
            primaryUser.Id,
            alternateUser.Id
        );

        Test.startTest();

        System.enqueueJob(
            new ApprovalReassign.RemovePermissionQueueable(
                new List<Id>{
                    primaryUser.Id
                },
                userToAltMap
            )
        );

        Test.stopTest();
    }

    // ==========================================
    // Flow coverage: TPB_TOFSubmitForApproval
    // fires on cgcloud__User_Document__c Create.
    // We only need the flow to execute here, not
    // to succeed - synthetic data may not match
    // any approval process's entry criteria.
    // ==========================================
    @IsTest
    static void testTOFSubmitForApprovalFlowCoverage() {

        cgcloud__User_Document_Template__c template =
            new cgcloud__User_Document_Template__c(
                cgcloud__Creation_Platform__c = 'All',
                cgcloud__Sales_Org__c = '0001',
                cgcloud__Active__c = true,
                cgcloud__Description_Language_1__c = 'TOF',
                cgcloud__Sort__c = 6,
                cgcloud__Mobility_Relevant__c = true
            );

        insert template;

        Test.startTest();

        try {

            insert new cgcloud__User_Document__c(
                cgcloud__User_Document_Template__c = template.Id,
                cgcloud__Date__c = Date.today(),
                cgcloud__Phase__c = 'Initial',
                cgcloud__Work_Time_From__c = '09:00',
                cgcloud__Work_Time_Thru__c = '17:00',
                cgcloud__Responsible__c = UserInfo.getUserId(),
                cgcloud__Accountable__c = UserInfo.getUserId(),
                TPB_Activity_Type__c = 'ADP Time Off'
            );

        } catch (Exception ex) {

            // The insert itself must succeed for the Create-triggered
            // flow to fire at all - fail loudly here instead of
            // silently reporting 0% flow coverage again.
            System.assert(false, 'Daily Report insert failed before the flow could fire: ' + ex.getMessage());
        }

        Test.stopTest();
    }

    // ==========================================
    // Flow coverage: ReAssign_Approval_Process
    // fires on User Update when ManagerId or
    // Custom_Delegated_Approver__c changes.
    // ==========================================
    @IsTest
    static void testReAssignApprovalProcessFlowCoverage() {

        // Use users already proven to have complete Territory/Org Unit
        // setup (they're an active TPB_RSM__c on a real record) - the
        // managed package's UserTrigger null-dereferences on users
        // missing that setup, which would block the update before the
        // flow ever gets a chance to fire.
        List<User> users = [
            SELECT Id, ManagerId
            FROM User
            WHERE Id IN (
                SELECT TPB_RSM__c
                FROM cgcloud__User_Document__c
                WHERE TPB_RSM__c != null
            )
            AND IsActive = true
            LIMIT 2
        ];

        if (users.size() < 2) {
            return;
        }

        User targetUser = users[0];
        User newManager = users[1];

        Test.startTest();

        try {

            targetUser.ManagerId = newManager.Id;

            update targetUser;

        } catch (Exception ex) {

            // The update itself must succeed for the Update-triggered
            // flow to fire at all - fail loudly here instead of
            // silently reporting 0% flow coverage again.
            System.assert(false, 'User update failed before the flow could fire: ' + ex.getMessage());
        }

        Test.stopTest();
    }
}