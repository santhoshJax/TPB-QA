import { LightningElement, track, wire, api } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { refreshApex } from '@salesforce/apex';
import { sleep, reduceErrors } from 'c/tpbUtils';
import { NavigationMixin } from 'lightning/navigation';
import searchDataResult from '@salesforce/apex/TPB_MassPrebookController.searchDataResult';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import tpbMassPrebookInputQuantity from 'c/tpbMassPrebookInputQuantity';
import completeOrder from '@salesforce/apex/TPB_MassPrebookController.completeOrder';
import updateOrderItems from '@salesforce/apex/TPB_MassPrebookController.updateOrderItems';
import cancelOrderData from '@salesforce/apex/TPB_MassPrebookController.cancelOrderData';
import saveOrderByFrame from '@salesforce/apex/TPB_MassPrebookController.saveOrderByFrame';

export default class TpbMassPrebookDatatable extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  @api hqAccountId;

  @api wavePeriod;

  @api disabled = false;

  @api orderType; // 'Promo' | 'Straight Stock'
  get isPromoRecordType() {
    return this.orderType === 'Promo';
  }

  async save() {
    let res;

    const apiStores = this.apiStores;

    if (apiStores.length > 3000) {
      res = await this.saveStoresByFrames();
    } else {
      res = await this.saveStores();
    }

    return res;
  }

  async saveStoresByFrames() {
    this.loadingOfSaveStoresByFrames = true;

    const frameSize = 3000; // frame size to 11000 cause the segment is good for Apex
    let q = this.apiStores.map((item) => item);
    let rows = [];
    let i = 0;
    let countOfBatch = Math.floor(q.length / frameSize) + 1;
    // initialize state for apex
    let apexState = {
      mapOrgUnitQuantity: {
        mapOrgUnitQuantity: '0'
      },
      mapAccOrgUnit: {
        mapAccOrgUnit: ''
      },
      OrderId: this.recordId,
      OrderType: this.orderType
    };

    do {
      i = i + 1;
      rows = q.splice(0, frameSize);

      if (rows.length > 0) {
        try {
          // eslint-disable-next-line no-await-in-loop
          const res = await saveOrderByFrame({
            intFrameIndex: i, // 当前批次，起始数字为1
            intFrameTotal: countOfBatch, // 总共有多少个批次
            lstRows: rows, // 当前批次的数据
            mapOrderData: apexState
          });

          if (res.result !== 'OK') {
            this.showError('Fail to save. Reason: ' + res.errorMessage);
            this.loadingOfSaveStoresByFrames = false;
            return false;
          }

          apexState = res.mapOrderData;
        } catch (error) {
          this.showError(error);
          this.loadingOfSaveStoresByFrames = false;
          return false;
        }
      }
    } while (rows.length > 0);

    // Process: Do something else
    // {
    //   try {
    //     console.time('updateOrderByFrame');
    //     const updateRes = await updateOrderByFrame({
    //       strOrderId: this.recordId
    //     });

    //     if (updateRes.result !== 'OK') {
    //       this.showError(
    //         'Fail to update order, reason is: ' + updateRes.errorMessage
    //       );
    //       this.loadingOfSaveStoresByFrames = false;
    //       return false;
    //     }
    //   } catch (error) {
    //     this.showError(error);
    //     this.loadingOfSaveStoresByFrames = false;
    //     return false;
    //   }
    //   console.timeEnd('updateOrderByFrame');
    // }

    // the End
    // reload latest apiStores and update UI
    await refreshApex(this.apiStoresRes);

    this.showToast('save success!', 'success');
    this.loadingOfSaveStoresByFrames = false;

    return true;
  }

  async saveStores() {
    this.loadingOfSaveStoresByFramesStores = true;
    let resSave = false;
    try {
      //   const apiStores = parseApiStores(this.currentStores);
      const apiStores = this.apiStores;

      // save stores to backend
      const res = await updateOrderItems({
        lstInputItems: apiStores,
        strOrderType: this.orderType,
        strOrderId: this.recordId
      });

      if (res.result === 'OK') {
        resSave = true;
        this.showToast('Save success', 'success');
      } else {
        this.showError(res.errorMessage);
      }
    } catch (error) {
      this.showError('Invalid stores');
    }

    // reload latest apiStores and update UI
    refreshApex(this.apiStoresRes);

    this.loadingOfSaveStoresByFramesStores = false;

    return resSave;
  }

  queryTerm = '';

  @track pagination = {
    page: 1,
    pageSize: 50,
    total: 1, // default to 1 in case of crashing
    onPageChange(event) {
      const { page } = event.detail;
      this.pagination.page = page;
      this.storeSelectedRows = [...this.storeSelectedRows];
    },
    onPageSizeChange(event) {
      const { pageSize } = event.detail;
      this.pagination.page = 1;
      this.pagination.pageSize = pageSize;
      this.storeSelectedRows = [...this.storeSelectedRows];
    }
  };

  loadingOfSaveStoresByFrames = false;
  loadingOfList = false; // get list data
  loadingOfSaveStoresByFramesOrderedQuantity = false; // inline editing
  loadingOfInputQuantity = false;
  loadingOfOrderPlannedQuantity = false;
  loadingOfSaveStoresByFramesStores = false;
  get loading() {
    return (
      this.loadingOfSaveStoresByFrames ||
      this.loadingOfList ||
      this.loadingOfSaveStoresByFramesOrderedQuantity ||
      this.loadingOfInputQuantity ||
      this.loadingOfOrderPlannedQuantity ||
      this.loadingOfSaveStoresByFramesStores
    );
  }

  get isSelectionEmpty() {
    return !this.storeSelectedRows || this.storeSelectedRows.length === 0;
  }

  get isInputQuantityDisabled() {
    return this.disabled || this.isSelectionEmpty;
  }

  get isOrderPlannedQuantitiesDisabled() {
    return !(!this.disabled && this.isPromoRecordType);
  }

  sortBy = '';
  sortOrder = 'ASC';

  //
  // New states
  //

  // states
  currentStores = [];
  currentStoresDb = new Map();

  storeSelectedRows = [];

  storeDraftValues = [];

  storeFilters = [];

  // getters
  get storeFilterCriteria() {
    if (!this.currentStores || this.currentStores.length === 0) {
      return [];
    }

    return ['accState', 'accWholesalerName']
      .map((fieldName) => {
        const column = this.storeColumns.find(
          (item) => item.fieldName === fieldName
        );

        return {
          name: fieldName,
          label: column.label
        };
      })
      .map((filter) => {
        const existedValues = new Set();

        // filter.options = this.currentStores
        filter.options = this.currentStores
          .map((store) => {
            return {
              label: store[filter.name],
              value: store[filter.name]
            };
          })
          .filter((option) => {
            if (!option.value) {
              return false;
            }

            if (!existedValues.has(option.value)) {
              existedValues.add(option.value);
              return true;
            }
            return false;
          })
          .sort((a, b) => {
            if (typeof a.value !== 'string') {
              return -1;
            }
            if (typeof b.value !== 'string') {
              return 1;
            }
            return a.value.localeCompare(b.value);
          });

        return filter;
      });
  }

  get storeRowOffset() {
    const { page, pageSize } = this.pagination;

    return (page - 1) * pageSize;
  }

  // new store column
  get storeColumns() {
    const columns = getColumns();

    if (this.disabled) {
      columns.forEach((col) => {
        col.editable = false;
      });
    }

    return columns;
  }

  // new store UI data
  get storeData() {
    let res = this.currentStores;

    // filter by queryTerm
    if (this.queryTerm?.trim().length > 0) {
      res = res.filter((item) => {
        return new RegExp(`${this.queryTerm}`, 'ig').test(
          JSON.stringify(Object.values(item))
        );
      });
    }

    // filter by filters
    res = res.filter((record) => {
      for (const filter of this.storeFilters) {
        if (filter.op === 'EQ') {
          if (record[filter.field] === filter.value) {
            continue;
          } else {
            return false;
          }
        }
      }

      return true;
    });

    // pagination
    const { page, pageSize } = this.pagination;
    const startPos = (page - 1) * pageSize;
    const endPos = startPos + pageSize;
    res = res.slice(startPos, endPos);

    return res;
  }

  //Cancel Click button
  @api async handleCancelClick() {
    try {
      //let resSave = await this.save();

      //if (resSave) {
      const cancelOrderRes = await cancelOrderData({
        strOrderId: this.recordId,
        strOrderType: this.orderType,
        strWave: this.isPromoRecordType ? this.wavePeriod : ''
      });

      if (cancelOrderRes.result === 'OK') {
        this.showToast('Mass Prebook Order cancel success', 'success');
        await sleep(3000);
        this.navigateToRecordViewPage(this.recordId);
      } else {
        this.showError(cancelOrderRes.errorMessage);
      }
      //}
    } catch (error) {
      this.showError(error);
    }
  }

  //   verify() {
  //     if (!this.apiStores) {
  //       this.showError('You can only complete order when data is loaded');
  //       return false;
  //     }

  // let allValid = true;

  // for (const apiStore of this.apiStores) {
  //   if (!(apiStore.qTO >= 1)) {
  //     allValid = false;
  //     this.showError(
  //       'You have some records without Quantity Ordered. Please complete them and try again'
  //     );
  //     break;
  //   }
  // }

  // return allValid;
  //}

  // when order complete
  @api async handleCompleteOrder() {
    try {
      //let resSave = await this.save();

      // return if verification finds qty has 0 or null
      //   if (!this.verify()) {
      //     return;
      //   }

      //if (resSave) {
      const completeOrderRes = await completeOrder({
        strOrderId: this.recordId,
        strHqAccountId: this.hqAccountId,
        strOrderType: this.orderType
      });

      if (completeOrderRes.result === 'OK') {
        this.showToast('Mass Prebook Order placed', 'success');
        await sleep(3000);
        this.navigateToRecordViewPage(this.recordId);
      } else {
        this.showError(completeOrderRes.errorMessage);
      }
      //}
    } catch (error) {
      this.showError(error);
    }
  }

  getChangesByPageRowSelected(pageSelectedRows) {
    const idsSelected = new Set(pageSelectedRows.map((row) => row.accountId));
    const idsToAdd = [];
    const idsToDelete = [];

    this.storeData.forEach((row) => {
      if (idsSelected.has(row.accountId)) {
        idsToAdd.push(row.accountId);
      } else {
        idsToDelete.push(row.accountId);
      }
    });

    return { idsToAdd, idsToDelete };
  }

  handleRowSelected(event) {
    const { selectedRows } = event.detail;

    // memory to avoid page data is clean up accidentally when user navigates between pages
    if (
      selectedRows.length === 0 &&
      this.lastPageWhenRowSelection !== this.pagination.page
    ) {
      return;
    }
    this.lastPageWhenRowSelection = this.pagination.page;

    const { idsToAdd, idsToDelete } =
      this.getChangesByPageRowSelected(selectedRows);

    const ids = new Set(this.storeSelectedRows);
    idsToAdd.forEach((id) => ids.add(id));
    idsToDelete.forEach((id) => ids.delete(id));

    this.storeSelectedRows = Array.from(ids);
  }

  handleLookupCellChange(event) {
    event.stopPropagation();

    const res = event.detail;

    if (!res) {
      return;
    }

    // res = {
    //     "fieldName": "accWholesalerName",
    //     "relatedAccountRecord": {
    //         "Id": "a2o6u0000007U3UAAU",
    //         "Retailer__c": "0013i00001cltYfAAI",
    //         "Wholesaler__c": "0013i00001ckQuTAAU",
    //         "Supplier_Id__c": "102-740075",
    //         "Retailer__r": {
    //             "Name": "WINN DIXIE #0450",
    //             "Account_Number_old__c": "38815",
    //             "Id": "0013i00001cltYfAAI"
    //         },
    //         "Wholesaler__r": {
    //             "Account_Number_old__c": "1080",
    //             "Name": "SUPER FOOD SERVICES",
    //             "Id": "0013i00001ckQuTAAU"
    //         }
    //     }
    // }
    this.loadingOfSaveStoresByFramesOrderedQuantity = true;

    const { fieldName, relatedAccountRecord } = res;

    if (fieldName === 'accWholesalerName') {
      const accountId = relatedAccountRecord.Retailer__c;
      const store = this.currentStoresDb.get(accountId);
      const apiStore = this.apiStoresDb.get(accountId);

      if (store && apiStore) {
        apiStore.oAc.rAcId = relatedAccountRecord.Id;
        store.accRelatedAccountId = relatedAccountRecord.Id;

        apiStore.oAc.wsNm = relatedAccountRecord.Wholesaler__r.Name;
        store.accWholesalerName = relatedAccountRecord.Wholesaler__r.Name;

        apiStore.oAc.ws =
          relatedAccountRecord.Wholesaler__r.Account_Number_old__c;
        store.accWholesaler =
          relatedAccountRecord.Wholesaler__r.Account_Number_old__c;

        apiStore.oAc.wsCt = relatedAccountRecord.Supplier_Id__c;
        store.accWholesalerCustomer = relatedAccountRecord.Supplier_Id__c;
      }
    }

    this.loadingOfSaveStoresByFramesOrderedQuantity = false;
  }

  handleCellChange(event) {
    const { draftValues } = event.detail;

    this.loadingOfSaveStoresByFramesOrderedQuantity = true;

    try {
      this.updateStoreRecords(draftValues);
      //this.showToast('update success!', 'success');
    } catch (e) {
      this.showError(e);
    }

    // clear the draft values
    this.storeDraftValues = [];
    this.loadingOfSaveStoresByFramesOrderedQuantity = false;
  }

  handleStoreFilterChange(event) {
    this.storeFilters = event.detail;
  }

  updateStoreRecords(records) {
    for (const record of records) {
      this.validateStoreRecord(record);
    }

    for (const record of records) {
      this.updateStoreRecord(record);
    }

    // trigger to update ui data
    // this.onApiStoresUpdated();
    // this.currentStores = [...this.currentStores];
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

  // validate to a record
  validateStoreRecord(draftValue) {
    let { accountId, qtyOrdered } = draftValue;

    const record = this.currentStoresDb.get(accountId);

    if (!record) {
      throw new Error('Record is not found.');
    }

    if (qtyOrdered < 0) {
      throw new Error(
        'User cannot order less than zero quantity for this product at this store'
      );
    }

    if (this.isPromoRecordType) {
      if (qtyOrdered > record.qtyMax) {
        throw new Error(
          'User cannot order more than the max quantity for this product at this store'
        );
      }

      if (record.qtyPlanned === 0) {
        if (qtyOrdered !== 1 || qtyOrdered !== 0) {
          throw new Error(
            'User only order one or zero quantity for this product at this store'
          );
        }
      } else if (record.qtyPlanned > 0) {
        if (qtyOrdered > record.qtyPlanned * 2) {
          throw new Error(
            'User cannot order more than the two times of planned quantity for this product at this store'
          );
        }
      } else {
        throw new Error('Invalid input');
      }
    }

    return true;
  }

  updateStoreRecord(draftValue) {
    const { accountId, qtyOrdered } = draftValue;

    const store = this.currentStoresDb.get(accountId);
    const apiStore = this.apiStoresDb.get(accountId);

    // apiStore.qTOO = store.qtyOrdered;
    apiStore.qTO = Number(qtyOrdered);
    store.qtyOrdered = apiStore.qTO;

    if (this.isPromoRecordType) {
      apiStore.qTR = Number(apiStore.qTP) - Number(qtyOrdered);
      store.qtyRemaining = apiStore.qTR;
    }
  }

  get summaryColumns() {
    return getSummaryColumns();
  }

  get summaryRecords() {
    // TODO: unknown summary info
    return [];
  }

  apiStoresDb = new Map();
  apiStores;
  apiStoresRes;
  @wire(searchDataResult, {
    strOrderId: '$recordId',
    strHqAccountId: '$hqAccountId'
  })
  searchDataResult(response) {
    this.apiStoresRes = response;

    const { error, data } = response;

    if (error) {
      this.showError(error);
      return;
    }

    if (!data) {
      return;
    }

    if (data.result === 'OK') {
      try {
        if (!Array.isArray(data.data)) {
          return;
        }

        if (typeof data.data[0] === 'string') {
          this.apiStores = data.data.reduce(
            (stores, fileContent) => stores.concat(JSON.parse(fileContent)),
            []
          );
        } else {
          // make a copy so that UI can edit the origin data
          this.apiStores = data.data.map((item) => ({
            ...item,
            oAc: { ...item.oAc }
          }));
        }
      } catch (err) {
        this.showError(err);
        return;
      }

      this.apiStores = this.apiStores.map((store) => {
        store.qTOO = store.qTO; // backup the qTO field initial value
        return store;
      });
      this.apiStoresDb = this.apiStores.reduce((db, store) => {
        db.set(store.aId, store);
        return db;
      }, new Map());

      // Begin of debugging
      //   this.apiStores = this.apiStores.map((store, index) => {
      //     return {
      //       ...store,
      //       aId: `${index}`
      //     };
      //   });
      // End of debugging
      this.onApiStoresUpdated();
    } else {
      this.showError(data.errorMessage);
    }
  }

  onApiStoresUpdated() {
    this.currentStores = parseStores(this.apiStores);
    this.currentStoresDb = this.currentStores.reduce((db, store) => {
      db.set(store.accountId, store);
      return db;
    }, new Map());
    this.pagination.total = this.currentStores.length;
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

  async loadData() {
    this.loadingOfList = true;
    await refreshApex(this.apiStoresRes);
    this.loadingOfList = false;
  }

  handleInputQuantities() {
    this.loadingOfInputQuantity = true;

    tpbMassPrebookInputQuantity
      .open()
      .then(async (result) => {
        if (!result) {
          return; // user closed the modal
        }

        const { success, quantity: newQuantity } = result;

        if (success) {
          const draftValues = this.storeSelectedRows.map((accountId) => {
            return {
              accountId,
              qtyOrdered: Number(newQuantity)
            };
          });

          try {
            this.updateStoreRecords(draftValues);
            // this.showToast('update success!', 'success');
          } catch (e) {
            this.showError(e);
          }
        }
      })
      .finally(() => {
        this.loadingOfInputQuantity = false;
      });
  }

  async handleOrderPlannedQuantities() {
    this.loadingOfOrderPlannedQuantity = true;

    const confirmed = await LightningConfirm.open({
      message:
        'Would you like to order the planned quantities for all stores in this Chain?',
      variant: 'headerless'
      // setting theme would have no effect
    });

    if (confirmed) {
      try {
        const draftValues = this.currentStores.map((store) => {
          return {
            accountId: store.accountId,
            qtyOrdered: store.qtyPlanned
          };
        });

        try {
          this.updateStoreRecords(draftValues);
          //this.showToast('update success!', 'success');
        } catch (e) {
          this.showError(e);
        }
      } catch (error) {
        this.showError(error);
      }
    }

    this.loadingOfOrderPlannedQuantity = false;
  }

  async connectedCallback() {
    await this.loadData();
  }

  handleSearchKeyUp(event) {
    const isEnterKey = event.keyCode === 13;
    if (isEnterKey) {
      this.queryTerm = event.target.value;
      this.pagination.page = 1; // back to first page
    }
  }
}

function getColumns() {
  return [
    { fieldName: 'accAccountNumber', label: 'Account #', initialWidth: 80 },
    { fieldName: 'accAccountName', label: 'Account Name', initialWidth: 160 },
    // { fieldName: 'storeNumber', label: 'Store #' },
    { fieldName: 'accAddress', label: 'Address', initialWidth: 160 },
    { fieldName: 'accCity', label: 'City', initialWidth: 80 },
    { fieldName: 'accState', label: 'State', initialWidth: 40 },
    { fieldName: 'accZip', label: 'Zip', initialWidth: 80 },
    { fieldName: 'accWholesaler', label: 'Wholesaler #', initialWidth: 80 },
    {
      fieldName: 'accNTCCustomerNumber',
      label: 'NTC Customer #',
      initialWidth: 80
    },
    {
      fieldName: 'accWholesalerName', // set for filter
      label: 'Wholesaler Name', // set for filter
      initialWidth: 160,
      type: 'customWholesalerName', // set for custom lookup
      editable: false, // set for custom lookup
      typeAttributes: {
        // set for custom lookup
        fieldName: 'accWholesalerName',
        label: 'Wholesaler Name',
        //accountId: { fieldName: 'accountId' },
        wholesalerName: { fieldName: 'accWholesalerName' },
        relatedAccountId: { fieldName: 'accRelatedAccountId' }
      }
    },
    {
      fieldName: 'accWholesalerCustomer',
      label: 'Wholesaler Customer #',
      initialWidth: 120
    },
    // { fieldName: 'brandUPW', label: 'Brand UPW' },
    { fieldName: 'qtyPlanned', label: 'QTY Planned', initialWidth: 60 },
    { fieldName: 'qtyMax', label: 'Max Quantity', initialWidth: 60 },
    {
      fieldName: 'qtyOrdered',
      label: 'Qty Ordered',
      initialWidth: 60,
      editable: true
    },
    { fieldName: 'qtyRemaining', label: 'Qty Remaining', initialWidth: 60 }
  ];
}

function getSummaryColumns() {
  return [
    { fieldName: 'itemName', label: 'Item Name', initialWidth: 250 },
    { fieldName: 'ntcItemNumber', label: 'NTC Item #', initialWidth: 90 },
    {
      fieldName: 'wholesalerItemNumber',
      label: 'Wholesaler Item #',
      initialWidth: 138
    },
    { fieldName: 'qtyPlanned', label: 'QTY Planned', initialWidth: 128 },
    {
      fieldName: 'qtyOrdered',
      label: 'Qty Ordered',
      initialWidth: 128,
      editable: true
    },
    { fieldName: 'qtyRemaining', label: 'Qty Remaining', initialWidth: 128 }
  ];
}

function parseStores(apiStores) {
  if (!Array.isArray(apiStores)) {
    throw new Error('Invalid params');
  }

  return apiStores.map((store) => {
    return {
      accAccountName: store.oAc.acNm,
      accAccountNumber: store.oAc.acNu,
      accAddress: store.oAc.ads,
      accCity: store.oAc.cty,
      accNTCCustomerNumber: store.oAc.nTNu,
      accountId: store.aId, // as recordId
      accRelatedAccountId: store.oAc.rAcId,
      accState: store.oAc.sta,
      accWholesaler: store.oAc.ws,
      accWholesalerCustomer: store.oAc.wsCt,
      accWholesalerName: store.oAc.wsNm,
      accZip: store.oAc.zip,
      itemName: store.itNm,
      nTCItem: store.ntIm,
      orderId: store.oId,
      orderItemId: store.oTId,
      productId: store.pId,
      qtyMax: store.mxQ,
      qtyOrdered: store.qTO,
      qtyPlanned: store.qTP,
      qtyRemaining: store.qTR,
      wholesalerItem: store.wsIm
    };
  });
}

// function parseApiStores(stores) {
//   if (!Array.isArray(stores)) {
//     throw new Error('Invalid params');
//   }

//   return stores.map((store) => {
//     return {
//       oAc: {
//         acNm: store.accAccountName,
//         acNu: store.accAccountNumber,
//         ads: store.accAddress,
//         cty: store.accCity,
//         nTNu: store.accNTCCustomerNumber,
//         sta: store.accState,
//         ws: store.accWholesaler,
//         wsCt: store.accWholesalerCustomer,
//         wsNm: store.accWholesalerName,
//         zip: store.accZip
//       },
//       aId: store.accountId,
//       itNm: store.itemName,
//       ntIm: store.nTCItem,
//       oId: store.orderId,
//       oTId: store.orderItemId,
//       pId: store.productId,
//       mxQ: store.qtyMax,
//       qTO: store.qtyOrdered,
//       qTP: store.qtyPlanned,
//       qTR: store.qtyRemaining,
//       wsIm: store.wholesalerItem
//     };
//   });
// }