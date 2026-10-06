/**
 * @description Visit description
 * @param  delete delete description
 * @param  insert insert description
 * @param  update update description
 * @return        return description
 */
trigger TPB_ValidateVisitsTrigger on Visit(
    before delete,
    before insert,
    before update,
    after update
) {
    new SDF_TGF_MetadataTriggerHandler().run();
}