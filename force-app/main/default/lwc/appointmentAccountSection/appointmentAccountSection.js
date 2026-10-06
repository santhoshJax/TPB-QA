import {LightningElement, api, wire, track} from 'lwc';
// import {showToast} from 'c/utils';
// import getContacts from '@salesforce/apex/AppointmentAccountSectionController.getContactList';
// import getWholesalers from '@salesforce/apex/AppointmentAccountSectionController.getWholesalerList';
// import searchWholesalers from '@salesforce/apex/AppointmentAccountSectionController.searchWholesalers';
// import getWorkOrder from '@salesforce/apex/AppointmentAccountSectionController.getWorkOrder';
// import getPicklistVals from '@salesforce/apex/AppointmentUtilities.getPicklistVals';
// import upsertRecords from '@salesforce/apex/AppointmentUtilities.upsertRecords';
// import deleteRecord from '@salesforce/apex/AppointmentUtilities.deleteRecord';

export default class AppointmentAccountSection extends LightningElement {
    // spinner = true;
    // @api accId;
    // @api accName;
    // @api accAddress;
    // @track contacts;
    // @track wholesalers;
    // wholesalerResults = [];
    // wholesalerTypes = [];
    // search = false;
    // callCount = '';
    // callObjective = '';
    // contactTitles = [];

    // connectedCallback() {
    //     this.init();
    // }

    // async init() {
    //     try {
    //         let contacts = await getContacts({'accountId' : this.accId});
    //         let wholesalers = await getWholesalers({'accountId' : this.accId});
    //         let workOrder = await getWorkOrder({'accountId' : this.accId});
    //         let wholesalerTypes = await getPicklistVals({
    //             'objectName': 'Related_Account__c',
    //             'fieldName': 'Type__c',
    //             'valuesToOmit': []
    //         });
    //         let contactTitles = await getPicklistVals({
    //             'objectName': 'Contact',
    //             'fieldName': 'Title2__c',
    //             'valuesToOmit': []
    //         });

    //         for(let i=0; i < contacts.length; i++) {
    //             if(contacts[i].Days_of_the_Week__c) {
    //                 let days = contacts[i].Days_of_the_Week__c.split(';');
                    
    //                 for(let j=0; j < days.length; j++) {
    //                     switch(days[j]) {
    //                         case 'Sunday':
    //                             contacts[i].Sunday = true;
    //                             break;
    //                         case 'Monday':
    //                             contacts[i].Monday = true;
    //                             break;
    //                         case 'Tuesday':
    //                             contacts[i].Tuesday = true;
    //                             break;
    //                         case 'Wednesday':
    //                             contacts[i].Wednesday = true;
    //                             break;
    //                         case 'Thursday':
    //                             contacts[i].Thursday = true;
    //                             break;
    //                         case 'Friday':
    //                             contacts[i].Friday = true;
    //                             break;
    //                         case 'Saturday':
    //                             contacts[i].Saturday = true;
    //                             break;
    //                     }
    //                 }
    //             }
    //         }

    //         for(let i=0; i < wholesalers.length; i++) {
    //             wholesalers[i].wholesalerName = wholesalers[i].Wholesaler__r.Name;
    //             wholesalers[i].clearingHouse = wholesalers[i].Wholesaler__r.Clearing_House_Participant__c;
    //         }

    //         this.contacts = contacts;
    //         this.wholesalers = wholesalers;
    //         this.callCount = workOrder['count'];
    //         this.callObjective = workOrder['objective'];
    //         this.wholesalerTypes = wholesalerTypes;
    //         this.contactTitles = contactTitles;
    //     }
    //     catch(error) {
    //         console.log(error);
    //     }
    //     finally {
    //         this.spinner = false;
    //     }
    // }

    // updateContact(event) {
    //     const field = event.target.name;
    //     const index = event.target.dataset.index;
    //     const textFields = ['Email', 'Phone', 'OtherPhone', 'FirstName', 'LastName', 'Title2__c', 'Contact_Note__c'];

    //     if(textFields.includes(field)) {
    //         const value = event.target.value;
    //         this.contacts[index][field] = value;
    //     }
    //     else if(field === 'Decision_Maker__c') {
    //         const checked = event.target.checked;
    //         this.contacts[index][field] = checked;
    //     }
    //     else {
    //         const checked = event.target.checked;
    //         let days = this.contacts[index].Days_of_the_Week__c ? this.contacts[index].Days_of_the_Week__c.split(';') : [];

    //         if(!checked) {
    //             days = days.filter(e => e !== field);
    //         }
    //         else {
    //             days.push(field);
    //         }

    //         this.contacts[index]['Days_of_the_Week__c'] = days.join(';');
    //     }
    // }

    // updateWholesaler(event) {
    //     const field = event.target.name;
    //     const index = event.target.dataset.index;

