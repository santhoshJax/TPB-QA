/**
 * @description TPB_VisitTriggerHandler
 *
 * @author Rachel Zhao
 * @date 2022-11-28
 *
 */
public without sharing class TPB_VisitTriggerHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description beforeDelete description
     *
     */
    protected override void beforeDelete() {
        validateVisitStatus((List<Visit>) Trigger.old);
    }

    /**
     * @description beforeInsert description
     *
     */
    protected override void beforeInsert() {
        validatePlannedTime((List<Visit>) Trigger.new);
    }

    /**
     * @description beforeUpdate description
     *
     */
    protected override void beforeUpdate() {
        validatePlannedTime((List<Visit>) Trigger.new);
    }

    /**
     * @description validateVisitStatus description
     * @param  lstVisits lstVisits description
     *
     */
    private void validateVisitStatus(List<Visit> lstVisits) {
        // delete msg
        String msgDelValidate = 'This visit is {0} , cannot be deleted.';
        // delete Status validate
        for (Visit visit : lstVisits) {
            if (
                'Completed'.equals(visit.Status) ||
                'InProgress'.equals(visit.Status)
            ) {
                msgDelValidate = msgDelValidate.replace('{0}', visit.status);
                //add error
                visit.addError(msgDelValidate);
            }
        }
    }

    /**
     * @description validatePlannedTime description
     * @param  lstVisits lstVisits description
     *
     */
    private void validatePlannedTime(List<Visit> lstVisits) {
        //lstAccids
        List<String> lstAccids = new List<String>();
        //mapAcc2OHId
        Map<String, String> mapAcc2OHId = new Map<String, String>();
        //get Accounts Id
        for (Visit visit : lstVisits) {
            if (visit.AccountId != null) {
                //add lstAccids
                lstAccids.add(visit.AccountId);
            }
        }
        //lstOperatingIds
        List<String> lstOperatingIds = new List<String>();
        // get OperatingHoursId
        for (Account acc : [
            SELECT Id, OperatingHoursId
            FROM Account
            WHERE Id IN :lstAccids
        ]) {
            //check OperatingHoursId
            if (acc.OperatingHoursId != null) {
                lstOperatingIds.add(acc.OperatingHoursId);
                mapAcc2OHId.put(acc.Id, acc.OperatingHoursId);
            }
        }
        //check lstOperatingIds size
        if (lstOperatingIds.size() <= 0) {
            return;
        }
        getTimeSlots(lstOperatingIds, lstVisits, mapAcc2OHId);
    }

    /**
     * @description getTimeSlots description
     * @param  lstOperatingIds lstOperatingIds description
     * @param  lstVisits       lstVisits description
     * @param  mapAcc2OHId     mapAcc2OHId description
     */
    private void getTimeSlots(List<String> lstOperatingIds, List<Visit> lstVisits, Map<String, String> mapAcc2OHId){
        //get timeslots
        Map<String, List<TimeSlot>> mapTimeSlots = new Map<String, List<TimeSlot>>();
        for (TimeSlot timeSlot : [
            SELECT Id, OperatingHoursId, StartTime, DayOfWeek, EndTime
            FROM TimeSlot
            WHERE OperatingHoursId IN :lstOperatingIds
        ]) {
            //check mapTimeSlots
            if (mapTimeSlots.containsKey(timeSlot.OperatingHoursId)) {
                mapTimeSlots.get(timeSlot.OperatingHoursId).add(timeSlot);
            } else {
                List<TimeSlot> lstSlots = new List<TimeSlot>();
                lstSlots.add(timeSlot);
                mapTimeSlots.put(timeSlot.OperatingHoursId, lstSlots);
            }
        }

        //check Visit time
        for (Visit visit : lstVisits) {
            if (visit.AccountId == null) {
                return;
            }
            if (
                mapAcc2OHId.containsKey(visit.AccountId) &&
                mapTimeSlots.containsKey(mapAcc2OHId.get(visit.AccountId))
            ) {
                validateTimeSlots(mapTimeSlots.get(mapAcc2OHId.get(visit.AccountId)), visit);
            }
        }
    }

    /**
     * @description validateTimeSlots description
     * @param  lstTimeSlots lstTimeSlots description
     * @param  visit        visit description
     */
    private void validateTimeSlots(List<TimeSlot> lstTimeSlots, Visit visit){
        //timeStart
        Time timeStart = visit.PlannedVisitStartTime.time();
        //timeEnd
        Time timeEnd = visit.PlannedVisitEndTime.time();
        //strWeekDay
        String strWeekDay = visit.PlannedVisitStartTime.format('EEEE');
        //check mapAcc2OHId and mapTimeSlots
        for (TimeSlot timeSlot : lstTimeSlots) {
            if (
                //check start time
                strWeekDay == timeSlot.DayOfWeek &&
                (timeStart < timeSlot.StartTime ||
                timeStart > timeSlot.EndTime ||
                timeEnd < timeSlot.StartTime ||
                timeEnd > timeSlot.EndTime)
            ) {
                //validate start time
                String msgStartTimeError = 'Visit time must be within the account\'s operating hours.';
                //add error
                visit.PlannedVisitStartTime.addError(msgStartTimeError);
            }
        }
    }
}