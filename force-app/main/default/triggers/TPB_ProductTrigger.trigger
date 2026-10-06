/**
 * @author Tina Wu
 * @date 4/13/2023
 * @description TPB_ProductTrigger
 */
trigger TPB_ProductTrigger on Product2(after update){
    new SDF_TGF_MetadataTriggerHandler().run();
}