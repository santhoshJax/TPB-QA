/**
 * @author: RZ
 * date:9/24/2023
 * @description  Daily Report Trigger
 * 
 */
public without sharing class TPB_DailyReportTriggerHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description beforeInsert description
     * 
     */
    protected override void beforeInsert() {
        checkIfTOFOverlapsTime((List<cgcloud__User_Document__c>) Trigger.new);
    }
    /**
     * @description beforeUpdate description
     * 
     */
    protected override void beforeUpdate() {
        //get DailyReport new data
        List<cgcloud__User_Document__c> lstDailyReportNew = (List<cgcloud__User_Document__c>) Trigger.new;
        //get DailyReport old data
        Map<Id, cgcloud__User_Document__c> lstDailyReportOld = (Map<Id,cgcloud__User_Document__c>)Trigger.oldMap;
        List<cgcloud__User_Document__c> lstNeedCheckTOFTime = new List<cgcloud__User_Document__c>();
        for (cgcloud__User_Document__c dailyreport : lstDailyReportNew) {
            if ((dailyreport.cgcloud__Phase__c == 'Released' && lstDailyReportOld.get(dailyreport.Id).cgcloud__Phase__c != 'Released') || (dailyreport.cgcloud__Total_Working_Duration_Min__c != 0 && lstDailyReportOld.get(dailyreport.Id).cgcloud__Total_Working_Duration_Min__c == 0)) {
                lstNeedCheckTOFTime.add(dailyreport);
            }
        }
        if (lstNeedCheckTOFTime.size() > 0) {
            checkIfTOFOverlapsTime(lstNeedCheckTOFTime);
        }
    }

    /**
     * @description checkIfTOFOverlapsTime description
     * @param  lstDailyReport lstDailyReport description
     * 
     */ 
    public void checkIfTOFOverlapsTime(List<cgcloud__User_Document__c> lstDailyReport){
        // Daily report ids
        List<String> lstTOFIds = new List<String>();
        // Daily report Responsible ids
        List<String> lstResponsibleIds = new List<String>();
        // Daily report Date
        List<Date> lstDates = new List<Date>();
        Map<Id, List<cgcloud__User_Document__c>> mapTofAndExistTofs = new Map<Id, List<cgcloud__User_Document__c>>();
        // loop lstDailyReport
        for (cgcloud__User_Document__c dailyReport : lstDailyReport) {
            lstTOFIds.add(dailyReport.Id);
            lstResponsibleIds.add(dailyReport.cgcloud__Responsible__c);
            lstDates.add(dailyReport.cgcloud__Date__c);
            mapTofAndExistTofs.put(dailyReport.Id, new List<cgcloud__User_Document__c>());
        }
        List<cgcloud__User_Document__c> lstExistTOFs = [SELECT Id, cgcloud__Responsible__c, cgcloud__Date__c, cgcloud__Phase__c, TPB_StartTime__c, TPB_EndTime__c FROM cgcloud__User_Document__c WHERE Id NOT IN :lstTOFIds AND cgcloud__Responsible__c IN :lstResponsibleIds AND cgcloud__Date__c IN :lstDates AND cgcloud__Phase__c != 'Correction' AND cgcloud__Phase__c != 'Initial'];
        if (lstExistTOFs.size() > 0) {
            for (cgcloud__User_Document__c dailyReport : lstDailyReport) {
                for (cgcloud__User_Document__c existTOF : lstExistTOFs) {
                    if (isNewOverlapsTime(dailyReport, existTOF)) {
                        mapTofAndExistTofs.get(dailyReport.Id).add(existTOF);
                    }else if(isExistOverlapsTime(dailyReport, existTOF)){
                        mapTofAndExistTofs.get(dailyReport.Id).add(existTOF);
                    }
                }
                if(mapTofAndExistTofs.get(dailyReport.Id).size() > 0){
                    dailyReport.cgcloud__Work_Time_From__c.addError('You should not submit a TOF request that overlaps with the time of another TOF request you submitted.');
                }
            }
        }

    }

    /**
     * @description isNewOverlapsTime description
     * @param  dailyReport dailyReport description
     * @param  existTOF    existTOF description
     * @return             return description
     */ 
    private Boolean isNewOverlapsTime(cgcloud__User_Document__c dailyReport, cgcloud__User_Document__c existTOF){
        // check overlapsTime
        if (dailyReport.cgcloud__Responsible__c == existTOF.cgcloud__Responsible__c && 
            dailyReport.cgcloud__Date__c == existTOF.cgcloud__Date__c && 
            ((dailyReport.TPB_StartTime__c >= existTOF.TPB_StartTime__c && dailyReport.TPB_StartTime__c <= existTOF.TPB_EndTime__c) || 
            (dailyReport.TPB_EndTime__c >= existTOF.TPB_StartTime__c && dailyReport.TPB_EndTime__c <= existTOF.TPB_EndTime__c)))
        {
            return true;
        }
        return false;
    }

    /**
     * @description isExistOverlapsTime description
     * @param  dailyReport dailyReport description
     * @param  existTOF    existTOF description
     * @return             return description
     */ 
    private Boolean isExistOverlapsTime(cgcloud__User_Document__c dailyReport, cgcloud__User_Document__c existTOF){
        // check overlapsTime
        if (dailyReport.cgcloud__Responsible__c == existTOF.cgcloud__Responsible__c && 
            dailyReport.cgcloud__Date__c == existTOF.cgcloud__Date__c && 
            ((existTOF.TPB_StartTime__c >= dailyReport.TPB_StartTime__c && existTOF.TPB_StartTime__c <= dailyReport.TPB_EndTime__c) ||
            (existTOF.TPB_EndTime__c >= dailyReport.TPB_StartTime__c && existTOF.TPB_EndTime__c <= dailyReport.TPB_EndTime__c)))
        {
            return true;
        }
        return false;
    }
}