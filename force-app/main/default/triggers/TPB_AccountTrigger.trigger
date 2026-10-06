/**
 * @description Visit description
 * @param  delete delete description
 * @param  insert insert description
 * @param  update update description
 * @return        return description
 */
trigger TPB_AccountTrigger on Account(
    before insert,
    before update,
    after insert,
    after update
){
    new SDF_TGF_MetadataTriggerHandler().run();
}