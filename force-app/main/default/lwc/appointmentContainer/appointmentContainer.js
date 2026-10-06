import {LightningElement, wire, track, api} from 'lwc';
// import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
// import ACCOUNT_NAME_FIELD from '@salesforce/schema/ServiceAppointment.Account.Name';
// import ACCOUNT_ID_FIELD from '@salesforce/schema/ServiceAppointment.AccountId';
// import WORK_ORDER_FIELD from '@salesforce/schema/ServiceAppointment.ParentRecordId';
// import STREET_FIELD from '@salesforce/schema/ServiceAppointment.Street';
// import CITY_FIELD from '@salesforce/schema/ServiceAppointment.City';
// import STATE_FIELD from '@salesforce/schema/ServiceAppointment.State';
// import ZIP_FIELD from '@salesforce/schema/ServiceAppointment.PostalCode';
// import APPOINTMENT_FIELD from '@salesforce/schema/ServiceAppointment.AppointmentNumber';
// import STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
// import PRICEBOOK_ID_FIELD from '@salesforce/schema/WorkOrder.Pricebook2Id';
// import ACTUAL_START_FIELD from '@salesforce/schema/ServiceAppointment.ActualStartTime';
// import IP_FIELD from '@salesforce/schema/ServiceAppointment.unknown_custom_field';
// import FEIN_FIELD from '@salesforce/schema/ServiceAppointment.Account.FEIN__c';
// import TOBACCO_FIELD from '@salesforce/schema/ServiceAppointment.Account.State_Tobacco_Number__c';
// import TAX_FIELD from '@salesforce/schema/ServiceAppointment.Account.State_Tax_Number__c';
// import FREQUENCY_FIELD from '@salesforce/schema/ServiceAppointment.Account.Frequency__c';
// import TIER_FIELD from '@salesforce/schema/ServiceAppointment.Account.Tier__c';
// import PARENT_ACCOUNT_FIELD from '@salesforce/schema/ServiceAppointment.Account.Parent.Name';
// import ACCOUNT_NUMBER_FIELD from '@salesforce/schema/ServiceAppointment.Account.Account_Number_old__c';
// import {refreshApex} from '@salesforce/apex';
// import TOTAL_DISCOUNT_FIELD from '@salesforce/schema/WorkOrder.Total_Discount__c';
// import TOTAL_INVOICE_FIELD from '@salesforce/schema/WorkOrder.Total_Invoice__c';
// import TOTAL_PRICE_FIELD from '@salesforce/schema/WorkOrder.Total__c';
// import TOTAL_RETURN_FIELD from '@salesforce/schema/WorkOrder.Total_Returns__c';
// import TOTAL_REIMBURSEMENT_FIELD from '@salesforce/schema/WorkOrder.Total_Reimbursement__c';
// import getServiceReport from '@salesforce/apex/AppointmentContainerController.getServiceReport';
// import {NavigationMixin} from 'lightning/navigation';
// import {showToast} from 'c/utils';

export default class AppointmentContainer extends NavigationMixin(LightningElement) {
    // @api recordId; //ServiceAppointment
    // parentId; //WorkOrder
    // appointment = {};
    // lineView = 'Distribution View';
    // startCall = false;
    // lineSection = false;
    // accountSection = false;
    // taskSection = false;
    // scanningSection = false;
    // surveySection = false;
    // objectiveSection = false;
    // endSection = false;
    // accEdit = false;
    // @track wiredWorkOrder;
    // spinner = false;

    // connectedCallback() {
    //     this.lineSection = true;
    // }

    // @wire(getRecord, {
    //     recordId: '$recordId',
    //     fields: [APPOINTMENT_FIELD, STATUS_FIELD, STREET_FIELD, CITY_FIELD, STATE_FIELD, ZIP_FIELD, ACTUAL_START_FIELD, IP_FIELD,
    //              WORK_ORDER_FIELD,
    //              ACCOUNT_NAME_FIELD, ACCOUNT_ID_FIELD, FEIN_FIELD, TOBACCO_FIELD, TAX_FIELD, FREQUENCY_FIELD, TIER_FIELD, PARENT_ACCOUNT_FIELD, ACCOUNT_NUMBER_FIELD]})
    // setAppointment({data}) {
    //     if(data) {
    //         this.appointment = data;
    //         this.parentId = data.fields.ParentRecordId.value;

    //         const status = data.fields.Status.value;
    //         const actualStart = data.fields.ActualStartTime.value;
    //         const ipAddress = data.fields.IP_Address__c.value;

    //         if(status && actualStart && ipAddress) {
    //             this.startCall = true;
    //         }
    //     }
    // }

    // @wire(getRecord, {
    //     recordId: '$parentId',
    //     fields: [PRICEBOOK_ID_FIELD, TOTAL_DISCOUNT_FIELD, TOTAL_INVOICE_FIELD, TOTAL_PRICE_FIELD, TOTAL_RETURN_FIELD, TOTAL_REIMBURSEMENT_FIELD]})
    // workOrder(response) {
    //     this.wiredWorkOrder = response;
    // }

    // accEditHandler() {
    //     this.accEdit = !this.accEdit;
    // }

    // accEditClose() {
    //     this.accEdit = false;
    // }

    // get accName() {
    //     return getFieldValue(this.appointment, ACCOUNT_NAME_FIELD);
    // }

