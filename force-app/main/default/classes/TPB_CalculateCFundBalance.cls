/**
* @author Feng Lian
* @date 7/4/2023
* @description calculate current c-fund balance for the users
*/
public with sharing class TPB_CalculateCFundBalance implements Database.Batchable<sObject>, Schedulable {
    private String strQuery;
    private Set<Id> userIds;
    /**
    * @description Constructor class
    */
    public TPB_CalculateCFundBalance() {
        //Find all User data that needs to be generated
        this.strQuery = 'SELECT Id, TPB_Balance__c FROM User WHERE Profile.Name = \'CG Cloud Mobile - TSM\' AND IsActive = true ';
    }
    
    /**
    * @description Constructor class
    * @param  strQuery statement
    */
    public TPB_CalculateCFundBalance(Set<Id> userIds) {
        //Creating a Parametric Construction Method
        this.userIds = userIds;
        this.strQuery = 'SELECT Id, TPB_Balance__c FROM User WHERE Profile.Name = \'CG Cloud Mobile - TSM\' AND IsActive = true AND Id IN : userIds';
    }
    
    /**
    * @description start description
    * @param   bc     description
    * @return  return description
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strQuery);
    }
    
    /**
    * @description execute description
    * @param  bc         description
    * @param  lstUser    description
    */
    public void execute(Database.BatchableContext bc, List<User> items) {
        Map<Id, Decimal> userMap = new Map<Id, Decimal>();
        List<User> updUsers = new List<User>();
        
        List<Order> wsOrders = [SELECT TotalAmount, CreatedById FROM Order WHERE CreatedById IN : items AND Status = 'Activated' AND TPB_State__c != null ];
        
        for (Order item : wsOrders) {
            Decimal balance = userMap.get(item.CreatedById);
            
            if (balance == null) {
                balance = 0;
            }
            
            balance += item.TotalAmount;
            userMap.put(item.CreatedById, balance);
        }
        
        List<cgcloud__Order__c> reOrders = [SELECT cgcloud__Value__c, cgcloud__Accountable__c FROM cgcloud__Order__c WHERE cgcloud__Accountable__c IN : items AND cgcloud__Phase__c = 'Released'];
        
        for (cgcloud__Order__c item : reOrders) {
            Decimal balance = userMap.get(item.cgcloud__Accountable__c);
            
            if (balance == null) {
                balance = 0;
            }
            
            balance -= item.cgcloud__Value__c;
            userMap.put(item.cgcloud__Accountable__c, balance);
        }
        
        for (User usr : items) {
            Decimal balance = userMap.get(usr.Id);
            if (balance != null && usr.TPB_Balance__c != balance) {
                usr.TPB_Balance__c = balance;
                updUsers.add(usr);
            }
        }
        
        if (updUsers.size() > 0) {
            update updUsers;
        }
    }
    
   /**
   * @description finish description
   * @param  bc description
   */
    public void finish(Database.BatchableContext bc) {
    }
    
    /**
    * @description execute description
    * @param  sc sc description
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TPB_CalculateCFundBalance(), 1);
    }
}