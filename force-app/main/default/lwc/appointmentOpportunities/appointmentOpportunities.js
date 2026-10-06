import {LightningElement, api, wire} from 'lwc';
// import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
// import {getObjectInfo} from 'lightning/uiObjectInfoApi';
// import ACCOUNT_OBJECT from '@salesforce/schema/Account';
// import FRE_NEW from '@salesforce/schema/ServiceAppointment.Account.Fre_New_Distribution_Target__c';
// import HTL_WRAPS_EXP from '@salesforce/schema/ServiceAppointment.Account.HTL_Wraps_Expansion_Target__c';
// import HTL_WRAPS_NEW from '@salesforce/schema/ServiceAppointment.Account.HTL_Wraps_New_Distribution_Target__c';
// import HEMP_WRAPS_NEW from '@salesforce/schema/ServiceAppointment.Account.Hemp_Wraps_New_Distribution_Target__c';
// import NATURAL_LEAF from '@salesforce/schema/ServiceAppointment.Account.Natural_Leaf_Wrap_New_Dist_Target__c';
// import PAPER_CONE_EXP from '@salesforce/schema/ServiceAppointment.Account.Paper_Cone_Expansion_Target__c';
// import PAPER_CONES_NEW from '@salesforce/schema/ServiceAppointment.Account.Paper_Cones_New_Distribution_Target__c';
// import PAPER_EXP from '@salesforce/schema/ServiceAppointment.Account.Paper_Expansion_Target__c';
// import PAPER_NEW from '@salesforce/schema/ServiceAppointment.Account.Paper_New_Distribution_Target__c';
// import RED_SUP_3_EXP from '@salesforce/schema/ServiceAppointment.Account.Red_Supreme_3_oz_Expansion_Target__c';
// import RED_SUP_3_NEW from '@salesforce/schema/ServiceAppointment.Account.Red_Supreme_3oz_New_Dist_Target__c';
// import RED_SUP_9 from '@salesforce/schema/ServiceAppointment.Account.Red_Supreme_9_98_Expansion_Target__c';
// import STOKERS_CAN from '@salesforce/schema/ServiceAppointment.Account.Stokers_MST_Expansion_Target__c';
// import STOKERS_FCN from '@salesforce/schema/ServiceAppointment.Account.Stokers_FCN_New_Distribution_Target__c';
// import STOKERS_NEW from '@salesforce/schema/ServiceAppointment.Account.Stokers_New_Distribution_Target__c';
// import STOKERS_TUB from '@salesforce/schema/ServiceAppointment.Account.Stokers_Tub_Backfill_Target__c';
// import WILD_HEMP from '@salesforce/schema/ServiceAppointment.Account.Wild_Hemp_New_Distribution_Target__c';

// import FRE_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Fre_New_Distribution_Target__c';
// import HTL_WRAPS_EXP_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.HTL_Wraps_Expansion_Target__c';
// import HTL_WRAPS_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.HTL_Wraps_New_Distribution_Target__c';
// import HEMP_WRAPS_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Hemp_Wraps_New_Distribution_Target__c';
// import NATURAL_LEAF_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Natural_Leaf_Wrap_New_Dist_Target__c';
// import PAPER_CONE_EXP_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Paper_Cone_Expansion_Target__c';
// import PAPER_CONES_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Paper_Cones_New_Distribution_Target__c';
// import PAPER_EXP_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Paper_Expansion_Target__c';
// import PAPER_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Paper_New_Distribution_Target__c';
// import RED_SUP_3_EXP_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Red_Supreme_3_oz_Expansion_Target__c';
// import RED_SUP_3_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Red_Supreme_3oz_New_Dist_Target__c';
// import RED_SUP_9_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Red_Supreme_9_98_Expansion_Target__c';
// import STOKERS_CAN_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Stokers_MST_Expansion_Target__c';
// import STOKERS_FCN_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Stokers_FCN_New_Distribution_Target__c';
// import STOKERS_NEW_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Stokers_New_Distribution_Target__c';
// import STOKERS_TUB_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Stokers_Tub_Backfill_Target__c';
// import WILD_HEMP_PARENT from '@salesforce/schema/ServiceAppointment.Account.Parent.Wild_Hemp_New_Distribution_Target__c';

