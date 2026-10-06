import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveOrder from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.saveOrder';
import deleteFiles from '@salesforce/apex/TPB_AddInventoryPurchasedForm.deleteFiles';
import searchDataResult from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.searchDataResult';
import LightningConfirm from 'lightning/confirm';
import addContentDocumentLink from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.addContentDocumentLink';
import searchUserState from '@salesforce/apex/TPB_AddInventoryPurchasedFormService.searchUserState';
import { getOrderItemsSubtotal } from 'c/tpbUtils';

export default class TpbAddInventoryOrderHeaders extends LightningElement {
  @api pageStatus;
  @api recordId;

  @api async save(options) {
    const saveRes = await this.dataUpdate(options);
    return saveRes;
  }

  isShow = false;
  isDisabled = false;
  isDeleteFileShow = false;
  isHeaderDisabled = false;
  stateInformationList = [];
  orderId = '';

  loadingOfCreateOrder = false;
  loadingOfUploadFile = false;
  loadingOfDeleteFile = false;
  get loading() {
    return (
      this.loadingOfCreateOrder ||
      this.loadingOfUploadFile ||
      this.loadingOfDeleteFile
    );
  }

  @track lstAllFiles = [];
  @track coreParams = {
    strOrderId: '',
    strVisitId: '',
    stateOptionsValue: '',
    strInvoiceNumber: '',
    strDollarAmountOfInvoice: ''
  };

  @api refreshOrder() {
    // TODO: refreshOrder and disable the ui when it's not draft
    this.isHeaderDisabled = true;
  }

  get acceptedFormats() {
    // refer to https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Image_types
    return ['.pdf', '.png', '.jpg', '.jpeg', '.svg', '.gif', '.webp', '.bmp'];
  }

  get allHeaderCmps() {
    return [
      ...this.template.querySelectorAll('[data-validation-required="true"]')
    ];
  }

  @track orderItems = [];

  get total() {
    if (!this.orderItems) {
      return null;
    }
    return (
      parseFloat(this.coreParams.strDollarAmountOfInvoice) -
      getOrderItemsSubtotal(this.orderItems)
    );
  }

  @api reportValidity() {
    this.allHeaderCmps.forEach((inputFields) => {
      inputFields.reportValidity();
    });
  }

  @api checkValidity() {
    return this.allHeaderCmps.reduce((validSoFar, inputFields) => {
      return validSoFar && inputFields.checkValidity();
    }, true);
  }

  connectedCallback() {
    document.addEventListener('orderupdated', (event) => {
      const { order, orderItems } = event.detail;
      this.order = order;
      this.orderItems = orderItems;
    });

    // Initialize Get id Check the data
    searchUserState().then((res) => {
      let options = [];
      if (res.result === 'OK') {
        Object.values(res.data)
          .sort()
          .forEach((item) => {
            options.push({
              label: item,
              value: item
            });
          });
      }
      this.stateInformationList = options;
    });

    if (this.recordId) {
      searchDataResult({ strRecord: this.recordId }).then((res) => {
        if (res.result === 'OK') {
          if (res.dataVisit) {
            this.coreParams.strVisitId = res.dataVisit;
            this.isHeaderDisabled = false;
            this.isShow = true;
          } else if (res.dataOrder) {
            this.coreParams.strInvoiceNumber =
              res.dataOrder.External_Order_Number__c;
            this.coreParams.strDollarAmountOfInvoice =
              res.dataOrder.External_Amount__c;
            this.coreParams.strVisitId = res.dataOrder.Related_Visit__c;
            this.coreParams.stateOptionsValue = res.dataOrder.TPB_State__c;
            this.orderId = res.dataOrder.Id;
            this.coreParams.strOrderId = res.dataOrder.Id;

            if (res.dataOrder.Status === 'Activated') {
              this.isHeaderDisabled = true;
              this.isShow = false;
              this.isDeleteFileShow = true;
            } else if (res.dataOrder.Status === 'Draft') {
              this.isShow = false;
              this.isHeaderDisabled = false;
            }
            this.isDisabled = true;

            if (res.dataFile) {
              for (let i = 0; i < res.dataFile.length; i++) {
                this.lstAllFiles.push({
                  documentId: res.dataFile[i].ContentDocumentId,
                  name:
                    res.dataFile[i].Title +
                    '.' +
                    res.dataFile[i].FileType.toLowerCase(),
                  contentVersion: res.dataFile[i].Id
                });
              }
            }
            this.isFileShow = false;
          }
        }
      });
    } else {
      this.isShow = true;
      this.isDisabled = false;
      this.isHeaderDisabled = false;
    }
  }

