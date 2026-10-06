/**
 * @author Wenbo Zhou
 * @date 2021-05-16
 * @description This class exists as a unified, trigger handler class. It
 * uses Custom Metadata, and introspection of the Trigger.new variable to
 * determine what trigger handler classes should be called, and in what order.
 *
 * SDF_TGF_Trigger_Config__mdt has three fields:
 *  * Object__c - is a metadata entity look up to an sObject ie: Account
 *  * Order__c - is an integer and determines the order the trigger
 *  *   handlers are executed
 *  * Class__c - is a String holding the name of the Trigger Handler to execute
 *
 * Note: This Trigger framework works like this:
 *
 * An .trigger for a sObject invokes this class via:
 * new MetadataTriggerHandler().run();
 *
 * This trigger handler class extends TriggerHandler - all the trigger handler
 * classes _must_ extend trigger handler. Most classes will only overwrite the
 * context methods like afterUpdate(). This class, however, overrides the run
 * method. This class is responsible for determining which other trigger
 * handler classes to instantiate and run.
 *
 * Concrete example:
 * AccountTrigger.trigger (in this org) - invokes this class.
 * This class queries the custom metadata and will find (at least) one metadata
 * record tied to Account and the metadata record's Class__c specifies
 * AccountTriggerHandler. This class then loops over the returned metadata
 * records, instantiating the classes specified. It then calls the appropriate
 * context methods on those classes.
 *
 * Note: The TriggerHandler framework below does *not* give you the ability to
 * order, or re-arrange the trigger work of managed packages. It also does not
 * allow you to declare the *order of methods* within the triggerHandler classes
 * themselves. When using the MetadataTriggerHandler, it's better to have a
 * high number of singularly focused trigger handler classes than a few classes
 * with multiple methods.
 */

public with sharing class SDF_TGF_MetadataTriggerHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description Default exception class
     */
    public class MetadataTriggerHandlerException extends Exception {
    }

    public static final String CLASS_UNABLE_INSTANTIATE_ERR = 'Unable to instantiate the handler class: ';

    @TestVisible
    private SDF_TGF_MetadataTriggerService mts;

    @TestVisible
    private List<SDF_TGF_Trigger_Config__mdt> triggerConfigs;

    @TestVisible
    private SDF_TGF_TriggerHandler activeHandler;

    /**
     * @description Constructor used by live triggers.
     */
    public SDF_TGF_MetadataTriggerHandler() {
        this(new SDF_TGF_MetadataTriggerService(
            SDF_TGF_MetadataTriggerService.getSObjectType()
        ));
    }

    /**
     * @description Constructor used by test classes.
     * @param mts an instance of metadata trigger service
     */
    public SDF_TGF_MetadataTriggerHandler(SDF_TGF_MetadataTriggerService mts) {
        this.mts = mts;
    }

    /**
     * @description Overrides the standard Run() method, which allows this
     * metadata based trigger handler can be an incremental update / sit beside
     * other trigger handlers classes that are directly invoked by a trigger
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    override public void run() {
        this.triggerConfigs = this.mts.getMetadataTriggers();

        /**
         * @description This loop is responsible for instantiating the trigger
         * handler classes identified by the query above, and then calling the
         * proper context methods.
         */
        for (SDF_TGF_Trigger_Config__mdt triggerConfig : this.triggerConfigs) {
            String handlerName = triggerConfig.Class__c;
            if (validateRun(handlerName)) {
                try {
                    activeHandler = (SDF_TGF_TriggerHandler) Type.forName(handlerName)
                        .newInstance();
                } catch (Exception ex) {
                    throw new MetadataTriggerHandlerException(
                        SDF_TGF_MetadataTriggerHandler.CLASS_UNABLE_INSTANTIATE_ERR + handlerName
                    );
                }

                super.addToLoopCount(handlerName);
                super.dispatchHandler(activeHandler);
            }
        }
    }
}