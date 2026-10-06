public with sharing class CallsPerDayAsync implements Queueable {

    private Date quarterStart;
    private Date quarterEnd;
    private Decimal quarterDaysRemaining;
    private Decimal visitGoal;
    private Set<Id> ownerIds;

    public CallsPerDayAsync(Set<Id> ownerIds) {
        for(Period period : [SELECT StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER LIMIT 1]) {
            this.quarterStart = period.StartDate;
            this.quarterEnd = period.EndDate;
        }

        Id hoursId = [SELECT Id FROM BusinessHours WHERE IsActive = true AND IsDefault = true LIMIT 1].Id;
        //Holidays will throw off this number so need to set a fixed value for testing
        this.quarterDaysRemaining = Test.isRunningTest() ? 90 : ((BusinessHours.diff(hoursId, date.today(), this.quarterEnd) / 3600000) / 24);

        this.visitGoal = Goals__c.getOrgDefaults().Quarterly_Visits__c;
        this.ownerIds = ownerIds;
    }

    public void execute(QueueableContext context) {
       /* List<User> userUpdates = new List<User>();
        
        for(AggregateResult ar : [SELECT COUNT(Id) completed, OwnerId owner FROM WorkOrder WHERE EndDate >= :this.quarterStart AND EndDate <= :this.quarterEnd AND Status = 'Completed' AND OwnerId IN :ownerIds AND Completed_Sales_Appointment__r.Call_Type__c = 'In-Store Visit' GROUP BY OwnerId]) {
            User user = new User(Id = (Id)ar.get('owner'));
            Decimal visitCount = Decimal.valueOf((Integer)ar.get('completed'));

            if(visitCount < this.visitGoal) {
                Decimal quarterVisitsRemaining = this.visitGoal - visitCount;
                user.Calls_per_Day_Goal__c = (quarterVisitsRemaining / this.quarterDaysRemaining).setScale(1);
            }
            else {
                user.Calls_per_Day_Goal__c = 0;
            }

            userUpdates.add(user);
        } 

        update userUpdates;*/
    }

}