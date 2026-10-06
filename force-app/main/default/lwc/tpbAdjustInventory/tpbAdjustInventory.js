import { LightningElement, track, wire } from 'lwc';
// import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchUserState from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.searchUserState';
import scannedProduct from '@salesforce/apex/TPB_AdjustInventory.scannedProduct';
import { reduceErrors } from 'c/tpbUtils';
import upsertInventory from '@salesforce/apex/TPB_AdjustInventory.upsertInventory';

const getProductInitialData = () => ({
  inventoryBalance: '',
  inventoryId: '',
  productId: '',
  productName: '',
  userId: ''
});

export default class TpbAdjustInventory extends LightningElement {
  @wire(searchUserState)
  userStateRes;

  async loadProductWithInventory() {
    if (!(this.product.code || this.productLookup.value) || !this.state.value) {
      return;
    }

    const response = await scannedProduct({
      strCode: this.product.code,
      strState: this.state.value,
      strProductId: this.productLookup.value
    });

    const { result, errorMessage } = response;

    if (result !== 'OK') {
      this.showError(errorMessage);
      throw new Error('Cannot find the record');
    }

    this.product.setData(response);
  }

  @track state = {
    value: '',
    async onChange(event) {
      this.state.value = event.detail.value;
      await this.loadProductWithInventory();
    }
  };

  get productName() {
    return this.product.data.productName;
  }

  get inventoryBalance() {
    if (typeof this.product.draftValues.inventoryBalance !== 'undefined') {
      return this.product.draftValues.inventoryBalance;
    }

    return this.product.data.inventoryBalance;
  }

  @track product = {
    code: '',
    editable: false,
    data: getProductInitialData(),
    draftValues: {},
    setData(newValue) {
      // reset draft values
      this.resetDraftValues();

      // set new values
      Object.getOwnPropertyNames(this.data).forEach((propName) => {
        if (typeof newValue[propName] !== 'undefined') {
          this.data[propName] = newValue[propName];
        }
      });
    },
    resetDraftValues() {
      this.draftValues = {};
    },
    reset() {
      this.code = '';
      this.draftValues = {};
    }
  };

  @track adjustMode = {
    options: [
      {
        label: 'By scanning',
        value: 'scan'
      },
      {
        label: 'By lookup',
        value: 'lookup'
      }
    ],
    value: 'scan',
    reset() {
      this.value = 'scan';
    }
  };

  @track productLookup = {
    value: '',
    reset() {
      this.value = '';
    }
  };

  get isAdjustModeVisible() {
    return this.state.value;
  }

  get isScanVisible() {
    return this.state.value && this.adjustMode.value === 'scan';
  }

  get isLookupProductVisible() {
    return this.state.value && this.adjustMode.value === 'lookup';
  }

  get isEditorVisible() {
    return (
      !!this.state.value && !!(this.product.code || this.productLookup.value)
    );
  }

  get isEditorDisabled() {
    return !this.product.editable;
  }

  resetEditorVisible() {
    this.product.code = '';
    this.product.setData(getProductInitialData());
    this.productLookup.value = '';
  }

  get stateOptions() {
    if (!this.userStateRes.data) {
      return null;
    }

    const { data: res } = this.userStateRes;

    if (res && res.result === 'OK') {
      return Object.values(res.data)
        .sort()
        .map((item) => {
          return { label: item, value: item };
        });
    }

    return null;
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

  getFields() {
    return {
      ...this.product.data,
      inventoryOldBalance: this.product.data.inventoryBalance || 0, // api needs number
      inventoryBalance: this.inventoryBalance, // use getter to dynamically get value
      state: this.state.value
    };
  }

  // this doesn't work
  //   closeQuickAction() {
  //     this.dispatchEvent(new CloseActionScreenEvent());
  //   }

  onAdjustModeChange(event) {
    this.adjustMode.value = event.detail.value;
    this.onCancel();
  }

  async onScan(event) {
    const { code } = event.detail;

    if (!code) {
      return;
    }

    this.product.code = code;
    await this.loadProductWithInventory();
    this.product.editable = true;
  }

  handleProductLookupFormSubmit(event) {
    event.preventDefault();
    return false;
  }

  async handleProductLookupChange(event) {
    this.productLookup.value = event.detail.value[0] || '';
    await this.loadProductWithInventory();
    this.product.editable = true;
  }

  async onInventoryBalanceChange(event) {
    this.product.draftValues.inventoryBalance = event.detail.value;
  }

  async onCancel() {
    this.product.editable = false;

    // this.closeQuickAction();
    this.resetEditorVisible();
  }

  validate() {
    const inventoryBalanceCmp = this.template.querySelector(
      '[data-id="formField-inventoryBalance"]'
    );
    inventoryBalanceCmp.reportValidity();

    if (!inventoryBalanceCmp.checkValidity()) {
      return false;
    }

    return true;
  }

  async onSave() {
    const fields = this.getFields();

    if (!this.validate()) {
      return;
    }

    const response = await upsertInventory({ item: fields });

    const { result, errorMessage } = response;

    if (result !== 'OK') {
      this.showError(errorMessage);
      return;
    }

    this.product.editable = false;

    this.showSuccess('Balance updated');

    // refresh the data
    await this.loadProductWithInventory();
  }
}