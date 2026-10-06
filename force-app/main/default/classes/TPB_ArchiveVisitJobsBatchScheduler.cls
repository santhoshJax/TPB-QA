global class TPB_ArchiveVisitJobsBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Trigger the batch job
        TPB_ArchiveVisitJobsBatch batch = new TPB_ArchiveVisitJobsBatch();
        Database.executeBatch(batch, 100);
    }
}