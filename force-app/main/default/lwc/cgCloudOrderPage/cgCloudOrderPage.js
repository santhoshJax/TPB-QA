import { LightningElement, track, wire, api } from 'lwc';
import getProducts from '@salesforce/apex/TPB_OnlineAppController.getProducts';
import getOrderItems from '@salesforce/apex/TPB_OnlineAppController.getOrderItems';
import createOrderLineItems from '@salesforce/apex/TPB_OnlineAppController.createOrderLineItems';
import updateOrderTotal from '@salesforce/apex/TPB_OnlineAppController.updateOrder';
import getOrderItemTemplates from '@salesforce/apex/TPB_OnlineAppController.getOrderItemTemplates';
import getPromotions from '@salesforce/apex/TPB_OnlineAppController.getPromotions';
import getTacticProducts from '@salesforce/apex/TPB_OnlineAppController.getTacticProducts';
import getRewardsAndHurdles from '@salesforce/apex/TPB_OnlineAppController.getRewardsAndHurdles';
import rewardCriteriaCheck from '@salesforce/apex/TPB_OnlineAppController.rewardCriteriaCheck';
import getRewardProductsGratis from '@salesforce/apex/TPB_OnlineAppController.getRewardProductsGratis';
import getPrebookWholesaler from '@salesforce/apex/TPB_OnlineAppController.getPrebookWholesaler';
import getRewardDiscount from '@salesforce/apex/TPB_OnlineAppController.getRewardDiscount';
import getCGCAppCustomSettings from '@salesforce/apex/TPB_OnlineAppController.getCustomSettings';
import getWholesalerAuthProducts from '@salesforce/apex/TPB_OnlineAppController.getWholesalerAuthProducts';
import cancelOrder from '@salesforce/apex/TPB_OnlineAppController.cancelOrder';
import formFactorPropertyName from '@salesforce/client/formFactor';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";
export default class CgCloudOrderPage extends LightningElement {
    @api orderId;
    @api visitId;
    @api selectedCustomerId;
    @track icon_size = 'small';
    @track isModalOpen = false;
    @track isPreBook = false;
    @track istpbPromoTab = false;
    @track selectedTypeValue = '';
    @track previousTypeValue = '';
    @track rewardProductsData = '';
    @track wholeSaleOrderCode = '';
    @track selectedWholeSaler = '';
    @track productCode;
    @track isPromotionFilter = false;
    @track isGratis = false;
    @track cartonValue = 1;
    @track eachValue = 0;
    @track rewardsApplied = 0;
    @track totalRewards = 1;
    @track selectedProductName;
    @track selectedProductsArray = [];
    @track selectedTab = 'cart';
    @track filterPromotionOptions = '';
    @track refreshGetPromotions = '';
    @track refreshTacticProducts;
    @track selectedPromotionHurdlesLabel;
    @track selectedPromotionLabel;
    @track selectedPromotionValue;
    @track rewardItemsData;
    @track isFiltered = false;
    @track orderSpinner = true;
    @track isCartTab = true;
    @track isOOSTab = false;
    @track isMobile = false;
    @track isselectedProductsArray = false;
    @track isEachCartonDisabled = false;
    @track isEach = true;
    @track isCarton = true;
    @track orderItemResponceData = [];
    @track rewardsProgramList = [];
    @track wholeSalerOptions;
    @track hasRendered = false;
    @track isRewardModel = false;
    @track rewardHelpText = '';
    @track isRewardFulfilled = true;
    @track isRewardGranted = false;
    @track rewardCardStyle = 'background-color: #fc5d5da3;color: #ffffff;';
    @track eachSpcPriceValue = 0;
    @track cartonPiecesCount = 0;
    @track cartonSpcPriceValue = 0;
    @track suggestedQtyValue = 0;
    @track basePriceValue = 0;
    @track maxAllocationValue = 0;
    @track specialPriceValue = 0;
    @track selectedProductData = {
        productId: '',
        cartonOrderLineItemId: '',
        eachOrderLineItemId: ''
    };
    @track unitPriceOfCarton = 0.00;
    @track unitPriceOfEach = 0.00;
    @track totalPriceOfEach = 0.00;
    @track totalPriceOfCarton = 0.00;
    @track stockBalance = 0.00;
    @track suggestedQty = 0.00;
    @track UomType = 'Carton';
    @track promotionHeaderLabel = 'Filter By Promotion...';
    @track listOfProductsData = [];
    @track selectedProductsValue = [];
    @track isSelectedProduct = false;
    @track isRewardsButton = false;
    @track isRewardGraftOpen = false;
    @track productsData = [];
    @track wholesalersData = [];
    @track wholeSalerAuthProductsData;
    @track typeOptions = [];
    @track typeOptionsAll = [];
    @track promotionsOptionsAll = [];
    @track rewardGroupsUI = [];
    @track maxFreeProducts = 1;
    @track rewardFreeSelectionMap = {};
    @track currentRewardId = null;
    @track currentRewardGroupId = null;
    @track customSettingLimits;
    @track isPromotionProductsLimitExceed = false;
    @track isFreeItem = false;
    @track selectedLineItemRecord = [];
    @track selectedLineKey = '';
    layoutResizeHandler;
    layoutAnimationFrameId;
    pendingTypeChange = null;
    getLineKey(productId, typeId) {
        return `${productId || 'NA'}-${typeId || 'NA'}`;
    }
    getCashSaleTypeId() {
        const cashSaleType = this.typeOptionsAll?.find(type => type.label === 'Cash Sale');
        return cashSaleType ? cashSaleType.value : null;
    }
    findOrderItemsByType(productId, typeId) {
        return this.orderItemResponceData.filter(item =>
            item.productId === productId && item.typeId === typeId
        );
    }
    findOrderItemByUom(productId, typeId, uom) {
        return this.orderItemResponceData.find(item =>
            item.productId === productId &&
            item.typeId === typeId &&
            item.uom === uom
        );
    }
    resolveTypeChangeForUpdate(uomType, quantityValue, basePrice, specialPrice, orderItemId) {
        const resolution = {
            orderItemId,
            quantityValue,
            basePrice,
            specialPrice,
            typeId: this.selectedTypeValue,
            deleteOrderItemId: null,
            typeChangeHandled: false,
            newLineKey: orderItemId || this.getLineKey(this.selectedProduct, this.selectedTypeValue)
        };
        const pending = this.pendingTypeChange;
        if (pending && pending.productId === this.selectedProduct && pending.fromTypeId && pending.toTypeId && pending.fromTypeId !== pending.toTypeId) {
            const targetTypeId = pending.toTypeId;
            const targetItem = this.findOrderItemByUom(this.selectedProduct, targetTypeId, uomType);
            if (targetItem) {
                resolution.orderItemId = targetItem.orderItemId;
                resolution.quantityValue = (targetItem.quantity || 0) + quantityValue;
                resolution.basePrice = targetItem.basePrice || basePrice;
                resolution.specialPrice = targetItem.specialPrice || specialPrice;
                resolution.newLineKey = targetItem.orderItemId;
            } else {
                resolution.orderItemId = null;
                resolution.newLineKey = this.getLineKey(this.selectedProduct, targetTypeId);
            }
            resolution.typeId = targetTypeId;
            if (pending.uoms && pending.uoms[uomType]) {
                resolution.deleteOrderItemId = pending.uoms[uomType];
                pending.uoms[uomType] = null;
            }
            resolution.typeChangeHandled = true;
        }
        return resolution;
    }
    async finalizePendingTypeChange(deleteOrderItemId) {
        this.orderSpinner = true;
        if (!this.pendingTypeChange || !this.pendingTypeChange.uoms) {
            return;
        }
        const idsToDelete = new Set(Object.values(this.pendingTypeChange.uoms).filter(Boolean));
        if (deleteOrderItemId) {
            idsToDelete.add(deleteOrderItemId);
        }
        for (const id of idsToDelete) {
            await this.deleteOrderLineItem(id);
        }
        this.orderSpinner = false;
        this.pendingTypeChange = null;
    }
    toggleDropdown() {
        this.isFiltered = !this.isFiltered;
    }
    updateRowHighlight() {
        if (!Array.isArray(this.selectedProductsArray) || !this.selectedProductsArray.length) {
            return;
        }
        const highlightKey = this.selectedLineKey || this.getLineKey(this.selectedProduct, this.selectedTypeValue);
        this.selectedProductsArray = this.selectedProductsArray.map(group => ({
            ...group,
            items: group.items.map(item => ({
                ...item,
                ariaSelected: item.key === highlightKey ? 'true' : 'false'
            }))
        }));
    }
    async handleScanPopupClosed() {
        const previousKeys = new Set(
            (this.orderItemResponceData || []).map(item => item.orderItemId || this.getLineKey(item.productId, item.typeId))
        );
        await this.processOrderItems();
        const newlyAddedItems = this.orderItemResponceData.filter(
            item => !(previousKeys.has(item.orderItemId || this.getLineKey(item.productId, item.typeId)))
        );
        if (newlyAddedItems.length) {
            const firstNew = newlyAddedItems[0];
            const targetLineKey = firstNew.orderItemId || this.getLineKey(firstNew.productId, firstNew.typeId);
            this.selectedProduct = firstNew.productId;
            this.selectedTypeValue = firstNew.typeId;
            this.selectedLineKey = targetLineKey;
            this.populateSelectedProductDetails(this.selectedProduct);
            this.updateRowHighlight();
        }
    }
    async connectedCallback() {
        await this.getTypeOptions();
        await this.getAppCustomSettings();
        await this.getWholesalerAuthProductsInfo();
        this.isMobile = (formFactorPropertyName && (formFactorPropertyName.toLowerCase() === 'small' || formFactorPropertyName.toLowerCase() === 'medium')) ? true : false;
        this.icon_size = this.isMobile ? 'xx-small' : 'small';
        this.layoutResizeHandler = this.handleViewportResize.bind(this);
        window.addEventListener('resize', this.layoutResizeHandler);
    }
    disconnectedCallback() {
        if (this.layoutResizeHandler) {
            window.removeEventListener('resize', this.layoutResizeHandler);
        }
        if (this.layoutAnimationFrameId) {
            cancelAnimationFrame(this.layoutAnimationFrameId);
            this.layoutAnimationFrameId = null;
        }
    }
    async getAppCustomSettings() {
        await getCGCAppCustomSettings()
            .then(result => {
                this.customSettingLimits = result;
            }).catch(error => {
                console.error('getAppCustomSettings error... ' + JSON.stringify(error));
            })
    }
    async getTypeOptions() {
        await getOrderItemTemplates()
            .then(result => {
                if (this.selectedPromotionValue) {
                    this.typeOptions = result
                        .filter(item => item.Name === 'Cash Sale')
                        .map(item => ({
                            label: item.Name,
                            value: item.Id
                        }));
                } else {
                    this.typeOptions = result
                        .filter(item => !['Free Item'].includes(item.Name))
                        .map(item => ({
                            label: item.Name,
                            value: item.Id
                        }));
                }
                this.typeOptionsAll = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
                this.selectedTypeValue = this.typeOptionsAll.find(type => type.label === 'Cash Sale').value;
            }).catch(error => {
                console.error('getOrderItemTemplates error... ' + JSON.stringify(error));
            })
    }
    async getWholesalerAuthProductsInfo() {
        await getWholesalerAuthProducts({ accountId: this.selectedCustomerId })
            .then(result => {
                this.wholeSalerAuthProductsData = result;
            }).catch(error => {
                console.error('getWholesalerAuthProductsInfo error...' + JSON.stringify(error));
            })
    }
    async getPreBookWholeSalerOptions() {
        await getPrebookWholesaler({ accountId: this.selectedCustomerId, productId: this.selectedProduct })
            .then(result => {
                this.wholeSalerOptions = result.map(item => ({
                    label: item.accountName || '',
                    value: item.accountId || '',
                    sublabel: `Wholesale Order Code ${item.sku || ''}`,
                    skuCode: item.sku
                }));
                setTimeout(() => {
                    const singleCombobox = this.template.querySelector('c-custom-lookup-search');
                    if (singleCombobox && this.wholeSalerOptions) {
                        singleCombobox.refreshOptions(this.wholeSalerOptions);
                    }
                }, 0);
            }).catch(error => {
                console.error('getPreBookWholeSalerOptions error...' + JSON.stringify(error));
            })
    }
    @wire(getProducts, { visitId: '$visitId' })
    wireProductsData({ error, data }) {
        if (data) { console.log('wireProductsData data...', JSON.stringify(data));
            this.listOfProductsData = data;
            // this.productsData = data.map(item => ({
            //     label: item.product.Name,
            //     value: item.product.Id
            // }));
            this.productsData = data
            .filter(item => item.product && item.product.Id)
            .map(item => ({
                label: item.product.Name,
                value: item.product.Id
            }));
            this.orderSpinner = false;
            setTimeout(async () => {
                const multiselectCombobox = this.template.querySelector('c-cg-cloud-multiselect-picklist');
                if (multiselectCombobox && this.productsData) {
                    multiselectCombobox.options = this.productsData;
                }
                await this.processOrderItems();
            }, 0);
        } else if (error) {
            console.error('wireProductsData error...', error);
            this.orderSpinner = false;
        }
    }
    @wire(getTacticProducts, { visitId: '$visitId', promotionId: '$selectedPromotionValue', orderId: '$orderId' })
    wireGetTacticProducts(result) {
        this.refreshTacticProducts = result;
        const { data, error } = result;
        if (data) {
            console.log('getTacticProducts data....' + JSON.stringify(data));
            if (data.length) {
                const groupedData = {};
                this.orderItemResponceData = [];
                const matchedProduct = data.find(item => item.product?.Id === this.selectedProduct);
                this.selectedProduct = matchedProduct ? matchedProduct.product.Id : data[0].product.Id;

                data.forEach(item => {
                    const productId = item.product?.Id;
                    const productName = item.product?.Name || '';
                    const productCode = item.product?.cgcloud__Consumer_Goods_Product_Code__c || '';
                    const subCategory = item.product?.cgcloud__Criterion_2_Product__r?.Name || 'Uncategorized';
                    const basePrice = item.basePrice || 0;
                    // If there are order items, render each as its own line; otherwise render a single base line.
                    const itemsToRender = (item.orderItemList && item.orderItemList.length > 0)
                        ? item.orderItemList
                        : [{ uom: null, quantity: 0, typeId: null, orderItemId: null }];
                    itemsToRender.forEach(orderItem => {
                        let defaultLabel = 'Cash Sale';
                        let orderItemId = orderItem.orderItemId;
                        if (orderItem.typeId) {
                            const opt = this.typeOptionsAll.find(o => o.value === orderItem.typeId);
                            defaultLabel = opt?.label || defaultLabel;
                        } else if (item.orderItemList && item.orderItemList.length > 0) {
                            const opt = this.typeOptionsAll.find(o => o.value === item.orderItemList[0]?.typeId);
                            defaultLabel = opt?.label || defaultLabel;
                            orderItemId = item.orderItemList[0]?.orderItemId;
                        }
                        const matchedOption = this.typeOptionsAll.find(opt => opt.label === defaultLabel);
                        const typeLabel = matchedOption?.label || '';
                        const typeIdVal = orderItem.typeId || item.product?.typeId || matchedOption?.value || '';
                        const typeConfig = {
                            'Return': { isCarton: true, isEach: true },
                            'Prebook': { isCarton: true, isEach: false },
                            'Free Item': { isCarton: true, isEach: false }
                        };
                        const promotionMatch = this.promotionsOptionsAll.find(opt => opt.Id === this.selectedPromotionValue);
                        let config = {};
                        if (promotionMatch && promotionMatch.TPB_Promotion_Type__c && promotionMatch.TPB_Promotion_Type__c == 'Product Purchase') {
                            config = { isCarton: false, isEach: true };
                        } else {
                            config = typeConfig[typeLabel] || { isCarton: true, isEach: false };
                        }
                        if (!groupedData[subCategory]) {
                            groupedData[subCategory] = [];
                        }
                        let cartonQty = 0;
                        let eachQty = 0;
                        if (orderItem.uom === 'Carton') {
                            cartonQty = orderItem.quantity || 0;
                        }
                        if (orderItem.uom === 'Each') {
                            eachQty = orderItem.quantity || 0;
                        }
                        if (item.orderItemList && item.orderItemList.length > 0) {
                            this.orderItemResponceData.push(orderItem);
                        }
                        groupedData[subCategory].push({
                            productId,
                            productName,
                            productCode,
                            typeLabel,
                            typeId: typeIdVal,
                            Carton: cartonQty,
                            Each: eachQty,
                            ariaSelected: 'false',
                            isCartonRead: config.isCarton,
                            isEachRead: config.isEach,
                            basePrice: basePrice,
                            key: orderItemId || this.getLineKey(productId, typeIdVal)
                        });
                    });
                });
                this.selectedProductsArray = Object.keys(groupedData).map(subCategory => ({
                    label: subCategory,
                    items: groupedData[subCategory]
                }));
                this.allSelectedProducts = this.allSelectedProducts || [];
                this.allSelectedProducts = JSON.parse(JSON.stringify(this.selectedProductsArray));
                this.isselectedProductsArray = this.selectedProductsArray.length > 0;
                const exists = this.orderItemResponceData.some(
                    item => item.productId === this.selectedProduct
                );
                if (!exists) {
                    const productObj = this.selectedProductsArray.flatMap(group => group.items).find(p => p.productId === this.selectedProduct);
                    const defaultLabel = 'Cash Sale';
                    const matchedOption = this.typeOptionsAll.find(opt => opt.label === defaultLabel);
                    const typeIdVal = matchedOption.value !== ''
                        ? matchedOption.value
                        : '';
                    if (productObj) {
                        const defaultCartonItem = {
                            basePrice: productObj.basePrice,
                            orderItemId: '',
                            productId: productObj.productId,
                            productName: productObj.productName,
                            quantity: 0,
                            specialPrice: 0,
                            suggestedQty: 0,
                            typeId: typeIdVal,
                            uom: 'Carton'
                        };
                        this.orderItemResponceData.push(defaultCartonItem);
                    }
                }
                this.populateSelectedProductDetails(this.selectedProduct);
                this.selectedProductsArray = this.selectedProductsArray.map(group => ({
                    ...group,
                    items: group.items.map(item => ({
                        ...item,
                        ariaSelected: item.key === this.selectedLineKey ? 'true' : 'false'
                    }))
                }));
            }
        } else if (error) {
            console.error('wireGetTacticProducts error... ', JSON.stringify(error));
        }
    }
    @wire(getPromotions, { accountId: '$selectedCustomerId' })
    wiregetPromotions(result) {
        this.refreshGetPromotions = result;
        const { data, error } = result;
        if (data) {
            this.promotionsOptionsAll = data;
            this.updatePromotionOptions(data);
        } else if (error) {
            console.error('wiregetPromotions error... ', error);
        }
    }
    async getRewardDiscountMethod(selectedPromotionId) {
        await getRewardDiscount({ promotionId: selectedPromotionId })
            .then(result => {
                console.log('getRewardDiscountMethod result...' + JSON.stringify(result));
                this.rewardDiscount = result;
            }).catch(error => {
                console.error('getRewardDiscountMethod error... ', JSON.stringify(error));
            })
    }
    updatePromotionOptions(data) {
        const sortedData = [...data].sort((a, b) =>
            a.cgcloud__Slogan__c.localeCompare(b.cgcloud__Slogan__c)
        );
        this.filterPromotionOptions = sortedData.map(item => {
            const isSelected = item.Id === this.selectedPromotionValue;
            return {
                label: item.cgcloud__Slogan__c,
                value: item.Id,
                cssClass: `dropdown-item ${isSelected ? 'selected' : ''}`
            };
        });
    }
    handleWholeSalerChange(event) {
        this.selectedWholeSaler = event.detail.payload.values;
        if (this.isPreBook && this.selectedWholeSaler !== null) {
            const selectedWholesaler = this.wholeSalerOptions.find(
                item => item.value === this.selectedWholeSaler
            );
            this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
        }
    }
    async handleTypeChange(event) {
        this.previousTypeValue = this.selectedTypeValue;
        this.selectedTypeValue = event.detail.value;
        const selectedTypeLabel = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue)?.label;
        this.isFreeItem = (selectedTypeLabel == 'Free Item') ? true : false;
        const previousTypeLabel = this.typeOptionsAll.find(type => type.value === this.previousTypeValue)?.label;
        if (previousTypeLabel !== selectedTypeLabel) {
            this.cartonValue = 0;
            this.eachValue = 0;
            this.specialPriceValue = 0.00;
            this.totalPriceOfEach = 0.00;
            this.totalPriceOfCarton = 0.00;
        }
        const typeConfig = {
            //'Return': { isCarton: false, isEach: true },// To allow only Each in Return
            'Return': { isCarton: true, isEach: true }, // To allow Cartons & Each in Return
            'Prebook': { isCarton: true, isEach: false }
        };
        const config = typeConfig[selectedTypeLabel] || { isCarton: true, isEach: true };
        this.isCarton = config.isCarton;
        this.isEach = config.isEach;
        this.isPreBook = selectedTypeLabel === 'Prebook';
        if (this.isPreBook) {
            await this.getPreBookWholeSalerOptions();
        }
        if (this.selectedProduct && this.previousTypeValue && this.previousTypeValue !== this.selectedTypeValue) {
            const sourceItems = this.findOrderItemsByType(this.selectedProduct, this.previousTypeValue);
            if (sourceItems.length) {
                this.pendingTypeChange = {
                    productId: this.selectedProduct,
                    fromTypeId: this.previousTypeValue,
                    toTypeId: this.selectedTypeValue,
                    uoms: {
                        Carton: sourceItems.find(item => item.uom === 'Carton')?.orderItemId || null,
                        Each: sourceItems.find(item => item.uom === 'Each')?.orderItemId || null
                    }
                };
            } else {
                this.pendingTypeChange = null;
            }
        } else {
            this.pendingTypeChange = null;
        }
        this.updateRowHighlight();
    }
    openProductsModel() {
        this.isModalOpen = true;
        this.selectedProductsValue = [];
        Promise.resolve().then(() => {
            const childCmp = this.template.querySelector('c-cg-cloud-multiselect-picklist');
            if (childCmp) {
                childCmp.clearSelections();
                childCmp.resetDisabledOptions();
            }
        });
    }
    closeModal() {
        this.isRewardModel = false;
    }
    async handleDeleteOrder() {
        const result = await LightningConfirm.open({
            message: 'Are you sure want to Cancel the order.',
            variant: "default",
            label: "Info"
        });
        // if (result) {
        //     this.orderSpinner = true;
        //     deleteRecord(this.orderId)
        //         .then(() => {
        //             this.dispatchEvent(new ShowToastEvent({
        //                 title: "Delete Order ",
        //                 message: "Order deleted successfully",
        //                 variant: "success"
        //             }));
        //             this.orderSpinner = false;
        //             this.dispatchEvent(new CustomEvent('navigate'));
        //         })
        //         .catch(error => {
        //             console.error('handleDeleteOrder error...', error);
        //             this.dispatchEvent(new ShowToastEvent({
        //                 title: "Error",
        //                 message: "Failed to delete Order .",
        //                 variant: "error"
        //             }));
        //         });
        // }
        if (result) {
            this.orderSpinner = true;
            cancelOrder({ orderId: this.orderId })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: "Order Cancelled",
                        message: "Order cancelled successfully",
                        variant: "success"
                    }));
                    this.orderSpinner = false;
                    this.dispatchEvent(new CustomEvent('navigate'));
                })
                .catch(error => {
                    console.error('handleDeleteOrder error...', error);
                });
        }
    }
    
    closeProductModal() {
        this.isModalOpen = false;
        this.selectedProductsValue = [];
        const childCmp = this.template.querySelector('c-cg-cloud-multiselect-picklist');
        if (childCmp) {
            childCmp.clearSelections();
            childCmp.resetDisabledOptions();
        }
    }
    closeRewardGraftModal() {
        this.isRewardGraftOpen = false;
        this.isRewardModel = true;
        this.updateFreeSelectionForCurrentGroup();
    }

    allSelectedProducts = [];
    handleSelectProduct(event) {
        this.selectedProductsValue = event.detail.payload.values;
    }
    handleAddProduct() {
        //if (!Array.isArray(this.selectedProductsValue) || !this.selectedProductsValue.length) return;
        if (!Array.isArray(this.selectedProductsValue) || !this.selectedProductsValue.length) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Selection',
                    message: 'Please select at least one product to proceed.',
                    variant: 'warning'
                })
            );
            return;
        }
        const cashSaleTypeId = this.getCashSaleTypeId();
        if (!cashSaleTypeId) {
            console.warn('Cash Sale order item template not found.');
            return;
        }
        this.orderSpinner = true;
        this.allSelectedProducts = this.allSelectedProducts || [];
        this.selectedProductsArray = this.selectedProductsArray || [];
        this.selectedTypeValue = cashSaleTypeId;
        const childCmp = this.template.querySelector('c-cg-cloud-multiselect-picklist');
        if (childCmp) {
            childCmp.disableSelectedOptions();
        }
        const existingIds = new Set(this.allSelectedProducts.map(item => item.product?.Id));
        const uniqueNewProducts = this.listOfProductsData.filter(item =>
            this.selectedProductsValue.includes(item.product?.Id) &&
            !existingIds.has(item.product?.Id)
        );
        if (uniqueNewProducts.length) {
            this.allSelectedProducts.push(...uniqueNewProducts);
            this.selectedProductsArray = [...this.allSelectedProducts];
            const newlyAddedProductId = uniqueNewProducts[uniqueNewProducts.length - 1]?.product?.Id || null;
            if (newlyAddedProductId) {
                this.selectedProduct = newlyAddedProductId;
                this.selectedLineKey = this.getLineKey(newlyAddedProductId, cashSaleTypeId);
            }
        }
        const responseBody = this.selectedProductsValue.map(prodId => {
            const productId = prodId;
            const matchedProduct = this.listOfProductsData.find(item => item.product?.Id === productId);
            const existingCarton = this.orderItemResponceData.find(item =>
                item.productId === productId &&
                item.typeId === cashSaleTypeId &&
                item.uom === this.UomType
            );
            this.selectedProduct = productId;
            return {
                orderItemId: existingCarton?.orderItemId || null,
                productId,
                specialPrice: this.cartonSpcPriceValue,
                uom: this.UomType,
                quantity: existingCarton ? existingCarton.quantity + 1 : 1,
                basePrice: matchedProduct?.basePrice || 0,
                suggestedQty: matchedProduct?.suggestedQty || 0,
                typeId: cashSaleTypeId,
                isPromoted: !!this.selectedPromotionValue,
                wholeSalerId: existingCarton?.wholeSalerId || null,
                reimbursableAmount: existingCarton?.reimbursableAmount || 0,
                promotionId: this.selectedPromotionValue || existingCarton?.promotionId || null
            };
        });
        if (responseBody.length) {
            createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) })
                .then(async resp => {
                    await this.processOrderItems();
                }).catch(error => {
                    console.error('handleAddProduct error...' + JSON.stringify(error));
                });
        }
        this.isModalOpen = false;
    }
    async processOrderItems() {
        await getOrderItems({ orderId: this.orderId })
            .then(response => {
                console.log('orderLine Items:', JSON.stringify(response));
                if (response.length) {
                    this.orderItemResponceData = response.map(item => ({
                        ...item,
                        key: item.orderItemId || this.getLineKey(item.productId, item.typeId)
                    }));
                    // Extract unique product IDs from order items
                    this.selectedProductsValue = [
                        ...new Set(this.orderItemResponceData.map(item => item.productId).filter(Boolean))
                    ];
                    this.allSelectedProducts = this.allSelectedProducts || [];
                    this.selectedProductsArray = this.selectedProductsArray || [];
                    this.orderSpinner = false;
                    const existingIds = new Set(this.allSelectedProducts.map(item => item.product?.Id));
                    const uniqueNewProducts = this.listOfProductsData.filter(item =>
                        this.selectedProductsValue.includes(item.product?.Id) &&
                        !existingIds.has(item.product?.Id)
                    );
                    if (uniqueNewProducts.length) {
                        this.allSelectedProducts.push(...uniqueNewProducts);
                    }
                    // Default select first product if not already selected
                    const productInfoMap = new Map(
                        this.listOfProductsData.map(item => [item.product?.Id, item.product])
                    );
                    const groupedData = {};
                    response.forEach(item => {
                        const product = productInfoMap.get(item.productId) || {};
                        const productName = product.Name || '';
                        const productCode = product.cgcloud__Consumer_Goods_Product_Code__c || '';
                        const subCategory = product.cgcloud__Criterion_2_Product__r?.Name || 'Uncategorized';
                        const typeLabel = this.typeOptionsAll.find(type => type.value === item.typeId)?.label || '';
                        const uomKey = item.uom;
                        if (!groupedData[subCategory]) {
                            groupedData[subCategory] = [];
                        }
                        const typeConfig = {
                            //'Return': { isCarton: false, isEach: true },// To allow only Each in Return
                            'Return': { isCarton: true, isEach: true }, // To allow Cartons & Each in Return
                            'Prebook': { isCarton: true, isEach: false },
                            'Free Item': { isCarton: true, isEach: false }
                        };
                        const config = typeConfig[typeLabel] || { isCarton: true, isEach: true };
                        //const lineKey = this.getLineKey(item.productId, item.typeId);
                        const lineKey = item.orderItemId || this.getLineKey(item.productId, item.typeId);
                        const existing = groupedData[subCategory].find(prod => prod.lineKey === lineKey);

                        if (existing) {
                            existing[uomKey] = (existing[uomKey] || 0) + item.quantity;
                            if (uomKey === 'Carton') {
                                existing.cartonOrderItemId = item.orderItemId;
                            }
                            if (uomKey === 'Each') {
                                existing.eachOrderItemId = item.orderItemId;
                            }
                            existing.key = existing.cartonOrderItemId || existing.eachOrderItemId || existing.key || lineKey;
                        } else {

                            const newEntry = {
                                key: item.orderItemId || lineKey,
                                lineKey,
                                productId: item.productId,
                                typeId: item.typeId,
                                Carton: 0,
                                Each: 0,
                                productName,
                                productCode,
                                typeLabel,
                                ariaSelected: 'false',
                                isCartonRead: config.isCarton,
                                isEachRead: config.isEach,
                                cartonOrderItemId: null,
                                eachOrderItemId: null
                            };
                            newEntry[uomKey] = item.quantity;
                            if (uomKey === 'Carton') {
                                newEntry.cartonOrderItemId = item.orderItemId;
                            }
                            if (uomKey === 'Each') {
                                newEntry.eachOrderItemId = item.orderItemId;
                            }
                            groupedData[subCategory].push(newEntry);
                        }
                    });
                    this.selectedProductsArray = Object.keys(groupedData).map(subCategory => ({
                        label: subCategory,
                        items: groupedData[subCategory]
                    }));
                    this.allSelectedProductsArray = JSON.parse(JSON.stringify(this.selectedProductsArray));
                    this.isselectedProductsArray = this.selectedProductsArray.length > 0;
                    if (this.orderItemResponceData.length > 0) {
                        let matchedProduct = this.orderItemResponceData.find(item => item.orderItemId === this.selectedLineKey);
                        if (!matchedProduct && this.selectedLineKey) {
                            matchedProduct = this.orderItemResponceData.find(item =>
                                this.getLineKey(item.productId, item.typeId) === this.selectedLineKey
                            );
                        }
                        if (!matchedProduct) {
                            matchedProduct = this.orderItemResponceData.find(item =>
                                item.productId === this.selectedProduct && item.typeId === this.selectedTypeValue
                            );
                        }
                        if (!matchedProduct) {
                            matchedProduct = this.orderItemResponceData.find(item => item.productId === this.selectedProduct) ||
                                this.orderItemResponceData[0];
                        }
                        this.selectedProduct = matchedProduct.productId;
                        this.selectedTypeValue = matchedProduct.typeId;
                        this.selectedLineKey = matchedProduct.orderItemId || this.getLineKey(matchedProduct.productId, matchedProduct.typeId);
                    }
                    this.populateSelectedProductDetails(this.selectedProduct);
                    this.updateRowHighlight();
                } else {
                    this.selectedProductsArray = [];
                    this.isselectedProductsArray = false;
                    this.orderSpinner = false;
                    this.isSelectedProduct = this.isselectedProductsArray;
                    this.selectedProductsValue = [];
                    this.orderItemResponceData = [];
                    this.selectedLineKey = '';
                }
            })
            .catch(error => {
                console.error('processOrderItems error...', JSON.stringify(error));
                this.orderSpinner = false;
            });
    }
    navigateToStoreCockpit() {
        this.dispatchEvent(new CustomEvent('navigate'));
    }
    handleSelectRecord(event) {
        const dataset = event.currentTarget.dataset;
        const keyFromRow = dataset.key ?? null;
        const typeFromRow = dataset.typeId ?? null;
        const productFromRow = dataset.productId ?? dataset.id ?? null;
        if (productFromRow) {
            this.selectedProduct = productFromRow;
        }
        if (typeFromRow) {
            this.selectedTypeValue = typeFromRow;
        }
        this.selectedLineKey =
            keyFromRow ??
            this.getLineKey(this.selectedProduct, this.selectedTypeValue);
        this.pendingTypeChange = null;
        this.populateSelectedProductDetails(this.selectedProduct);
        this.updateRowHighlight();
    }
    async populateSelectedProductDetails(selectedProduct) {
        /* Previous implementation (productId-driven) for reference:
        let selectedItems = this.orderItemResponceData.filter(item => item?.productId === selectedProduct);
        this.selectedLineItemRecord = this.orderItemResponceData.find(item => item?.productId === selectedProduct);
        this.selectedTypeValue = (selectedItems[0]?.typeId !== undefined) ? selectedItems[0].typeId : this.typeOptionsAll.find(type => type.label === 'Cash Sale')?.value;
        */
        let selectedItems = this.orderItemResponceData.filter(item =>
            item?.productId === selectedProduct && item?.typeId === this.selectedTypeValue
        );
        const pendingMatchesSelection =
            this.pendingTypeChange &&
            this.pendingTypeChange.productId === selectedProduct &&
            this.pendingTypeChange.toTypeId === this.selectedTypeValue;

        if (!selectedItems.length) {
            if (pendingMatchesSelection && this.pendingTypeChange?.fromTypeId) {
                selectedItems = this.orderItemResponceData.filter(item =>
                    item?.productId === selectedProduct && item?.typeId === this.pendingTypeChange.fromTypeId
                );
            }
            if (!selectedItems.length) {
                selectedItems = this.orderItemResponceData.filter(item => item?.productId === selectedProduct);
            }
        }
        const preferredLineItem = selectedItems.find(item => item.orderItemId === this.selectedLineKey) ||
            selectedItems.find(item => item.uom === 'Carton') ||
            selectedItems.find(item => item.uom === 'Each') ||
            null;
        this.selectedLineItemRecord = preferredLineItem || (selectedItems.length ? selectedItems[0] : null);
        const productObj = this.listOfProductsData.find(item => item?.product?.Id === selectedProduct);
        if (this.selectedLineItemRecord?.orderItemId) {
            this.selectedLineKey = this.selectedLineItemRecord.orderItemId;
        } else if (!this.selectedLineKey) {
            this.selectedLineKey = this.getLineKey(selectedProduct, this.selectedTypeValue);
        }
        if (!this.pendingTypeChange && this.selectedLineItemRecord?.typeId) {
            this.selectedTypeValue = this.selectedLineItemRecord.typeId;
        } else if (!this.selectedTypeValue) {
            this.selectedTypeValue = this.typeOptionsAll.find(type => type.label === 'Cash Sale')?.value;
        }
        this.selectedTypeValue = this.selectedLineItemRecord?.typeId || this.selectedTypeValue || this.typeOptionsAll.find(type => type.label === 'Cash Sale')?.value;
        const productId = selectedProduct?.value || selectedProduct;
        const productKey = String(productId).trim();
        if (!this.wholeSalerAuthProductsData || (typeof this.wholeSalerAuthProductsData === 'object' && Object.keys(this.wholeSalerAuthProductsData).length === 0)) {
            await this.getWholesalerAuthProductsInfo();
        }
        if (this.wholeSalerAuthProductsData && this.wholeSalerAuthProductsData[productKey]) {
            this.wholesalersData = this.wholeSalerAuthProductsData[productKey];
        }
        const selectedTypeLabel = this.typeOptionsAll.find(type => type.value === this.selectedTypeValue)?.label;
        this.isFreeItem = (selectedTypeLabel == 'Free Item') ? true : false;
        this.productCode = productObj?.product.cgcloud__Consumer_Goods_Product_Code__c || '';
        this.isPreBook = selectedTypeLabel === 'Prebook';
        if (this.isPreBook) {
            await this.getPreBookWholeSalerOptions();
            this.selectedWholeSaler = selectedItems[0]?.wholeSalerId || '';
            if (this.selectedWholeSaler != null && this.selectedWholeSaler != '') {
                const selectedWholesaler = this.wholeSalerOptions.find(
                    item => item.value === this.selectedWholeSaler
                );
                this.wholeSaleOrderCode = selectedWholesaler ? selectedWholesaler.skuCode : null;
            }
        }
        this.selectedProductName = productObj?.product?.Name || '';
        this.stockBalance = parseFloat(productObj?.stockBalance).toFixed(2) || 0;
        this.suggestedQty = productObj?.suggestedQty || 0;
        this.cartonPiecesCount = productObj?.cartonPieces || 0;
        this.maxAllocationValue = productObj?.maxAllocation || 0;
        this.basePriceValue = productObj?.basePrice || 0;
        const typeConfig = {
            //'Return': { isCarton: false, isEach: true },// To allow only Each in Return
            'Return': { isCarton: true, isEach: true }, // To allow Cartons & Each in Return
            'Prebook': { isCarton: true, isEach: false }
        };
        let config = {};
        if (this.selectedPromotionValue) {
            const promotionMatch = this.promotionsOptionsAll.find(opt => opt.Id === this.selectedPromotionValue);
            if (promotionMatch && promotionMatch.TPB_Promotion_Type__c && promotionMatch.TPB_Promotion_Type__c == 'Product Purchase') {
                config = { isCarton: false, isEach: true };
            } else {
                config = { isCarton: true, isEach: false };
            }
        } else {
            config = typeConfig[selectedTypeLabel] || { isCarton: true, isEach: true };

        }
        this.isCarton = config.isCarton;
        this.isEach = config.isEach;
        if (selectedTypeLabel == 'Cash Sale' && !this.selectedPromotionValue) {
            this.isEach = this.cartonPiecesCount > 1 ? true : this.isEach;
        }
        //this.isEach = (this.selectedPromotionValue == null || this.selectedPromotionValue == '') ? true : false; // need to check later
        let each = 0;
        let carton = 0;

        selectedItems.forEach(item => {
            if (item.uom === 'Each') each = item.quantity;
            if (item.uom === 'Carton') carton = item.quantity;
        });
        const cartonItem = selectedItems.find(item => item.productId === selectedProduct && item.uom === 'Carton') || {};
        const eachItem = selectedItems.find(item => item.productId === selectedProduct && item.uom === 'Each') || {};

        this.unitPriceOfCarton = this.basePriceValue > 0 ? this.basePriceValue : 0;
        this.unitPriceOfCarton = this.unitPriceOfCarton.toFixed(2);
        if (this.selectedPromotionValue) {
            const promotionMatch = this.promotionsOptionsAll.find(opt => opt.Id === this.selectedPromotionValue);
            if (promotionMatch && promotionMatch.TPB_Promotion_Type__c && promotionMatch.TPB_Promotion_Type__c == 'Product Purchase') {
                this.specialPriceValue = eachItem.specialPrice > 0 ? eachItem.specialPrice : 0;
            } else {
                this.specialPriceValue = cartonItem.specialPrice > 0 ? cartonItem.specialPrice : 0;
            }
        } else {
            //this.specialPriceValue = cartonItem?.specialPrice > 0 ? cartonItem.specialPrice : (eachItem?.specialPrice || 0);

            if (eachItem?.specialPrice > 0) {
                //this.specialPriceValue = (eachItem.specialPrice * this.cartonPiecesCount).toFixed(2);
                this.specialPriceValue = Math.round(eachItem.specialPrice * this.cartonPiecesCount * 100) / 100;
            } else if (cartonItem?.specialPrice > 0) {
                this.specialPriceValue = (cartonItem.specialPrice).toFixed(2);
            } else {
                this.specialPriceValue = 0.00;
            }
        }
        
        this.eachValue = each;
        this.cartonValue = carton;
        await this.orderLineItemCalculation();

        const updatedSelectedItems = {
            productId: selectedProduct,
            cartonOrderLineItemId: null,
            eachOrderLineItemId: ''
        };
        selectedItems.forEach(({ uom, orderItemId }) => {
            if (uom === 'Carton') {
                updatedSelectedItems.cartonOrderLineItemId = orderItemId;
            } else if (uom === 'Each') {
                updatedSelectedItems.eachOrderLineItemId = orderItemId;
            }
        });
        this.selectedProductData = Object.keys(updatedSelectedItems).length > 0 ? updatedSelectedItems : {};
        this.isSelectedProduct = !!updatedSelectedItems.productId;
    }
    searchItemMatches(item, searchVal) {
        if (!item || typeof item !== 'object') {
            return false;
        }
        return Object.keys(item).some(key => {
            const value = item[key];
            return typeof value === 'string' && value.toLowerCase().includes(searchVal);
        });
    }
    handleKeyUp() {
        const searchInput = this.template.querySelector('[data-id="searchInput"]');
        const inputValue = searchInput && typeof searchInput.value === 'string'
            ? searchInput.value
            : '';
        this.handleSearchChange({ detail: { value: inputValue } });
    }
    handleSearchChange(event) {
        const inputValue = event?.detail?.value ?? event?.target?.value ?? '';
        const searchVal = String(inputValue).toLowerCase().trim();
        const sourceGroups = Array.isArray(this.allSelectedProductsArray)
            ? this.allSelectedProductsArray
            : [];
        if (!sourceGroups.length) {
            this.selectedProductsArray = [];
            this.isSelectedProduct = false;
            this.isselectedProductsArray = false;
            return;
        }
        if (searchVal) {
            const filteredGroups = [];
            sourceGroups.forEach(group => {
                const items = Array.isArray(group?.items) ? group.items : [];
                const filteredItems = items.filter(item => this.searchItemMatches(item, searchVal));
                if (filteredItems.length > 0) {
                    filteredGroups.push({ ...group, items: filteredItems });
                }
            });
            this.selectedProductsArray = filteredGroups;
            this.isSelectedProduct = false;
            this.isselectedProductsArray = filteredGroups.length > 0;
            return;
        }

        this.selectedProductsArray = JSON.parse(JSON.stringify(sourceGroups));

        let selectedRow;
        for (const group of this.selectedProductsArray) {
            const items = Array.isArray(group?.items) ? group.items : [];
            const current = items.find(item => item?.ariaSelected === 'true');
            if (current) {
                selectedRow = current;
                break;
            }
        }

        if (!selectedRow) {
            const firstGroup = this.selectedProductsArray.find(group => Array.isArray(group?.items) && group.items.length > 0);
            selectedRow = firstGroup?.items?.[0];
        }

        if (selectedRow) {
            this.handleSelectRecord({
                currentTarget: {
                    dataset: {
                        id: selectedRow.key,
                        key: selectedRow.key,
                        productId: selectedRow.productId,
                        typeId: selectedRow.typeId
                    }
                }
            });
        }

        this.isSelectedProduct = !!selectedRow;
        this.isselectedProductsArray = this.selectedProductsArray.length > 0;
    }
    increaseQuantity(event) {
        const orderItemId = event.currentTarget.dataset.orderitemId || null;
        const uomType = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        // Debounce API call by 1500ms
        this.debounceTimeout = setTimeout(async () => {
            // HARD STOP for Prebook without wholesaler
            if (!this.validatePrebookBeforeQuantityChange()) {
                return;
            }
            //Need to open later
            // if (this.isGratis && this.selectedPromotionValue != '' && this.selectedPromotionValue != null && this.isPromotionProductsLimitExceed) {
            //     const result = await LightningConfirm.open({
            //         message: 'You have exceeded the max quantity allowed for this promotion.',
            //         variant: "default",
            //         label: "Info"
            //     });
            //     //return;
            // }
            // Step 1: Increment the correct value
            if (name && this[name] !== undefined) {
                this[name]++;
            }
            // Step 3: Define base and special price calculations
            const [cartonItem, eachItem] = ['Carton', 'Each'].map(uom =>
                this.orderItemResponceData.find(item =>
                    item.uom === uom &&
                    item.productId === this.selectedProduct &&
                    item.typeId === this.selectedTypeValue
                )
            );
            let quantityValue = (uomType === 'Carton') ? this.cartonValue : this.eachValue;
            const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
            if (!specialPriceValidateResponse.isValid) {
                this.specialPriceValue = 0.00;
                return;
            }
            const specialPriceOfEach = await this.orderLineItemCalculation();
            // Step 5: Handle special price changes
            if (name === 'specialPriceValue' && this.specialPriceValue > 0) {
                if (cartonItem) {
                    await this.generateResponseBody(
                        this.selectedProduct,
                        'Carton',
                        cartonItem.quantity,
                        this.basePriceValue,
                        this.specialPriceValue,
                        cartonItem?.orderItemId,
                        this.selectedTypeValue,
                        this.selectedWholeSaler
                    );
                }
                if (eachItem && this.isEach) {
                    this.eachValue = eachItem.quantity;
                    await this.generateResponseBody(
                        this.selectedProduct,
                        'Each',
                        eachItem.quantity,
                        this.basePriceValue,
                        specialPriceOfEach,
                        eachItem?.orderItemId,
                        this.selectedTypeValue,
                        this.selectedWholeSaler
                    );
                }
            }
            // Step 6: Handle quantity change
            if (quantityValue > 0 && name !== 'specialPriceValue') {
                const finalSpecialPrice = name === 'cartonValue' ? this.specialPriceValue : specialPriceOfEach;
                let finalBaseprice =
                    uomType === 'Carton' ? this.unitPriceOfCarton :
                        uomType === 'Each' ? this.unitPriceOfEach : 0;

                const resolution = this.resolveTypeChangeForUpdate(
                    uomType,
                    quantityValue,
                    finalBaseprice,
                    finalSpecialPrice,
                    orderItemId
                );
                await this.generateResponseBody(
                    this.selectedProduct,
                    uomType,
                    resolution.quantityValue,
                    resolution.basePrice,
                    resolution.specialPrice,
                    resolution.orderItemId,
                    resolution.typeId,
                    this.selectedWholeSaler
                );
                if (resolution.typeChangeHandled) {
                    await this.finalizePendingTypeChange(resolution.deleteOrderItemId);
                }
                if (resolution.orderItemId) {
                    this.selectedLineKey = resolution.newLineKey;
                }
            }
        }, 500);
    }
    decreaseQuantity(event) {
        this.orderSpinner = true;
        const uom = event.target.dataset.uom;
        const name = event.currentTarget.dataset.name;
        const orderItemId = event.currentTarget.dataset.orderitemId;
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
        // Debounce API call by 1500ms
        this.debounceTimeout = setTimeout(async () => {
            // HARD STOP for Prebook without wholesaler
            // if (!this.validatePrebookBeforeQuantityChange()) {
            //     this.orderSpinner = false;
            //     return;
            // }
            // Step 1: Decrement the value but avoid going below 0
            if (name && this[name] !== undefined && this[name] > 0) {
                this[name]--;
            }
            // Step 3: Define base and special price calculations
            const [cartonItem, eachItem] = ['Carton', 'Each'].map(uom =>
                this.orderItemResponceData.find(item =>
                    item.uom === uom &&
                    item.productId === this.selectedProduct &&
                    item.typeId === this.selectedTypeValue
                )
            );
            const quantityValue = uom === 'Carton' ? this.cartonValue : this.eachValue;
            const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
            if (!specialPriceValidateResponse.isValid) {
                this.specialPriceValue = 0.00;
                return;
            }
            const specialPriceOfEach = await this.orderLineItemCalculation();
            //generateResponseBody(productId, uomType, quantityValue,basePrice, specialPriceValue, orderItemId,typeValue,wholeSalerId)
            if (name === 'specialPriceValue' && this.specialPriceValue > 0) {
                if (cartonItem) {
                    await this.generateResponseBody(
                        this.selectedProduct,
                        'Carton',
                        cartonItem.quantity,
                        this.basePriceValue,
                        this.specialPriceValue,
                        cartonItem?.orderItemId,
                        this.selectedTypeValue,
                        this.selectedWholeSaler
                    );
                }
                if (eachItem && this.isEach) {
                    this.eachValue = eachItem.quantity;
                    await this.generateResponseBody(
                        this.selectedProduct,
                        'Each',
                        eachItem.quantity,
                        this.basePriceValue,
                        specialPriceOfEach,
                        eachItem?.orderItemId,
                        this.selectedTypeValue,
                        this.selectedWholeSaler
                    );
                }
            }
            // Step 5: Prevent negative or invalid data
            if (quantityValue > 0 && name !== 'specialPriceValue') {
                const finalSpecialPrice = name === 'cartonValue' ? this.specialPriceValue : specialPriceOfEach;
                let finalBaseprice =
                    uom === 'Carton' ? this.unitPriceOfCarton :
                        uom === 'Each' ? this.unitPriceOfEach : 0;
                const resolution = this.resolveTypeChangeForUpdate(
                    uom,
                    quantityValue,
                    finalBaseprice,
                    finalSpecialPrice,
                    orderItemId
                );
                await this.generateResponseBody(
                    this.selectedProduct,
                    uom,
                    resolution.quantityValue,
                    resolution.basePrice,
                    resolution.specialPrice,
                    resolution.orderItemId,
                    resolution.typeId,
                    this.selectedWholeSaler
                );
                if (resolution.typeChangeHandled) {
                    await this.finalizePendingTypeChange(resolution.deleteOrderItemId);
                }
                if (resolution.orderItemId) {
                    this.selectedLineKey = resolution.newLineKey;
                }
            } else if (quantityValue == 0 && name !== 'specialPriceValue') {
                this.deleteOrderLineItem(orderItemId);
            } else {
                console.warn('Invalid quantityValue:', quantityValue);
            }
        }, 500);
        this.orderSpinner = false;
    }
    async handleChange(event) {
        if (!this.validatePrebookBeforeQuantityChange()) {
            event.target.value = 0;
            return;
        }

        const name = event.currentTarget.name;
        const uom = event.target.dataset.uom;
        const orderItemId = event.currentTarget.dataset.orderitemId;
        let roundedValue = (name != 'specialPriceValue') ? (Math.round(event.target.value)) : event.target.value;
        // Clear any previous error
        event.target.setCustomValidity("");
        event.target.reportValidity();
        const newVal = parseFloat(roundedValue, 10).toFixed(2);
        const parsedValue = isNaN(newVal) || newVal < 0 ? 0 : newVal;
        // if (roundedValue <= 0) {
        //     this.deleteOrderLineItem(orderItemId);
        //     return;
        // }
        const isQuantityField = name === 'cartonValue' || name === 'eachValue';
        //const isSpecialPriceField = name === 'specialPriceValue';
        
        // Quantity fields ONLY
        if (isQuantityField) {
            
            const numericValue = Number(roundedValue);
            let previousValue;
            if (name === 'cartonValue') {
                previousValue = this.cartonValue;
            } else if (name === 'eachValue') {
                previousValue = this.eachValue;
            } else {
                previousValue = 0; // for safety (e.g. specialPriceValue)
            }
            // Block negatives
            if (numericValue < 0) {
                event.target.setCustomValidity('Quantity cannot be negative');
                event.target.reportValidity();
                event.target.value = previousValue;
                this.orderSpinner = false;
                return;
            }
            if (numericValue === previousValue) {
                // Blur fired but value didn't change
                return;
            }

            //  Allow delete only for quantity fields
            if (numericValue === 0) {
                await this.deleteOrderLineItem(orderItemId);
                return;
            }
        }
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
            this.orderItemResponceData.find(item =>
                item.uom === uom &&
                item.productId === this.selectedProduct &&
                item.typeId === this.selectedTypeValue
            )
        );
        const quantityValue = uom === 'Carton' ? this.cartonValue : this.eachValue;
        const specialPriceValidateResponse = await this.validateSpecialPrice(this.basePriceValue, this.specialPriceValue);
        if (!specialPriceValidateResponse.isValid) {
            this.specialPriceValue = 0.00;
            return;
        }
        const specialPriceOfEach = await this.orderLineItemCalculation();
        if (name === 'specialPriceValue' && this.specialPriceValue > 0) {
            if (cartonItem) {
                await this.generateResponseBody(
                    this.selectedProduct,
                    'Carton',
                    cartonItem.quantity,
                    this.basePriceValue,
                    this.specialPriceValue,
                    cartonItem?.orderItemId,
                    this.selectedTypeValue,
                    this.selectedWholeSaler
                );
            }
            if (eachItem && this.isEach) {
                this.eachValue = eachItem.quantity;
                await this.generateResponseBody(
                    this.selectedProduct,
                    'Each',
                    eachItem.quantity,
                    this.basePriceValue,
                    specialPriceOfEach,
                    eachItem?.orderItemId,
                    this.selectedTypeValue,
                    this.selectedWholeSaler
                );
            }
        }
        if (quantityValue > 0 && name !== 'specialPriceValue') {
            const finalSpecialPrice = name === 'cartonValue' ? this.specialPriceValue : specialPriceOfEach;
            let finalBaseprice =
                uom === 'Carton' ? this.unitPriceOfCarton :
                    uom === 'Each' ? this.unitPriceOfEach : 0;
            const resolution = this.resolveTypeChangeForUpdate(
                uom,
                quantityValue,
                finalBaseprice,
                finalSpecialPrice,
                orderItemId
            );
            await this.generateResponseBody(
                this.selectedProduct,
                uom,
                resolution.quantityValue,
                resolution.basePrice,
                resolution.specialPrice,
                resolution.orderItemId,
                resolution.typeId,
                this.selectedWholeSaler
            );
            if (resolution.typeChangeHandled) {
                await this.finalizePendingTypeChange(resolution.deleteOrderItemId);
            }
            if (resolution.orderItemId) {
                this.selectedLineKey = resolution.newLineKey;
            }
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
            return { isValid: false };
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
            return { isValid: false };
        }
        // If base price is not present or invalid, skip base price comparison
        if (basePrice == null || isNaN(basePrice) || basePrice === 0) {
            return { isValid: true };
        }
        const lowerLimit = basePrice * 0.90;  // 10% lower
        //const upperLimit = Math.min(basePrice * 1.25, this.customSettingLimits.Max_Limit_Spl_Price__c);  // 25% higher or 200, whichever is lower
        const upperLimit = basePrice * 1.25;
        if (specialPrice < lowerLimit) {
            const result = await LightningConfirm.open({
                message: `Special Price cannot be less than 10% of Base Price (${lowerLimit.toFixed(2)}).`,
                variant: "default",
                label: "Info"
            });
            return { isValid: false };
        }
        if (specialPrice > upperLimit) {
            const result = await LightningConfirm.open({
                message: `Special Price cannot be more than 25% of Base Price (${upperLimit.toFixed(2)}).`,
                variant: "default",
                label: "Info"
            });
            return { isValid: false };
        }
        return { isValid: true };
    }
    async orderLineItemCalculation() {
        console.log('this.selectedLineItemRecord...'+JSON.stringify(this.selectedLineItemRecord));
        console.log('this.specialPriceValue...'+this.specialPriceValue);
        console.log('this.cartonPiecesCount...'+this.cartonPiecesCount);
        console.log('this.unitPriceOfCarton...'+this.unitPriceOfCarton);

        const specialPriceOfEach = (this.specialPriceValue > 0 && this.cartonPiecesCount > 0)
            ? (this.specialPriceValue / this.cartonPiecesCount)
            : 0.00;
        this.unitPriceOfEach = (this.unitPriceOfCarton > 0 && this.cartonPiecesCount > 0)
            ? (this.unitPriceOfCarton / this.cartonPiecesCount)
            : 0.00;
        console.log('this.unitPriceOfEach...'+this.unitPriceOfEach);
        if (this.specialPriceValue > 0) {
            this.totalPriceOfCarton = (this.specialPriceValue * this.cartonValue).toFixed(2);
            this.totalPriceOfEach = (specialPriceOfEach * this.eachValue).toFixed(2);
        } else {
            this.totalPriceOfCarton = (this.unitPriceOfCarton * this.cartonValue).toFixed(2);
            this.totalPriceOfEach = (this.unitPriceOfEach * this.eachValue).toFixed(2);
        }
        if (!this.isGratis && this.selectedPromotionValue !== null && !this.isRewardFulfilled && this.isRewardGranted) {

            if (this.rewardDiscount && this.selectedProduct in this.rewardDiscount) {
                let rewardType = this.rewardDiscount[this.selectedProduct].cgcloud__Reward_Type__c;//
                let productDiscountCarton = parseFloat(this.rewardDiscount[this.selectedProduct].cgcloud__Default_Value__c) * this.cartonValue;
                let productDiscountEach = ((productDiscountCarton / this.cartonPiecesCount).toFixed(2)) * this.eachValue;
                if (rewardType === 'PercentageDiscount') {
                    let discountPercent = parseFloat(this.rewardDiscount?.[this.selectedProduct]?.cgcloud__Default_Value__c);
                    // Normalize discount
                    discountPercent = isNaN(discountPercent) ? 0 : Math.abs(discountPercent);
                    discountPercent = Math.min(discountPercent, 100);
                    // Apply discount to Carton price
                    const cartonPriceVal = parseFloat(this.totalPriceOfCarton) || 0;
                    this.totalPriceOfCarton = Math.max(0, cartonPriceVal * (1 - discountPercent / 100)).toFixed(2);
                    // Apply discount to Each price
                    const eachPriceVal = parseFloat(this.totalPriceOfEach) || 0;
                    this.totalPriceOfEach = Math.max(0, eachPriceVal * (1 - discountPercent / 100)).toFixed(2);
                } else {
                    this.totalPriceOfCarton = (parseFloat(this.totalPriceOfCarton || 0) + parseFloat(productDiscountCarton || 0)).toFixed(2);
                    this.totalPriceOfEach = (parseFloat(this.totalPriceOfEach || 0) + parseFloat(productDiscountEach || 0)).toFixed(2);
                }
            }
        } else {
            if ( this.selectedLineItemRecord?.isPromoted === true && this.selectedLineItemRecord?.productId && this.selectedLineItemRecord?.promotionId && this.selectedLineItemRecord?.orderItemId) {
                if (this.selectedLineItemRecord?.uom == 'Carton') {
                    this.totalPriceOfCarton = (parseFloat(this.totalPriceOfCarton || 0) - parseFloat(this.selectedLineItemRecord?.reimbursableAmount || 0)).toFixed(2);
                }
                if (this.selectedLineItemRecord?.uom == 'Each') {
                    this.totalPriceOfEach = (parseFloat(this.totalPriceOfEach || 0) - parseFloat(this.selectedLineItemRecord?.reimbursableAmount || 0)).toFixed(2);
                }
            } else {

            }
        }
        return specialPriceOfEach;
    }
    validatePrebookBeforeQuantityChange() {
        if (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === '')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Wholesaler Required',
                    message: 'Please select a Wholesaler before updating quantity.',
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    async generateResponseBody(productId, uomType, quantityValue, basePrice, specialPriceValue, orderItemId, typeValue, wholeSalerId) {
        // if (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === '')) {
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Whole Saler is required',
        //             message: 'Whole Saler is required',
        //             variant: 'error'
        //         })
        //     );
        //     this.cartonValue = 0;
        //     return
        // }
        //if (quantityValue <= 0 || (this.isPreBook && (!this.selectedWholeSaler || this.selectedWholeSaler === ''))) return;
        if (quantityValue <= 0) {
            return;
        }
        if (this.isPreBook) {
            basePrice = 0;
            specialPriceValue = 0;
        }
        this.orderSpinner = true;
        let discountedAmount = 0;
        let savedpromotionId = null;
        let savedisPromoted = null;
        let savedorderItemId = orderItemId || null;
        if (!savedorderItemId) {
            const fallbackMatch = this.orderItemResponceData.find(
                item =>
                    item.productId === productId &&
                    item.typeId === typeValue &&
                    item.uom === uomType
            );
            if (fallbackMatch) {
                savedorderItemId = fallbackMatch.orderItemId;
                if (
                    fallbackMatch.typeId === typeValue &&
                    !this.selectedPromotionValue &&
                    fallbackMatch.promotionId &&
                    fallbackMatch.isPromoted
                ) {
                    this.selectedPromotionValue_Clone = fallbackMatch.promotionId;
                    savedpromotionId = fallbackMatch.promotionId;
                    savedisPromoted = fallbackMatch.isPromoted;
                }
            }
        } else {
            const matchingLineItem = this.orderItemResponceData.find(item => item.orderItemId === savedorderItemId);
            if ( matchingLineItem && matchingLineItem.typeId === typeValue && !this.selectedPromotionValue && matchingLineItem.promotionId && matchingLineItem.isPromoted) {
                this.selectedPromotionValue_Clone = matchingLineItem.promotionId;
                savedpromotionId = matchingLineItem.promotionId;
                savedisPromoted = matchingLineItem.isPromoted;
            }
        }
        const responseBody = [{
            orderItemId: savedorderItemId || null,
            productId,
            specialPrice: specialPriceValue,
            uom: uomType,
            quantity: quantityValue,
            basePrice: basePrice,
            suggestedQty: this.suggestedQtyValue,
            typeId: typeValue,
            isPromoted: this.selectedPromotionValue != null ? true : (savedisPromoted || false),
            wholeSalerId: wholeSalerId || null,
            reimbursableAmount: discountedAmount || 0,
            promotionId: this.selectedPromotionValue || savedpromotionId || null
        }];
        console.log('generateResponseBody request...' + JSON.stringify(responseBody));
        try {
            const resp = await createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) });
            console.log('generateResponseBody resp...' + JSON.stringify(resp));
            if (this.selectedPromotionValue == null || this.selectedPromotionValue === '') {
                if (this.selectedPromotionValue_Clone) {
                    await this.processOrderItems();
                    await this.getrewardCriteriaCheckbox(this.selectedPromotionValue_Clone);
                    await this.getRewardDiscountMethod(this.selectedPromotionValue_Clone);
                    if (!this.isGratis && this.selectedPromotionValue_Clone !== null && !this.isRewardFulfilled && this.isRewardGranted) {
                        await this.applyDiscountToItems(this.selectedPromotionValue_Clone);
                        this.selectedPromotionValue_Clone = null;
                    } else if (!this.isGratis && this.selectedPromotionValue_Clone !== null && this.isRewardFulfilled && !this.isRewardGranted) {
                        await this.removeDiscountToItems(this.selectedPromotionValue_Clone);
                        this.selectedPromotionValue_Clone = null;
                    }
                } else {
                    await this.processOrderItems();
                }
            } else {
                await refreshApex(this.refreshTacticProducts);
                await this.getrewardCriteriaCheckbox(this.selectedPromotionValue); // Ensure this returns a Promise or is marked async
                if (!this.isGratis && this.selectedPromotionValue !== null && !this.isRewardFulfilled && this.isRewardGranted) {
                    this.applyDiscountToItems(this.selectedPromotionValue);
                } else if (!this.isGratis && this.selectedPromotionValue !== null && this.isRewardFulfilled && !this.isRewardGranted) {
                    this.removeDiscountToItems(this.selectedPromotionValue);
                }
            }
            this.orderSpinner = false;
        } catch (error) {
            console.error('generateResponseBody error...' + JSON.stringify(error));
            this.orderSpinner = false;
        }
    }
    async applyDiscountToItems(selectedPromotionId) {
        this.orderSpinner = true;
        const matchingItems = this.orderItemResponceData.filter(item => item.promotionId === selectedPromotionId && item.orderItemId);
        const responseBody = matchingItems.map(item => {
            let reimbursableAmount = 0;
            if (!this.isGratis && selectedPromotionId !== null && !this.isRewardFulfilled && this.isRewardGranted && this.rewardDiscount && item.productId in this.rewardDiscount) {
                let rewardType = this.rewardDiscount[item.productId].cgcloud__Reward_Type__c;
                let rewardDiscount = this.rewardDiscount[item.productId].cgcloud__Default_Value__c;
                if (rewardType === 'PercentageDiscount') {
                    //choose price: specialPrice → basePrice
                    const unitPrice =
                        item.specialPrice && item.specialPrice > 0
                            ? parseFloat(item.specialPrice)
                            : parseFloat(item.basePrice) || 0;
                    const totalPrice = unitPrice * (item.quantity || 0);
                    reimbursableAmount = (totalPrice * rewardDiscount / 100).toFixed(2);
                }else{
                    reimbursableAmount = parseFloat(rewardDiscount).toFixed(2) * item.quantity;
                }
                reimbursableAmount = reimbursableAmount < 0 ? -reimbursableAmount : reimbursableAmount;
            }
            return {
                orderItemId: item.orderItemId,
                productId: item.productId,
                specialPrice: item.specialPrice || 0,
                uom: item.uom,
                quantity: item.quantity,
                basePrice: item.basePrice || 0,
                suggestedQty: item.suggestedQty,
                typeId: item.typeId,
                isPromoted: item.isPromoted || false,
                wholeSalerId: item.wholeSalerId || null,
                reimbursableAmount: reimbursableAmount,
                promotionId: item.promotionId || null
            };
        });
        try {
            const resp = await createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) });
            await refreshApex(this.refreshTacticProducts);
            await this.orderLineItemCalculation();
            this.orderSpinner = false;
        } catch (error) {
            console.error('applyDiscountToItems error...' + JSON.stringify(error));
            this.orderSpinner = false;
        }
    }
    async removeDiscountToItems(selectedPromotionId) { 
        this.orderSpinner = true;
        const matchingItems = this.orderItemResponceData.filter(
            item =>
                item.promotionId === selectedPromotionId &&
                item.orderItemId &&
                (!this.deletedOrderLineItemId || item.orderItemId !== this.deletedOrderLineItemId)
        );
        const responseBody = matchingItems.map(item => ({
            orderItemId: item.orderItemId,
            productId: item.productId,
            specialPrice: item.specialPrice || 0,
            uom: item.uom,
            quantity: item.quantity,
            basePrice: item.basePrice || 0,
            suggestedQty: item.suggestedQty,
            typeId: item.typeId,
            isPromoted: item.isPromoted || false,
            wholeSalerId: item.wholeSalerId || null,
            reimbursableAmount: 0,
            promotionId: item.promotionId || null
        }));
        try {
            const resp = await createOrderLineItems({ orderId: this.orderId, responseBody: JSON.stringify(responseBody) });
            await refreshApex(this.refreshTacticProducts);
            await this.orderLineItemCalculation();
            this.orderSpinner = false;
        } catch (error) {
            console.error('removeDiscountToItems error...' + JSON.stringify(error));
            this.orderSpinner = false;
        }
    }
    reviewOrder() {
        this.dispatchEvent(new CustomEvent('review'));
    }
    async deleteOrderLineItem(orderLineItemId) {
        try {
            if (!orderLineItemId) return;
            if (!this.orderSpinner) this.orderSpinner = true;
            this.selectedPromotionValue_Clone = this.orderItemResponceData.find(p => p.orderItemId === orderLineItemId)?.promotionId || null;
            await deleteRecord(orderLineItemId);
            this.deletedOrderLineItemId = orderLineItemId;
            await updateOrderTotal({ orderId: this.orderId });
            if (this.selectedPromotionValue == null || this.selectedPromotionValue === '') {
                if (this.selectedPromotionValue_Clone) { 
                    await refreshApex(this.refreshTacticProducts);
                    await this.getrewardCriteriaCheckbox(this.selectedPromotionValue_Clone);
                    // run only if NOT gratis
                    if (!this.isGratis) { 
                        await this.removeDiscountToItems(this.selectedPromotionValue_Clone);
                    }
                    this.selectedPromotionValue_Clone = null;
                }
                await this.processOrderItems();
            } else {
                await refreshApex(this.refreshTacticProducts);
                await this.getrewardCriteriaCheckbox(this.selectedPromotionValue);
                if (!this.isGratis) { 
                    await this.removeDiscountToItems(this.selectedPromotionValue);
                }
            }
            this.orderSpinner = false;
            return orderLineItemId;
        } catch (error) {
            console.error('deleteOrderLineItem error...', error);
            this.orderSpinner = false;
            return null; // or throw error if you want the caller to handle it
        }
    }
    handleCategoryClick(event) {
        this.selectedTab = event.currentTarget.dataset.id;
        if (this.selectedTab === 'oos') {
            this.isOOSTab = true;
            this.isCartTab = false;
            this.istpbPromoTab = false;
            this.isDistributedTab = false;
        } else if (this.selectedTab === 'cart') {
            this.isCartTab = true;
            this.isOOSTab = false;
            this.istpbPromoTab = false;
            this.isDistributedTab = false;
            this.clearFilter();
        } else if (this.selectedTab === 'tpb') {
            this.isCartTab = false;
            this.isOOSTab = false;
            this.istpbPromoTab = true;
            this.isDistributedTab = false;
        } else if (this.selectedTab === 'distributed') {
            this.isCartTab = false;
            this.isOOSTab = false;
            this.istpbPromoTab = false;
            this.isDistributedTab = true;
        }
    }
    get getTabClassForCart() {
        return this.selectedTab === 'cart' ? 'active-tab' : '';
    }
    get getTabClassForOOS() {
        return this.selectedTab === 'oos' ? 'active-tab' : '';
    }
    get getTabClassForSelling() {
        return this.selectedTab === 'selling' ? 'active-tab' : '';
    }
    get getTabClassForPromo() {
        return this.selectedTab === 'promo' ? 'active-tab' : '';
    }
    get getTabClassForTPB() {
        return this.selectedTab === 'tpb' ? 'active-tab' : '';
    }
    get getTabClassForDistributed() {
        return this.selectedTab === 'distributed' ? 'active-tab' : '';
    }
    renderedCallback() {
        this.scheduleProductListHeight();
    }
    handleViewportResize() {
        this.scheduleProductListHeight();
    }
    scheduleProductListHeight() {
        if (this.layoutAnimationFrameId) {
            cancelAnimationFrame(this.layoutAnimationFrameId);
        }
        this.layoutAnimationFrameId = requestAnimationFrame(() => {
            this.layoutAnimationFrameId = null;
            this.adjustProductListHeight();
        });
    }
    adjustProductListHeight() {
        const container = this.template.querySelector('.product-table-container');
        if (container) {
            const isStackedLayout = (window.innerWidth || 0) < 1024;
            const detailCard = this.template.querySelector('[data-id="orderDetailCard"]');
            const detailPanel = this.template.querySelector('[data-id="orderDetailPanel"]');
            const detailHeight = detailCard?.getBoundingClientRect()?.height
                || detailPanel?.getBoundingClientRect()?.height
                || 0;
            const bottomTabBar = this.template.querySelector('.bottom-tab-bar');
            const containerRect = container.getBoundingClientRect();
            const tabTop = bottomTabBar ? bottomTabBar.getBoundingClientRect().top : 0;
            let availableHeight = tabTop > 0
                ? (tabTop - containerRect.top - 8)
                : ((window.innerHeight || 0) - containerRect.top - 88);
            const minHeight = 260;
            if (!Number.isFinite(availableHeight)) {
                availableHeight = minHeight;
            }
            let resolvedHeight = Math.max(Math.floor(availableHeight), minHeight);
            // iPad landscape: keep list height aligned with right detail panel to avoid early scroll.
            if (!isStackedLayout && detailHeight > 0) {
                resolvedHeight = Math.max(Math.floor(detailHeight), resolvedHeight);
            }
            // Avoid portrait "blank gap": let content define height and only cap with maxHeight.
            container.style.height = 'auto';
            container.style.maxHeight = `${resolvedHeight}px`;
        }
    }
    async handleFilterChange(event) {
        this.selectedPromotionValue = event.currentTarget.dataset.id;

        this.promotionHeaderLabel = event.currentTarget.dataset.name;
        this.updatePromotionOptions(
            this.filterPromotionOptions.map(p => ({
                Id: p.value,
                cgcloud__Slogan__c: p.label
            }))
        );
        this.isFiltered = false;
        this.isRewardsButton = true;
        await this.getTypeOptions();
        // Ensure the wire param is updated before refresh to avoid stale cache
        await Promise.resolve();
        await refreshApex(this.refreshTacticProducts); //Newly Added
        //await this.processOrderItems();
        await this.getrewardCriteriaCheckbox(this.selectedPromotionValue);
        await this.getRewardDiscountMethod(this.selectedPromotionValue);
        await this.orderLineItemCalculation();
    }
    async clearFilter() {
        this.selectedPromotionValue = '';
        this.isFiltered = false;
        this.isEach = true;
        this.isCarton = true;
        this.isRewardsButton = false;
        this.promotionHeaderLabel = 'Filter By Promotion...';
        this.updatePromotionOptions(
            this.filterPromotionOptions.map(p => ({
                Id: p.value,
                cgcloud__Slogan__c: p.label
            }))
        );
        await refreshApex(this.refreshTacticProducts);
        await this.processOrderItems();
        await this.getTypeOptions();
    }
    handlePrmotionRewards() {
        this.isRewardModel = true;
        this.callGetRewardsAndHurldes();
    }
    getRewardBaseStyle(isFulfilled) {
        return isFulfilled
            ? 'background-color: #0095ff; color: #ffffff;'
            : 'background-color: #fc5d5da3; color: #ffffff;';
    }
    updateRewardGroupHeaderStyles() {
        if (!Array.isArray(this.rewardGroupsUI)) {
            return;
        }
        this.rewardGroupsUI = this.rewardGroupsUI.map(group => {
            const baseStyle = this.getRewardBaseStyle(group.isFulfilled);
            const isFreeItemsSelected = !!this.rewardFreeSelectionMap?.[group.groupId];
            return {
                ...group,
                rewardCardStyle: isFreeItemsSelected
                    ? 'background-color: #8fd19e; color: #ffffff;'
                    : baseStyle
            };
        });
    }
    updateFreeSelectionForCurrentGroup() {
        if (!this.currentRewardGroupId || !Array.isArray(this.rewardGroupsUI)) {
            return;
        }
        const group = this.rewardGroupsUI.find(g => g.groupId === this.currentRewardGroupId);
        if (!group) {
            return;
        }
        const totalQuantity = (this.rewardProductsData || []).reduce(
            (sum, product) => sum + (product.quantity || 0),
            0
        );
        const maxAllowed = Number(group.maxFreeProducts || this.maxFreeProducts || 0);
        const nextMap = {};
        this.rewardGroupsUI.forEach(g => {
            nextMap[g.groupId] = false;
        });
        nextMap[group.groupId] = totalQuantity >= maxAllowed;
        this.rewardFreeSelectionMap = nextMap;
        this.updateRewardGroupHeaderStyles();
    }
    syncRewardHeaderFromExistingFreeItems() {
        if (!Array.isArray(this.rewardGroupsUI) || !this.rewardGroupsUI.length) {
            return;
        }
        const freeItemTypeId = this.typeOptionsAll.find(opt => opt.label === 'Free Item')?.value;
        if (!freeItemTypeId) {
            return;
        }
        const promotionId = this.selectedPromotionValue;
        const freeItemCount = (this.orderItemResponceData || []).reduce((sum, item) => {
            if (
                item.typeId === freeItemTypeId &&
                item.promotionId === promotionId
            ) {
                return sum + (item.quantity || 0);
            }
            return sum;
        }, 0);
        if (!freeItemCount) {
            this.rewardFreeSelectionMap = {};
            this.updateRewardGroupHeaderStyles();
            return;
        }
        const fulfilledGroup =
            this.rewardGroupsUI.find(group => group.isFulfilled) || this.rewardGroupsUI[0];
        if (!fulfilledGroup) {
            return;
        }
        this.currentRewardGroupId = fulfilledGroup.groupId;
        const nextMap = {};
        this.rewardGroupsUI.forEach(g => {
            nextMap[g.groupId] = false;
        });
        nextMap[fulfilledGroup.groupId] = true;
        this.rewardFreeSelectionMap = nextMap;
        this.updateRewardGroupHeaderStyles();
    }
    callGetRewardsAndHurldes() {
        getRewardsAndHurdles({ promotionId: this.selectedPromotionValue })
            .then(result => {
                console.log('getRewardsAndHurdles...result' + JSON.stringify(result));
                if (!result?.rewardGroups?.length) {
                    this.rewardGroupsUI = [];
                    return;
                }
                const promotionLabel =
                    this.filterPromotionOptions.find(
                        p => p.value === this.selectedPromotionValue
                    )?.label;
                this.selectedPromotionLabel = promotionLabel;
                // Build UI model per reward group
                this.rewardGroupsUI = result.rewardGroups.map((rewardGroup, groupIndex) => {
                    const hurdles = rewardGroup.hurdleList || [];
                    const rewards = rewardGroup.rewardList || [];
                    // DEFINE THIS FIRST
                    const isGroupFulfilled = this.rewardResultsMap?.[rewardGroup.rewardGroupId]?.rewardFulfilled ?? false;
                    //const rawHelpValue = this.rewardResultsMap?.[rewardGroup.rewardGroupId]?.rewardHelpText;
                    const matchedHurdle = hurdles.find(h => h.cgcloud__Promotion_Reward_Group__c === rewardGroup.rewardGroupId);
                    const hurdleNumericValue = matchedHurdle
                        ? Number(matchedHurdle.cgcloud__Numeric_Value__c)
                        : null;
                    const rawHelpValue = this.rewardResultsMap?.[rewardGroup.rewardGroupId]?.rewardHelpText ?? hurdleNumericValue;
                    let helpText = '';
                    if (rawHelpValue !== null && rawHelpValue !== undefined && rawHelpValue !== '') {
                        const numericValue = Number(rawHelpValue);

                        if (!isNaN(numericValue) && numericValue !== 0) {
                            if (numericValue > 0) {
                                helpText = `${numericValue} more`;
                            } else {
                                helpText = `${Math.abs(numericValue)} less`;
                            }
                        }
                    }
                    return {
                        groupId: rewardGroup.rewardGroupId,
                        // FIXED TEMPLATE STRING
                        groupLabel: `${promotionLabel} - Group ${groupIndex + 1}`,
                        hurdlesLabel: `${promotionLabel} ( ${hurdles.length} ) Hurdles`,
                        rewardCardStyle: this.getRewardBaseStyle(isGroupFulfilled),
                        hurdles: hurdles.map((h, index) => ({
                            id: h.Id,
                            label: h.cgcloud__Title__c,
                            isCompleted: isGroupFulfilled,
                            //iconName: isGroupFulfilled ? 'utility:check' : 'utility:close',
                            iconName: index === 0 ? (isGroupFulfilled ? 'utility:check' : 'utility:close') : 'utility:check',
                            helpText: index === 0 ? helpText : ''
                        })),
                        rewards: rewards.map(r => ({
                            id: r.Id,
                            label: r.cgcloud__Title__c
                        })),
                        maxFreeProducts: rewards[0]?.cgcloud__Default_Value__c ?? 1,
                        isFulfilled: isGroupFulfilled,
                        isNotFulfilled: !isGroupFulfilled,
                    };
                });
                this.updateRewardGroupHeaderStyles();
                this.syncRewardHeaderFromExistingFreeItems();
            })
            .catch(error => {
                console.error('getRewardsAndHurdles error...',JSON.stringify(error));
            });
    }
    async getrewardCriteriaCheckbox(selectedPromotionId) {
        try {
            const results = await rewardCriteriaCheck({
                promotionId: selectedPromotionId,
                orderId: this.orderId
            });
            console.log('getrewardCriteriaCheckbox results...',JSON.stringify(results));
            this.rewardResultsMap = this.rewardResultsMap || {};
            this.rewardResultsMap = {};
            results.forEach(r => {
                this.rewardResultsMap[r.rewardGroupId] = r;
            });
            this.totalRewards = results.length;
            // Defensive guard
            if (!Array.isArray(results) || results.length === 0) {
                this.resetRewardUI();
                return;
            }
            //ANY reward fulfilled
            const fulfilledReward = results.find(r => r.rewardFulfilled === true);
            const isFulfilled = !!fulfilledReward;
            const activeReward = fulfilledReward || results[0]; // fallback
            this.rewardsApplied = isFulfilled ? '1' : '0';
            this.isRewardFulfilled = !isFulfilled;
            this.isRewardGranted = isFulfilled;
            this.isGratis = activeReward.promotionType === 'Gratis';
            this.rewardCardStyle = isFulfilled
                ? 'background-color: #0095ff; color: #ffffff;'
                : 'background-color: #fc5d5da3; color: #ffffff;';
            this.isPromotionProductsLimitExceed = isFulfilled;
            // Help text
            if (!isFulfilled && activeReward.rewardHelpText) {
                const cleanValue = parseInt(activeReward.rewardHelpText, 10);
                this.rewardHelpText = !isNaN(cleanValue)
                    ? `${cleanValue} more`
                    : '';
            } else {
                this.rewardHelpText = '';
            }
            // ✅ GRATIS clean-up logic (only when NOT fulfilled)
            if (!isFulfilled && activeReward.promotionType === 'Gratis') {
                await this.handleGratisCleanup(selectedPromotionId);
            }
        } catch (error) {
            console.error('getrewardCriteriaCheckbox error...',JSON.stringify(error));
        }
    }
    resetRewardUI() {
        this.rewardsApplied = '0';
        this.isRewardFulfilled = true;
        this.isRewardGranted = false;
        this.isGratis = false;
        this.rewardHelpText = '';
        this.rewardCardStyle =
            'background-color: #fc5d5da3; color: #ffffff;';
    }
    async handleGratisCleanup(selectedPromotionId) {
        if (!selectedPromotionId) return;
        const freeItemTypeId =
            this.typeOptionsAll.find(opt => opt.label === 'Free Item')?.value;
        if (!freeItemTypeId) return;
        const freeItems = this.orderItemResponceData.filter(
            item =>
                item.typeId === freeItemTypeId &&
                item.promotionId === selectedPromotionId
        );
        if (freeItems.length) {
            freeItems.forEach(item => {
                if (item.orderItemId) {
                    this.deleteOrderLineItem(item.orderItemId);
                }
            });
        }else{

        }
    }
    handleCheckRewards(event) {
        this.isRewardGranted = event.detail.checked;
    }

    async handleIncrement(event) {
        const id = event.currentTarget.dataset.id;
        const product = this.rewardProductsData.find(p => p.productId === id);
        let totalQuantity = 0;
        this.rewardProductsData.forEach(p => {
            totalQuantity += p.quantity;
        });
        if (!product) return;
        totalQuantity += 1;
        //product.basePrice =1; //need to remove it later 
        if (product.basePrice <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Limit Reached',
                    message: 'The Selected Product Base Price is 0, Please choose other Product',
                    variant: 'warning'
                })
            );
            return;
        }
        if (/*product.quantity > product.inventoryBalance ||*/ totalQuantity > this.maxFreeProducts) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Limit Reached',
                    message: 'You have exceeded the max quantity allowed for this promotion.',
                    variant: 'warning'
                })
            );
            return;
        }
        if (product.basePrice > 0 && /*product.quantity <= product.inventoryBalance &&*/ totalQuantity <= this.maxFreeProducts) {
            product.quantity += 1;
            this.rewardProductsData = [...this.rewardProductsData];
            this.updateFreeSelectionForCurrentGroup();
            let selectedTypeValue = this.typeOptionsAll.find(type => type.label === 'Free Item').value;
            // Call response builder
            await this.generateResponseBody(
                id,
                'Carton',
                product.quantity,
                product.basePrice || 0,
                product.specialPriceValue || 0,
                product.lineItemId || null,
                selectedTypeValue, null
            );
        }
    }
    handleDecrement(event) {
        const id = event.currentTarget.dataset.id;
        const product = this.rewardProductsData.find(p => p.productId === id);
        if (!product) return;
        if (product.quantity > 0) {
            product.quantity -= 1;
            this.rewardProductsData = [...this.rewardProductsData];
            this.updateFreeSelectionForCurrentGroup();
            if (product.quantity === 0) {
                this.deleteOrderLineItem(product.lineItemId);
            } else {
                let selectedTypeValue = this.typeOptionsAll.find(type => type.label === 'Free Item').value;
                this.generateResponseBody(
                    id,
                    'Carton',
                    product.quantity,
                    product.basePrice || 0,
                    product.specialPriceValue || 0,
                    product.lineItemId || null,
                    selectedTypeValue, null
                );
            }
        }
    }
    getRewardProducts(rewardId) {
        const payload = {
            rewardId: rewardId,
            orderId: this.orderId
        };
        getRewardProductsGratis(payload)
            .then(result => {
                this.rewardProductsData = result.map(item => ({
                    ...item,
                    quantity: item.lineItemQty
                }));
                console.log('getRewardProducts result...' + JSON.stringify(result));
                this.updateFreeSelectionForCurrentGroup();
            }).catch(error => {
                console.error('getRewardProducts error...' + JSON.stringify(error));
            })
    }
    handleModelRewards(event) {
        const dataset = event.currentTarget.dataset;
        const rewardId = dataset.rewardId ?? null;
        this.currentRewardId = rewardId;
        const matchedGroup = this.rewardGroupsUI?.find(group =>
            Array.isArray(group.rewards) && group.rewards.some(r => r.id === rewardId)
        );
        this.currentRewardGroupId = matchedGroup?.groupId || null;
        if (matchedGroup?.maxFreeProducts) {
            this.maxFreeProducts = matchedGroup.maxFreeProducts;
        }
        this.isRewardGraftOpen = true;
        this.isRewardModel = false;
        this.getRewardProducts(rewardId);
    }
}