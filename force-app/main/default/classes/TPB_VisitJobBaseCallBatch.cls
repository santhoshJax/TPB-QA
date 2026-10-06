/**
 * @author Mi Li
 * @date 3/1/2023
 * @description change visit object form Base_Call fields
 */
public with sharing class TPB_VisitJobBaseCallBatch implements Database.Batchable<sObject> {
  private String query;
  //year or Quarter
  private String strType;
  //is Test
  private Boolean boolRunTest;
  //run date
  private Date datRunDate = System.Date.today();
  //Account Id
  private Set<Id> setAccountId;

  /**
   * @description Constructor class
   * @param  strType        statement
   * @param  boolRunTest    statement
   */
  public TPB_VisitJobBaseCallBatch(String strType, Boolean boolRunTest) {
    //query account data
    this.strType = strType;
    this.boolRunTest = boolRunTest;
    this.datRunDate = System.Date.today();
    this.query = 'SELECT Id FROM Account WHERE Last_Completed_Call__c != null';
  }

  /**
   * @description Constructor class
   * @param  setAccountId   statement
   * @param  strType        statement
   * @param  boolRunTest    statement
   * @param  datRunDate     statement
   *
   */
  public TPB_VisitJobBaseCallBatch(
    Set<Id> setAccountId,
    String strType,
    Boolean boolRunTest,
    Date datRunDate
  ) {
    this.setAccountId = setAccountId;
    this.strType = strType;
    this.boolRunTest = boolRunTest;
    this.datRunDate = datRunDate;
    this.query = 'SELECT Id FROM Account WHERE Id IN: setAccountId';
  }

  /**
   * @description start description
   * @param   bc     description
   * @return  return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  /**
   * @description execute description
   * @param  bc           description
   * @param  lstAccount   description
   */
  public void execute(Database.BatchableContext bc, List<Account> lstAccount) {
    Set<String> setAccountIds = new Set<String>();
    for (Account objAccount : lstAccount) {
      setAccountIds.add(objAccount.Id);
    }

    //query Period data
    List<Period> lstPeriod = [
      SELECT Id, StartDate, EndDate
      FROM Period
      WHERE
        Type = :strType
        AND EndDate = :datRunDate.addDays(-1)
        AND StartDate < :datRunDate.addDays(-1)
      ORDER BY StartDate DESC
      LIMIT 1
    ];

    Date dateStartTime;
    Date dateEndTime;
    //Test data
    if (boolRunTest) {
      dateStartTime = System.Date.today().addDays(-10);
      dateEndTime = System.Date.today().addDays(10);
    } else if (lstPeriod.size() > 0) {
      dateStartTime = lstPeriod[0].StartDate;
      dateEndTime = lstPeriod[0].EndDate;
    }
    if (
      (setAccountIds.size() > 0 &&
      dateStartTime != null &&
      dateEndTime != null) || boolRunTest
    ) {
      //update Visit BaseCall
      updateVisitBaseCall(setAccountIds, dateStartTime, dateEndTime);
    }
  }

  /**
   * @description update Visit Base Call description
   * @param  setAccountIds   Set<String>
   * @param  dateStartTime  Date
   * @param  dateEndTime    Date
   */
  public void updateVisitBaseCall(
    Set<String> setAccountIds,
    Date dateStartTime,
    Date dateEndTime
  ) {
    //query Last_Call__c = true and Completed Visit data
    List<Visit> lstVisit = getVisitData(
      dateStartTime,
      dateEndTime,
      setAccountIds
    );

    //query Visit data
    Map<String, Visit> mapAccountIdVisit = getAccountAndVisitData(lstVisit);

    if (strType == 'Quarter') {
      //query Status = 'Completed'  and Quarterly_Base_Call__c = true Visit data
      List<Visit> lstQuarterlyBaseCallVisit = updateQuarterlyBaseCallVisit(
        setAccountIds,
        mapAccountIdVisit,
        dateStartTime
      );
      if (lstQuarterlyBaseCallVisit.size() > 0) {
        update lstQuarterlyBaseCallVisit;
      }
    }

    //update mapAccountIdVisit
    if (mapAccountIdVisit.size() > 0) {
      update mapAccountIdVisit.Values();
    }
  }

  /**
   * @description get Account And Visit Data description
   * @param    lstVisit           List<Visit>
   * @return   mapAccountIdVisit  Map<String, Visit>
   */
  public Map<String, Visit> getAccountAndVisitData(List<Visit> lstVisit) {
    //query Visit data
    Map<String, Visit> mapAccountIdVisit = new Map<String, Visit>();
    for (Visit objVisit : lstVisit) {
      if (!mapAccountIdVisit.containsKey(objVisit.Id)) {
        //update Visit BaseCall
        if (strType == 'Year' && objVisit.Base_Call__c != true) {
          objVisit.Base_Call__c = true;
          mapAccountIdVisit.put(objVisit.Id, objVisit);
        } else if (strType == 'Quarter') {
          //update Visit Quarterly BaseCall
          objVisit.Quarterly_Base_Call__c = true;
        }
        mapAccountIdVisit.put(objVisit.Id, objVisit);
      }
    }

    return mapAccountIdVisit;
  }

  /**
   * @description get Visit Data description
   * @param    dateStartTime    Date
   * @param    dateEndTime      Date
   * @param    setAccountIds     Set<String>
   * @return    lstVisit        List<Visit>
   */
  public List<Visit> getVisitData(
    Date dateStartTime,
    Date dateEndTime,
    Set<String> setAccountIds
  ) {
    //query Last_Call__c = true and Completed Visit data
    List<Visit> lstVisit = [
      SELECT Id, AccountId, Status, Base_Call__c, Quarterly_Base_Call__c
      FROM Visit
      WHERE
        Status = 'Completed'
        AND Last_Call__c = TRUE
        AND cgcloud__Visit_Template__c != NULL
        AND ((cgcloud__Completed_Date__c <= :dateEndTime
        AND cgcloud__Completed_Date__c > :dateStartTime)
        OR (cgcloud__Completed_Date__c < :dateEndTime
        AND cgcloud__Completed_Date__c >= :dateStartTime))
        AND AccountId IN :setAccountIds
      ORDER BY AccountId, cgcloud__Completed_Date__c DESC
    ];

    return lstVisit;
  }

  /**
   * @description update Quarterly Base Call Visit description
   * @param    setAccountIds      Set<String>
   * @param    mapAccountIdVisit Map<String, Visit>
   * @param    dateStartTime     Date
   * @return  lstQuarterlyBaseCallVisit  List<Visit>
   */
  public List<Visit> updateQuarterlyBaseCallVisit(
    Set<String> setAccountIds,
    Map<String, Visit> mapAccountIdVisit,
    Date dateStartTime
  ) {
    List<Visit> lstQuarterlyBaseCallVisit = [
      SELECT Id, AccountId, Quarterly_Base_Call__c
      FROM Visit
      WHERE
        Status = 'Completed'
        AND Quarterly_Base_Call__c = TRUE
        AND cgcloud__Visit_Template__c != NULL
        AND AccountId IN :setAccountIds
        AND Id NOT IN :mapAccountIdVisit.KeySet()
        AND cgcloud__Completed_Date__c >= :Date.newInstance(
          dateStartTime.year(),
          1,
          1
        )
      ORDER BY AccountId DESC
    ];
    //query Visit data
    for (Visit objVisit : lstQuarterlyBaseCallVisit) {
      objVisit.Quarterly_Base_Call__c = false;
    }

    return lstQuarterlyBaseCallVisit;
  }

  /**
   * @description finish description
   * @param  bc bc description
   */
  public void finish(Database.BatchableContext bc) {
    //query next Period
    List<Period> lstPeriod = [
      SELECT Id, StartDate, EndDate
      FROM Period
      WHERE
        Type = :strType
        AND StartDate = :datRunDate
        AND EndDate > :datRunDate
      ORDER BY StartDate DESC
      LIMIT 1
    ];

    //next run date
    if (lstPeriod.size() > 0 || boolRunTest) {
      Date datNextRunDate;
      //Test data
      if (boolRunTest) {
        datNextRunDate = System.Date.today().addDays(20);
      } else {
        datNextRunDate = Date.newInstance(
          lstPeriod[0].EndDate.Year(),
          lstPeriod[0].EndDate.month(),
          lstPeriod[0].EndDate.day() + 1
        );
      }

      //schedule next TPB_VisitJobBaseCallScheduler
      List<String> lstString = String.valueOf(datNextRunDate).split('-');
      String strNextRunDate = strType == 'Quarter' ? '0 0 1 ' : '0 0 2 ';
      strNextRunDate +=
        Integer.valueOf(lstString[2]) +
        ' ' +
        Integer.valueOf(lstString[1]) +
        ' ? ' +
        lstString[0];
      if (!boolRunTest) {
        System.schedule(
          'TPB_VisitJobBaseCallScheduler ' +
          strType +
          ' job ' +
          String.valueOf(datNextRunDate),
          strNextRunDate,
          new TPB_VisitJobBaseCallScheduler(strType, false)
        );
      }
    }
  }
}