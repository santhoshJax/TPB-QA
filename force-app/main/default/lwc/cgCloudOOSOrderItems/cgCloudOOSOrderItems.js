import { LightningElement, api, track, wire } from 'lwc';
import getOrderItems from '@salesforce/apex/TPB_OnlineAppController.getOrderItems';
import getOOSItems from '@salesforce/apex/TPB_OnlineAppController.getOOSItems';
import createOrderLineItems from '@salesforce/apex/TPB_OnlineAppController.createOrderLineItems';
import getOrderItemTemplates from '@salesforce/apex/TPB_OnlineAppController.getOrderItemTemplates';
import getPrebookWholesaler from '@salesforce/apex/TPB_OnlineAppController.getPrebookWholesaler';
import getCGCAppCustomSettings from '@salesforce/apex/TPB_OnlineAppController.getCustomSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";
import { refreshApex } from '@salesforce/apex';
export default class CgCloudOOSOrderItems extends LightningElement {
    @api isOOSProductsArray = false;
    @api oosProductsArray = [];
    @api selectedCustomerId;
    @track typeOptions = [];
    @track typeOptionsAll = [];
    @track allSelectedProductsArray = [];
    @track selectedTypeValue = '';
    @track previousTypeValue = '';
    @track wholeSalerOptions;
    @track wholeSaleOrderCode ='';
    @track selectedWholeSaler = '';
    @track isPreBook = false;
    @track isCarton = true;
     @track isEach = true;
    @track isSelectedProduct = false;
    @track isOOSSpinner = true;
   
    @api orderId;
    @track orderItemResponceData = [];
    @track selectedProductData = {
        productId: '',
        cartonOrderLineItemId: '',
        eachOrderLineItemId: '',
        productName: ''
    };
    @track selectedProductName;
    @track oosData = [];
    @api visitId;
    @track selectedProduct;
    @track eachSpcPriceValue = 0;
    @track cartonPiecesCount = 0;
    @track cartonSpcPriceValue = 0;
    @track suggestedQtyValue = 0;
    @track maxAllocationValue = 0;
    @track specialPriceValue = 0;
    @track unitPriceOfCarton = 0.00;
    @track unitPriceOfEach = 0.00;
    @track totalPriceOfEach = 0.00;
    @track totalPriceOfCarton = 0.00;
    @track stockBalance = 0.00;
    @track suggestedQty = 0.00;
    @track cartonValue = 0;
    @track eachValue = 0;
    @track UomType = 'Carton';
    @track refreshOOSItems ='';
    connectedCallback() {
        getOrderItemTemplates()
            .then(result => {
                // this.typeOptions = result.map(item => ({
                //     label: item.Name,
                //     value: item.Id
                // }));
                this.typeOptions = result
                .filter(item => !['Free Item',].includes(item.Name))
                .map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
                this.typeOptionsAll = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
                this.selectedTypeValue = this.typeOptionsAll.find(type => type.label === 'Cash Sale').value;
            }).catch(error => {
                console.error('getOrderItemTemplates error: ' + JSON.stringify(error));
            });
        this.getAppCustomSettings();
    }
    renderedCallback() {
        const container = this.template.querySelector('.product-table-container');
        if (container) {
            const offset = 200; // Header + footer estimated height
            container.style.maxHeight = `${window.innerHeight - offset}px`;
        }
    }
    getAppCustomSettings() {
        getCGCAppCustomSettings()
        .then(result => {
            this.customSettingLimits = result;
            console.log('getAppCustomSettings: '+JSON.stringify(result));

        }).catch(error => {
            console.error('getAppCustomSettings error: '+JSON.stringify(error));
        })
    }
    @wire(getOOSItems, { visitId: '$visitId' })
    wireGetOOSItemsData(value) {
        this.refreshOOSItems = value;
        const { data, error } = value;
        if (data) {
            console.log('visitId...', this.visitId);
            console.log('getOOSItems....', JSON.stringify(data));
            this.isOOSSpinner = false;
            const groupedData = {};
            this.allSelectedProductsArray = [];
             const matchedProduct = data.find(item => item?.productId === this.selectedProduct);
                this.selectedProduct = matchedProduct ? matchedProduct.productId : data[0]?.productId;
            data.map(item => {
                // Extract product code from productName (last number in parentheses)
                const productCodeMatch = item.productName.match(/\((\d+)\)$/);
                const productCode = productCodeMatch ? productCodeMatch[1] : '';


                // Default type label
                let defaultLabel = 'Cash Sale';
                if(item.typeId){ 
                    defaultLabel = this.typeOptionsAll.find(opt => opt.value === item.typeId).label;
                }
                
                const matchedOption = this.typeOptionsAll.find(opt => opt.label === defaultLabel);
                const typeLabel = matchedOption?.label || '';
                //const typeIdVal = item.product?.typeId || matchedOption?.value || '';


                const typeConfig = {
                    'Return':  { isCarton: false, isEach: true },
                    'Prebook': { isCarton: true,  isEach: false },
                    'Free Item': { isCarton: true,  isEach: false }
                };
                const config = typeConfig[typeLabel] || { isCarton: true, isEach: true };

                const enrichedItem = {
                    productId: item.productId,
                    productName: item.productName,
                    productCode: productCode, // extracted from productName
                    Carton: 0,
                    Each: 0,
                    cartonPieces: item.cartonPieces,
                    basePrice: item.basePrice,
                    suggestedQty: item.suggestedQty,
                    stockBalance: item.stockBalance,
                    quantity: item.quantity,
                    maxAllocation: item.maxAllocation,
                    typeLabel: this.typeOptionsAll.find(type => type.value === item.typeId)?.label || 'Cash Sale',
                    typeId: item.typeId || null,
                    ariaSelected: 'false',
                    isCartonRead : config.isCarton,
                    isEachRead : config.isEach
                };

                const groupKey = item.productSubCategory;

                if (!groupedData[groupKey]) {
                    groupedData[groupKey] = [];
                }

                groupedData[groupKey].push(enrichedItem);
            });

            // this.oosData = this.oosData.map(prod => {
            //     return {
            //         ...prod,
            //         ariaSelected: prod.productId === this.oosData[0]?.productId ? 'true' : 'false'
            //     };
            // });
            const firstGroupKey = Object.keys(groupedData)[0];
            if (firstGroupKey && groupedData[firstGroupKey].length > 0) {
                groupedData[firstGroupKey][0].ariaSelected = 'true';
            }
            console.log('firstGroupKey....' + JSON.stringify(firstGroupKey));
            this.oosData = Object.keys(groupedData).map(label => ({
                label,
                items: groupedData[label]
            }));
            this.allSelectedProductsArray = JSON.parse(JSON.stringify(this.oosData));
            this.isOOSProductsArray = this.oosData.length > 0;
            setTimeout(() => {

                if (this.isOOSProductsArray) {
                    this.processOrderItems();
                }
            }, 100);
            this.isSelectedProduct = this.selectedProduct != undefined && this.selectedProduct != '' && this.oosData.length > 0;
            console.log('this.oosProductsArray...' + JSON.stringify(this.oosData));
        } else if (error) {
            this.isOOSSpinner = false;
            console.log('error', error);
        }
    }
    handleTypeChange(event) {
        this.previousTypeValue = this.selectedTypeValue;
        this.selectedTypeValue = event.detail.value;
        const selectedTypeLabel = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue)?.label;
        this.isFreeItem = (selectedTypeLabel == 'Free Item') ? true : false;

