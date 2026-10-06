import {LightningElement, api, track} from 'lwc';
// import {showToast} from 'c/utils';
// import getLineItems from '@salesforce/apex/AppointmentLineItemSectionController.getLineItems';
// import getPicklistVals from '@salesforce/apex/AppointmentUtilities.getPicklistVals';
// import getWholesalers from '@salesforce/apex/AppointmentLineItemSectionController.getWholesalers';
// import updateRecords from '@salesforce/apex/AppointmentLineItemSectionController.updateRecords';
// import deleteRecord from '@salesforce/apex/AppointmentUtilities.deleteRecord';

export default class AppointmentLineItemSection extends LightningElement {
    // displayMain = true;
    // spinner = false;
    // cartView = false;
    // @api workOrderId;
    // @api accountId;
    // @api pricebookId;
    // @track lineItems = [];
    // itemTypes = [];
    // wholesalers = [];
    // primaryWholesaler = '';
    // zones = [];
    // units = [];
    // @track lineItemUpdates = [];

    // connectedCallback() {
    //     this.init(false);
    // }

    // async init(reloadLines) {
    //     this.spinner = true;

    //     try {
    //         let lineItems = await getLineItems({
    //             'workOrderId' : this.workOrderId,
    //             'accountId' : this.accountId
    //         });
    //         let families = new Set();

    //         for(let i=0; i < lineItems.length; i++) {
    //             families.add(lineItems[i].displayGroup);
    //         }

    //         for(let name of families) {
    //             let count = 0;
    //             let family = {
    //                 'name': name,
    //                 'show': true,
    //                 'products': []
    //             };

    //             for(let i=0; i < lineItems.length; i++) {
    //                 if(name === lineItems[i].displayGroup) {
    //                     family.products.push(lineItems[i]);
    //                     count++;
    //                 }
    //             }

    //             family.name = family.name + ' - ' + count;
    //             this.lineItems.push(family);
    //         }

    //         if(!reloadLines) {
    //             let itemTypes = await getPicklistVals({
    //                 'objectName': 'WorkOrderLineItem',
    //                 'fieldName': 'Item_Type__c',
    //                 'valuesToOmit': ['Signage Check']
    //             });
    //             let zones = await getPicklistVals({
    //                 'objectName': 'WorkOrderLineItem',
    //                 'fieldName': 'Zone__c',
    //                 'valuesToOmit': []
    //             });
    //             let units = await getPicklistVals({
    //                 'objectName': 'WorkOrderLineItem',
    //                 'fieldName': 'UoM__c',
    //                 'valuesToOmit': []
    //             });
    //             let wholesalers = await getWholesalers({'accountId' : this.accountId});

    //             this.wholesalers.push({
    //                 'label': '--None--',
    //                 'value': ''
    //             })

    //             for(let i=0; i < wholesalers.length; i++) {
    //                 if(wholesalers[i].Type__c === 'Primary') {
    //                     this.primaryWholesaler = wholesalers[i].Id;
    //                 }

    //                 this.wholesalers.push({
    //                     'label': wholesalers[i].Wholesaler__r.Name,
    //                     'value': wholesalers[i].Id
    //                 })
    //             }
        
    //             this.itemTypes = itemTypes;
    //             this.zones = zones;
    //             this.units = units;
    //         }
    //     }
    //     catch(error) {
    //         console.log(error);
    //     }
    //     finally {
    //         this.spinner = false;
    //     }
    // }

    // @api
    // toggleView(view) {
    //     let lineItems = this.lineItems;

    //     for(let i=0; i < lineItems.length; i++) {
    //         let name = this.lineItems[i].name.substr(0, this.lineItems[i].name.lastIndexOf(' - '));
    //         let products = lineItems[i].products;
    //         let count = 0;

    //         for(let j=0; j < products.length; j++) {
    //             if(view !== 'Cart View') {
    //                 count++;
    //             }
    //             else {
    //                 if(products[j].itemType) {
    //                     count++;
    //                 }
    //             }
    //         }

    //         if(count > 0) {
    //             this.lineItems[i].name = name + ' - ' + count;
    //             this.lineItems[i].show = true;
    //         }
    //         else {
    //             this.lineItems[i].show = false;
    //         }
    //     }

    //     this.cartView = view === 'Cart View' ? true : false;
    // }

    // lineUpdateHandler(event) {
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;
    //     const field = event.target.name;
    //     const calcs = ['unitPrice', 'quantity', 'discount', 'shelfPrice'];
    //     const checkboxes = ['inStock', 'resale'];
    //     let value;

