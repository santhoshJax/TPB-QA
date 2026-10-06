/**
 * @author Guanshu Wang
 * @date 05/24/2023
 * @description TPB_VisitJobEOVCalcuBatch:  Executed at 1:00 a.m every day
 * system.schedule('CreateEOVBatch', '0 0 1 * * ?', new TPB_CreateEOVScheduler());
 */
public with sharing class TPB_CreateEOVScheduler implements Schedulable {
    /**
     * @description execute TPB_VisitJobEOVCalcuBatch
     * @param  sc sc
     */
    //execute batch job
    public void execute(SchedulableContext sc) {
        //set how many records to batch run in once
        Database.executeBatch(new TPB_VisitJobEOVCalcuBatch());
    }
}