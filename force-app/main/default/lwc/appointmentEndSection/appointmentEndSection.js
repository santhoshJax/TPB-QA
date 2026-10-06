import {LightningElement, api, wire} from 'lwc';
// import {updateRecord} from 'lightning/uiRecordApi';
// import {showToast} from 'c/utils';
// import STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
// import NOTES_FIELD from '@salesforce/schema/ServiceAppointment.ServiceNote';
// import ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
// import createAppointment from '@salesforce/apex/AppointmentEndSectionController.createAppointment';
// import distributionCounter from '@salesforce/apex/AppointmentEndSectionController.distributionCounter';

export default class AppointmentEndSection extends LightningElement {
    // @api appointmentId;
    // @api workOrderId;
    // disabled = false;
    // followUp = false;
    // spinner = false;
    // appointment;
    // distributionModal = false;
    // distributionCount = 0;

    // connectedCallback() {
    //     this.disabled = true;
    //     this.appointment = {
    //         'status': '',
    //         'start': '',
    //         'end': ''
    //     }
    // }

    // get statuses() {
    //     return [
    //         {label: 'Completed', value: 'Completed'},
    //         {label: 'Cannot Complete', value: 'Cannot Complete'},
    //         {label: 'Canceled', value: 'Canceled'}
    //     ];
    // }

    // statusHandler(event) {
    //     const status = event.target.value;
    //     this.appointment.status = status;

    //     if(status === 'Cannot Complete') {
    //         this.followUp = true;
    //         this.disabled = true;
    //     }
    //     else {
    //         this.followUp = false;
    //         this.disabled = false;
    //     }
    // }

    // dateHandler(event) {
    //     const dateType = event.target.dataset.field;
    //     const dateVal = event.target.value;

    //     if(dateType === 'start') {
    //         this.appointment.start = dateVal;
    //     }
    //     else if(dateType === 'end') {
    //         this.appointment.end = dateVal;
    //     }

    //     if(this.appointment.start && this.appointment.end) {
    //         this.disabled = false;
    //     }
    //     else {
    //         this.disabled = true;
    //     }
    // }
    
    // save() {
    //     this.spinner = true;
    //     let fields = {};

    //     fields[ID_FIELD.fieldApiName] = this.appointmentId;
    //     fields[STATUS_FIELD.fieldApiName] = this.appointment.status;
    //     fields[NOTES_FIELD.fieldApiName] = this.template.querySelector('[data-field=\'notes\']').value;

    //     updateRecord({fields})
    //     .then(() => {
    //         if(this.followUp !== true) {
    //             this.showToast('The appointment has been updated.', 'success', 'dismissable');
    //         }
    //         else {
    //             this.newAppointment();
    //         }

    //         return distributionCounter({'workOrderId': this.workOrderId});
    //     })
    //     .then(results => {
    //         if(results !== 0 && this.appointment.status === 'Completed') {
    //             this.distributionCount = results;
    //             this.distributionModal = true;
    //         }
    //     })
    //     .catch(error => {
    //         this.showToast(JSON.stringify(error), 'error', 'sticky');
    //     })
    //     .finally(() => {
    //         this.spinner = false;
    //     });
    // }

    // newAppointment() {
    //     this.spinner = true;
    //     const startDate = this.template.querySelector('[data-field=\'start\']').value;
    //     const endDate = this.template.querySelector('[data-field=\'end\']').value;

    //     createAppointment({
    //         'oldAppointmentId': this.appointmentId,
    //         'schedStart': startDate,
    //         'schedEnd': endDate
    //     })
    //     .then(results => {
    //         if(results !== 'SUCCESS') {
    //             this.showToast(results, 'error', 'sticky');
    //         }
    //         else {
    //             this.showToast('A follow up appointment has been created.', 'success', 'dismissable');
    //         }
    //     })
    //     .catch(error => {
    //         this.showToast(error, 'error', 'sticky');
    //     })
    //     .finally(() => {
    //         this.spinner = false;
    //     });
    // }

    // showToast(message, variant, mode) {
    //     const toastEvent = showToast(message, variant, mode);
    //     this.dispatchEvent(toastEvent);
    // }

    // close() {
    //     const closeSection = new CustomEvent('close', {});
    //     this.dispatchEvent(closeSection);
    // }

    // closeDistributionModal() {
    //     this.distributionModal = false;
    // }
}