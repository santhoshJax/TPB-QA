/**
 * @description ContentDocumentLink description
 * @param  insert insert description
 * @param  delete delete description
 * @return        return description
 *
 * @author Jie Yu
 * @date 2023-07-19
 */
trigger TPB_ContentDocumentLinkTrigger on ContentDocumentLink(
    after insert,
    after delete
){
    //Call hanlder
    //hanler is configure by metadata
    new SDF_TGF_MetadataTriggerHandler().run();
}