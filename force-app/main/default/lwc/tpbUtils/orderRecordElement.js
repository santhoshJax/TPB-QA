import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import { refreshApex } from '@salesforce/apex';
import searchDataResult from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.searchDataResult';
import searchOrderItems from '@salesforce/apex/TPB_AddInventoryPurchasedForm.searchOrderItems';

import { reduceErrors } from './reduceErrors';

export class OrderRecordElement extends NavigationMixin(LightningElement) {
  get isOrderNotDraft() {
    return this.order?.Status !== 'Draft';
  }

  orderId = '';
  order;
  orderFiles;
  orderRes;
  @wire(searchDataResult, { strRecord: '$recordId' }) loadOrder(response) {
    this.orderRes = response;

    const { error, data } = response;

    if (error) {
      this.showError(error);
      return;
    }

    if (!data) {
      return;
    }

    if (data.result === 'OK') {
      if (data.dataOrder) {
        this.orderId = data.dataOrder.Id;
        this.order = data.dataOrder;
        this.orderFiles = data.dataFile;
        this.dispatchEventOfOrderUpdated();
      }
    } else {
      this.showError(data.errorMessage);
    }
  }

  orderItems;
  orderItemsRes;
  @wire(searchOrderItems, { strOrderId: '$recordId' }) loadOrderItems(
    response
  ) {
    this.orderItemsRes = response;

    const { error, data } = response;

    if (error) {
      this.showError(error);
      return;
    }

    if (!data) {
      return;
    }

    if (data.result === 'OK') {
      this.orderItems = data.data;
      this.dispatchEventOfOrderUpdated();
    } else {
      this.showError(data.errorMessage);
    }
  }

  dispatchEventOfOrderUpdated() {
    document.dispatchEvent(
      new CustomEvent('orderupdated', {
        detail: {
          order: this.order,
          orderItems: this.orderItems
        }
      })
    );
  }

  async refreshData() {
    await refreshApex(this.orderRes);
    await refreshApex(this.orderItemsRes);
    this.dispatchEventOfOrderUpdated();
  }

  showError(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: reduceErrors(error).join(', '),
        variant: 'error'
      })
    );
  }

  showSuccess(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: message,
        variant: 'success'
      })
    );
  }

  navigateToRecordViewPage(recordId) {
    // View a custom object record.
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: recordId,
        objectApiName: 'namespace__ObjectName', // objectApiName is optional
        actionName: 'view'
      }
    });
  }
}