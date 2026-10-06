import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateOrderItems from '@salesforce/apex/TPB_MassPrebookController.updateOrderItems';
import { reduceErrors } from 'c/tpbUtils';

export default class TpbMassPrebookItemDatatable extends LightningElement {
  @api records;
  @api columns;
  @api disabled = false;

  draftValues = [];

  //   handleSave(event) {
  //     console.log('Begin of handleSave');
  //     let draftValues = event.detail.draftValues;
  //     console.log('update values', JSON.stringify(draftValues));

  //     this.draftValues = [];
  //   }

  get myColumns() {
    return this.columns.map((col) => {
      return {
        ...col,
        editable: col.editable && !this.disabled
      };
    });
  }

  loadingOfUpdateRecord = false;
  get loading() {
    return this.loadingOfUpdateRecord;
  }

  showToast(title, type) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        variant: type
      })
    );
  }

  showError(error) {
    this.showToast(reduceErrors(error).join(', '), 'error');
  }

  getRecordById(recordId) {
    return this.records.find((item) => item.id === recordId);
  }

  async handleCellChange(event) {
    let draftValues = event.detail.draftValues;
    let hasChanges = false;

    // validation
    for (const draftValue of draftValues) {
      const record = this.getRecordById(draftValue.id);

      for (const fieldName of Object.keys(draftValue)) {
        // validate qtyOrdered field once it is changed
        if (
          fieldName === 'qtyOrdered' &&
          `${draftValue.qtyOrdered}` !== `${record.qtyOrdered}`
        ) {
          let isValid = true;

          if (Number(draftValue.qtyOrdered) < 0) {
            this.showError(
              'User cannot order less than zero quantity for this product at this store'
            );
            isValid = false;
          }

          if (Number(draftValue.qtyOrdered) > 10000) {
            this.showError(
              'User cannot order more than the max quantity for this product at this store'
            );
            isValid = false;
          }

          if (!isValid) {
            // clean the changes once validation is failed
            this.draftValues = [];

            // return directly without submitting anything
            return;
          }
        }
      }
    }

    // see if any real changes
    for (const draftValue of draftValues) {
      const record = this.getRecordById(draftValue.id);
      for (const fieldName of Object.keys(draftValue)) {
        if (`${record[fieldName]}` !== `${draftValue[fieldName]}`) {
          hasChanges = true;
        }
      }
      draftValue.qtyPlanned = record.qtyPlanned;
      draftValue.qtyMax = record.qtyMax;
    }

    if (hasChanges) {
      const updateRes = await this.updateOrderItems(
        transferDraftValues(draftValues)
      );

      if (updateRes) {
        this.dispatchEvent(new CustomEvent('recordchange', { detail: null }));
      }
    }

    this.draftValues = [];
  }

  async updateOrderItems(draftValues) {
    this.loadingOfUpdateRecord = true;

    try {
      const data = await updateOrderItems({ inputItems: draftValues });

      if (data.result === 'OK') {
        this.showToast('update success', 'success');
        this.loadingOfUpdateRecord = false;
        return true;
      }
      this.showError(data.errorMessage);
    } catch (error) {
      this.showError(error);
    }

    this.loadingOfUpdateRecord = false;
    return false;
  }
}

const mapFieldToAPIField = {
  id: 'orderItemId',
  qtyOrdered: 'qTYOrdered',
  qtyPlanned: 'qTYPlanned',
  qtyMax: 'maxQuantity'
};

function transferDraftValues(draftValues) {
  return draftValues.map((recordValues) => {
    const newRecordValues = {};

    Object.keys(recordValues).forEach((fieldName) => {
      newRecordValues[mapFieldToAPIField[fieldName]] = recordValues[fieldName];
    });

    return newRecordValues;
  });
}