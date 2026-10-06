import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/tpbUtils';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllWholesalerAccount from '@salesforce/apex/TPB_MassPrebookController.getAllWholesalerAccount';
import getOrderData from '@salesforce/apex/TPB_MassPrebookController.getOrderData';
//import completeOrder from '@salesforce/apex/TPB_MassPrebookController.completeOrder';
//import cancelOrderData from '@salesforce/apex/TPB_MassPrebookController.cancelOrderData';
import validationsPromotion from '@salesforce/apex/TPB_MassPrebookController.validationsPromotion';
export default class TpbMassPrebook extends NavigationMixin(LightningElement) {
  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value = '') {
    this._recordId = value;
  }

  _recordId = '';
  _hqAccountId = '';
  _disabled = true;

  stateInformationList = [];
  stateOptionsWavePeriodValue = [];

  isDisabled = false;
  isShowProduct = true;
  loadingOfSaveProduct = false; // save product data

  isShowSubmitDisabled = false;
  isShowCompleteDisabled = true;
  isShowCancelDisabled = true;

  get title() {
    if (this.recordId) {
      return 'Edit Mass Prebook Order';
    }
    return 'Create Mass Prebook Order';
  }

  @track coreParams = {
    strHqAccountId: '',
    strShipDateFrom: '',
    strProductId: '',
    strProductPromotion: 'Promo',
    stateOptionsValue: '',
    stateOptionsWavePeriodValue: ''
  };

  get lsProductPromotionOptions() {
    return [
      { label: 'Promo', value: 'Promo' },
      { label: 'Straight Stock', value: 'Straight Stock' }
    ];
  }

  get loading() {
    return this.loadingOfSaveProduct;
  }

  //State
  handleOptionsChange(event) {
    this.coreParams.stateOptionsValue = event.detail.value;
    this.coreParams.stateOptionsWavePeriodValue = event.detail.value;
  }

  connectedCallback() {
    if (this.recordId) {
      // Initialize Get id Check the data
      getOrderData({ strOrderId: this.recordId }).then((data) => {
        if (data) {
          if (data.result === 'OK') {
            let options = [];
            let optionsWavePeriod = [];
            if (data.dataOrderType) {
              this.coreParams.strProductPromotion = data.dataOrderType;
              this.isShowProduct =
                data.dataOrderType === 'Promo' ? true : false;
            }
            if (data.data.TPB_Mass_Prebook_Product__c) {
              this.coreParams.strProductId =
                data.data.TPB_Mass_Prebook_Product__c;
            }
            if (data.data.TPB_HQ_Account__c) {
              this.coreParams.strHqAccountId = data.data.TPB_HQ_Account__c;
              this._hqAccountId = data.data.TPB_HQ_Account__c;
            }
            if (data.data.TPB_Ship_Date__c) {
              this.coreParams.strShipDateFrom = data.data.TPB_Ship_Date__c;
            }
            if (data.data.TPB_Wave_Order_Date__c) {
              options.push({
                label: this.waveOrderDateFormat(
                  data.data.TPB_Wave_Order_Date__c,
                  1
                ),
                value: data.data.TPB_Wave_Order_Date__c
              });
              optionsWavePeriod.push({
                label: this.wavePeriodDateFormat(
                  data.data.TPB_Wave_Order_Date__c,
                  1
                ),
                value: data.data.TPB_Wave_Order_Date__c
              });

              this.stateInformationList = options;
              this.stateOptionsWavePeriodValue = optionsWavePeriod;

              this.coreParams.stateOptionsValue =
                data.data.TPB_Wave_Order_Date__c;
              this.coreParams.stateOptionsWavePeriodValue =
                data.data.TPB_Wave_Order_Date__c;
            }
            this._recordId = this.recordId;
            if (data.data.Status && data.data.Status === 'Draft') {
              //   if (
              //       data.ChildOrderStatus &&
              //       data.ChildOrderStatus === 'Activated'
              //   ) {
              //       this.isShowSubmitDisabled = true;
              //   } else {
              this.isShowSubmitDisabled = true;
              this._disabled = false;
              this.isShowCompleteDisabled = false;
              this.isShowCancelDisabled = false;
              //}
            } else if (data.data.Status && data.data.Status === 'Cancelled') {
              this.isShowSubmitDisabled = true;
            } else if (data.data.Status && data.data.Status === 'Completed') {
              this.isShowSubmitDisabled = true;
              this.isShowCancelDisabled = false;
            }
            this.isDisabled = true;
            // 处理数据
          }
        }
      });
    }
  }

  //HQAccount Change
  handleHQAccountChange(event) {
    this.coreParams.strHqAccountId = event.detail.value[0];
  }
  //Ship Date Change
  handleShipDateFromChange(event) {
    this.coreParams.strShipDateFrom = event.detail.value;
  }

  //select Product
  handleProductChange(event) {
    this.coreParams.strProductId = event.detail.value[0];
    if (this.coreParams.strProductPromotion === 'Promo') {
      validationsPromotion({
        strProductId: this.coreParams.strProductId,
        strHqAccountId: this.coreParams.strHqAccountId
      }).then((res) => {
        if (res.result === 'OK') {
          let options = [];
          let optionsWavePeriod = [];
          let intWave = 1;
          Object.values(res.data).forEach((item) => {
            options.push({
              label: this.waveOrderDateFormat(item, intWave),
              value: item
            });
            optionsWavePeriod.push({
              label: this.wavePeriodDateFormat(item, intWave),
              value: item
            });
            intWave++;
          });
          this.stateInformationList = options;
          this.stateOptionsWavePeriodValue = optionsWavePeriod;
        } else if (res.result === 'NG') {
          this.coreParams.strProductId = null;
          this.showError(res.errorMessage);
        }
      });
    }
  }

  //formatDate
  formatDate(date) {
    const _date = date.split('-');
    const dateObj = { month: _date[1], day: _date[2], year: _date[0] };
    return dateObj.month + '/' + dateObj.day + '/' + dateObj.year;
  }

  //wave Period Date Format
  waveOrderDateFormat(item, intWave) {
    return (
      'Wave ' +
      intWave +
      ' Period: ' +
      this.formatDate(item.split(',')[0].split('=')[0]) +
      '-' +
      this.formatDate(item.split(',')[0].split('=')[1])
    );
  }

  //wave Order Entry Date Format
  wavePeriodDateFormat(item, intWave) {
    return (
      'Wave ' +
      intWave +
      ' Order Entry: ' +
      this.formatDate(item.split(',')[1].split('=')[0]) +
      '-' +
      this.formatDate(item.split(',')[1].split('=')[1])
    );
  }

  //Product or Promotion Change
  handleProductPromotionChange(event) {
    this.coreParams.strProductPromotion = event.detail.value;
    if (event.detail.value === 'Promo') {
      this.isShowProduct = true;
      this.coreParams.strShipDateFrom = null;
    } else {
      this.isShowProduct = false;
    }
    this.coreParams.strProductId = null;
    this.coreParams.stateOptionsValue = null;
    this.coreParams.stateOptionsWavePeriodValue = null;
  }

  //Cancel Click button
  async handleCancelClick() {
    if (this._recordId) {
      //Save Click button
      const el = this.template.querySelector('c-tpb-mass-prebook-datatable');
      el.handleCancelClick();
    }
    //if (this._recordId) {
    //   try {
    //     this.loadingOfSaveProduct = true;
    //     const cancelOrderRes = await cancelOrderData({
    //       strOrderId: this._recordId,
    //       strWave:
    //         this.coreParams.strProductPromotion === 'Promo'
    //           ? String(this.coreParams.stateOptionsValue.split(','))
    //           : ''
    //     });

    //     if (cancelOrderRes.result) {
    //       this.loadingOfSaveProduct = false;
    //     }
    //     if (cancelOrderRes.result === 'OK') {
    //       this.toast('Mass Prebook Order cancel success', 'success');
    //       await sleep(3000);
    //       this.navigateToRecordViewPage(this._recordId);
    //     } else {
    //       this.showError(cancelOrderRes.errorMessage);
    //     }
    //   } catch (error) {
    //     this.showError(error);
    //   }
    // }
    // this.loadingOfSaveProduct = false;
  }

  // when order complete
  async handleCompleteOrder() {
    if (this._recordId) {
      //Save Click button
      const el = this.template.querySelector('c-tpb-mass-prebook-datatable');
      el.handleCompleteOrder();
      //   try {
      //     this.loadingOfSaveProduct = true;
      //     const completeOrderRes = await completeOrder({
      //       strOrderId: this._recordId,
      //       strHqAccountId: this.coreParams.strHqAccountId,
      //       strOrderType: this.coreParams.strProductPromotion
      //     });

      //     if (completeOrderRes.result) {
      //       this.loadingOfSaveProduct = false;
      //     }
      //     if (completeOrderRes.result === 'OK') {
      //       this.toast('Mass Prebook Order placed', 'success');
      //       await sleep(3000);
      //       this.navigateToRecordViewPage(this._recordId);
      //     } else {
      //       this.showError(completeOrderRes.errorMessage);
      //     }
      //   } catch (error) {
      //     this.showError(error);
      //   }
    }
    //this.loadingOfSaveProduct = false;
  }

  // when Submit Order
  async handleSubmitOrder() {
    if (
      this.coreParams.strProductPromotion === 'Promo' &&
      (!this.coreParams.strHqAccountId ||
        !this.coreParams.strProductId ||
        !this.coreParams.stateOptionsValue)
    ) {
      this.showError('Please fill in the complete information');
      return;
    }
    if (
      this.coreParams.strProductPromotion === 'Straight Stock' &&
      (!this.coreParams.strHqAccountId ||
        !this.coreParams.strProductId ||
        !this.coreParams.strShipDateFrom)
    ) {
      this.showError('Please fill in the complete information');
      return;
    }

    try {
      const submitOrderRes = await getAllWholesalerAccount({
        strHqAccountId: this.coreParams.strHqAccountId,
        strProductId: this.coreParams.strProductId,
        strShipDateFrom: this.coreParams.strShipDateFrom,
        strProductPromotion: this.coreParams.strProductPromotion,
        strWave:
          this.coreParams.strProductPromotion === 'Promo'
            ? this.coreParams.stateOptionsValue
            : ''
      });

      if (submitOrderRes.result === 'OK') {
        this._recordId = submitOrderRes.dataOrderId;
        this._hqAccountId = submitOrderRes.dataAccountId;
        this.isShowCompleteDisabled = false;
        this.isShowCancelDisabled = false;
        this.isShowSubmitDisabled = true;
        this.isDisabled = true;
        this._disabled = false;
        this.toast('Create Mass Prebook Order Success', 'success');
      } else {
        this.showError(submitOrderRes.errorMessage);
      }
    } catch (error) {
      this.showError(error);
    }
  }

  //show error
  showError(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: reduceErrors(error).join(', '),
        variant: 'error'
      })
    );
  }

  //toast
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