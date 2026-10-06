import { LightningElement, wire, api, track } from 'lwc';
import suggestedOrderPrebook from '@salesforce/apex/TPB_OnlineAppController.suggestedOrderPrebook';
import getPrebookWholesaler from '@salesforce/apex/TPB_OnlineAppController.getPrebookWholesaler';
import createOrderLineItems from '@salesforce/apex/TPB_OnlineAppController.createOrderLineItems';
import getOrderItemTemplates from '@salesforce/apex/TPB_OnlineAppController.getOrderItemTemplates';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
export default class CgCloudTPBPromoPrebook extends LightningElement {
    @api accountId;
    @api orderId;
    tpbPromo = true;
    @track isMainSpinner = true;
    @track isselectedProductsArray = false;
    @track isSelectedProduct = false;
    @track selectedProductName;
    @track productCode;
    @track maxAllocationValue;
    @track selectedProduct;
    @track allSelectedProductsArray = [];
    @track unitPriceOfCarton = 0.00;
    @track cartonValue = 0;
    @track totalPriceOfCarton = 0.00;
    @track suggestedQty = 0.00;
    @track wholeSaleOrderCode = '';
    @track refreshSuggestedOrderPrebookData = '';
    @track lineItemId;
    @track selectedWholeSaler;
    @track wholeSalerOptions = [];
    @track suggestedOrderPrebook = [];
    @track isPreBook = true;
    @track UomType = 'Carton';
 

    async connectedCallback() {
        await this.getTypeOptions();
    }
    @wire(suggestedOrderPrebook, { accountId: '$accountId', orderId: '$orderId', tpbPromo: '$tpbPromo' })
    async wireSuggestedOrderPrebook(result) {
        // this.isMainSpinner = true;
        this.refreshSuggestedOrderPrebookData = result;
        const { data, error } = result;
        this.allSelectedProductsArray = [];
        if (data) {
            console.log('suggestedOrderPrebook data1..', JSON.stringify(data));
            if (data.length) {
                this.isMainSpinner = false;
                const groupedData = {};
                await this.getTypeOptions();
                data.map(item => {
                    const enrichedItem = {
                        productId: item.productId,
                        productName: item.productName,
                        Carton: item.lineItemQty || 0,
                        suggestedQty: item.minQty || 0,
                        quantity: item.lineItemQty || 0,
                        maxAllocation: item.maxQty || 0,
                        wholeSalerId: item.wholeSalerId,
                        typeId: item.typeId || '',
                        productCode: item.cgcProductCode,
                        typeLabel: 'Prebook',
                        orderItemId: item.lineItemId || null,
                        ariaSelected: 'false'
                    };
                    const groupKey = '05715';
                    if (!groupedData[groupKey]) {
                        groupedData[groupKey] = [];
                    }

                    groupedData[groupKey].push(enrichedItem);
                });
                const firstGroupKey = Object.keys(groupedData)[0];
                if (firstGroupKey && groupedData[firstGroupKey].length > 0) {
                    groupedData[firstGroupKey][0].ariaSelected = 'true';
                }
                this.suggestedOrderPrebook = Object.keys(groupedData).map(label => ({
                    label,
                    items: groupedData[label]
                }));
                let productObj;
                this.allSelectedProductsArray = JSON.parse(JSON.stringify(this.suggestedOrderPrebook));
                await this.getPreBookWholeSalerOptions();
                console.log('suggestedOrderPrebook data2..', JSON.stringify(this.suggestedOrderPrebook));


                if (this.selectedProduct) { console.log('this.selectedProduct...111', this.selectedProduct);
                    productObj = this.suggestedOrderPrebook
                        .flatMap(group => group.items)
                        .find(p => p.productId === this.selectedProduct);
                } else { 
                    // Otherwise use first one
                    productObj = this.suggestedOrderPrebook?.[0]?.items?.[0];
                    this.selectedProduct = productObj?.productId;
                     console.log('this.selectedProduct...222', this.selectedProduct);
                }

                console.log('productObj...111'+JSON.stringify(productObj));
                
                this.isselectedProductsArray = !!productObj;
                this.isSelectedProduct = !!productObj && this.suggestedOrderPrebook.length > 0;
                
                if (productObj) {
                    this.selectedProductName = productObj.productName;
                    this.maxAllocationValue = productObj.maxAllocation;
                    this.suggestedQty = productObj.suggestedQty;
                    this.lineItemId = productObj.orderItemId;
                    this.cartonValue = productObj.Carton;
                    //this.typeId = productObj.typeId;
                    //console.log('this.typeId...111'+this.typeId);
                    this.productCode = productObj.productCode || '';
                    this.selectedWholeSaler = productObj.wholeSalerId || null;
                }
                
                
               
            }else{
                this.isMainSpinner = false;
            }
        } else if (error) {
            this.isMainSpinner = false;
            console.error('suggestedOrderPrebook error:', error);
        }
    }

