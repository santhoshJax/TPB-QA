import { api } from 'lwc';
import {
  OrderRecordElement,
  sleep,
  getOrderItemsSubtotal,
  formatUSD
} from 'c/tpbUtils';
import completeOrder from '@salesforce/apex/TPB_AddInventoryPurchasedForm.completeOrder';
import TpbConfirm from 'c/tpbConfirm';

export default class TpbAddInventoryPurchasedForm extends OrderRecordElement {
  _recordId = '';

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value = '') {
    this._recordId = value;
  }

  loadingOfCheck = false;
  loadingOfComplete = false;
  get loading() {
    return this.loadingOfCheck || this.loadingOfComplete;
  }

  // is datatable having changes
  isDatatableChanging = false;

  get title() {
    if (this.order?.data) {
      return 'Edit Inventory Order';
    }
    return 'Create Inventory Order';
  }

  get disablePlaceOrder() {
    return (
      !(this.recordId && this.order?.Status === 'Draft') ||
      this.isDatatableChanging ||
      this.loading
    );
  }

  connectedCallback() {
    window.addEventListener('popstate', () => {
      window.location.reload();
    });
  }

  onDatatableCellChange() {
    this.isDatatableChanging = true;
  }

  onDatatableSave() {
    this.isDatatableChanging = false;
  }

  onDatatableCancel() {
    this.isDatatableChanging = false;
  }

  async validate() {
    // validate headers field by field
    const headerCmp = this.template.querySelector(
      'c-tpb-add-inventory-order-headers'
    );
    headerCmp.reportValidity();
    if (!headerCmp.checkValidity()) {
      return false;
    }

    // validate attachment
    if (!this.orderFiles || this.orderFiles.length === 0) {
      this.showError('Please upload the invoice at "Attach receipt".');
      return false;
    }

    if (this.orderItems && this.orderItems.length === 0) {
      this.showError(
        'The order is empty, please add some products to the order.'
      );
      return false;
    }

    // validate prices
    const orderAmountCents = formatUSD(this.order.External_Amount__c);
    const orderSubtotalCents = formatUSD(
      getOrderItemsSubtotal(this.orderItems)
    );

    if (orderAmountCents !== orderSubtotalCents) {
      this.showError(
        'Invoice total and inventory value total do not match. Please review and correct inventory input.'
      );
      return false;
    }

    // validate UoM of Each or Case
    const isUoMInvalid = !!this.orderItems.find((orderItem) => {
      return ['Each', 'Case'].includes(orderItem.uoM);
    });
    if (isUoMInvalid) {
      const confirm = await this.showUoMInvalidMessage();

      if (!confirm) {
        return false;
      }
    }

    return true;
  }

  async showUoMInvalidMessage() {
    const res = await TpbConfirm.open({
      size: 'medium',
      content:
        'Are you sure you have purchased an Each or Case item? Please review your entries before completing your order.',
      labelYes: "I'm Sure",
      labelNo: 'Back'
    });

    return res;
  }

  handleOrderCreated(e) {
    this._recordId = e.detail;
  }

  async saveHeaders() {
    const headersCmp = this.template.querySelector(
      'c-tpb-add-inventory-order-headers'
    );

    try {
      return await headersCmp.save({ showSuccessMsg: false });
    } catch (e) {
      this.showError(
        'Something wrong to save the order, please refresh and try again'
      );
      return false;
    }
  }

  async handleSaveAndCheckOrder() {
    this.loadingOfCheck = true;

    const saveHeaderRes = await this.saveHeaders();

    if (!saveHeaderRes) {
      this.loadingOfCheck = false;
      return;
    }

    await this.refreshData();

    const isValid = await this.validate();
    if (isValid) {
      this.showSuccess('Order form is valid');
    }

    this.loadingOfCheck = false;
  }

  async handlePlaceOrder() {
    this.loadingOfComplete = true;

    const saveHeaderRes = await this.saveHeaders();

    if (!saveHeaderRes) {
      this.loadingOfComplete = false;
      return;
    }

    await this.refreshData();

    const isValid = await this.validate();
    if (!isValid) {
      this.loadingOfComplete = false;
      return;
    }

    try {
      const completeOrderRes = await completeOrder({
        strOrderId: this.recordId
      });

      if (completeOrderRes.result === 'OK') {
        this.showSuccess('Order placed');
        await sleep(3000);
        this.navigateToRecordViewPage(this.order.Related_Visit__c);
      } else {
        this.showError(completeOrderRes.errorMessage);
      }
    } catch (error) {
      this.showError(error);
    }

    this.loadingOfComplete = false;
  }
}