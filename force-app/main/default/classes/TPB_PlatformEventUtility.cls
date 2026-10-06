/**************************************************************************************
Apex Class Name:  PlatformEventUtility
Version     : 1.0
Created Date    : 2023-03-24
Function    : utility class for platform event integrated with ADW
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description platform event utility class
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
public with sharing class TPB_PlatformEventUtility {
    private string codeScan;
	//private constructor for code scan
	private TPB_PlatformEventUtility(){
        codeScan = 'code scan issue fix';
    }
	 /**
     * @description publishAccountEventsADW
     * Create the method for integration to publish Account event to ADW
     * so that integrations can merge formula fields in ADW
     * @param  eventlist eventlist description
	 * @return string description
     */
    public static String publishAccountEventsADW(List<TPB_PE_ADW_Account__e> eventlist){
    	// Call method to publish events
		List<Database.SaveResult> results = EventBus.publish(eventlist);
		String returnVal;

		// Inspect publishing result for each event
		for (Database.SaveResult srItem : results) {
			//publish success
		    if (srItem.isSuccess()) {
		        //System.debug('Successfully published event.');
		        //below code is for code scan no useless.
		        returnVal = 'Successfully published event.';

		    } else {
		        for(Database.Error errItem : srItem.getErrors()) {

		            //below code is for code scan no useless.
		            if(errItem != null){
		            	returnVal = 'Error returned: ' + errItem.getStatusCode() + ' - ' + errItem.getMessage();
		            }
		        }
		    }
		}

		return returnVal;
    }

  //   public static void publishWorkOrderLineItemEventsADW(List<TPB_PE_ADW_WorkOrderLineItem__e> eventlist){
  //   	// Call method to publish events
		// List<Database.SaveResult> results = EventBus.publish(eventlist);

		// // Inspect publishing result for each event
		// for (Database.SaveResult sr : results) {
		// 	//publish success
		//     if (sr.isSuccess()) {
		//         System.debug('Successfully published event.');
		//     } else {
		//         for(Database.Error err : sr.getErrors()) {
		//             System.debug('Error returned: ' +
		//                         err.getStatusCode() +
		//                         ' - ' +
		//                         err.getMessage());
		//         }
		//     }
		// }
  //   }
}