    async getPreBookWholeSalerOptions() {
        await getPrebookWholesaler({ accountId: this.accountId, productId: this.selectedProduct })
            .then(result => {
                console.log('wholeSaler...' + JSON.stringify(result));
                this.wholeSalerOptions = result.map(item => ({
                    label: item.accountName || '',
                    value: item.accountId || '',
                    sublabel: `Wholesale Order Code ${item.sku || ''}`,
                    skuCode: item.sku
                }));
                console.log(
                    'wholeSalerOptions...' + JSON.stringify(this.wholeSalerOptions));
                // this.wholeSaleOrderCode = this.wholeSalerOptions[0].skuCode;
                if(this.selectedWholeSaler !== '' && this.selectedWholeSaler !== null){
                    const selectedWholesaler = this.wholeSalerOptions.find(
                        item => item.value === this.selectedWholeSaler
                    );
        
                    this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
                }
                
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
    async getTypeOptions() {
        await getOrderItemTemplates()
            .then(result => {
                this.typeOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
                this.typeId = this.typeOptions.find(type => type.label === 'Prebook').value;
                console.log('this.typeId...222'+this.typeId);
            }).catch(error => {
                console.error('getOrderItemTemplates error: ' + JSON.stringify(error));
            })
    }
    async handleSelectRecord(event) {
        this.selectedProduct = event.currentTarget.dataset.id;
        console.log('this.selectedProduct...000'+this.selectedProduct);
        this.suggestedOrderPrebook = this.suggestedOrderPrebook.map(group => ({
            ...group,
            items: group.items.map(prod => ({
                ...prod,
                ariaSelected: prod.productId === this.selectedProduct ? 'true' : 'false'
            }))
        }));
        console.log('this.suggestedOrderPrebook data3..' + JSON.stringify(this.suggestedOrderPrebook));
            const productObj = this.suggestedOrderPrebook
            .flatMap(group => group.items)
            .find(p => p.productId === this.selectedProduct);
        
        this.isSelectedProduct = !!productObj;
        this.isselectedProductsArray = !!productObj;
        console.log('productObj...333'+JSON.stringify(productObj));
        if (productObj) {
            this.selectedProductName = productObj.productName;
            this.maxAllocationValue = productObj.maxAllocation;
            this.suggestedQty = productObj.suggestedQty;
            this.lineItemId = productObj.orderItemId;
            //this.typeId = productObj.typeId;
            //console.log('this.typeId...333'+this.typeId);
            this.cartonValue = productObj.Carton;
            this.productCode = productObj.productCode || '';
            this.selectedWholeSaler = productObj.wholeSalerId || null;
        }
        await this.getPreBookWholeSalerOptions();
    }

    async handleWholeSalerChange(event) {
        this.selectedWholeSaler = event.detail.payload.values;
        console.log('this.selectedWholeSaler...' + this.selectedWholeSaler);
        if (this.isPreBook && this.selectedWholeSaler !== null) {
            await this.getPreBookWholeSalerOptions();
            // this.isMainSpinner = true;
            const selectedWholesaler = this.wholeSalerOptions.find(
                item => item.value === this.selectedWholeSaler
            );

            this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
        }
    }


    increaseQuantity(event) {
        const orderItemId = event.currentTarget.dataset.orderitemId || null;
        const uomType = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;

        if (!this.selectedWholeSaler || this.selectedWholeSaler === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Whole Saler is required',
                    message: 'Whole Saler is required',
                    variant: 'error'
                })
            );
            return;
        }


        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        
        this.debounceTimeout = setTimeout(() => {
            // this.orderSpinner = true;
            console.log('item...inc..', orderItemId);
            console.log('uomType...inc..', uomType);
            console.log('name...inc..', name);
            console.log('productId...inc..', this.selectedProduct);

            // Step 1: Increment the correct value
            if (name && this[name] !== undefined) {
                this[name]++;
            }

            this.totalPriceOfCarton = (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
            let quantityValue = this.cartonValue;

            if (quantityValue > 0) {
                this.isMainSpinner = true;
                this.generateResponseBody(
                    this.selectedProduct,
                    uomType,
                    quantityValue,
                    0,
                    0,
                    orderItemId, this.selectedWholeSaler || null
                );
            }
        });
    }

    decreaseQuantity(event) {

        const uom = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;
        // this.orderSpinner = true;

        const orderItemId = event.currentTarget.dataset.orderitemId;


        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        this.debounceTimeout = setTimeout(() => {
            console.log('uomType...dec..', uom);
            console.log('orderItemId...dec..', orderItemId);
            console.log('productId...dec..', this.selectedProduct);
            // Step 1: Decrement the value but avoid going below 0
            if (name && this[name] !== undefined && this[name] > 0) {
                this[name]--;
            }

            this.totalPriceOfCarton = (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
            const quantityValue = this.cartonValue;
            // Step 5: Prevent negative or invalid data
            if (quantityValue > 0) {
                this.isMainSpinner = true;

                this.generateResponseBody(
                    this.selectedProduct,
                    uom,
                    quantityValue,
                    0,
                    0,
                    orderItemId, this.selectedWholeSaler || null
                );
            } else if (quantityValue == 0) {
                this.deleteOrderLineItem(orderItemId);
            } else {
                console.warn('Invalid quantityValue:', quantityValue);
            }
        });
    }


    handleChange(event) {
        //const { productId, uom, orderItemId } = event.target.dataset;
        
        

        const name = event.currentTarget.name;
        const uom = event.target.dataset.uom;
        const orderItemId = event.currentTarget.dataset.orderitemId;

        //const newVal = parseInt(event.target.value, 10);
        //const parsedValue = isNaN(newVal) || newVal < 0 ? 0 : newVal;

        console.log(`orderItemId...ip..${orderItemId}`);
         let roundedValue = (name != 'specialPriceValue') ? (Math.round(event.target.value)) : event.target.value;
         const newVal = parseFloat(roundedValue, 10).toFixed(2);
        const parsedValue = isNaN(newVal) || newVal < 0 ? 0 : newVal;

        console.log('this.selectedWholeSaler ' + this.selectedWholeSaler);
        if (!this.selectedWholeSaler || this.selectedWholeSaler === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Whole Saler is required',
                    message: 'Whole Saler is required',
                    variant: 'error'
                })
            );
            event.target.value = 0;
            return;
        }

