import LightningDatatable from 'lightning/datatable';
import customWholesalerName from './customWholesalerName.html';

export default class TpbCustomTypeMassPrebookDatatable extends LightningDatatable {
  static customTypes = {
    customWholesalerName: {
      template: customWholesalerName,
      standardCellLayout: true,
      typeAttributes: [
        'fieldName',
        'label',
        'relatedAccountId',
        'wholesalerName'
      ]
    }
  };
}