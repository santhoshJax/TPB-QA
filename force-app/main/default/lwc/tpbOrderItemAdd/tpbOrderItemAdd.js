import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { reduceErrors } from 'c/tpbUtils';
import saveOrderDetail from '@salesforce/apex/TPB_AddInventoryPurchasedForm.saveOrderDetail';
import getRecentUnitPrice from '@salesforce/apex/TPB_AddInventoryPurchasedForm.getRecentUnitPrice';

export default class TpbOrderItemAdd extends LightningModal {
  @api orderId;
  @api recordId;
  @api orderItems;

  loading = false;

  // form default values,
  // and client gets its value within form submit event's `event.detail.fields`.
  // other fields that has no definition works as an lightning-record-edit-form field automatically
  @track formData = {
    quantity: {
      value: 1,
      onChange(event) {
        this.formData.quantity.value = event.detail.value;
      }
    },
    unitPrice: {
      value: 0,
      onChange(event) {
        this.formData.unitPrice.value = event.detail.value;
      }
    },
    productId: {
      value: null
    },
    uom: {
      value: 'Carton'
    }
  };

  get labels() {
    return {
      saveButton: 'Add Product'
    };
  }

  get modalTitle() {
    if (!this.recordId) {
      return 'Add Order Product';
    }
    return 'Edit Order Product';
  }

  showToast(...args) {
    return this.template
      .querySelector('[data-dom-id="eventBridge"]')
      .showToast(...args);
  }

  getInputField(fieldName) {
    return [...this.template.querySelectorAll('lightning-input-field')].find(
      (item) => item.fieldName === fieldName
    );
  }

  handleTypeChange(event) {
    const newType = event.detail.value;
    if (newType === 'Return') {
      this.getInputField('UoM__c').value = 'Each';
    } else if (newType === 'Purchase') {
      this.getInputField('UoM__c').value = 'Carton';
    }
  }

  validateForm(fields) {
    // field level checkes
    const inputCmps = [
      ...this.template.querySelectorAll('[data-input-validation="required"]')
    ];
    if (
      !inputCmps.reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();

        if (typeof inputCmp.checkValidity === 'function') {
          return validSoFar && inputCmp.checkValidity();
        }

        return validSoFar;
      }, true)
    ) {
      // ending
      this.showToast({
        title: 'Error',
        message: 'Changes are required to the form.',
        variant: 'error',
        mode: 'sticky'
      });
      return false;
    }

    // business level checks
    if (
      this.orderItems.find(({ product2Id, uoM, type }) => {
        return (
          product2Id === fields.Product2Id &&
          uoM === fields.UoM__c &&
          type === fields.TPB_Type__c
        );
      })
    ) {
      this.showToast({
        title: 'Error',
        message: `The Product with the UoM is already exists in the order products.`,
        variant: 'error'
      });
      return false;
    }

    return true;
  }

  async getUnitPrice(inputOrderId, inputProductId, strUnitType) {
    const res = await getRecentUnitPrice({
      inputOrderId,
      inputProductId,
      strUnitType
    });
    this.formData.unitPrice.value = res;
  }

  async handleProductChange(event) {
    this.formData.productId.value = event.detail.value[0];
    await this.getUnitPrice(
      this.orderId,
      event.detail.value[0],
      this.formData.uom.value
    );
  }

  async handleUomChange(event) {
    this.formData.uom.value = event.detail.value;
    await this.getUnitPrice(
      this.orderId,
      this.formData.productId.value,
      event.detail.value
    );
  }

  async handleSubmit(event) {
    event.preventDefault(); // stop the form from submitting

    this.loading = true;

    const fields = event.detail.fields;

    if (!this.validateForm(fields)) {
      return;
    }

    // NOTICE: UnitPrice for Return keeps negative in value and positive in UI
    if (fields.TPB_Type__c === 'Return') {
      fields.UnitPrice = -1 * Math.abs(fields.UnitPrice);
    }

    const params = {
      strOrderId: this.orderId,
      inputItems: [fields]
    };

    try {
      const res = await saveOrderDetail(params);

      if (res.result === 'OK') {
        this.showToast({
          message: 'Order product is added successfully!',
          variant: 'success'
        });
        this.close('success');
      } else {
        this.showToast({
          // remove the Insert failed... part of message to keep it the same message as single record updates
          message: res.errorMessage.replace(/^Insert failed\.[^,]+, /, ''),
          variant: 'error'
        });
      }
    } catch (error) {
      this.showToast({
        message: reduceErrors(error)
          .join(', ')
          .split(', ')[1]
          .replace('.: []', ''),
        variant: 'error'
      });
    } finally {
      this.loading = false;
    }
  }
}