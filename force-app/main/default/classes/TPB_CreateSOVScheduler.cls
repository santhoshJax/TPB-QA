/**
 * @author Guanshu Wang
 * @date 05/24/2023
 * @modified date 06/21/2024 by Aza Tattibayev
 * @description TPB_CreateSOVBatch:  Executed at 1:30 a.m every day
 * system.schedule('CreateSOVBatch', '0 30 1 * * ?', new TPB_CreateSOVScheduler());
 */
public with sharing class TPB_CreateSOVScheduler implements Schedulable {
    //execute batch job
    /**
     * @description execute TPB_CreateSOVBatch
     * @param  sc sc
     */
    public void execute(SchedulableContext sc) {
        //set how many records to batch run at once
        Database.executeBatch(new TPB_CreateSOVBatch(),10);
    }
}