        // const orderLineItemType = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue).label;
        // if(orderLineItemType == 'Return'){
        //     this.isReturn = true;
        //     // this.isEach = true;
        // }else if(orderLineItemType == 'Cash Sale'){
        //     this.isReturn = false;
        //     // this.isEach = this.cartonPiecesCount > 1 ? true : false;
        // }

        // if(selectedTypeLabel == 'Return' || selectedTypeLabel == 'Prebook'){
        //     this.cartonValue = 0; 
        //     this.eachValue = 0;
        //     this.specialPriceValue = 0.00;
        // } 
        
        const previousTypeLabel = this.typeOptionsAll.find(type => type.value === this.previousTypeValue)?.label;
        console.log('previousTypeLabel...'+previousTypeLabel);
        console.log('selectedTypeLabel...'+selectedTypeLabel);
        if(previousTypeLabel !== selectedTypeLabel){
            this.cartonValue = 0; 
            this.eachValue = 0;
            this.specialPriceValue = 0.00;
        }

        const typeConfig = {
            'Return':  { isCarton: false, isEach: true },
            'Prebook': { isCarton: true,  isEach: false }
        };
        const config = typeConfig[selectedTypeLabel] || { isCarton: true, isEach: true };
        this.isCarton = config.isCarton;
        this.isEach = config.isEach;