        if (roundedValue <= 0 && orderItemId){
            this.deleteOrderLineItem(orderItemId);
            return;
        } 

        // this.orderSpinner = true;
        // console.log(`item...ip..${orderitemId}`);
        console.log(`uomType...ip..${uom}`);
        console.log(`inputName...ip..${name}`);
        console.log(`parsedValue...ip..${parsedValue}`);
        const isCartonSpc = name === 'cartonSpcPriceValue';
        const canSetSpecialPrice =
            (isCartonSpc && this.cartonValue > 0);

        if ((isCartonSpc) && !canSetSpecialPrice) {
            this[name] = 0;
            console.warn(`${name} not allowed when corresponding quantity is 0`);
        } else {
            this[name] = parsedValue;
        }

        const quantityValue = this.cartonValue;
        this.totalPriceOfCarton = (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
        if (quantityValue > 0) {
            this.isMainSpinner = true;
            this.generateResponseBody(this.selectedProduct, uom, quantityValue, 0, 0, orderItemId, this.selectedWholeSaler || null);
        } else if (quantityValue == 0) {
            this.deleteOrderLineItem(orderItemId);
        }
    }


    generateResponseBody(productId, uomType, quantityValue, basePrice, specialPriceValue, orderItemId, wholeSalerId) {
        console.log('this.selectedWholeSaler ' + this.selectedWholeSaler);

        if (!this.selectedWholeSaler || this.selectedWholeSaler === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Whole Saler is required',
                    message: 'Whole Saler is required',
                    variant: 'error'
                })
            );
        }
        if(quantityValue <= 0 || (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === ''))) return;
        console.log('generateResponseBody...');
        
        this.typeId = this.typeOptions.find(type => type.label === 'Prebook').value;
        console.log('this.typeId...444'+this.typeId);
        const responseBody = [{
            orderItemId: orderItemId || null,
            productId,
            specialPrice: specialPriceValue,
            uom: uomType,
            quantity: quantityValue,
            basePrice: basePrice,
            suggestedQty: this.suggestedQty,
            wholeSalerId: wholeSalerId || null,
            typeId: this.typeId,
            isPromoted: false,
            reimbursableAmount: 0,
            promotionId: null
        }];
        this.isMainSpinner = true;
        console.log('responseBody:', JSON.stringify(responseBody));
        createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) })
            .then(resp => {
                console.log('resp...' + JSON.stringify(resp));
                refreshApex(this.refreshSuggestedOrderPrebookData);
            }).catch(error => {
                this.isMainSpinner = false;
                console.error('error...' + JSON.stringify(error));
            });
    }

    async deleteOrderLineItem(orderLineItemId) {




        try {
            if(!orderLineItemId) return;
            if (!this.isMainSpinner) this.isMainSpinner = true;
            
            
            await deleteRecord(orderLineItemId);

            console.log('Deleted record ' + orderLineItemId);
            refreshApex(this.refreshSuggestedOrderPrebookData);

            
        } catch (error) {
            console.error('Error deleting Order Line Item:', error);
            this.isMainSpinner = false;
            return null; // or throw error if you want the caller to handle it
        }
    }
    handleSearchChange(event) {
        const searchVal = event.target.value?.toLowerCase().trim();

        // If search value is non-empty, apply filtering
        if (searchVal && this.allSelectedProductsArray?.length) {
            this.suggestedOrderPrebook = this.allSelectedProductsArray
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
            this.isselectedProductsArray = this.suggestedOrderPrebook.length > 0;
    
            console.log('Filtered suggestedOrderPrebook:', JSON.stringify(this.suggestedOrderPrebook));
        } 
        // If search is cleared, show full data
        else {
            this.suggestedOrderPrebook = JSON.parse(JSON.stringify(this.allSelectedProductsArray));
             const selectedProductIds = this.suggestedOrderPrebook.flatMap(group =>group.items.filter(item => item.ariaSelected === "true").map(item => item.productId));
            if (selectedProductIds.length > 0) {

                const selectedId = selectedProductIds[0];
                console.log('selectedId...' + selectedId);
                        this.handleSelectRecord({ currentTarget: { dataset: { id: selectedId } } });
            }
            this.isSelectedProduct = this.suggestedOrderPrebook.length > 0;
            this.isselectedProductsArray = this.suggestedOrderPrebook.length > 0;
            console.log('Search cleared, reset to full list');
        }
    }

}