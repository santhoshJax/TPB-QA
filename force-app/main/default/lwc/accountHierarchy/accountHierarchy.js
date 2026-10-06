import {LightningElement, api, wire, track} from 'lwc';
import {getRecord, getRecordNotifyChange} from 'lightning/uiRecordApi';
import PARENT_ID from '@salesforce/schema/Account.ParentId';
import getAccounts from '@salesforce/apex/AccountHierarchyController.getAccounts';
import updateAccounts from '@salesforce/apex/AccountHierarchyController.updateAccounts';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
        type: 'url',
        fieldName: 'recordLink',
        label: 'Name',
        initialWidth: 200,
        typeAttributes: {
            label: {
                fieldName: 'accName'
            }
        },
        cellAttributes: {
            iconPosition: 'right',
            iconName: {
                fieldName: 'iconName'
            }
        }
    },
    {
        type: 'text',
        fieldName: 'recordType',
        label: 'Type',
    },
    {
        type: 'text',
        fieldName: 'wholesaleType',
        label: 'P or S',
    },
    {
        type: 'text',
        fieldName: 'ownerName',
        label: 'Owner',
    },
    {
        type: 'text',
        fieldName: 'billingCity',
        label: 'City',
    },
    {
        type: 'text',
        fieldName: 'billingState',
        label: 'State',
    },
    {
        type: 'boolean',
        fieldName: 'cashSales',
        label: 'Cash',
        initialWidth: 50
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{
                label: 'Change Cash Sales',
                name: 'editCashSales'
            }]
        }
    }
]

export default class AccountHierarchy extends LightningElement {
    @api recordId;
    spinner = false;
    recordType = '';
    parentId = '';
    @track columns = COLUMNS;
    @track accounts = [];

    renderedCallback() {
        const grid =  this.template.querySelector('lightning-tree-grid');
        grid.expandAll();
    }

    @wire(getRecord, {
        'recordId': '$recordId',
        'fields': [PARENT_ID]
    })
    account({data}) {
        if(data) {
            let accountId = data.id;
            this.recordType = data.recordTypeInfo.name;
            this.parentId = data.fields.ParentId.value;
            this.findAccounts(accountId, this.recordType, this.parentId);
        }
    }

    findAccounts(accountId, recordType, parentId) {
        getAccounts({
            'accountId': accountId,
            'recordType': recordType,
            'parentId': parentId
        })
        .then(results => {
            let accounts = JSON.parse(results);
            this.accounts = accounts;
        })
        .catch(error => {
            this.showToast(error, 'error');
        })
        .finally(() => {
            this.spinner = false;
            getRecordNotifyChange([{'recordId': this.recordId}]);
        });
    }

    changeAccount(event) {
        let row = event.detail.row;

        if(row.recordType !== 'Wholesaler') {
            this.spinner = true;
            let cashSales = row.cashSales !== true ? true : false;
            let accountUpdates = [{
                'Id': row.accId,
                'Cash_Sales__c': cashSales
            }];
    
            if(row.hasChildren) {
                let accounts = this.accounts;
    
                for(var i=0; i < accounts.length; i++) {
                    if(row.accId === accounts[i].accId) {
                        let children = accounts[i]._children;
    
                        for(var k=0; k < children.length; k++) {
                            if(cashSales !== children[k].cashSales && children[k].recordType !== 'Wholesaler') {
                                let child = {
                                    'Id': children[k].accId,
                                    'Cash_Sales__c': cashSales
                                }
        
                                accountUpdates.push(child);
                            }
                        }
                    }
                }
            }
    
            updateAccounts({'accounts': accountUpdates})
            .then(results => {
                this.findAccounts(this.recordId, this.recordType, this.parentId);
                this.showToast(results, 'success');
            })
            .catch(error => {
                this.showToast(error, 'error');
                this.spinner = false;
            });
        }
        else {
            this.showToast('You cannot modify this field for Wholesalers', 'info');
        }
    }

    showToast(message, variant) {
        const toastEvent = new ShowToastEvent({
            'message': message,
            'variant': variant
        });
        this.dispatchEvent(toastEvent);
    }
}