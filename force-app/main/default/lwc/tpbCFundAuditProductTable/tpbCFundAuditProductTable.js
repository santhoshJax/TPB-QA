// LWC
import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Apex
import { refreshApex } from '@salesforce/apex';
import getCFundAuditProducts from '@salesforce/apex/TPB_AddCFundAuditService.getCFundAuditProducts';
import addScannedProduct from '@salesforce/apex/TPB_AddCFundAudit.addScannedProduct';
import deleteCFundAuditProduct from '@salesforce/apex/TPB_AddCFundAuditService.deleteCFundAuditProduct';
import updateCFundAuditProduct from '@salesforce/apex/TPB_AddCFundAuditService.updateCFundAuditProduct';
// Custom Codes
import { reduceErrors } from 'c/tpbUtils';
import {
  COLUMNS,
  TABLE_INDEX_COL_WIDTH
} from './tpbCFundAuditProductTable-utils';
import { fen } from 'c/tpbUtils';

export default class TpbCFundAuditProductTable extends LightningElement {
  // recordId of C-Fund Audit
  @api recordId;
  _recordId = '';

  productItems;
  actualProductOnHand = 0;
  actualProductOnHandTwo = 0;
  @api disabled;
  @api state;

  tableIndexColWidth = TABLE_INDEX_COL_WIDTH;

  get tableRecords() {
    if (!this.products) {
      return [];
    }

    return this.products
      .map((item) => item)
      .sort((a, b) => a.productName.localeCompare(b.productName));
  }

  // Apex data: OrderId, Id, Product2.Name, Quantity, UnitPrice, UoM__c
  columns = COLUMNS;

  draftValues = [];

  get tableColumnWidths() {
    const dict = {};

    this.columns.forEach((col) => {
      let fieldName = col.fieldName;

      if (!col.fieldName && col.label === 'Quick Action') {
        fieldName = 'quickAction';
      }

      dict[fieldName] = col.fixedWidth || col.initialWidth || 'auto';
    });

    return dict;
  }

  get tableColumns() {
    return this.columns
      .map((col) => {
        const actionCols = ['action', 'button'];
        if (this.disabled && actionCols.includes(col.type)) {
          // editable only when order is draft
          return null;
        }

        // make editable field conditional if field is editable, otherwise no need to edit
        return {
          ...col,
          editable: col.editable === true ? !this.disabled : false
        };
      })
      .filter((col) => !!col);
  }

  products;
  productsRep;
  @wire(getCFundAuditProducts, {
    strCFundAuditId: '$_recordId',
    strState: '$state'
  })
  getProducts(response) {
    this.productsRep = response;
    const { data, error } = response;
    if (error) {
      this.showError(error);
    } else if (data) {
      if (data.result === 'OK') {
        this.products = data.data;
        let totalAmount = 0;
        let totalAmountTwo = 0;
        for (let i = 0; i < data.data.length; i++) {
          totalAmount += data.data[i].totalAmount;
          if (
            data.data[i].expectedQuantity != null &&
            data.data[i].unitPrice != null
          ) {
            totalAmountTwo +=
              fen(data.data[i].expectedQuantity) * data.data[i].unitPrice;
          }
        }

        this.actualProductOnHand = parseFloat(totalAmount).toFixed(2);
        this.actualProductOnHandTwo = (totalAmountTwo / 100).toFixed(2);
        this.dispatchEvent(
          new CustomEvent('auditproducts', {
            detail: {
              totalAmount: parseFloat(totalAmount).toFixed(2),
              value: this.state
            }
          })
        ); // TODO: change auditId
      } else {
        this.showError(data.errorMessage);
      }
    }
  }

  connectedCallback() {
    this._recordId = this.recordId;
  }

  handleResize(event) {
    const sizes = event.detail.columnWidths;
    const colCmps = this.template.querySelectorAll(
      'table[data-name="totalTable"] thead th'
    );

    if (sizes?.length > 0 && colCmps?.length > 0) {
      sizes.forEach((size, index) => {
        colCmps[index + 1].width = size;
      });
    }

    const tableWidth =
      this.tableIndexColWidth +
      sizes.reduce((tableW, colW) => tableW + colW, 0);
    const tableCmp = this.template.querySelector(
      'table[data-name="totalTable"]'
    );
    if (tableCmp) {
      tableCmp.style.width = `${tableWidth}px`;
    }
  }

  refreshData() {
    refreshApex(this.productsRep);
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

  handleAuditCreated(e) {
    this._recordId = e.detail;
  }

  showError(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: reduceErrors(error).join(', '),
        variant: 'error'
      })
    );
  }

  async handleRowAction(event) {
    const { action, row } = event.detail;
    switch (action.name) {
      case 'delete':
        await this.deleteRow(row);
        break;
      default:
    }
  }

  async deleteRow(row) {
    const ok = await LightningConfirm.open({
      message: 'Are you sure about deleting the record?',
      variant: 'headerless',
      label: 'Remove'
      // setting theme would have no effect
    });

    if (ok) {
      const deleteRes = await deleteCFundAuditProduct({
        strCFundAuditProductId: row.id
      });
      if (deleteRes.result === 'OK') {
        this.showSuccess('Record is deleted.');
      } else {
        this.showError(deleteRes.errorMessage);
      }

      await this.refreshData();
    }
  }

  /**
   *
   * @param {*} event
   */
  async handleSave(event) {
    try {
      // Update all records in parallel thanks to the UI API
      let updateDataValue = event.detail.draftValues;
      let isUpdate = true;
      if (updateDataValue && updateDataValue.length > 0) {
        for (let i = 0; i < updateDataValue.length; i++) {
          let hasBarPropertyQuantity = Object.prototype.hasOwnProperty.call(
            updateDataValue[i],
            'quantity'
          );
          //   let hasBarPropertyUnitPrice = Object.prototype.hasOwnProperty.call(
          //     updateDataValue[i],
          //     'unitPrice'
          //   );

          if (
            hasBarPropertyQuantity &&
            (parseFloat(updateDataValue[i].quantity) < 0 ||
              !updateDataValue[i].quantity)
          ) {
            isUpdate = false;
            break;
          }
          //   if (
          //     hasBarPropertyUnitPrice &&
          //     (parseFloat(updateDataValue[i].unitPrice) <= 0 ||
          //       !updateDataValue[i].unitPrice)
          //   ) {
          //     isUpdate = false;
          //     break;
          //   }
        }
      }
      if (!isUpdate) {
        this.showError('Quantity or price must be greater than zero!');
      } else {
        const updateRes = await updateCFundAuditProduct({
          lstCFundAuditProduct: event.detail.draftValues,
          strState: this.state
        });
        if (updateRes.result === 'OK') {
          // Clear all datatable draft values
          this.draftValues = [];
          this.showSuccess('Products updated');
        } else {
          this.showError(updateRes.errorMessage);
        }
        await this.refreshData();
      }
    } catch (error) {
      this.showError(error);
    }
  }

  async doScanProduct(code) {
    try {
      const res = await addScannedProduct({
        strCFundAuditId: this._recordId,
        strCode: code,
        strState: this.state
      });
      if (res.result === 'OK') {
        this.showSuccess(`Product ${code} is being added.`);
        this.refreshData();
      } else {
        this.showError(res.errorMessage);
      }
    } catch (e) {
      this.showError(reduceErrors(e).join(', '));
    }
  }

  /**
   * handleScanProduct
   *
   * @param {*} event
   */
  async handleScanProduct(event) {
    const { code } = event.detail;
    if (!code) {
      this.showError('Scanner responsed an empty.');
    }
    await this.doScanProduct(code, this.state);
  }
}