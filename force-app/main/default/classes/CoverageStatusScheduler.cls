public class CoverageStatusScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CoverageStatusBatch(), 200);
    }

}