/**************************************************************************************
Apex Class Name:  TPB_GTMOppStatusUpdateUtility
Version     : 1.0
Created Date    : 2023-08-14
Function    : Shared Logic to Close GTM Opportunities Based on Selling Activities within a Store
OwnerId     :
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Evonne              2023-08-14           Original Version
*************************************************************************************/
public with sharing class TPB_GTMOppStatusUpdateUtility {

    /**
     * @description Category
     */
    private static final String CATEGORY = 'Category';
    /**
     * @description SubCategory
     */
    private static final String SUBCATEGORY = 'SubCategory';
    /**
     * @description Brand
     */
    private static final String BRAND = 'Brand';
    /**
     * @description Flavor
     */
    private static final String FLAVOR = 'Flavor';
    /**
     * @description Package
     */
    private static final String STRPACKAGE = 'Package';
    /**
     * @description CalculatedDistribution
     */
    private static final String CALCULATEDDISTRIBUTION = 'CalculatedDistribution';
    /**
     * @description CURRENT
     */
    private static final String CURRENT = 'CURRENT';
    /**
     * @description BASE
     */
    private static final String BASE = 'BASE';
    /**
     * @description DISTRIBUTED
     */
    private static final String DISTRIBUTED = 'Distributed';
    /**
     * @description OPEN
     */
    private static final String OPEN = 'Open';
    /**
     * @description ACHIEVED
     */
    private static final String ACHIEVED = 'Achieved';

    /**
     * @description TPB_GTMOppStatusUpdateUtility description
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private TPB_GTMOppStatusUpdateUtility() {}

    /**
     * @description getProductLevel description
     * @param  objVisitJob objVisitJob description
     * @return             return description
     */
    public static Map<String, String> getProductLevel(cgcloud__Visit_Job__c objVisitJob) {
        Map<String, String> mapProductLevel = new Map<String, String> {
            CATEGORY => objVisitJob.cgcloud__Product__r.cgcloud__Criterion_1_Product__c,
            SUBCATEGORY => objVisitJob.cgcloud__Product__r.cgcloud__Criterion_2_Product__c,
            BRAND => objVisitJob.cgcloud__Product__r.cgcloud__Criterion_3_Product__c,
            FLAVOR => objVisitJob.cgcloud__Product__r.cgcloud__Criterion_4_Product__c,
            STRPACKAGE => objVisitJob.cgcloud__Product__r.cgcloud__Criterion_5_Product__c,
            CALCULATEDDISTRIBUTION => objVisitJob.TPB_Calculated_EOV__c
        };
        return mapProductLevel;
    }

    /**
     * @description getMapVisitJobProductsLast description
     * @param  lstCurrentVisitJobs lstCurrentVisitJobs description
     * @return                     return description
     */
    public static Map<String, List<Map<String, String>>> getMapVisitJobProductsLast(List<cgcloud__Visit_Job__c> lstCurrentVisitJobs) {
        Map<String, List<Map<String, String>>> mapVisitJobProductsLast = new Map<String, List<Map<String, String>>>();
        for (cgcloud__Visit_Job__c objVisitJobLast : lstCurrentVisitJobs) {
            String strKey = objVisitJobLast.cgcloud__Visit__r.AccountId + '-' + objVisitJobLast.cgcloud__Visit__r.TPB_Sales_Cycle__c + '-' + objVisitJobLast.cgcloud__Visit__r.TPB_Quarterly_Base_Visit__c;
            Map<String, String> mapProductDetails = getProductLevel(objVisitJobLast);
            List<Map<String, String>> lstMapProductDetails = mapVisitJobProductsLast.get(strKey) == null ? new List<Map<String, String>>() : mapVisitJobProductsLast.get(strKey);
            lstMapProductDetails.add(mapProductDetails);
            mapVisitJobProductsLast.put(strKey, lstMapProductDetails);
        }
        return mapVisitJobProductsLast;
    }

    /**
     * @description getMapCurrentBaseProduct description
     * @param  mapVisitJobProductsLast  mapVisitJobProductsLast description
     * @param  lstVisitJobQuarterlyBase lstVisitJobQuarterlyBase description
     * @return                          return description
     */
    public static Map<String, Map<String, List<Map<String, String>>>> getMapCurrentBaseProduct(Map<String, List<Map<String, String>>> mapVisitJobProductsLast, List<cgcloud__Visit_Job__c> lstVisitJobQuarterlyBase) {
        Map<String, Map<String, List<Map<String, String>>>> mapCurrentBaseProduct = new Map<String, Map<String, List<Map<String, String>>>>();
        //Key: visit id
        Map<String, List<Map<String, String>>> mapBaseProduct = new Map<String, List<Map<String, String>>>();
        if (lstVisitJobQuarterlyBase.size() > 0) {
            for (cgcloud__Visit_Job__c objVisitJobBase: lstVisitJobQuarterlyBase) {
                // String strKey = objVisitJobBase.cgcloud__Visit__r.AccountId + '-' + objVisitJobBase.cgcloud__Visit__r.TPB_Sales_Cycle__c + '-' + objVisitJobBase.cgcloud__Product__c;
                List<Map<String, String>> lstMapBaseProduct = mapBaseProduct.get(objVisitJobBase.cgcloud__Visit__c) == null ? new List<Map<String, String>>() : mapBaseProduct.get(objVisitJobBase.cgcloud__Visit__c);
                lstMapBaseProduct.add(getProductLevel(objVisitJobBase));
                mapBaseProduct.put(objVisitJobBase.cgcloud__Visit__c, lstMapBaseProduct);
            }
        } else {
            for (String strKey : mapVisitJobProductsLast.keySet()) {
                Map<String, List<Map<String, String>>> mapProduct = new Map<String, List<Map<String, String>>>();
                mapProduct.put(CURRENT, mapVisitJobProductsLast.get(strKey));
                mapCurrentBaseProduct.put(strKey.substringBeforeLast('-'), mapProduct);
            }
        }

        for (String strKey : mapVisitJobProductsLast.keySet()) {
            if (mapBaseProduct.containsKey(strKey.substringAfterLast('-'))) {
                List<Map<String, String>> lstMapBaseProduct = mapBaseProduct.get(strKey.substringAfterLast('-')) == null ? new List<Map<String, String>>() : mapBaseProduct.get(strKey.substringAfterLast('-'));
                Map<String, List<Map<String, String>>> mapProduct = new Map<String, List<Map<String, String>>> {BASE => lstMapBaseProduct};
                mapProduct.put(CURRENT, mapVisitJobProductsLast.get(strKey));
                mapCurrentBaseProduct.put(strKey.substringBeforeLast('-'), mapProduct);
            }
        }
        return mapCurrentBaseProduct;
    }

    /**
     * @description getLstGTMOppUpdate description
     * @param  lstGTMOpp               lstGTMOpp description
     * @param  mapVisitJobProductsLast mapVisitJobProductsLast description
     * @param  mapCurrentBaseProduct   mapCurrentBaseProduct description
     * @return                         return description
     */
    public static List<TPB_GTM_Opportunity__c> getLstGTMOppUpdate(
        List<TPB_GTM_Opportunity__c> lstGTMOpp,
        Map<String, List<Map<String, String>>> mapVisitJobProductsLast,
        Map<String, Map<String, List<Map<String, String>>>> mapCurrentBaseProduct) {
            List<TPB_GTM_Opportunity__c> lstGTMOppUpdate = new List<TPB_GTM_Opportunity__c>();
            for (TPB_GTM_Opportunity__c objGTMOpp : lstGTMOpp) {
                String strKey = objGTMOpp.TPB_Account_ID__c + '-' + objGTMOpp.TPB_Current_Sales_Cycle__c;
                List<Map<String, String>> lstMapBase = new List<Map<String, String>>();
                if (mapCurrentBaseProduct.get(strKey) != null) {
                    if (mapCurrentBaseProduct.get(strKey).get(BASE) != null) {
                        lstMapBase = mapCurrentBaseProduct.get(strKey).get(BASE);
                    }

                    List<Map<String, String>> lstMapCurrent = mapCurrentBaseProduct.get(strKey).get(CURRENT);
                    // Scenario 1,2
                    if (objGTMOpp.TPB_Type__c == 'New Distribution') {
                        String strStatus = OPEN;

                        if (mapCurrentBaseProduct.containsKey(strKey)) {
                            for (Map<String, String> mapProductDetails : mapCurrentBaseProduct.get(strKey).get(CURRENT)) {
                                if (mapProductDetails.get(objGTMOpp.TPB_Product_Level__c) == objGTMOpp.TPB_Product_ID__c && mapProductDetails.get(CALCULATEDDISTRIBUTION) == DISTRIBUTED && strStatus == OPEN) {
                                    strStatus = ACHIEVED;
                                }
                            }
                        }
                        objGTMOpp.TPB_Status__c = strStatus;
                        lstGTMOppUpdate.add(objGTMOpp);
                    } else {
                        if (mapCurrentBaseProduct.containsKey(strKey) && (lstMapBase.size() > 0)) {
                            // Integer intBaseProduct = 0;
                            Integer intBaseProductDistributed = 0;
                            // Integer intCurrentProduct = 0;
                            Integer intCurrentProductDistributed = 0;
                            for (Map<String, String> mapProduct : lstMapBase) {
                                if (mapProduct.get(objGTMOpp.TPB_Product_Level__c) == objGTMOpp.TPB_Product_ID__c && mapProduct.get(CALCULATEDDISTRIBUTION) == DISTRIBUTED) {
                                    // intBaseProduct++;
                                    intBaseProductDistributed++;
                                }
                            }
                            for (Map<String, String> mapProduct : lstMapCurrent) {
                                if (mapProduct.get(objGTMOpp.TPB_Product_Level__c) == objGTMOpp.TPB_Product_ID__c && mapProduct.get(CALCULATEDDISTRIBUTION) == DISTRIBUTED) {
                                    // intCurrentProduct++;
                                    intCurrentProductDistributed++;
                                }
                            }
                            switch on objGTMOpp.TPB_Type__c {
                                when 'SKU Expansion' {
                                    if (intBaseProductDistributed < intCurrentProductDistributed) {
                                        objGTMOpp.TPB_Status__c = ACHIEVED;
                                        lstGTMOppUpdate.add(objGTMOpp);
                                    } else {
                                        objGTMOpp.TPB_Status__c = OPEN;
                                        lstGTMOppUpdate.add(objGTMOpp);
                                    }
                                }
                                when 'SKU Maintenance' {
                                    if (intBaseProductDistributed <= intCurrentProductDistributed) {
                                        objGTMOpp.TPB_Status__c = ACHIEVED;
                                        lstGTMOppUpdate.add(objGTMOpp);
                                    } else {
                                        objGTMOpp.TPB_Status__c = OPEN;
                                        lstGTMOppUpdate.add(objGTMOpp);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return lstGTMOppUpdate;
        }

}