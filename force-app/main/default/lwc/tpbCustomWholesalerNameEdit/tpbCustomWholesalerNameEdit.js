import { LightningElement, api } from 'lwc';
import getRelatedAccountsByRetailerId from '@salesforce/apex/TPB_MassPrebookController.getRelatedAccountsByRetailerId';

export default class TpbCustomWholesalerNameEdit extends LightningElement {
  @api fieldName;
  @api label;
  @api relatedAccountId;
  @api wholesalerName;

  retailerId;

  relatedAccounts;
  relatedAccountRecords;

  showLookup = false;

  loadingOfRelatedAccounts = false;
  get loading() {
    return this.loadingOfRelatedAccounts;
  }

  async handleShowLookup() {
    // this triggers to load lookup data
    this.showLookup = true;
  }

  async loadRelatedAccounts() {
    try {
      const data = await getRelatedAccountsByRetailerId({
        strRetailerAccountId: this.retailerId
      });
      this.relatedAccountRecords = data;
      this.relatedAccounts = data.map((record) => {
        return {
          relatedAccountId: record.Id,
          retailerId: record.Retailer__c,
          wholesalerId: record.Wholesaler__c,
          wholesalerName: record.Wholesaler__r.Name
        };
      });
    } catch (error) {
      this.error = error;
    }
  }

  async handleDataLoad(event) {
    this.loadingOfRelatedAccounts = true;

    const relatedAccount = event.detail.relatedAccount;
    this.retailerId = relatedAccount.fields.Retailer__c.value;
    await this.loadRelatedAccounts();

    this.loadingOfRelatedAccounts = false;
  }

  // combobox {
  _value; // relatedAccountId

  // return value is string only
  get value() {
    if (this._value) {
      return this.getRelatedAccountById(this._value);
    }

    if ((this.relatedAccounts || []).length > 0) {
      return this.getRelatedAccountById(this.relatedAccountId);
    }

    return null;
  }

  getRelatedAccountById(id) {
    const fn = (item) => item.relatedAccountId === id;
    return (this.relatedAccounts || []).find(fn);
  }

  get isOptionsReady() {
    return !this.loading && Array.isArray(this.relatedAccounts);
  }

  get options() {
    return (this.relatedAccounts || []).map((item) => {
      return {
        label: item.wholesalerName,
        value: item.relatedAccountId
      };
    });
  }

  // combobox }

  handleChange(event) {
    this._value = event.detail.value;

    const relatedAccountRecord = this.relatedAccountRecords.find(
      (record) => record.Id === this._value
    );

    this.dispatchEvent(
      new CustomEvent('lookupcellchange', {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          fieldName: this.fieldName,
          relatedAccountRecord: relatedAccountRecord
        }
      })
    );

    this.showLookup = false;
  }

  handleBlur() {
    this.showLookup = false;
  }
}