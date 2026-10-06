public class DeleteSkills implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
       String queryString = 'SELECT Id FROM SkillRequirement';
              
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<SkillRequirement> scope) {
       // delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        
    }

}