  //Visit
  handleVisitChange(event) {
    this.coreParams.strVisitId = event.detail.value[0];
  }

  //State
  handleOptionsChange(event) {
    this.coreParams.stateOptionsValue = event.detail.value;
  }

  onInputChange(event) {
    const newValue = event.detail.value.trim();

    if (event.target.name === 'invoiceNumber') {
      this.coreParams.strInvoiceNumber = newValue;
    } else if (event.target.name === 'dollarAmountOfInvoice') {
      this.coreParams.strDollarAmountOfInvoice = newValue;
    }
  }

  //Invoice file Uploader
  handleUploadFinished(event) {
    this.loadingOfUploadFile = true;

    const lstDocumentId = [];
    const uploadedFiles = event.detail.files;
    for (let i = 0; i < uploadedFiles.length; i++) {
      this.lstAllFiles.push(uploadedFiles[i]);
      lstDocumentId.push(uploadedFiles[i].documentId);
    }
    if (lstDocumentId.length >= 1 && this.orderId) {
      addContentDocumentLink({
        lstDocumentId: lstDocumentId,
        strOrderId: this.orderId
      }).finally(() => {
        this.loadingOfUploadFile = false;
      });
    } else {
      this.loadingOfUploadFile = false;
    }
  }

  validate() {
    return [
      ...this.template.querySelectorAll('[data-validation-required="true"]')
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
  }

  async dataUpdate(options = {}) {
    const { showSuccessMsg = true } = options;

    if (!this.validate()) {
      return false;
    }

    const saveRes = await saveOrder({ objOrderData: this.coreParams })
      .then((res) => {
        if (res.result === 'OK') {
          this.isShow = false;
          this.isDisabled = true;
          this.orderId = res.RecordId;
          this.coreParams.strOrderId = res.RecordId;

          if (showSuccessMsg) {
            this.toast('Save Success', 'success');
          }
          this.dispatchEvent(
            new CustomEvent('ordercreated', { detail: res.RecordId })
          );
          return true;
        }

        this.toast(res.errorMessage, 'error');
        return false;
      })
      .catch((error) => {
        this.toast(error.body ? error.body.message : error, 'error');
        return false;
      });

    return saveRes;
  }

  async submitEvent() {
    this.loadingOfCreateOrder = true;

    if (!this.orderId) {
      if (!this.coreParams.strVisitId || !this.coreParams.stateOptionsValue) {
        this.toast('Please fill in the complete information', 'error');
      } else {
        await this.dataUpdate();
      }
    } else {
      if (
        this.coreParams.strVisitId &&
        this.coreParams.stateOptionsValue &&
        this.coreParams.strInvoiceNumber &&
        this.coreParams.strDollarAmountOfInvoice &&
        this.lstAllFiles.length >= 1
      ) {
        await this.dataUpdate();
      } else {
        this.toast('Please fill in the complete information', 'error');
      }
    }

    this.loadingOfCreateOrder = false;
  }

  // Delete Files
  async handleDeleteFilesChange(event) {
    this.loadingOfDeleteFile = true;

    const strDocumentId = event.currentTarget.dataset.id;
    const strIndex = event.currentTarget.dataset.index;
    const result = await LightningConfirm.open({
      message: 'Do you want to delete the selected file.',
      variant: 'headerless',
      label: 'Do you want to delete the selected file'
    });

    if (result) {
      this.lstAllFiles.splice(strIndex, 1);
      deleteFiles({ strDocumentId: strDocumentId }).then((res) => {
        if (res.result === 'OK') {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success',
              message: 'Deleted Success',
              variant: 'success'
            })
          );
        }

        this.loadingOfDeleteFile = false;
      });
    }

    this.loadingOfDeleteFile = false;
  }

  toast(title, type) {
    const toastEvent = new ShowToastEvent({
      title,
      variant: type
    });
    this.dispatchEvent(toastEvent);
  }
}