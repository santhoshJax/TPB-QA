public with sharing class QuarterlyVisitReportController {

    public List<String> getReportValues() {
        Id reportId = [SELECT Id FROM Report WHERE DeveloperName = 'Quarterly_Visit_Goal'].Id;
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
        Reports.ReportFact factMap = results.getFactMap().get('0!T');

        Reports.SummaryValue totalVisitGoal = factMap.getAggregates()[0];
        Reports.SummaryValue callsMade = factMap.getAggregates()[1];
        Reports.SummaryValue cpdGoal = factMap.getAggregates()[2];
        Reports.SummaryValue percentToGoal = factMap.getAggregates()[3];

        return new List<String>{
            totalVisitGoal.getLabel(), callsMade.getLabel(), cpdGoal.getLabel(), percentToGoal.getLabel()
        };
    }

}