    // get accId() {
    //     return getFieldValue(this.appointment, ACCOUNT_ID_FIELD);
    // }

    // get street() {
    //     return getFieldValue(this.appointment, STREET_FIELD);
    // }

    // get city() {
    //     return getFieldValue(this.appointment, CITY_FIELD);
    // }

    // get state() {
    //     return getFieldValue(this.appointment, STATE_FIELD);
    // }

    // get zip() {
    //     return getFieldValue(this.appointment, ZIP_FIELD);
    // }

    // get address() {
    //     return {
    //         'street': getFieldValue(this.appointment, STREET_FIELD),
    //         'city': getFieldValue(this.appointment, CITY_FIELD),
    //         'state': getFieldValue(this.appointment, STATE_FIELD),
    //         'zip': getFieldValue(this.appointment, ZIP_FIELD),
    //     }
    // }

    // get appointmentNumber() {
    //     return getFieldValue(this.appointment, APPOINTMENT_FIELD);
    // }

    // get status() {
    //     return getFieldValue(this.appointment, STATUS_FIELD);
    // }

    // get actualStart() {
    //     return getFieldValue(this.appointment, ACTUAL_START_FIELD);
    // }

    // get fein() {
    //     return getFieldValue(this.appointment, FEIN_FIELD);
    // }

    // get tobacco() {
    //     return getFieldValue(this.appointment, TOBACCO_FIELD);
    // }

    // get tax() {
    //     return getFieldValue(this.appointment, TAX_FIELD);
    // }

    // get frequency() {
    //     return getFieldValue(this.appointment, FREQUENCY_FIELD);
    // }

    // get tier() {
    //     return getFieldValue(this.appointment, TIER_FIELD);
    // }
    
    // get parent() {
    //     return getFieldValue(this.appointment, PARENT_ACCOUNT_FIELD);
    // }

    // get accNumber() {
    //     return getFieldValue(this.appointment, ACCOUNT_NUMBER_FIELD);
    // }

    // get pricebookId() {
    //     return getFieldValue(this.wiredWorkOrder.data, PRICEBOOK_ID_FIELD);
    // }

    // get totalInvoice() {
    //     return getFieldValue(this.wiredWorkOrder.data, TOTAL_INVOICE_FIELD);
    // }

    // get totalPrice() {
    //     return getFieldValue(this.wiredWorkOrder.data, TOTAL_PRICE_FIELD);
    // }

    // get totalDiscount() {
    //     return getFieldValue(this.wiredWorkOrder.data, TOTAL_DISCOUNT_FIELD);
    // }

    // get totalReturn() {
    //     return getFieldValue(this.wiredWorkOrder.data, TOTAL_RETURN_FIELD);
    // }

    // get totalReimbursement() {
    //     return getFieldValue(this.wiredWorkOrder.data, TOTAL_REIMBURSEMENT_FIELD);
    // }

    // get lineViewOptions() {
    //     return [
    //         {label: 'Distribution View', value: 'Distribution View'},
    //         {label: 'Cart View', value: 'Cart View'}
    //     ];
    // }

    // headerActions(event) {
    //     this.lineSection = false;
    //     this.accountSection = false;
    //     this.taskSection = false;
    //     this.scanningSection = false;
    //     this.surveySection = false;
    //     this.objectiveSection = false;
    //     this.endSection = false;

    //     const actionType = event.detail.value;
    //     switch(actionType) {
    //         case 'lines':
    //             this.lineSection = true;
    //             break;
    //         case 'account':
    //             this.accountSection = true;
    //             break;
    //         case 'task':
    //             this.taskSection = true;
    //             break;
    //         case 'scan':
    //             this.scanningSection = true;
    //             break;
    //         case 'survey':
    //             this.surveySection = true;
    //             break;
    //         case 'objective':
    //             this.objectiveSection = true;
    //             break;
    //         case 'end':
    //             this.endSection = true;
    //             break;
    //     }
    // }

    // closeHandler() {
    //     this.lineSection = true;
    //     this.accountSection = false;
    //     this.taskSection = false;
    //     this.scanningSection = false;
    //     this.surveySection = false;
    //     this.objectiveSection = false;
    //     this.endSection = false;
    // }

    // toggleView(event) {
    //     let view = event.target.value;
    //     this.template.querySelector('c-appointment-line-item-section').toggleView(view);
    // }

    // saveHandler() {
    //     refreshApex(this.wiredWorkOrder);
    // }

    // preview() {
    //     this.spinner = true;

    //     getServiceReport({workOrderId: this.parentId})
    //     .then(result => {
    //         if(result !== '') {
    //             this.openPreview(result);
    //         }
    //         else {
    //             this.showToast('Please click the Generate Invoice button first', 'info', 'sticky');
    //         }
    //     })
    //     .catch(error => {
    //         this.showToast('There was an error previewing the invoice: ' + error, 'error', 'sticky');
    //     })
    //     .finally(() => {
    //         this.spinner = false;
    //     });
    // }

    // openPreview(workOrderId) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__namedPage',
    //         attributes: {
    //             pageName: 'filePreview'
    //         },
    //         state : {
    //             recordIds: workOrderId,
    //             selectedRecordId: workOrderId
    //         }
    //     })
    // }

    // showToast(message, variant, mode) {
    //     const toastEvent = showToast(message, variant, mode);
    //     this.dispatchEvent(toastEvent);
    // }
}