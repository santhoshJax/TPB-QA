/**
 * @description ContentDocument description
 * @param  delete delete description
 * @return        return description
 * 
 * @author Jie Yu
 * @date 2023-07-19 
 */
trigger TPB_ContentDocumentTrigger on ContentDocument(
    before delete,
    after delete
){
    new SDF_TGF_MetadataTriggerHandler().run();
}