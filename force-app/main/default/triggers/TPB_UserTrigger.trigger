/**
 * @author Tina Wu
 * @date 4/13/2023
 * @description TPB_UserTrigger
 */
trigger TPB_UserTrigger on User(
    before insert,
    before update,
    after insert,
    after update
){
    new SDF_TGF_MetadataTriggerHandler().run();
}