    //     if(field === 'Type__c' || field === 'Supplier_Id__c') {
    //         const value = event.target.value;
    //         this.wholesalers[index][field] = value;
    //     }
    // }

    // newContact() {
    //     this.contacts.push({
    //         'AccountId': this.accId,
    //         'FirstName': '',
    //         'LastName': '',
    //         'Email': '',
    //         'Phone': '',
    //         'Days_of_the_Week__c': '',
    //         'Title2__c': '',
    //         'Decision_Maker__c': false
    //     });
    // }

    // newWholesaler() {
    //     this.wholesalers.push({
    //         'Retailer__c': this.accId,
    //         'Wholesaler__c': '',
    //         'wholesalerName': '',
    //         'Type__c': '',
    //         'Supplier_Id__c': ''
    //     });
    // }

    // removeWholesaler(event) {
    //     const index = event.target.dataset.index;
    //     this.wholesalers[index].confirmDelete = true;
    // }

    // removeContact(event) {
    //     const index = event.target.dataset.index;
    //     this.contacts[index].confirmDelete = true;
    // }

    // yesDeleteContact(event) {
    //     this.spinner = true;
    //     const index = event.target.dataset.index;

    //     if(this.contacts[index].Id) {
    //         deleteRecord({
    //             'recordId': this.contacts[index].Id
    //         })
    //         .then(results => {
    //             this.showToast('The contact has been deleted.', 'success', 'dismissable');
    //         })
    //         .catch(error => {
    //             this.showToast(error, 'error', 'sticky');
    //         })
    //         .finally(() => {
    //             this.contacts.splice(index, 1);
    //             this.spinner = false;
    //         });
    //     }
    //     else {
    //         this.contacts.splice(index, 1);
    //         this.spinner = false;
    //     }
    // }

    // noDeleteContact(event) {
    //     const index = event.target.dataset.index;
    //     this.contacts[index].confirmDelete = false;
    // }

    // yesDeleteWholesaler(event) {
    //     this.spinner = true;
    //     const index = event.target.dataset.index;

    //     if(this.wholesalers[index].Id) {
    //         deleteRecord({
    //             'recordId': this.wholesalers[index].Id
    //         })
    //         .then(results => {
    //             this.showToast('The related wholesaler has been deleted.', 'success', 'dismissable');
    //         })
    //         .catch(error => {
    //             this.showToast(error, 'error', 'sticky');
    //         })
    //         .finally(() => {
    //             this.wholesalers.splice(index, 1);
    //             this.spinner = false;
    //         });
    //     }
    //     else {
    //         this.wholesalers.splice(index, 1);
    //         this.spinner = false;
    //     }
    // }

    // noDeleteWholesaler(event) {
    //     const index = event.target.dataset.index;
    //     this.wholesalers[index].confirmDelete = false;
    // }

    // findWholesalers(event) {
    //     const input = event.target.value;

    //     if(input.length > 2) {
    //         searchWholesalers({
    //             'input': input
    //         })
    //         .then(results => {
    //             this.wholesalerResults = results;
    //             this.search = true;
    //         });
    //     }
    //     else {
    //         this.wholesalerResults = [];
    //         this.search = false;
    //     }
    // }

    // selectedWholesaler(event) {
    //     const index = event.target.dataset.index;
    //     const accName = event.target.dataset.name;
    //     const accId = event.target.dataset.id;
    //     const clearing = event.target.dataset.clearing;
        
    //     let wholesaler = {
    //         'Retailer__c': this.accId,
    //         'Wholesaler__c': accId,
    //         'wholesalerName': accName,
    //         'Type__c': '',
    //         'Supplier_Id__c': '',
    //         'clearingHouse': clearing
    //     };

    //     this.wholesalerResults = [];
    //     this.search = false;
    //     this.wholesalers[index] = wholesaler;
    // }

    // saveContacts() {
    //     this.saveRecords('contacts');
    // }

    // saveWholesalers() {
    //     this.saveRecords('wholesalers');
    // }

    // saveRecords(objectType) {
    //     this.spinner = true;

    //     upsertRecords({
    //         'records': JSON.stringify(this[objectType]),
    //         'sObjectType': objectType
    //     })
    //     .then(results => {
    //         if(!results.startsWith('[')) {
    //             this.showToast(results, 'error', 'sticky');
    //         }
    //         else {
    //             this.showToast('The Account has been updated.', 'success', 'dismissable');
    //             this[objectType] = JSON.parse(results);
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

    // selectHandler(event) {
    //     const detail = event.detail;

    //     if(detail.target.sObject === 'related') {
    //         this.updateWholesaler(detail);
    //     }
    //     else if(detail.target.sObject === 'contact') {
    //         this.updateContact(detail);
    //     }
    // }

}