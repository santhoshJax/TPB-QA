export const TABLE_INDEX_COL_WIDTH = 52;

export const COLUMNS = [
  {
    label: 'Product',
    fieldName: 'productName',
    editable: false
  },
  // {
  //     label: 'UoM',
  //     fieldName: 'UoM',
  //     initialWidth: 90,
  //     editable: false
  // },
  {
    label: 'Unit Price',
    fieldName: 'unitPrice',
    initialWidth: 110,
    type: 'number',
    editable: false,
    typeAttributes: {
      step: '0.001',
      minimumFractionDigits: '3',
      maximumFractionDigits: '3'
    }
  },
  {
    label: 'Expected Quantity',
    fieldName: 'expectedQuantity',
    initialWidth: 170,
    type: 'number',
    editable: false,
    typeAttributes: {
      step: '0.001',
      minimumFractionDigits: '3',
      maximumFractionDigits: '3'
    }
  },
  {
    label: 'Actual Quantity',
    fieldName: 'quantity',
    initialWidth: 150,
    type: 'number',
    editable: true,
    typeAttributes: {
      step: '0.001',
      minimumFractionDigits: '3',
      maximumFractionDigits: '3'
    }
  },
  {
    label: 'Variance',
    fieldName: 'variance',
    initialWidth: 100,
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

export const PRODUCT_FIELDS = [
  'TPB_CFund_Audit_Product__c.TPB_CFund_Audit__c',
  'TPB_CFund_Audit_Product__c.TPB_Actual_Product__c',
  'TPB_CFund_Audit_Product__c.TPB_Quantity__c',
  'TPB_CFund_Audit_Product__c.TPB_Total_Amount__c',
  'TPB_CFund_Audit_Product__c.TPB_Unit_Price__c'
];