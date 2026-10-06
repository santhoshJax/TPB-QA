import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import init from '@salesforce/apex/TPB_AddCFundAudit.init';
import { NavigationMixin } from 'lightning/navigation';
import STATUS_FIELD from '@salesforce/schema/TPB_CFund_Audit__c.TPB_Status__c';
import saveAndSubmit from '@salesforce/apex/TPB_AddCFundAudit.saveAndSubmit';
import { sleep } from 'c/tpbUtils';
import searchInventoryUserState from '@salesforce/apex/TPB_AddCFundAuditService.searchInventoryUserState';
import submitAndProcessApprovalRequest from '@salesforce/apex/TPB_AddCFundAudit.submitAndProcessApprovalRequest';
export default class TpbAddCFundAudit extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  cFundAuditId;
  cFundAuditStatus = '';
  maps = new Map();

  activeSections = ['A', 'B'];
  stateOptionsValueList = [];
  specialPrice = 0;

  @track coreParams = {
    actualProductValue: 0,
    actualCashAndCashEquivalent: 0,
    cashVariance: 0,
    productVariance: 0,
    auditResult: 0
    // tsmName: '',
  };

  @track cFundAuditData = {
    recordId: '',
    baseCFund: 0,
    expectedProductValue: 0,
    expectedCashAndCashEquivalents: 0,
    totalAdjustments: 0,
    bankBalance: 0,
    pendingReimbursements: 0,
    promoValue: 0,
    actualCashOnHand: 0,
    totalAccountableCFund: 0
  };

  @wire(getRecord, {
    recordId: '$cFundAuditId',
    fields: [STATUS_FIELD]
  })
  cFundAudit({ data }) {
    if (data) {
      this.cFundAuditStatus = data.fields.TPB_Status__c.value;
    }
  }

  get ShowStatus() {
    return this.cFundAuditStatus === 'Draft' ||
      this.cFundAuditStatus === '' ||
      this.cFundAuditStatus === 'Reject'
      ? false
      : true;
  }

  get SubmitDisabled() {
    return (this.cFundAuditStatus === 'Draft' ||
      this.cFundAuditStatus === '' ||
      this.cFundAuditStatus === 'Reject') &&
      this.cFundAuditId
      ? false
      : true;
  }

  connectedCallback() {
    this.cFundAuditId = this.recordId;
    this.cFundAuditData.recordId = this.recordId;
    searchInventoryUserState().then((res) => {
      let options = [];
      if (res.result === 'OK') {
        if (res.data && res.data.length > 0) {
          res.data.forEach((item) => {
            options.push({
              label: item,
              value: item + ' Actual Products'
            });
          });
        } else {
          options.push({
            label: '',
            value: 'Actual Products'
          });
        }
      }
      this.stateOptionsValueList = options;
    });

    init({ strRecord: this.recordId })
      .then((res) => {
        if (res.result === 'OK') {
          if (res.data) {
            this.cFundAuditData.baseCFund = parseFloat(
              res.data.baseCFund
            ).toFixed(2);
            this.cFundAuditData.expectedProductValue = parseFloat(
              res.data.expectedProductValue
            ).toFixed(2);
            this.cFundAuditData.totalAccountableCFund = parseFloat(
              res.data.totalAccountableCFund
            ).toFixed(2);
            this.cFundAuditData.totalAdjustments = parseFloat(
              res.data.totalAdjustments
            ).toFixed(2);
            this.cFundAuditData.expectedCashAndCashEquivalents = parseFloat(
              res.data.expectedCashAndCashEquivalents
            ).toFixed(2);
            if (this.recordId && res.dataTPB_CFund_Audit__c) {
              this.cFundAuditData.bankBalance = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Bank_Balance__c
              ).toFixed(2);
              this.cFundAuditData.pendingReimbursements = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Pending_Reimbursements__c
              ).toFixed(2);
              this.cFundAuditData.promoValue = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Promo_Value__c
              ).toFixed(2);
              this.coreParams.actualCashAndCashEquivalent = parseFloat(
                res.dataTPB_CFund_Audit__c
                  .TPB_Actual_Cash_and_Cash_Equivalent__c
              ).toFixed(2);
              this.cFundAuditData.actualCashOnHand = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Cash_On_Hand__c
              ).toFixed(2);
              this.coreParams.cashVariance = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Cash_Variance__c
              ).toFixed(2);
              this.coreParams.productVariance = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Product_Variance__c
              ).toFixed(2);
              this.coreParams.auditResult = parseFloat(
                res.dataTPB_CFund_Audit__c.TPB_Audit_Result__c
              ).toFixed(2);
            } else {
              this.cFundAuditData.pendingReimbursements = parseFloat(
                res.data.pendingReimbursements
              ).toFixed(2);
              this.cFundAuditData.promoValue = parseFloat(
                res.data.promoValue
              ).toFixed(2);
              this.coreParams.actualCashAndCashEquivalent = (
                (parseFloat(res.data.promoValue) * 100 +
                  parseFloat(res.data.pendingReimbursements) * 100) /
                100
              ).toFixed(2);
              this.coreParams.cashVariance = (
                (parseFloat(this.coreParams.actualCashAndCashEquivalent) * 100 -
                  parseFloat(
                    this.cFundAuditData.expectedCashAndCashEquivalents
                  ) *
                    100) /
                100
              ).toFixed(2);
              this.coreParams.productVariance = (
                (parseFloat(this.coreParams.actualProductValue) * 100 -
                  parseFloat(res.data.expectedProductValue) * 100) /
                100
              ).toFixed(2);
              this.coreParams.auditResult = (
                (parseFloat(this.coreParams.cashVariance) * 100 +
                  parseFloat(this.coreParams.productVariance) * 100) /
                100
              ).toFixed(2);
            }
          }
        }
      })
      .catch((error) => {
        this.toast(error.body ? error.body.message : error, 'error');
      });

    window.addEventListener('popstate', () => {
      window.location.reload();
    });
  }

  onInputBlur(event) {
    const newValue = event.target.value.trim();
    if (event.target.name === 'actualCashOnHand') {
      this.cFundAuditData.actualCashOnHand = newValue;
    }
    if (event.target.name === 'bankBalance') {
      this.cFundAuditData.bankBalance = newValue;
    }
    this.updateData();
  }

  updateData() {
    let actualCashAndCashEquivalent = (
      (parseFloat(this.cFundAuditData.actualCashOnHand) * 100 +
        parseFloat(this.cFundAuditData.bankBalance) * 100 +
        parseFloat(this.cFundAuditData.promoValue) * 100 +
        parseFloat(this.cFundAuditData.pendingReimbursements) * 100) /
      100
    ).toFixed(2);

    let cashVariance = (
      (parseFloat(actualCashAndCashEquivalent) * 100 -
        parseFloat(this.cFundAuditData.expectedCashAndCashEquivalents) * 100) /
      100
    ).toFixed(2);

    let productVariance = (
      (
        parseFloat(this.coreParams.actualProductValue) * 100 -
        parseFloat(this.cFundAuditData.expectedProductValue) * 100
      ).toFixed(2) / 100
    ).toFixed(2);

    this.coreParams.actualCashAndCashEquivalent = actualCashAndCashEquivalent;
    this.coreParams.cashVariance = cashVariance;
    this.coreParams.productVariance = productVariance;
    this.coreParams.auditResult = (
      (parseFloat(cashVariance) * 100 + parseFloat(productVariance) * 100) /
      100
    ).toFixed(2);
  }

  //save data
  saveEvent() {
    saveAndSubmit({ cFundAuditData: this.cFundAuditData })
      .then((res) => {
        if (res.result === 'OK') {
          this.cFundAuditId = res.data;
          this.cFundAuditData.recordId = res.data;
          this.toast('Save Success', 'success');
          this.dispatchEvent(
            new CustomEvent('auditcreated', { detail: res.data })
          ); // TODO: change auditId
        } else {
          this.toast(res.errorMessage, 'error');
        }
      })
      .catch((error) => {
        this.toast(error.body ? error.body.message : error, 'error');
      });
  }

  //update actual Product On Hand
  handleAuditProducts(e) {
    this.maps.set(e.detail.value, e.detail.totalAmount);
    let totalAmount = 0;
    this.maps.forEach((value) => {
      totalAmount += parseFloat(value);
    });
    this.coreParams.actualProductValue = parseFloat(totalAmount).toFixed(2);
    this.updateData();
  }

  //submit Event
  submitEvent() {
    submitAndProcessApprovalRequest({
      cFundAuditData: this.cFundAuditData
    })
      .then((res) => {
        if (res.result === 'OK') {
          this.toast('Submit Success', 'success');
          this.cFundAuditStatus = 'Approval In Progress';

          sleep(3000).then(() => {
            this.navigateToRecordViewPage(this.cFundAuditId);
          });
        } else {
          this.toast(res.errorMessage, 'error');
        }
      })
      .catch((error) => {
        this.toast(error.body ? error.body.message : error, 'error');
      });
    //}
  }

  toast(title, type) {
    const toastEvent = new ShowToastEvent({
      title,
      variant: type
    });
    this.dispatchEvent(toastEvent);
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