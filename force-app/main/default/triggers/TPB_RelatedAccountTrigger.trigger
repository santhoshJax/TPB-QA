/**
 * @description Related_Account__c description
 * @param  insert insert description
 * @return        return description
 *
 * @author Jie Yu
 * @date 2023-07-19
 */
trigger TPB_RelatedAccountTrigger on Related_Account__c(
    before insert
){
    //Call hanlder
    //hanler is configure by metadata
    new SDF_TGF_MetadataTriggerHandler().run();
}