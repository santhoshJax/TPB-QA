import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class TpbOrderItemTypeSelector extends LightningElement {
  _value = '';
  @api get value() {
    return this._value;
  }

  get label() {
    return {
      Type: 'Type for Scanner'
    };
  }

  // NOTICE: the OrderItem doesn't have Record Type officially.
  // I have no idea why it works with Order api name
  @wire(getObjectInfo, { objectApiName: 'Order' })
  orderItemInfo;

  @wire(getPicklistValues, {
    recordTypeId: '$orderItemInfo.data.defaultRecordTypeId',
    fieldApiName: 'OrderItem.TPB_Type__c'
  })
  typePicklistValues;

  get options() {
    if (!this.typePicklistValues?.data) {
      return [];
    }

    if (!this._value && this.typePicklistValues.data.defaultValue) {
      this._value = this.typePicklistValues.data.defaultValue.value;
    }

    return this.typePicklistValues.data.values.map((item) => {
      return {
        label: item.label,
        value: item.value
      };
    });
  }

  handleValueChange = (event) => {
    this._value = event.detail.value;
    // @api onchange event
    this.dispatchEvent(new CustomEvent('change', { detail: this._value }));
  };
}