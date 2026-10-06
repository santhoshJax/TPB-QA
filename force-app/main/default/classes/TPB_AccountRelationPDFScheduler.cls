/**
 * @author Mi Li
 * @date 4/25/2023
 * @description TPB_AccountRelationPDFBatch:   Executed every night at 11pm
 * system.schedule('TPB_AccountRelationPDFBatch', '0 0 23 * * ?', new TPB_AccountRelationPDFScheduler());
 */
public with sharing class TPB_AccountRelationPDFScheduler implements Schedulable{
    /**
     * @description execute description
     * @param  sc sc description
     */
    public void execute(SchedulableContext sc){
        Database.executeBatch(new TPB_AccountRelationPDFBatch(), 200);
    }
}