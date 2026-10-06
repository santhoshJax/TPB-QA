global class VisitJobDeleteBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        VisitJobDeleteBatch batch = new VisitJobDeleteBatch();
        Database.executeBatch(batch,200); // Adjust batch size if needed
    }
}