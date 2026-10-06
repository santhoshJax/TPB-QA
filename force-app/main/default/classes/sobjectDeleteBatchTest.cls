@isTest
    private class sobjectDeleteBatchTest {
        
        @isTest
        static void testSObjectDeleteBatch() {
            // Step 1: Create test data
                    // create visit job
          cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
            Name = 'Test Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert accTemplate;
        
        
                
                Account testAccount = new Account(Name = 'Test Account', Status__c = 'Closed Permanently', Closure_Reason__c = 'Closed Permanently - Out of Business', cgcloud__Account_Template__c = accTemplate.Id);
            List<Account> testAccounts = new List<Account>();
            for (Integer i = 0; i < 5; i++) {
                testAccounts.add(new Account(Name = 'Test Account'+i, Status__c = 'Closed Permanently', Closure_Reason__c = 'Closed Permanently - Out of Business', cgcloud__Account_Template__c = accTemplate.Id));
            }
            insert testAccounts;
    
            // Step 2: Formulate query string
            String query = 'SELECT Id FROM Account WHERE Name LIKE \'Test Account%\'';
    
            // Step 3: Instantiate and run the batch
            Test.startTest();
            sobjectDeleteBatch batch = new sobjectDeleteBatch(query);
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            // Step 4: Assert that accounts are deleted
            List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%'];
            System.assertEquals(0, deletedAccounts.size(), 'All test accounts should be deleted.');
        }
    }