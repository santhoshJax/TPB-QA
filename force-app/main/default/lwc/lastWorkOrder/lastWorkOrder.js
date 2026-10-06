import {LightningElement, api, wire, track} from 'lwc';
// import getLines from '@salesforce/apex/LastWorkOrderController.getPreviousLines';
// import {getRecord} from 'lightning/uiRecordApi';
// import {refreshApex} from '@salesforce/apex';

export default class LastWorkOrder extends LightningElement {
    // @api recordId;
    // @api objectApiName;
    // accountId;
    // appointmentId;
    // objectFields;
    // @track wiredList;
    // @track lines;

    // connectedCallback() {
    //     switch(this.objectApiName) {
    //         case 'Account':
    //             this.accountId = this.recordId;
    //             break;
    //         case 'ServiceAppointment':
    //             this.appointmentId = this.recordId;
    //             this.objectFields = ['ServiceAppointment.AccountId'];
    //             break;
    //     }
    // }

    // refresh() {
    //     refreshApex(this.wiredList);
    // }

    // @wire(getLines, {accountId: '$accountId'})
    // wiredLine(results) {
    //     this.wiredList = results;
    //     this.lines = results;
    // }

    // @wire(getRecord, {
    //     recordId: '$appointmentId',
    //     fields: '$objectFields'
    // })
    // wiredRecord({data}) {
    //     if(data) {
    //         this.accountId = data.fields.AccountId.value;
    //     }
    // }
}