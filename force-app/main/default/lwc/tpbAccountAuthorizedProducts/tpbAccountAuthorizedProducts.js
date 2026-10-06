import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import RECORD_TYPE from '@salesforce/schema/Account.RecordType.Name';
import PARENT_ID from '@salesforce/schema/Account.ParentId';
import userID from '@salesforce/user/Id';
import PROFILE_ID from '@salesforce/schema/User.ProfileId';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import RELATED_ACCOUNTED from '@salesforce/schema/Visit.AccountId';
import RELATED_VISIT_TYPE from '@salesforce/schema/Visit.TPB_VisitType__c';
import searchProducts from '@salesforce/apex/TPB_AccountAuthorizedProducts.searchProducts';
import upsertProducts from '@salesforce/apex/TPB_AccountAuthorizedProducts.upsertProducts';
import { showToast } from 'c/utils';

export default class TpbAccountAuthorizedProducts extends LightningElement {
  @api recordId;
  @api objectApiName;
  accountId;
  visitId;
  spinner = false;
  get isShowSaveButton() {
    return (
      this.profileName === 'System Administrator' ||
      this.profileName === 'Account Management' ||
      this.profileName === 'CG Cloud Mobile - RSM' ||
      this.profileName === 'CG Cloud Mobile - TSM'
    );
  }
  recordType = '';
  profileName = '';
  @track groupedProducts = [];
  @track updatedProducts = [];

  connectedCallback() {
    if (this.objectApiName === 'Account') {
      this.accountId = this.recordId;
    } else if (this.objectApiName === 'Visit') {
      this.visitId = this.recordId;
    }
  }

  @wire(getRecord, {
    recordId: '$accountId',
    fields: [RECORD_TYPE, PARENT_ID]
  })
  account({ data }) {
    if (data) {
      let accountId = data.id;
      this.recordType = data.recordTypeInfo.name;
      if (accountId) {
        this.findProducts(accountId);
      }
    }
  }

  @wire(getRecord, {
    recordId: '$visitId',
    fields: [RELATED_ACCOUNTED, RELATED_VISIT_TYPE]
  })
  visit({ data }) {
    if (data) {
      this.accountId = data.fields.AccountId.value;
      this.recordType = data.fields.TPB_VisitType__c.value;
    }
  }

  @wire(getRecord, { recordId: userID, fields: [PROFILE_ID, PROFILE_NAME] })
  userDetails({ error, data }) {
    if (data) {
      this.profileName = data.fields.Profile.value.fields.Name.value;
    } else if (error) {
      this.error = error;
    }
  }

  findProducts(accountId) {
    this.spinner = true;
    searchProducts({
      accountId: accountId,
      strRecordType: this.recordType
    })
      .then((results) => {
        let families = new Set();

        for (let i = 0; i < results.length; i++) {
          families.add(results[i].family);
        }

        for (let name of families) {
          let family = {
            family: name,
            products: []
          };

          for (let i = 0; i < results.length; i++) {
            if (name === results[i].family) {
              family.products.push(results[i]);
            }
          }

          this.groupedProducts.push(family);
        }
      })
      .catch((error) => {
        this.showToast(error, 'error', 'sticky');
      })
      .finally(() => {
        this.spinner = false;
      });
  }

  get wholesaler() {
    return this.recordType === 'Wholesaler' ? true : false;
  }

  get headquarter() {
    return this.recordType === 'Headquarter' ? true : false;
  }

  appliedHandler(event) {
    this.changeHandler(event);
  }

  changeHandler(event) {
    const groupIndex = event.target.dataset.index1;
    const productIndex = event.target.dataset.index2;
    const field = event.target.name;
    let accProd = this.groupedProducts[groupIndex].products[productIndex];
    let updatedProducts = this.updatedProducts;
    let value;

    if (field === 'applied') {
      value = event.target.checked;
    } else {
      value = event.target.value;
    }

    accProd[field] = value;

    for (let i = 0; i < updatedProducts.length; i++) {
      if (
        updatedProducts[i].productId === accProd.productId &&
        updatedProducts[i].accountId === accProd.accountId
      ) {
        this.updatedProducts.splice(i, 1);
      }
    }

    this.groupedProducts[groupIndex].products[productIndex] = accProd;
    this.updatedProducts.push(accProd);
  }

  saveProducts() {
    this.spinner = true;

    upsertProducts({
      rawProducts: JSON.stringify(this.updatedProducts),
      accountId: this.accountId
    })
      .then((results) => {
        if (results !== 'SUCCESS') {
          this.showToast(results, 'error', 'sticky');
        } else {
          getRecordNotifyChange([{ recordId: this.accountId }]);
          this.showToast('Products saved', 'success', 'dismissible');
        }
      })
      .catch((error) => {
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