    //     if(checkboxes.includes(field)) {
    //         value = event.target.checked;
    //     }
    //     else {
    //         value = event.target.value;
    //     }

    //     let line = this.lineItems[familyIndex].products[productIndex];
    //     line[field] = value;

    //     if(field === 'itemType') {
    //         line.discount = 0;
    //         line.unitPrice = 0;
    //         line.totalPrice = 0;
    //         line.isNotPrebook = true;
    //         line.prebookDate = null;
    //         line.wholesalerNotEnabled = true;
    //         line.wholesalerId = null;
    //         line.uom = null;
    //         line.discountNotEnabled = true;
    //         line.returnType = false;
    //         line.pricingNotEnabled = false;
    //         line.uomNotEnabled = false;

    //         switch(value) {
    //             case 'Cash Sale':
    //                 line.uom = 'Carton';
    //                 line.discountNotEnabled = line.productDiscountEnabled ? false : true;
    //                 break;
    //             case 'Prebook':
    //                 const today = new Date();
    //                 line.prebookDate = today.toISOString().split('T', 1)[0];
    //                 line.isNotPrebook = false;
    //                 line.wholesalerNotEnabled = false;
    //                 line.wholesalerId = this.primaryWholesaler;
    //                 line.uom = 'Carton';
    //                 line.pricingNotEnabled = true;
    //                 break;
    //             case 'Return':
    //                 line.uom = 'Each';
    //                 line.returnType = true;
    //                 break;
    //             case 'Bill Thru':
    //                 line.wholesalerNotEnabled = false;
    //                 line.wholesalerId = this.primaryWholesaler;
    //                 line.uom = 'Carton';
    //                 line.pricingNotEnabled = true;
    //                 break;
    //             case 'Product Purchase':
    //                 line.uom = 'Each';
    //                 break;
    //             case 'Suggested Order':
    //                 line.wholesalerNotEnabled = false;
    //                 line.wholesalerId = this.primaryWholesaler;
    //                 line.uom = 'Carton';
    //                 line.pricingNotEnabled = true;
    //                 break;
    //             case 'Reimbursable Gratis':
    //                 line.uom = 'Each';
    //                 line.discountNotEnabled = line.productDiscountEnabled ? false : true;
    //                 break;
    //             case 'Non-Reimbursable Gratis':
    //                 line.uom = 'Each';
    //                 line.discountNotEnabled = line.productDiscountEnabled ? false : true;
    //                 break;
    //             case 'POS Placement':
    //                 line.pricingNotEnabled = true;
    //                 line.uomNotEnabled = true;
    //         }

    //         if(value !== '') {
    //             line.cartView = true;
    //         }
    //         else {
    //             line.cartView = false;
    //         }
    //     }
    //     else if(field === 'inStock') {
    //         if(value !== true) {
    //             line.cartView = true;
    //         }
    //         else {
    //             line.cartView = false;
    //             line.itemType = '';
    //         }
    //     }
    //     else if(field === 'uom') {
    //         if(value === 'Carton') {
    //             line.eachPrice = parseFloat(line.unitPrice) / line.perCarton;
    //         }
    //         else {
    //             line.eachPrice = parseFloat(line.unitPrice);
    //         }
    //     }
    //     else if(calcs.includes(field)) {
    //         const valueFloat = value !== '' ? parseFloat(value) : 0;
    //         const unitPriceFloat = line.unitPrice !== '' && line.unitPrice !== undefined ? parseFloat(line.unitPrice) : 0;
    //         const quantityFloat = line.quantity !== '' && line.quantity !== undefined ? parseFloat(line.quantity) : 0;
    //         const discountFloat = line.discount !== '' && line.discount !== undefined ? parseFloat(line.discount) : 0;

    //         //totalPrice (Total__c) is set via a workflow but want to show calculations in real-time
    //         switch(field) {
    //             case 'unitPrice':
    //                 line.totalPrice = (valueFloat * quantityFloat) - discountFloat;
    //                 line.unitPrice = valueFloat !== 0 ? valueFloat : null;
    //                 break;
    //             case 'quantity':
    //                 line.totalPrice = (unitPriceFloat * valueFloat) - discountFloat;
    //                 line.quantity = valueFloat !== 0 ? valueFloat : null;
    //                 break;
    //             case 'discount':
    //                 line.totalPrice = (unitPriceFloat * quantityFloat) - valueFloat;
    //                 line.discount = valueFloat !== 0 ? valueFloat : null;
    //                 break;
    //             case 'shelfPrice':
    //                 line.shelfPrice = valueFloat !== 0 ? valueFloat : null;
    //                 break;
    //         }
    //     }

