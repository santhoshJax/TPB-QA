global class sobjectDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {
        public String query;   
        global  sobjectDeleteBatch(String squery){
                 this.query=squery;
        }
        global Database.QueryLocator start(Database.BatchableContext BC) {
                return Database.getQueryLocator(query)  ;
       }
        global void execute(Database.BatchableContext BC, List<SObject> scope) {
                if (!scope.isEmpty()) {
                    delete scope;
                    Database.emptyRecycleBin(scope);  
                }
            }
        
            global void finish(Database.BatchableContext BC) {
                System.debug('Finished deleting records marked for archive.');
            }
        }