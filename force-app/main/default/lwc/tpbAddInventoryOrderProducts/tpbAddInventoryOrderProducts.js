import { api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import deleteOrderItem from '@salesforce/apex/TPB_AddInventoryPurchasedForm.deleteOrderItem';
import addScannedProduct from '@salesforce/apex/TPB_AddInventoryPurchasedForm.addScannedProduct';
import OrderItemAddModal from 'c/tpbOrderItemAdd';
import { OrderRecordElement, reduceErrors, fen, yuan } from 'c/tpbUtils';

const COLUMNS = [
  {
    label: 'Product',
    fieldName: 'productName',
    editable: false
  },
  {
    label: 'Type',
    fieldName: 'type',
    initialWidth: 100,
    editable: false
  },
  {
    label: 'UoM',
    fieldName: 'uoM',
    initialWidth: 90,
    editable: false
  },
  {
    label: 'Quantity',
    fieldName: 'quantity',
    initialWidth: 100,
    editable: true
  },
  {
    label: 'Price',
    fieldName: 'unitPrice',
    initialWidth: 110,
    type: 'currency',
    editable: true
  },
  {
    label: 'Subtotal',
    fieldName: '_subtotal',
    initialWidth: 110,
    type: 'currency',
    editable: false
  },
  {
    label: 'Quick Action',
    type: 'button',
    initialWidth: 120,
    typeAttributes: {
      label: 'Remove',
      name: 'delete',
      title: 'Remove',
      variant: 'base'
    }
  }
];

export default class TpbAddInventoryOrderProducts extends OrderRecordElement {
  @api recordId;

  typeForScan = '';

  loadingOfScan = false;
  loadingOfAdd = false;
  loadingOfSaveTable = false;
  loadingOfDeleteTableRecord = false;
  get loading() {
    return (
      this.loadingOfScan ||
      this.loadingOfAdd ||
      this.loadingOfSaveTable ||
      this.loadingOfDeleteTableRecord
    );
  }

  get datatableOrderItems() {
    if (!this.orderItems) {
      return [];
    }

    return this.orderItems
      .map((orderItem) => {
        return {
          ...orderItem,
          // NOTICE: UnitPrice for Return keeps negative in value and positive in UI
          unitPrice: Math.abs(orderItem.unitPrice),
          _subtotal: yuan(fen(orderItem.unitPrice) * orderItem.quantity),
          id: orderItem.orderItemId
        };
      })
      .sort((a, b) => {
        let res = a.productName.localeCompare(b.productName);
        if (res === 0) {
          res = a.type.localeCompare(b.type);
        }
        if (res === 0) {
          res = a.uoM.localeCompare(b.uoM);
        }
        return res;
      });
  }

  // Apex data: OrderId, Id, Product2.Name, Quantity, UnitPrice, UoM__c
  columns = COLUMNS;

  draftValues = [];

  get columnsData() {
    return this.columns
      .map((col) => {
        const actionCols = ['action', 'button'];
        if (this.isOrderNotDraft && actionCols.includes(col.type)) {
          // editable only when order is draft
          return null;
        }

        // make editable field conditional if field is editable, otherwise no need to edit
        return {
          ...col,
          editable: col.editable === true ? !this.isOrderNotDraft : false
        };
      })
      .filter((col) => !!col);
  }

  async handleRowAction(event) {
    const { action, row } = event.detail;

    switch (action.name) {
      case 'delete': {
        this.loadingOfDeleteTableRecord = true;
        await this.deleteRow(row);
        this.loadingOfDeleteTableRecord = false;
        break;
      }
      default:
    }
  }

  async deleteRow(row) {
    const ok = await LightningConfirm.open({
      message: 'Are you sure about deleting the order product?',
      variant: 'headerless',
      label: 'Delete'
      // setting theme would have no effect
    });

    if (ok) {
      const deleteRes = await deleteOrderItem({
        strOrderItemId: row.orderItemId
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
   * handleAddProduct
   */
  async handleAddProduct() {
    if (!this.order) {
      return;
    }

    this.loadingOfAdd = true;

    const addingRes = await OrderItemAddModal.open({
      orderId: this.recordId,
      orderItems: this.orderItems
    });

    if (addingRes === 'success') {
      await this.refreshData();
    }

    this.loadingOfAdd = false;
  }

  handleCellChange(event) {
    // let the parent knows that it's changing
    this.dispatchEvent(new CustomEvent('cellchange', { detail: event.detail }));
  }

  handleCancel(event) {
    // let the parent knows that it's not changing any more
    this.dispatchEvent(new CustomEvent('cancel', { detail: event.detail }));
  }

  /**
   *
   * @param {*} event
   */
  async handleSave(event) {
    this.loadingOfSaveTable = true;

    // Convert datatable draft values into record objects
    const records = event.detail.draftValues.slice().map((draftValue) => {
      const fields = {};
      const originalRecord = this.orderItems.find(
        (item) => item.orderItemId === draftValue.id
      );

      // Convert apex OrderDetail fields to updateRecord fields
      if (draftValue.id) {
        fields.Id = draftValue.id;
      }
      if (draftValue.quantity) {
        fields.Quantity = draftValue.quantity;
      }
      if (draftValue.unitPrice) {
        fields.UnitPrice = draftValue.unitPrice;
        if (originalRecord.type === 'Return') {
          fields.UnitPrice = -1 * Math.abs(fields.UnitPrice);
        }
      }

      return { fields };
    });

    // Clear all datatable draft values
    this.draftValues = [];

    try {
      // Update all records in parallel thanks to the UI API
      const recordUpdatePromises = records.map((record) =>
        updateRecord(record)
      );
      await Promise.all(recordUpdatePromises);

      // let the parent knows that it's changed
      this.dispatchEvent(new CustomEvent('save', { detail: event.detail }));

      this.showSuccess('Order products updated');

      await this.refreshData();
    } catch (error) {
      this.showError(error);
    } finally {
      this.loadingOfSaveTable = false;
    }
  }

  async doScanProduct(code, type) {
    try {
      const res = await addScannedProduct({
        strOrderId: this.recordId,
        strCode: code,
        strType: type
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
      return;
    }

    this.loadingOfScan = true;

    const typeSelector = this.template.querySelector(
      'c-tpb-order-item-type-selector'
    );

    const type = typeSelector.value;
    await this.doScanProduct(code, type);

    this.loadingOfScan = false;
  }
}