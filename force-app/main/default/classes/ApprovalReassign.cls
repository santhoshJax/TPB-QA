public without sharing class ApprovalReassign {

    // ===============================
    // Invocable Wrapper
    // ===============================
    public class ReassignRequest {

        @InvocableVariable(required=true)
        public Id primaryUserIds;

        @InvocableVariable(required=true)
        public Id alternateApproverIds;
    }

    // ===============================
    // Entry Method
    // ===============================
    @InvocableMethod(
        label='Reassign Daily Report Approvals'
        description='Reassign approval work items to alternate approver'
    )
    public static void process(List<ReassignRequest> requests) {

        System.debug('=== START process() ===');

        if (requests == null || requests.isEmpty()) {

            System.debug('=== No Requests Found ===');
            return;
        }

        // ==========================================
        // primary user -> alternate approver
        // ==========================================
        Map<Id, Id> userToAlternateMap =
            new Map<Id, Id>();

        Set<Id> primaryUserIds =
            new Set<Id>();

        for (ReassignRequest req : requests) {

            System.debug('=== Processing Request ===');
            System.debug('Primary User: ' + req.primaryUserIds);
            System.debug('Alternate User: ' + req.alternateApproverIds);

            if (req.primaryUserIds != null &&
                req.alternateApproverIds != null) {

                primaryUserIds.add(req.primaryUserIds);

                userToAlternateMap.put(
                    req.primaryUserIds,
                    req.alternateApproverIds
                );
            }
        }

        System.debug('=== primaryUserIds === ' + primaryUserIds);
        System.debug('=== userToAlternateMap === ' + userToAlternateMap);

        if (primaryUserIds.isEmpty()) {

            System.debug('=== No Primary Users ===');
            return;
        }

        // ==========================================
        // Get User Documents
        // CreatedById = primaryUserIds
        // ==========================================
        List<cgcloud__User_Document__c> reports = [

            SELECT
                Id,
                TPB_RSM__c,
                CreatedById
            FROM cgcloud__User_Document__c
            WHERE CreatedById IN :primaryUserIds
        ];

        System.debug('=== Reports Found === ' + reports);

        if (reports.isEmpty()) {

            System.debug('=== No Reports Found ===');
            return;
        }

        List<Id> reportIds =
            new List<Id>();

        List<Id> primaryIds =
            new List<Id>();

        List<Id> alternateIds =
            new List<Id>();

        for (cgcloud__User_Document__c r : reports) {

            System.debug('=== Processing Report === ' + r.Id);

            Id altUser =
                userToAlternateMap.get(r.CreatedById);

            System.debug('=== Alternate User === ' + altUser);

            if (altUser != null) {

                reportIds.add(r.Id);

                primaryIds.add(r.CreatedById);

                alternateIds.add(altUser);
            }
        }

        System.debug('=== reportIds === ' + reportIds);
        System.debug('=== primaryIds === ' + primaryIds);
        System.debug('=== alternateIds === ' + alternateIds);

        if (!reportIds.isEmpty()) {

            reassignAsync(
                reportIds,
                primaryIds,
                alternateIds
            );
        }

        System.debug('=== END process() ===');
    }

    // ===============================
    // FUTURE METHOD
    // ===============================
    @future
    public static void reassignAsync(
        List<Id> reportIds,
        List<Id> primaryIds,
        List<Id> alternateIds
    ) {

        System.debug('=== START reassignAsync ===');

        System.debug('=== reportIds === ' + reportIds);
        System.debug('=== primaryIds === ' + primaryIds);
        System.debug('=== alternateIds === ' + alternateIds);

        if (reportIds == null ||
            reportIds.isEmpty()) {

            System.debug('=== No Report Ids ===');
            return;
        }

        // ==========================================
        // Build primary -> alternate map
        // ==========================================
        Map<Id, Id> userToAltMap =
            new Map<Id, Id>();

        for (Integer i = 0; i < primaryIds.size(); i++) {

            userToAltMap.put(
                primaryIds[i],
                alternateIds[i]
            );
        }

        System.debug('=== userToAltMap === ' + userToAltMap);

        // ==========================================
        // Get Reports
        // ==========================================
        Map<Id, cgcloud__User_Document__c> reportMap =

            new Map<Id, cgcloud__User_Document__c>(

                [
                    SELECT
                        Id,
                        TPB_RSM__c,
                        CreatedById,
                        RSM_Alternate_Approver__c
                    FROM cgcloud__User_Document__c
                    WHERE Id IN :reportIds
                ]
            );

        System.debug('=== reportMap === ' + reportMap);

        // ==========================================
        // Update Alternate Approver
        // ==========================================
        List<cgcloud__User_Document__c> reportsToUpdate =
            new List<cgcloud__User_Document__c>();

        for (cgcloud__User_Document__c report :
            reportMap.values()) {

            Id altUser =
                userToAltMap.get(report.CreatedById);

            System.debug('=== Updating Report === ' + report.Id);
            System.debug('=== altUser === ' + altUser);

            if (altUser != null) {

                report.RSM_Alternate_Approver__c =
                    altUser;

                reportsToUpdate.add(report);
            }
        }

        System.debug(
            '=== reportsToUpdate === '
            + reportsToUpdate
        );

        if (!reportsToUpdate.isEmpty()) {

            update reportsToUpdate;

            System.debug(
                '=== Reports Updated Successfully ==='
            );
        }

        // ==========================================
        // Get Pending Approval Processes
        // ==========================================
        List<ProcessInstance> processInstances = [

            SELECT
                Id,
                TargetObjectId
            FROM ProcessInstance
            WHERE TargetObjectId IN :reportIds
            AND Status = 'Pending'
        ];

        System.debug(
            '=== processInstances === '
            + processInstances
        );

        if (processInstances.isEmpty()) {

            System.debug(
                '=== No Pending Approval Processes ==='
            );

            return;
        }

        // ==========================================
        // ProcessInstanceId -> ReportId
        // ==========================================
        Map<Id, Id> processToReportMap =
            new Map<Id, Id>();

        Set<Id> processInstanceIds =
            new Set<Id>();

        for (ProcessInstance pi : processInstances) {

            processInstanceIds.add(pi.Id);

            processToReportMap.put(
                pi.Id,
                pi.TargetObjectId
            );
        }

        System.debug(
            '=== processToReportMap === '
            + processToReportMap
        );

        // ==========================================
        // Get Work Items
        // ==========================================
        List<ProcessInstanceWorkitem> workItems = [

            SELECT
                Id,
                ActorId,
                ProcessInstanceId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId IN :processInstanceIds
        ];

        System.debug(
            '=== workItems === '
            + workItems
        );

        List<ProcessInstanceWorkitem> workItemsToUpdate =
            new List<ProcessInstanceWorkitem>();

        for (ProcessInstanceWorkitem wi : workItems) {

            System.debug(
                '=== Processing WorkItem === '
                + wi.Id
            );

            Id reportId =
                processToReportMap.get(
                    wi.ProcessInstanceId
                );

            cgcloud__User_Document__c report =
                reportMap.get(reportId);

            if (report == null) {

                System.debug('=== Report Null ===');
                continue;
            }

            Id alternateUser =
                userToAltMap.get(report.CreatedById);

            System.debug(
                '=== Report CreatedById === '
                + report.CreatedById
            );

            System.debug(
                '=== Report TPB_RSM__c === '
                + report.TPB_RSM__c
            );

            System.debug(
                '=== Current ActorId === '
                + wi.ActorId
            );

            System.debug(
                '=== Alternate User === '
                + alternateUser
            );

            // ==========================================
            // Reassign when ActorId
            // != TPB_RSM__c
            // ==========================================
            if (alternateUser != null &&
                wi.ActorId != report.TPB_RSM__c) {

                System.debug(
                    '=== Reassigning WorkItem === '
                    + wi.Id
                );

                wi.ActorId = alternateUser;

                workItemsToUpdate.add(wi);
            }
        }

        System.debug(
            '=== workItemsToUpdate === '
            + workItemsToUpdate
        );

        if (!workItemsToUpdate.isEmpty()) {

            update workItemsToUpdate;

            System.debug(
                '=== WorkItems Updated Successfully ==='
            );
        }

        // ==========================================
        // Queueable for Permission Set Removal
        // ==========================================
        System.enqueueJob(

            new RemovePermissionQueueable(

                new List<Id>(
                    new Set<Id>(primaryIds)
                ),

                userToAltMap
            )
        );

        System.debug('=== Queueable Enqueued ===');

        System.debug('=== END reassignAsync ===');
    }

    // ===============================
    // QUEUEABLE
    // ===============================
    public class RemovePermissionQueueable
        implements Queueable {

        private List<Id> userIds;

        private Map<Id, Id> userToAltMap;

        public RemovePermissionQueueable(
            List<Id> userIds,
            Map<Id, Id> userToAltMap
        ) {

            this.userIds = userIds;
            this.userToAltMap = userToAltMap;
        }

        public void execute(
            QueueableContext context
        ) {

            System.debug(
                '=== START Queueable execute ==='
            );

            System.debug(
                '=== userIds === ' + userIds
            );

            // ==========================================
            // Get Permission Set
            // ==========================================
            PermissionSet ps = [

                SELECT Id
                FROM PermissionSet
                WHERE Name = 'Approval_Permission_Set'
                LIMIT 1
            ];

            System.debug(
                '=== Permission Set === ' + ps.Id
            );

            // ==========================================
            // Get PSA Records
            // ==========================================
            List<PermissionSetAssignment> psaToDelete = [

                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :userIds
                AND PermissionSetId = :ps.Id
            ];

            System.debug(
                '=== PSA To Delete === '
                + psaToDelete
            );

            if (!psaToDelete.isEmpty()) {

                delete psaToDelete;

                System.debug(
                    '=== Permission Sets Removed ==='
                );
            }

            System.debug(
                '=== END Queueable execute ==='
            );
        }
    }
}