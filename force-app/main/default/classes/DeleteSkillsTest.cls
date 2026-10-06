@isTest
public class DeleteSkillsTest {
    
    public static testMethod void testSkills() {
     Account retailer = TestDataFactory.createRetailAccount();
      Schema.Location locationObj = TestDataFactory.createLocation();
    // WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);

     //  SkillRequirement sk = new SkillRequirement();
     // sk.RelatedRecordId = wOrder.Id;
       // sk.SkillId = [SELECT Id FROM Skill LIMIT 1].Id;
      // insert sk;
        
        Id jobId = Database.executeBatch(new DeleteSkills(), 200);
     }

}