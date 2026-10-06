import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class TpbRelatedWholesalerDataSource extends LightningElement {
  @api recordId;

  @api get relatedAccountRecord() {
    return this.relatedAccount;
  }

  @api get retailerId() {
    if (this.relatedAccount) {
      return this.relatedAccount.fields.Retailer__c.value;
    }
    return undefined;
  }

  relatedAccount;
  relatedAccountRes;
  @wire(getRecord, {
    recordId: '$recordId',
    fields: [
      'Related_Account__c.Id',
      'Related_Account__c.Wholesaler__c',
      'Related_Account__c.Retailer__c'
    ]
  })
  getRelatedAccountRecord(res) {
    const { data, error } = res;

    if (data) {
      this.relatedAccount = data;
      this.relatedAccountRes = res;
      this.dispatchEvent(
        new CustomEvent('dataload', {
          detail: { relatedAccount: this.relatedAccount }
        })
      );
    } else if (error) {
      this.error = error;
    }
  }
}