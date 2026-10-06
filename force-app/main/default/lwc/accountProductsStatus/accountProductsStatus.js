import {LightningElement, api, wire, track} from 'lwc';
import {getRecord, getRecordNotifyChange} from 'lightning/uiRecordApi';
import RECORD_TYPE from '@salesforce/schema/Account.RecordType.Name';
import PARENT_ID from '@salesforce/schema/Account.ParentId';
import getProducts from '@salesforce/apex/AccountProductsStatusController.getProducts';
import upsertProducts from '@salesforce/apex/AccountProductsStatusController.upsertProducts';
import {showToast} from 'c/utils';

export default class AccountProductsStatus extends LightningElement {
    @api recordId;
    @api objectApiName;
    accountId;
    appointmentId;
    spinner = false;
    recordType = '';
    @track groupedProducts = [];
    @track updatedProducts = [];

    connectedCallback() {
        switch(this.objectApiName) {
            case 'Account':
                this.accountId = this.recordId;
                break;
            case 'ServiceAppointment':
                this.appointmentId = this.recordId;
                break;
        }
    }

    @wire(getRecord, {
        recordId: '$appointmentId',
        fields: ['ServiceAppointment.ParentRecordId']
    })
    wiredRecord({data}) {
        if(data) {
            this.accountId = data.fields.ParentRecordId.value;
        }
    }

    @wire(getRecord, {
        'recordId': '$accountId',
        'fields': [RECORD_TYPE, PARENT_ID]
    })
    account({data}) {
        if(data) {
            let accountId = data.id;
            let parentId = data.fields.ParentId.value;
            this.recordType = data.recordTypeInfo.name;
            this.findProducts(accountId, parentId, this.recordType);
        }
    }

    findProducts(accountId, parentId, recordType) {
        this.spinner = true;

        getProducts({
            'accountId': accountId,
            'parentId': parentId,
            'recordType': recordType
        })
        .then(results => {
            let families = new Set();

            for(var i=0; i < results.length; i++) {
                families.add(results[i].family);
            }

            for(let name of families) {
                let family = {
                    'family': name,
                    'products': []
                };

                for(var i=0; i < results.length; i++) {
                    if(name === results[i].family) {
                        family.products.push(results[i]);
                    }
                }

                this.groupedProducts.push(family);
            }
        })
        .catch(error => {
            this.showToast(error, 'error', 'sticky');
        })
        .finally(() => {
            this.spinner = false;
        });
    }

    get wholesaler() {
        return this.recordType === 'Wholesaler' ? true : false;
    }

    get retailer() {
        return this.recordType === 'Retailer' ? true : false;
    }

    get headquarter() {
        return this.recordType === 'Headquarter' ? true : false;
    }

    appliedHandler(event) {
        if(this.retailer !== true) {
            this.changeHandler(event);
        }
        else {
            event.preventDefault();
        }
    }

    changeHandler(event) {
        const groupIndex = event.target.dataset.index1;
        const productIndex = event.target.dataset.index2;
        const field = event.target.name;
        let accProd = this.groupedProducts[groupIndex].products[productIndex];
        let updatedProducts = this.updatedProducts;
        let value;

        if(field === 'applied') {
            value = event.target.checked;
        }
        else {
            value = event.target.value;
        }

        accProd[field] = value;

        for(let i=0; i < updatedProducts.length; i++) {
            if(updatedProducts[i].productId === accProd.productId && updatedProducts[i].accountId === accProd.accountId) {
                this.updatedProducts.splice(i, 1);
            }
        }
        
        this.groupedProducts[groupIndex].products[productIndex] = accProd;
        this.updatedProducts.push(accProd);
    }

    saveProducts() {
        this.spinner = true;

        upsertProducts({
            'rawProducts': JSON.stringify(this.updatedProducts),
            'accountId': this.accountId
        })
        .then(results => {
            if(results !== 'SUCCESS') {
                this.showToast(results, 'error', 'sticky');
            }
            else {
                getRecordNotifyChange([{'recordId': this.accountId}]);
                this.showToast('Products saved', 'success', 'dismissable');
            }
        })
        .catch(error => {
            this.showToast(error, 'error', 'sticky');
        })
        .finally(() => {
            this.spinner = false;
        });
    }

    showToast(message, variant, mode) {
        const toastEvent = showToast(message, variant, mode);
        this.dispatchEvent(toastEvent);
    }
}