export default class AppointmentOpportunities extends LightningElement {
//     @api recordId;

//     @wire(getRecord, {
//         recordId: '$recordId',
//         fields: [
//             FRE_NEW, HTL_WRAPS_EXP, HTL_WRAPS_NEW, HEMP_WRAPS_NEW, NATURAL_LEAF, PAPER_CONE_EXP, PAPER_CONES_NEW, PAPER_EXP, PAPER_NEW, RED_SUP_3_EXP, RED_SUP_3_NEW,
//             RED_SUP_9, STOKERS_CAN, STOKERS_FCN, STOKERS_NEW, STOKERS_TUB, WILD_HEMP,
//             FRE_NEW_PARENT, HTL_WRAPS_EXP_PARENT, HTL_WRAPS_NEW_PARENT, HEMP_WRAPS_NEW_PARENT, NATURAL_LEAF_PARENT, PAPER_CONE_EXP_PARENT,
//             PAPER_CONES_NEW_PARENT, PAPER_EXP_PARENT, PAPER_NEW_PARENT, RED_SUP_3_EXP_PARENT, RED_SUP_3_NEW_PARENT, RED_SUP_9_PARENT, STOKERS_CAN_PARENT,
//             STOKERS_FCN_PARENT, STOKERS_NEW_PARENT, STOKERS_TUB_PARENT, WILD_HEMP_PARENT
//         ]
//     })
//     appointment;

//     @wire(getObjectInfo, {objectApiName: ACCOUNT_OBJECT})
//     objectInfo;

//     get freNew() {
//         const child = getFieldValue(this.appointment.data, FRE_NEW);
//         const parent = getFieldValue(this.appointment.data, FRE_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Fre_New_Distribution_Target__c.label : '';
//     }

//     get htlWrapsExp() {
//         const child = getFieldValue(this.appointment.data, HTL_WRAPS_EXP);
//         const parent = getFieldValue(this.appointment.data, HTL_WRAPS_EXP_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.HTL_Wraps_Expansion_Target__c.label : '';
//     }

//     get htlWrapsNew() {
//         const child = getFieldValue(this.appointment.data, HTL_WRAPS_NEW);
//         const parent = getFieldValue(this.appointment.data, HTL_WRAPS_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.HTL_Wraps_New_Distribution_Target__c.label : '';
//     }

//     get hempWrapsNew() {
//         const child = getFieldValue(this.appointment.data, HEMP_WRAPS_NEW);
//         const parent = getFieldValue(this.appointment.data, HEMP_WRAPS_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Hemp_Wraps_New_Distribution_Target__c.label : '';
//     }

//     get naturalLeaf() {
//         const child = getFieldValue(this.appointment.data, NATURAL_LEAF);
//         const parent = getFieldValue(this.appointment.data, NATURAL_LEAF_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Natural_Leaf_New_Distribution_Target__c.label : '';
//     }

//     get paperConeExp() {
//         const child = getFieldValue(this.appointment.data, PAPER_CONE_EXP);
//         const parent = getFieldValue(this.appointment.data, PAPER_CONE_EXP_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Paper_Cone_Expansion_Target__c.label : '';
//     }

//     get paperConeNew() {
//         const child = getFieldValue(this.appointment.data, PAPER_CONES_NEW);
//         const parent = getFieldValue(this.appointment.data, PAPER_CONES_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Paper_Cones_New_Distribution_Target__c.label : '';
//     }

//     get paperExp() {
//         const child = getFieldValue(this.appointment.data, PAPER_EXP);
//         const parent = getFieldValue(this.appointment.data, PAPER_EXP_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Paper_Expansion_Target__c.label : '';
//     }

//     get paperNew() {
//         const child = getFieldValue(this.appointment.data, PAPER_NEW);
//         const parent = getFieldValue(this.appointment.data, PAPER_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Paper_New_Distribution_Target__c.label : '';
//     }

//     get redSup3Exp() {
//         const child = getFieldValue(this.appointment.data, RED_SUP_3_EXP);
//         const parent = getFieldValue(this.appointment.data, RED_SUP_3_EXP_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Red_Supreme_3_oz_Expansion_Target__c.label : '';
//     }

//     get redSup3New() {
//         const child = getFieldValue(this.appointment.data, RED_SUP_3_NEW);
//         const parent = getFieldValue(this.appointment.data, RED_SUP_3_NEW_PARENT);


//         return child === true || parent === true ? this.objectInfo.data.fields.Red_Supreme_3oz_New_Distribution_Target__c.label : '';
//     }

//     get redSup9() {
//         const child = getFieldValue(this.appointment.data, RED_SUP_9);
//         const parent = getFieldValue(this.appointment.data, RED_SUP_9_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Red_Supreme_9_98_Expansion_Target__c.label : '';
//     }

//     get stokersCan() {
//         const child = getFieldValue(this.appointment.data, STOKERS_CAN);
//         const parent = getFieldValue(this.appointment.data, STOKERS_CAN_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Stokers_Can_Expansion_Target__c.label : '';
//     }

//     get stokersFcn() {
//         const child = getFieldValue(this.appointment.data, STOKERS_FCN);
//         const parent = getFieldValue(this.appointment.data, STOKERS_FCN_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Stokers_FCN_New_Distribution_Target__c.label : '';
//     }

//     get stokersNew() {
//         const child = getFieldValue(this.appointment.data, STOKERS_NEW);
//         const parent = getFieldValue(this.appointment.data, STOKERS_NEW_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Stokers_New_Distribution_Target__c.label : '';
//     }

//     get stokersTub() {
//         const child = getFieldValue(this.appointment.data, STOKERS_TUB);
//         const parent = getFieldValue(this.appointment.data, STOKERS_TUB_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Stokers_Tub_Expansion_Target__c.label : '';
//     }

//     get wildHemp() {
//         const child = getFieldValue(this.appointment.data, WILD_HEMP);
//         const parent = getFieldValue(this.appointment.data, WILD_HEMP_PARENT);

//         return child === true || parent === true ? this.objectInfo.data.fields.Wild_Hemp_New_Distribution_Target__c.label : '';
//     }

 }