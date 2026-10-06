import { track, api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class TpbMassPrebookInputQuantity extends LightningModal {
  @api productOptions = [];
  @api minQty = 0;
  @api maxQty = 10000;

  @track formData = {
    quantity: {
      value: 0,
      onChange(event) {
        this.formData.quantity.value = event.detail.value;
      }
    }
  };

  get labels() {
    return {
      title: 'Input Quantities',
      submit: 'Submit',
      minQtyMessage: `User cannot order less than ${this.minQty} quantity for this product at this store`,
      maxQtyMessage: `User cannot order greater than ${this.maxQty} quantity for this product at this store`
    };
  }

  showToast(...args) {
    return this.template
      .querySelector('[data-dom-id="eventBridge"]')
      .showToast(...args);
  }

  validate() {
    const allValid = [
      ...this.template.querySelectorAll('lightning-input')
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if (!allValid) {
      this.showToast({
        title: 'Error',
        message: 'Invalid inputs.',
        variant: 'error',
        mode: 'sticky'
      });
      return false;
    }

    return true;
  }

  async handleSubmit() {
    if (!this.validate()) {
      return;
    }

    this.close({
      success: true,
      quantity: Number(this.formData.quantity.value)
    });
  }
}