    //     //Necessary for allowed editing
    //     this.lineItems[familyIndex].products[productIndex] = line;
    //     let lineItemUpdates = this.lineItemUpdates;

    //     for(let i=0; i < lineItemUpdates.length; i++) {
    //         if(lineItemUpdates[i].recordId === line.recordId) {
    //             this.lineItemUpdates.splice(i, 1);
    //         }
    //     }

    //     this.lineItemUpdates.push(line);
    // }

    // newItem() {
    //     if(this.lineItemUpdates.length > 0) {
    //         this.spinner = true;
    //         this.save(this.lineItemUpdates, false, true);
    //     }
    //     else {
    //         this.displayMain = false;
    //     }
    // }

    // cloneLine(event) {
    //     this.spinner = true;
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;
    //     let lines = [];
    //     const line = this.lineItems[familyIndex].products[productIndex];
    //     let clonedLine = { ...line };

    //     clonedLine.recordId = null;
    //     //Push both in case a change was made before saving
    //     lines.push(line, clonedLine);

    //     this.save(lines, true, false);
    // }

    // removeLine(event) {
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;

    //     this.lineItems[familyIndex].products[productIndex].confirmDelete = true;
    // }

    // yesDeleteLine(event) {
    //     this.spinner = true;
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;
    //     const recordId = this.lineItems[familyIndex].products[productIndex].recordId;

    //     if(recordId) {
    //         deleteRecord({
    //             'recordId': this.lineItems[familyIndex].products[productIndex].recordId
    //         })
    //         .then(results => {
    //             if(results === true) {
    //                 this.showToast('The line item has been deleted.', 'success', 'dismissable');
    //                 this.resetAccordion(familyIndex);
    //             }
    //             else {
    //                 this.showToast('There was a problem deleting this record. Please try again.', 'error', 'sticky');
    //             }
    //         })
    //         .catch(error => {
    //             this.showToast(error, 'error', 'sticky');
    //         })
    //         .finally(() => {
    //             const deleteIndex = this.lineItemUpdates.findIndex(record => record === recordId);

    //             this.lineItemUpdates.splice(deleteIndex, 1);
    //             this.lineItems[familyIndex].products.splice(productIndex, 1);
    //             this.spinner = false;
    //         });
    //     }
    //     else {
    //         this.lineItems[familyIndex].products.splice(productIndex, 1);
    //         this.spinner = false;
    //         this.resetAccordion(familyIndex);
    //     }
    // }

    // resetAccordion(index) {
    //     let title = this.lineItems[index].name;
    //     let name = title.split(' - ')[0];
    //     let count = title.split(' - ').pop() - 1;

    //     this.lineItems[index].name = name + ' - ' + count;
    // }

    // noDeleteLine(event) {
    //     const familyIndex = event.target.dataset.index1;
    //     const productIndex = event.target.dataset.index2;

    //     this.lineItems[familyIndex].products[productIndex].confirmDelete = false;
    // }

    // submit() {
    //     this.spinner = true;
    //     this.save(this.lineItemUpdates, false, false);
    // }

    // save(lines, clone, newItem) {
    //     updateRecords({
    //         'lineItems': JSON.stringify(lines)
    //     })
    //     .then(results => {
    //         if(results !== 'SUCCESS') {
    //             this.showToast(results, 'error', 'dismissable');
    //         }
    //         else {
    //             this.showToast('The line items have been updated.', 'success', 'dismissable');
                
    //             const refreshWorkOrder = new CustomEvent('save', {});
    //             this.dispatchEvent(refreshWorkOrder);
    //         }
    //     })
    //     .catch(error => {
    //         this.showToast(error, 'error', 'dismissable');
    //     })
    //     .finally(() => {
    //         if(clone) {
    //             this.lineItems = [];
    //             this.init(true);
    //         }
    //         else if(newItem) {
    //             this.displayMain = false;
    //         }
    //         else {
    //             this.spinner = false;
    //         }
    //     });
    // }

    // showToast(message, variant, mode) {
    //     const toastEvent = showToast(message, variant, mode);
    //     this.dispatchEvent(toastEvent);
    // }

    // closeHandler() {
    //     this.lineItems = [];
    //     this.init(true);
    //     this.displayMain = true;
    // }

    // selectHandler(event) {
    //     const detail = event.detail;
    //     this.lineUpdateHandler(detail);
    // }
}