import {LightningElement, api, wire, track} from 'lwc';
//import getNotes from '@salesforce/apex/AppointmentNotesController.getNotes';
import {refreshApex} from '@salesforce/apex';

export default class AppointmentNotes extends LightningElement {
    // @api recordId;
    // @track wiredAppointments;
    // @track appointments;

    // refresh() {
    //     refreshApex(this.wiredAppointments);
    // }

    // @wire(getNotes, {accountId: '$recordId'})
    // wiredAppointments(results) {
    //     this.wiredAppointments = results;
    //     this.appointments = results;
    // }
}