@isTest
public with sharing class AppointmentTaskSectionTest {

    public static testMethod void testTask() {
        Account retailer = TestDataFactory.createRetailAccount();
        Task newTask = TestDataFactory.createTask(retailer.Id);

        test.startTest();
        List<Task> taskList = AppointmentTaskSection.getTasks(retailer.Id);
        AppointmentTaskSection.completeTask(newTask);
        test.stopTest();

        Task completedTask = [SELECT Status FROM Task WHERE Id = :newTask.Id LIMIT 1];

        system.assertEquals(1, taskList.size());
        system.assertEquals('Completed', completedTask.Status);
    }

}