        this.isPreBook = selectedTypeLabel === 'Prebook';
        if (this.isPreBook) {
            this.getPreBookWholeSalerOptions();
        }
    }
     getPreBookWholeSalerOptions() {
            getPrebookWholesaler({ accountId: this.selectedCustomerId, productId: this.selectedProduct })
                .then(result => {
                    console.log('wholeSaler...' + JSON.stringify(result));
                    this.wholeSalerOptions = result.map(item => ({
                        label: item.accountName || '',
                        value: item.accountId || '',
                        sublabel: `Wholesale Order Code ${item.sku || ''}`,
                        skuCode:item.sku 
                    }));
                    // this.wholeSaleOrderCode = this.wholeSalerOptions[0].skuCode;
                   setTimeout(() => {
                    const singleCombobox = this.template.querySelector('c-custom-lookup-search');
                    if (singleCombobox && this.wholeSalerOptions) {
                        singleCombobox.refreshOptions(this.wholeSalerOptions);
                    }
                }, 0);
                }).catch(error => {
                    console.error('wholeSaler error..' + JSON.stringify(error));
                })    
        }
    async processOrderItems() {
        await getOrderItems({ orderId: this.orderId })
            .then(response => {
                this.isOOSSpinner = false;
                console.log('orderLine Items:', JSON.stringify(response));
                console.log('this.oosData:', JSON.stringify(this.oosData));
                if (response && response.length > 0) {
                    const existingProductIds = response.map(item => item.productId);
                    const matchedProducts = this.oosData.flatMap(group =>
                        group.items.filter(prod => existingProductIds.includes(prod.productId))
                    );

                    if (matchedProducts.length > 0) {
                        this.orderItemResponceData = response;
                        this.oosData.forEach(group => {
                            group.items.forEach(product => {
                                // Loop over response items that match the current productId
                                response
                                    .filter(resItem => resItem.productId === product.productId)
                                    .forEach(resItem => {
                                        const uomKey = resItem.uom; // e.g., 'Carton' or 'Each'
                    
                                        if (uomKey && product.hasOwnProperty(uomKey)) {
                                            product[uomKey] = resItem.quantity || 0;
                                        }

                                        const matchedType = this.typeOptionsAll.find(type => type.value === resItem.typeId);
                                        if (matchedType) {
                                            product.typeLabel = matchedType.label;
                                        }

                                        const typeConfig = {
                                            'Return':  { isCarton: false, isEach: true },
                                            'Prebook': { isCarton: true,  isEach: false },
                                            'Free Item': { isCarton: true,  isEach: false }
                                        };
                                        const config = typeConfig[matchedType.label] || { isCarton: true, isEach: true };
                                        product.isCartonRead = config.isCarton;
                                        product.isEachRead = config.isEach;
                                    });
                            });
                        });
                        // if (!this.selectedProduct) {
                        //     this.selectedProduct = matchedProducts[0].productId;
                        // }
                        console.log('this.selectedProduct...111', this.selectedProduct);
                        if (this.orderItemResponceData.length > 0) {
                            const matchedProduct = this.selectedProduct
                                ? this.orderItemResponceData.find(item => item.productId === this.selectedProduct)
                                : null;
                            console.log('matchedProduct:', JSON.stringify(matchedProduct));
                            if (matchedProduct) {
                                this.selectedProduct = matchedProduct.productId;
                            } else if (!this.selectedProduct && matchedProducts.length) {
                                this.selectedProduct = matchedProducts[0].productId;
                            }
                        } else if (!this.selectedProduct && matchedProducts.length) {
                            this.selectedProduct = matchedProducts[0].productId;
                        }
                        console.log('this.selectedProduct...222', this.selectedProduct);
                        console.log('Matched Products:', JSON.stringify(matchedProducts));
                        this.populateSelectedProductDetails(this.selectedProduct);
                    } else {
                        this.setDefaultProduct();
                        refreshApex(this.refreshOOSItems);
                    }
                } else {
                    this.setDefaultProduct();
                    refreshApex(this.refreshOOSItems);
                }

            })
            .catch(error => {
                console.error('Error in processOrderItems:', JSON.stringify(error));
                this.isOOSSpinner = false;
            });
    }
    setDefaultProduct() {
        const defaultProduct = this.oosData?.[0]?.items?.[0];

        if (defaultProduct) {
            /* Previous implementation created a placeholder order item so the detail pane rendered:
            this.orderItemResponceData = [{
                basePrice: 0,
                orderItemId: '',
                productId: defaultProduct.productId,
                productName: defaultProduct.productName,
                quantity: 0,
                maxAllocation: 0,
                specialPrice: 0,
                stockBalance: 0,
                suggestedQty: 0,
                uom: 'Carton'
            }];

            this.selectedProduct = defaultProduct.productId;
            this.populateSelectedProductDetails(this.selectedProduct);
            */
            this.selectedProduct = defaultProduct.productId;
            this.populateSelectedProductDetails(this.selectedProduct);
        } else {
            this.selectedProduct = null;
            this.orderItemResponceData = [];
            this.isSelectedProduct = false;
        }
    }
    handleWholeSalerChange(event) {
        this.selectedWholeSaler = event.detail.payload.values;
        console.log('this.selectedWholeSaler...' + this.selectedWholeSaler);
        if (this.isPreBook && this.selectedWholeSaler !== null) {
            this.getPreBookWholeSalerOptions();
            //this.isOOSSpinner = true;
            // this.wholeSaleOrderCode = this.wholeSalerOptions[0].skuCode;
            const selectedWholesaler = this.wholeSalerOptions.find(
                item => item.value === this.selectedWholeSaler
            );

            this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
           
        }
        }
    handleSelectRecord(event) {
        this.selectedProduct = event.currentTarget.dataset.id;
        console.log('this.orderItemResponceData....' + JSON.stringify(this.orderItemResponceData));
        this.oosData = this.oosData.map(group => ({
            ...group,
            items: group.items.map(prod => ({
                ...prod,
                ariaSelected: prod.productId === this.selectedProduct ? 'true' : 'false'
            }))
        }));

        const exists = this.orderItemResponceData.some(
            item => item.productId === this.selectedProduct
        );

        // If not exists, create default "Carton" line item entry
        if (!exists) {
            const productObj = this.oosData.flatMap(group => group.items).find(p => p.productId === this.selectedProduct);

            if (productObj) {
                const defaultCartonItem = {
                    basePrice: 0,
                    orderItemId: '',
                    productId: productObj.productId,
                    productName: productObj.productName,
                    quantity: 0,
                    specialPrice: 0,
                    suggestedQty: 0,
                    uom: 'Carton'
                };

                this.orderItemResponceData.push(defaultCartonItem);
            }
        }
        this.populateSelectedProductDetails(this.selectedProduct);

    }
    populateSelectedProductDetails(selectedProduct) {
        console.log('Selected Product ID:', selectedProduct);
        console.log('Order Item Response Data:', JSON.stringify(this.orderItemResponceData));

        const selectedItems = this.orderItemResponceData.filter(item => item?.productId === selectedProduct);
        const productObj = this.oosData.flatMap(group => group.items).find(p => p.productId === this.selectedProduct);
        if (!productObj) {
            this.isSelectedProduct = false;
            return;
        }
        // this.productCode = productObj?.product.cgcloud__Consumer_Goods_Product_Code__c || '';
        const cashSaleTypeId = this.typeOptionsAll.find(type => type.label === 'Cash Sale')?.value;
        const orderItemTypeId = selectedItems.find(item => item.typeId)?.typeId || null;
        const oosTypeId = productObj.typeId || null;
        /* Original logic always pulled from the first order item, even if the product had no order lines:
        this.selectedTypeValue = selectedItems[0].typeId || cashSaleTypeId;
        */
        this.selectedTypeValue = orderItemTypeId || oosTypeId || cashSaleTypeId;
        console.log('selectedItems[0]?.typeId..' + (selectedItems[0]?.typeId));
        const selectedTypeLabel = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue)?.label || '';
        console.log('selectedTypeLabel...' + selectedTypeLabel);
        this.isPreBook = selectedTypeLabel === 'Prebook';
        if (this.isPreBook) {
            this.getPreBookWholeSalerOptions();
        }
        const primaryOrderItem = selectedItems[0];
        this.selectedWholeSaler = primaryOrderItem?.wholeSalerId || '';
        if (this.selectedWholeSaler !== '' && this.selectedWholeSaler !== null) {
            const selectedWholesaler = this.wholeSalerOptions.find(
                item => item.value === this.selectedWholeSaler
            );
            this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
        }
        console.log('productObj...', JSON.stringify(productObj));
        console.log('selectedItems...', JSON.stringify(selectedItems));
        this.selectedProductName = productObj?.productName || '';
        this.stockBalance = parseFloat(productObj?.stockBalance).toFixed(2) || 0;
        this.basePriceValue = productObj?.basePrice || 0;
        this.suggestedQty = productObj?.suggestedQty || 0;
        this.cartonPiecesCount = productObj?.cartonPieces || 0;
        this.maxAllocationValue = productObj?.maxAllocation || 0;
        //this.isEach = this.cartonPiecesCount > 1 ? true : false;


        const typeConfig = {
            'Return':  { isCarton: false, isEach: true },
            'Prebook': { isCarton: true,  isEach: false }
        };

        const config = typeConfig[selectedTypeLabel] || { isCarton: true, isEach: true };

        this.isCarton = config.isCarton;
        this.isEach = config.isEach;

        if(selectedTypeLabel == 'Cash Sale'){ 
            this.isEach = this.cartonPiecesCount > 1 ? true : false;
        }
        

        let carton = 0;
        let each = 0;

        let cartonItem = {};
        let eachItem = {};

        if (selectedItems.length > 0) {
            cartonItem = selectedItems.find(item => item.uom === 'Carton') || {};
            eachItem = selectedItems.find(item => item.uom === 'Each') || {};

            carton = cartonItem.quantity || 0;
            each = eachItem.quantity || 0;

            console.log('each...', JSON.stringify(each));
            this.unitPriceOfCarton = cartonItem.basePrice || 0;
            this.specialPriceValue = cartonItem.specialPrice || 0;
        } else {
            cartonItem = {};
            eachItem = {};
            carton = 0;
            each = 0;
            this.unitPriceOfCarton = 0;
            this.specialPriceValue = 0;
        }
        const piecesCount = this.cartonPiecesCount > 0 ? this.cartonPiecesCount : 1;
        if (each > 0) {
            this.unitPriceOfEach =
                eachItem.basePrice > 0
                    ? eachItem.basePrice.toFixed(2)
                    : (this.unitPriceOfCarton > 0 && piecesCount > 0)
                        ? (this.unitPriceOfCarton / piecesCount).toFixed(2)
                        : 0;
        } else {
            this.unitPriceOfEach = 0;
        }
        console.log('333...',);
        this.eachValue = each;
        this.cartonValue = carton;

        this.orderLineItemCalculation();
        console.log('444...',);
        const updatedSelectedItems = {
            productId: selectedProduct,
            cartonOrderLineItemId: cartonItem.orderItemId || '',
            eachOrderLineItemId: eachItem.orderItemId || ''
        };

        console.log('Final selected product object:', JSON.stringify(updatedSelectedItems));
        console.log('555...',);
        this.selectedProductData = updatedSelectedItems;
        this.isSelectedProduct = !!selectedProduct;
    }


    increaseQuantity(event) {
        const orderItemId = event.currentTarget.dataset.orderitemId || null;
        const uomType = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        this.debounceTimeout = setTimeout(async() => {
            console.log('item...inc..', orderItemId);
            console.log('uomType...inc..', uomType);
            console.log('name...inc..', name);
            console.log('productId...inc..', this.selectedProduct);

            // Step 1: Increment the correct value
            if (name && this[name] !== undefined) {
                this[name]++;
            }


            // Step 3: Define base and special price calculations
            const [cartonItem, eachItem] = ['Carton', 'Each'].map(uom =>
                this.orderItemResponceData.find(item => item.uom === uom && item.productId === this.selectedProduct)
            );

            let quantityValue = (uomType === 'Carton') ? this.cartonValue : this.eachValue;
            const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
            console.log('specialPriceValidateResponse:', specialPriceValidateResponse);
            if (!specialPriceValidateResponse.isValid) {
                this.specialPriceValue = 0.00;
                return; 
            }
            const specialPriceOfEach = this.orderLineItemCalculation();
            console.log('quantityValue:', quantityValue);
            console.log('eachValue:', this.eachValue);
            console.log('specialPriceValue:', this.specialPriceValue);
            console.log('selectedProductData:', JSON.stringify(this.selectedProductData));
            const orderLineItemType = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue).label;
            let specialCartonPrice = this.specialPriceValue;
            let specialPriceEach = specialPriceOfEach;
            if (orderLineItemType === 'Return') {
                specialCartonPrice = -1 * specialCartonPrice;
                specialPriceEach = -1 * specialPriceEach;
            }

            
            // Step 5: Handle special price changes
            if (name === 'specialPriceValue' && this.specialPriceValue > 0) {

                if (cartonItem) {
                    this.generateResponseBody(
                        this.selectedProduct,
                        'Carton',
                        cartonItem.quantity,
                        this.basePriceValue,
                        specialCartonPrice,
                        cartonItem?.orderItemId,this.selectedWholeSaler || null
                    );
                }

                if (eachItem && this.isEach) {
                    this.eachValue = eachItem.quantity;
                    this.generateResponseBody(
                        this.selectedProduct,
                        'Each',
                        eachQty,
                        this.basePriceValue,
                        specialPriceEach,
                        eachItem?.orderItemId,this.selectedWholeSaler || null
                    );
                }
            }

            // Step 6: Handle quantity change
            if (quantityValue > 0 && name !== 'specialPriceValue') {
                // const finalSpecialPrice = this.specialPriceValue > 0 ? this.specialPriceValue : 0;
                const finalSpecialPrice = name === 'cartonValue' ? specialCartonPrice : specialPriceEach;
                this.generateResponseBody(
                    this.selectedProduct,
                    uomType,
                    quantityValue,
                    this.basePriceValue,
                    finalSpecialPrice,
                    orderItemId,this.selectedWholeSaler || null
                );
            }
        }, 500);
    }

    decreaseQuantity(event) {

        const uom = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;

        const orderItemId = event.currentTarget.dataset.orderitemId;
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        this.debounceTimeout = setTimeout(async() => {
            console.log('uomType...dec..', uom);
            console.log('orderItemId...dec..', orderItemId);
            console.log('productId...dec..', this.selectedProduct);

            // Step 1: Decrement the value but avoid going below 0
            if (name && this[name] !== undefined && this[name] > 0) {
                this[name]--;
            }
            // Step 3: Define base and special price calculations
            const [cartonItem, eachItem] = ['Carton', 'Each'].map(uom =>
                this.orderItemResponceData.find(item => item.uom === uom && item.productId === this.selectedProduct)
            );
            const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
            console.log('specialPriceValidateResponse:', specialPriceValidateResponse);
            if (!specialPriceValidateResponse.isValid) {
                this.specialPriceValue = 0.00;
                return; 
            }
            const specialPriceOfEach = this.orderLineItemCalculation();
            const orderLineItemType = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue).label;
            let specialCartonPrice = this.specialPriceValue;
            let specialPriceEach = specialPriceOfEach;
            if (orderLineItemType === 'Return') {
                specialCartonPrice = -1 * specialCartonPrice;
                specialPriceEach = -1 * specialPriceEach;
            }
            const quantityValue = uom === 'Carton' ? this.cartonValue : this.eachValue;

            
            if (name === 'specialPriceValue' && this.specialPriceValue > 0) {

                if (cartonItem) {
                    this.generateResponseBody(
                        this.selectedProduct,
                        'Carton',
                        cartonItem.quantity,
                        this.basePriceValue,
                        specialCartonPrice,
                        cartonItem?.orderItemId,this.selectedWholeSaler || null
                    );
                }

                if (eachItem && this.isEach) {
                    this.eachValue = eachItem.quantity;
                    this.generateResponseBody(
                        this.selectedProduct,
                        'Each',
                        eachQty,
                        this.basePriceValue,
                        specialPriceEach,
                        eachItem?.orderItemId,this.selectedWholeSaler || null
                    );
                }
            }
            // Step 5: Prevent negative or invalid data
            if (quantityValue > 0 && name !== 'specialPriceValue') {
                const finalSpecialPrice = name === 'cartonValue' ? specialCartonPrice : specialPriceEach;
                // const finalSpecialPrice = this.specialPriceValue > 0 ? this.specialPriceValue : 0;

                this.generateResponseBody(
                    this.selectedProduct,
                    uom,
                    quantityValue,
                    this.basePriceValue,
                    finalSpecialPrice,
                    orderItemId,this.selectedWholeSaler || null
                );
            } else if (quantityValue == 0 && name !== 'specialPriceValue') {
                this.deleteOrderLineItem(orderItemId);
            } else {
                console.warn('Invalid quantityValue:', quantityValue);
            }
        }, 500);
    }


    async handleChange(event) {
        //const { productId, uom, orderItemId } = event.target.dataset;
        const name = event.currentTarget.name;
        const uom = event.target.dataset.uom;
        const orderItemId = event.currentTarget.dataset.orderitemId;
        
        // const newVal = parseInt(event.target.value, 10);
        // const parsedValue = isNaN(newVal) || newVal < 0 ? 0 : newVal;


         console.log(`orderItemId...ip..${orderItemId}`);
         let roundedValue = (name != 'specialPriceValue') ? (Math.round(event.target.value)) : event.target.value;
         const newVal = parseFloat(roundedValue, 10).toFixed(2);
        const parsedValue = isNaN(newVal) || newVal < 0 ? 0 : newVal;

        if (roundedValue <= 0 && orderItemId){
            this.deleteOrderLineItem(orderItemId);
            return;
        } 


        // console.log(`item...ip..${orderitemId}`);
        console.log(`uomType...ip..${uom}`);
        console.log(`inputName...ip..${name}`);
        console.log(`parsedValue...ip..${parsedValue}`);

        const isEachSpc = name === 'eachSpcPriceValue';
        const isCartonSpc = name === 'cartonSpcPriceValue';
        const canSetSpecialPrice =
            (isEachSpc && this.eachValue > 0) ||
            (isCartonSpc && this.cartonValue > 0);

        if ((isEachSpc || isCartonSpc) && !canSetSpecialPrice) {
            this[name] = 0;
            console.warn(`${name} not allowed when corresponding quantity is 0`);
        } else {
            this[name] = parsedValue;
        }

        const [cartonItem, eachItem] = ['Carton', 'Each'].map(uom =>
            this.orderItemResponceData.find(item => item.uom === uom && item.productId === this.selectedProduct)
        );

        const quantityValue = uom === 'Carton' ? this.cartonValue : this.eachValue;
        const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
        console.log('specialPriceValidateResponse:', specialPriceValidateResponse);
        if (!specialPriceValidateResponse.isValid) {
            this.specialPriceValue = 0.00;
            return; 
        }
        const specialPriceOfEach = this.orderLineItemCalculation();
        const orderLineItemType = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue).label;
        let specialCartonPrice = this.specialPriceValue;
        let specialPriceEach = specialPriceOfEach;
        if (orderLineItemType === 'Return') {
            specialCartonPrice = -1 * specialCartonPrice;
            specialPriceEach = -1 * specialPriceEach;
        }

        
        if (name === 'specialPriceValue' && this.specialPriceValue > 0) {

            if (cartonItem) {
                this.generateResponseBody(
                    this.selectedProduct,
                    'Carton',
                    cartonItem.quantity,
                    this.basePriceValue,
                    specialCartonPrice,
                    cartonItem?.orderItemId,
                    this.selectedWholeSaler || null
                );
            }

            if (eachItem && this.isEach) {
                this.eachValue = eachItem.quantity;
                this.generateResponseBody(
                    this.selectedProduct,
                    'Each',
                    eachQty,
                    this.basePriceValue,
                    specialPriceEach,
                    eachItem?.orderItemId,this.selectedWholeSaler || null
                );
            }
        }
        if (quantityValue > 0 && name !== 'specialPriceValue') {
            // const finalSpecialPrice = this.specialPriceValue > 0 ? this.specialPriceValue : 0;
            const finalSpecialPrice = name === 'cartonValue' ? specialCartonPrice : specialPriceEach;
            this.generateResponseBody(this.selectedProduct, uom, quantityValue, this.basePriceValue, finalSpecialPrice, orderItemId,this.selectedWholeSaler || null);
        } else if (quantityValue == 0 && name !== 'specialPriceValue') {
            this.deleteOrderLineItem(orderItemId);
        }
    }
    async validateSpecialPrice(basePrice, specialPrice) {
            // Edge case: invalid special price
            if (specialPrice == null || isNaN(specialPrice)) {
                const result = await LightningConfirm.open({
                                message: 'Special Price is required and must be a number.',
                                variant: "default",
                                label: "Info"
                            });
                // if(result){
                    
                // }
                return {isValid: false};
    
            }
            if (specialPrice === 0) {
                return { isValid: true };
            }
            // Always enforce: special price must not exceed this.customSettingLimits.Max_Limit_Spl_Price__c
            if (specialPrice > this.customSettingLimits.Max_Limit_Spl_Price__c) {
                const result = await LightningConfirm.open({
                                message: `Special Price cannot exceed (${(this.customSettingLimits.Max_Limit_Spl_Price__c).toFixed(2)}).`,
                                variant: "default",
                                label: "Info"
                            });
                // if(result){
                //     return {isValid: false};
                // }
                return {isValid: false};
            }
            // If base price is not present or invalid, skip base price comparison
            if (basePrice == null || isNaN(basePrice) || basePrice === 0) {
                return { isValid: true };
            }
            // Calculate limits
            const lowerLimit = basePrice * 0.90;  // 10% lower
            //const upperLimit = Math.min(basePrice * 1.25, this.customSettingLimits.Max_Limit_Spl_Price__c);  // 25% higher or 200, whichever is lower
            const upperLimit = basePrice * 1.25;
            if (specialPrice < lowerLimit) {
                const result = await LightningConfirm.open({
                                message: `Special Price cannot be less than 10% of Base Price (${lowerLimit.toFixed(2)}).`,
                                variant: "default",
                                label: "Info"
                            });
                // if(result){
                //     return {isValid: false};
                // }
                return {isValid: false};
            }
            if (specialPrice > upperLimit) {
                const result = await LightningConfirm.open({
                                message: `Special Price cannot be more than 25% of Base Price (${upperLimit.toFixed(2)}).`,
                                variant: "default",
                                label: "Info"
                            });
                // if(result){
                //     return {isValid: false};
                // }
                return {isValid: false};
            }
            return { isValid: true };
        }

    async generateResponseBody(productId, uomType, quantityValue, basePrice, specialPriceValue, orderItemId, wholeSalerId) {
        if (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === '')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Whole Saler is required',
                    message: 'Whole Saler is required',
                    variant: 'error'
                })
            );
            this.cartonValue = 0; 
        }
        if(quantityValue <= 0 || (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === ''))) return;

        this.isOOSSpinner = true;
        // const matchedItem = this.orderItemResponceData.find(item => item.productId === this.selectedProduct);
        // //const orderItemId = matchedItem ? matchedItem.orderItemId : null;
        // if (matchedItem && matchedItem.orderItemId && this.selectedTypeValue != matchedItem.typeId) {
        //     console.log("OrderItemId found:", matchedItem.orderItemId);
        //     this.deleteOrderLineItem(matchedItem.orderItemId);
        // }
        const matchedItem = this.orderItemResponceData.find(item => item.productId === this.selectedProduct);
            //const orderItemId = matchedItem ? matchedItem.orderItemId : null;
            if (matchedItem && matchedItem.orderItemId && this.selectedTypeValue != matchedItem.typeId) {
                console.log("OrderItemId found:", matchedItem.orderItemId);
                const deletedOrderLineItemId = await this.deleteOrderLineItem(matchedItem.orderItemId);
                console.log('deletedOrderLineItemId:', deletedOrderLineItemId);
                
                console.log('orderItemId:', orderItemId);
                if(deletedOrderLineItemId == orderItemId){
                    orderItemId = null;
                    console.log("orderItemId empty:", orderItemId);
                }
            }

        
        
        console.log('generateResponseBody...');
        const responseBody = [{
            orderItemId: orderItemId || null,
            productId,
            specialPrice: specialPriceValue,
            uom: uomType,
            quantity: quantityValue,
            basePrice: basePrice,
            suggestedQty: this.suggestedQtyValue,
            typeId: this.selectedTypeValue,
            wholeSalerId: wholeSalerId || null,
            isPromoted: false,
            reimbursableAmount: 0,
            promotionId: null
        }];
        console.log('responseBody:', JSON.stringify(responseBody));
        createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) })
            .then(resp => {
                console.log('resp...' + JSON.stringify(resp));
                this.processOrderItems();
            }).catch(error => {
                console.error('error...' + JSON.stringify(error));
            });
    }
    async deleteOrderLineItem(orderLineItemId) {
        try {
            if(!orderLineItemId) return;
            if (!this.isOOSSpinner) this.isOOSSpinner = true;
            
            
            await deleteRecord(orderLineItemId);

            console.log('Deleted record ' + orderLineItemId);
            this.processOrderItems();
            refreshApex(this.refreshOOSItems);

            return orderLineItemId;
        } catch (error) {
            console.error('Error deleting Order Line Item:', error);
            return null; // or throw error if you want the caller to handle it
        }
    }

    deleteOrderLineItem_Old(orderLineItemId) {
        this.isOOSSpinner = true;

        deleteRecord(orderLineItemId)
            .then(() => {
                console.log('Deleted record ' + orderLineItemId);
    //             this.oosData.forEach(group => {
    //     group.items.forEach(item => {
    //         if (item.orderItemId === orderLineItemId) {
    //             // Reset values
    //             item.basePrice = 0;
    //             item.orderItemId = '';
    //             item.quantity = 0;
    //             item.maxAllocation = 0;
    //             item.specialPrice = 0;
    //             item.stockBalance = 0;
    //             item.suggestedQty = 0;
    //             item.uom = 'Carton';
    //         }
    //     });
                // });
                refreshApex(this.refreshOOSItems);
                this.processOrderItems();

                // setTimeout(() => {
                //     const selectedItems = this.orderItemResponceData.filter(item => item?.productId === this.selectedProduct);
                //     console.log('selectedItems..' + JSON.stringify(selectedItems));
                //     this.selectedProductData = selectedItems.length > 0 ? selectedItems : [];
                //     this.isSelectedProduct = selectedItems.length > 0;
                //     console.log('selectedProductData..' + JSON.stringify(this.selectedProductData));
                //     console.log('this.isSelectedProduct ..' + this.isSelectedProduct);
                // }, 400);
            })
            .catch(error => {
                console.error('Error deleting Order Line Item:', error);
            });
    }

    orderLineItemCalculation() {
        let specialPriceOfEach;
        console.log('666...',);
        console.log('this.typeOptionsAll...', JSON.stringify(this.typeOptionsAll));
        const orderLineItemType = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue).label;
        console.log('34343...',);
        if (orderLineItemType === 'Return') {
            console.log('4455...',);
            // this.specialPriceValue = 0;
            // specialPriceOfEach = (this.specialPriceValue > 0 && this.cartonPiecesCount > 0)
            //     ? (this.specialPriceValue / this.cartonPiecesCount).toFixed(2)
            //     : 0;
            specialPriceOfEach = (this.specialPriceValue > 0)
                ? (this.specialPriceValue)
                : 0;
            console.log('777...',);
            this.unitPriceOfEach = (this.unitPriceOfCarton > 0 && this.cartonPiecesCount > 0)
                ? (this.unitPriceOfCarton / this.cartonPiecesCount).toFixed(2)
                : 0;
            // this.unitPriceOfEach = (this.unitPriceOfCarton > 0)
            //     ? (this.unitPriceOfCarton).toFixed(2)
            //     : 0;
            console.log('888...',);
            // if (this.specialPriceValue > 0) {
            //     this.totalPriceOfEach = -1 * (specialPriceOfEach * this.eachValue).toFixed(2);
            //     this.totalPriceOfCarton = -1 * (this.specialPriceValue * this.cartonValue).toFixed(2);
            // } else {
            //     this.totalPriceOfEach = -1 * (this.unitPriceOfEach * this.eachValue).toFixed(2);
            //     this.totalPriceOfCarton = -1 * (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
            // }
            if (this.specialPriceValue > 0) {
                this.totalPriceOfEach =  parseFloat((-1 * specialPriceOfEach * this.eachValue).toFixed(2));
                this.totalPriceOfCarton = parseFloat((-1 * this.specialPriceValue * this.cartonValue).toFixed(2)); 
            } else {
                this.totalPriceOfEach = parseFloat((-1 * this.unitPriceOfEach * this.eachValue).toFixed(2));  
                this.totalPriceOfCarton = parseFloat((-1 * this.unitPriceOfCarton * this.cartonValue).toFixed(2)); 
            }
            console.log('999...',);
        } else {
            console.log('000...',);
            specialPriceOfEach = (this.specialPriceValue > 0 && this.cartonPiecesCount > 0)
                ? this.specialPriceValue / this.cartonPiecesCount
                : 0;

            this.unitPriceOfEach = (this.unitPriceOfCarton > 0 && this.cartonPiecesCount > 0)
                ? (this.unitPriceOfCarton / this.cartonPiecesCount).toFixed(2)
                : 0;

            // Step 4: Calculate totals
            if (this.specialPriceValue > 0) {
                this.totalPriceOfCarton = (this.specialPriceValue * this.cartonValue).toFixed(2);
                this.totalPriceOfEach = (specialPriceOfEach * this.eachValue).toFixed(2);
            } else {
                this.totalPriceOfCarton = (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
                this.totalPriceOfEach = (this.unitPriceOfEach * this.eachValue).toFixed(2);
            }
            console.log('123...',);

        }
        return specialPriceOfEach;
    }
    handleSearchChange(event) {
        const searchVal = event.target.value?.toLowerCase().trim();
        if (searchVal && this.allSelectedProductsArray?.length) {
            this.oosData = this.allSelectedProductsArray
                .map(group => {
                    const filteredItems = group.items.filter(item =>
                        Object.values(item).some(val =>
                            typeof val === 'string' && val.toLowerCase().includes(searchVal)
                        )
                    );
                    return { ...group, items: filteredItems };
                })
                .filter(group => group.items.length > 0);
            this.isSelectedProduct = false;
            this.isOOSProductsArray = this.oosData.length > 0;
        } else {
            // Reset to full list
            this.oosData = JSON.parse(JSON.stringify(this.allSelectedProductsArray));
              const selectedProductIds = this.oosData.flatMap(group =>group.items.filter(item => item.ariaSelected === "true").map(item => item.productId));
            if (selectedProductIds.length > 0) {

                const selectedId = selectedProductIds[0];
                console.log('selectedId...' + selectedId);
                        this.handleSelectRecord({ currentTarget: { dataset: { id: selectedId } } });
            }
            this.isOOSProductsArray = this.oosData.length > 0;
             this.isSelectedProduct = this.oosData.length > 0;
        }
    }
}