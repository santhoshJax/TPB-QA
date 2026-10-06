import {LightningElement, track, api} from 'lwc';
// import {showToast} from 'c/utils';
// import getProducts from '@salesforce/apex/AppointmentProductSearchController.getProducts';
// import getDisplayGroups from '@salesforce/apex/AppointmentProductSearchController.getDisplayGroups';
// import saveRecords from '@salesforce/apex/AppointmentProductSearchController.saveRecords';

export default class AppointmentProductSearchSection extends LightningElement {
    // spinner = true;
    // @api workOrderId;
    // @api pricebookId;
    // @api lineItems = [];
    // @track products = [];
    // @track pricebookEntries = [];
    
    // connectedCallback() {
    //     this.init();
    // }

    // async init() {
    //     let existingIds = [];

    //     for(let i=0; i < this.lineItems.length; i++) {
    //         let products = this.lineItems[i].products;

    //         for(let j=0; j < products.length; j++) {
    //             existingIds.push(products[j].entryId);
    //         }
    //     }

    //     try {
    //         let products = await getProducts({
    //             'pricebookId' : this.pricebookId
    //         });
    //         let displayGroups = await getDisplayGroups();
    //         let families = new Set();

    //         for(let i=0; i < products.length; i++) {
    //             families.add(products[i].Product2.Display_Group__c);
    //         }

    //         for(let name of families) {
    //             //We are limiting to 500 in SOQL
    //             let sortOrder = displayGroups[name] !== undefined ? displayGroups[name] : 500;

    //             let family = {
    //                 'name': name,
    //                 'sortOrder': sortOrder,
    //                 'products': []
    //             };

    //             for(let i=0; i < products.length; i++) {
    //                 if(existingIds.includes(products[i].Id)) {
    //                     products[i].exists = true;
    //                 }

    //                 if(name === products[i].Product2.Display_Group__c) {
    //                     family.products.push(products[i]);
    //                 }
    //             }

    //             this.products.push(family);
    //         }

    //         this.products.sort((a, b) => a.sortOrder - b.sortOrder);
    //     }
    //     catch(error) {
    //         console.log(error);
    //     }
    //     finally {
    //         this.spinner = false;
    //     }
    // }

    // selectHandler(event) {
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;
    //     const checked = event.target.checked;
    //     const product = this.products[familyIndex].products[productIndex];
    //     const existingIndex = this.pricebookEntries.findIndex(p => p.Id === product.Id);

    //     if(!checked) {
    //         this.pricebookEntries.splice(existingIndex, 1);
    //     }
    //     else {
    //         this.pricebookEntries.push(product);
    //     }
    // }

    // save() {
    //     this.spinner = true;

    //     saveRecords({
    //         'workOrderId': this.workOrderId,
    //         'entries': this.pricebookEntries
    //     })
    //     .then(results => {
    //         if(results !== 'SUCCESS') {
    //             this.showToast(results, 'error', 'sticky');
    //         }
    //         else {
    //             this.showToast('The Line Items have been added.', 'success', 'dismissable');
    //             this.close();
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
}