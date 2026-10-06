import { LightningElement, api, track, wire } from 'lwc';
import getProductDistributionProducts from '@salesforce/apex/TPB_OnlineAppController.getProductDistributionProducts';
import getProducts from '@salesforce/apex/TPB_OnlineAppController.getProducts';
import createVisitJobs from '@salesforce/apex/TPB_OnlineAppController.createVisitJobs';
import ensureVisitJobsExist from '@salesforce/apex/TPB_OnlineAppController.ensureVisitJobsExist';
import getWholesalerAuthProducts from '@salesforce/apex/TPB_OnlineAppController.getWholesalerAuthProducts';
import { updateRecord } from 'lightning/uiRecordApi';
import VISIT_ID from '@salesforce/schema/Visit.Id';
import VISIT_PRODUCTDIST_PROCESSED from '@salesforce/schema/Visit.Product_Distribution_Accessed__c';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CgCloudProductDistribution extends LightningElement {
    @api visitId;
    @api accountId;
    @api selectedCustomerAccount;
    @api isVisitJobsCreated = false;
    @track selectedProducts = [];
    @track selectedProductsValue = [];
    @track filteredProductData = [];
    @track wholesalersData = [];
    @track searchVal = '';
    @track selectedValue;
    
    @track isModalOpen = false;
    @track wholeSalerAuthProductsData;
    @track selectedProductDistributorId;
    @track productDistributorPicklistOptions;
    @track productDistributSpinner = false;
    @track isInitialJobsProcessing = false;
    //@track wireRefreshProductDistributionData;
    @track defaultData;
    @track isProductDistribution = false;
    @track isProductSelected = false;
    @track groupedProductData = [];
    @track originalGroupedData = [];
    @track isLoading = false; // For SAL-328: modal loading state

    async connectedCallback() {
        this.productDistributSpinner = true;
        if (this.visitId) {

            // Only call ensureVisitJobsExist on first visit
            if (!this.isVisitJobsCreated) {
                console.log('First visit — calling ensureVisitJobsExist');
                try {
                    await ensureVisitJobsExist({
                        accountId: this.accountId,
                        visitId: this.visitId
                    });
                    console.log('ensureVisitJobsExist completed');
                } catch (error) {
                    console.error('ensureVisitJobsExist failed:', error);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to initialize products. Please retry.',
                        variant: 'error'
                    }));
                    this.productDistributSpinner = false;
                    return; // flag never set — next visit retries
                }

                // Mark flag ONLY after jobs created successfully
                try {
                    const fields = {};
                    fields[VISIT_ID.fieldApiName] = this.visitId;
                    fields[VISIT_PRODUCTDIST_PROCESSED.fieldApiName] = true;
                    await updateRecord({ fields });
                    console.log('VISIT_PRODUCTDIST_PROCESSED updated successfully');
                    this.dispatchEvent(new CustomEvent('visitfieldsupdated'));
                } catch (error) {
                    console.error('Error updating VISIT_PRODUCTDIST_PROCESSED:', error);
                    // Non-critical — jobs created — safe to continue
                }

            } else {
                console.log('Return visit — skipping ensureVisitJobsExist');
            }

            // Always fetch and render
            await this.loadProductDistributionData();
        }
        this.productDistributSpinner = false;
    }
    

    async handleScanPopupClosed() {
        this.productDistributSpinner = true;
        await this.loadProductDistributionData();
        this.productDistributSpinner = false;
    }

    async loadWholesalerAuthProducts() {
        await getWholesalerAuthProducts({ accountId: this.accountId })
            .then(result => {
                this.wholeSalerAuthProductsData = result;
            })
            .catch(error => {
                console.error('Error fetching getWholesalerAuthProducts:', error);
            });
    }
    async loadProductDistributionData() {
        this.productDistributSpinner = true;
        try {
            const data = await getProductDistributionProducts({
                accountId: this.accountId,
                visitId: this.visitId
            });
            //this.wireRefreshProductDistributionData = data;

            if (!data) {
                this.productDistributSpinner = false;
                return;
            }

            // Ensure wholesaler data is loaded first
            if (!this.wholeSalerAuthProductsData) {
                await this.loadWholesalerAuthProducts();
            }

            this.defaultData = data.productDistributions;
            this.productDistributorPicklistOptions = data.productDistributionPicklist;

            const groupedData = {};
            data.productDistributions.forEach(item => {
                this.selectedProductsValue = [
                        ...new Set(
                            data.productDistributions
                                .map(item => item.productId)
                                .filter(Boolean)
                        )
                ];
                if (!item.productId || !item.productName || !item.productSubCategory) return;
                const label = item.productSubCategory;
                const statusText = item.visitJobAnswer || '';
                let statusClass = '';
                if (statusText === 'OutOfStock') statusClass = 'status-oos';
                else if (statusText === 'Distributed') statusClass = 'status-distributed';
                else statusClass = 'status-other';
                if (!groupedData[label]) groupedData[label] = [];
                groupedData[label].push({
                    id: item.productId,
                    name: item.productName,
                    isDeletable: item.isDeletable,
                    originalStatus: statusText,
                    visitJobId: item.visitJobId,
                    statusText: statusText === 'OutOfStock' ? 'OOS' : '',
                    statusClass,
                    ariaSelected: 'false'
                });
            });

            let groupedProductData = Object.keys(groupedData).map(label => ({
                    label,
                    items: groupedData[label]
            }));


            const matchedProduct = data.productDistributions.find(
                item => item.productId && item.productId === this.selectedProductDistributorId
            );
            // For SAL-328: guard when refresh returns empty data
            this.selectedProductDistributorId = matchedProduct
                ? matchedProduct.productId
                : (data.productDistributions?.[0]?.productId || null);

            const distribution = this.defaultData.find(item => item.productId === this.selectedProductDistributorId);
            this.selectedValue = distribution?.visitJobAnswer || 'Distributed';

            groupedProductData = groupedProductData.map(group => ({
                ...group,
                items: group.items.map(item => ({
                    ...item,
                    ariaSelected: item.id === this.selectedProductDistributorId ? 'true' : 'false'
                }))
            }));

            this.groupedProductData = [...groupedProductData];
            this.originalGroupedData = [...groupedProductData];
            this.applySearchFilter();

            if (this.selectedProductDistributorId) {
                const stillExists = this.groupedProductData
                    .flatMap(g => g.items)
                    .some(i => i.id === this.selectedProductDistributorId);

                if (stillExists) {
                    this.handleProductClick({
                        currentTarget: { dataset: { id: this.selectedProductDistributorId } }
                    });
                }
            }

            this.isProductDistribution = this.originalGroupedData.length > 0;
            this.isProductSelected = this.originalGroupedData.length > 0;

            // Only access wholesaler data if defined
            if (this.wholeSalerAuthProductsData && this.selectedProductDistributorId in this.wholeSalerAuthProductsData) {
                this.wholesalersData = this.wholeSalerAuthProductsData[this.selectedProductDistributorId];
            } else {
                this.wholesalersData = null;
            }

        } catch (err) {
            console.error('Unexpected error during product distribution loading', err);
        } finally {
            if (!this.isInitialJobsProcessing) {
                this.productDistributSpinner = false;
            }
        }
    }

    @wire(getProducts, { visitId: '$visitId' })
    wireProductsData({ error, data }) {
        if (data) {
            this.listOfProductsData = data;
            this.productsData = data
                .filter(item => item.product && item.product.Id)
                .map(item => ({
                    label: item.product.Name,
                    value: item.product.Id
                }));
            setTimeout(() => {
                const multiselectCombobox = this.template.querySelector('c-cg-cloud-multiselect-picklist');
                if (multiselectCombobox && this.productsData) {
                    multiselectCombobox.options = this.productsData;
                }
            }, 0);
        } else if (error) {
            console.error('error', error);
        }
    }

    async renderedCallback() {
        const container = this.template.querySelector('.product-table-container');
        if (container) {
            // Let the list grow with content; rely on page scroll (not inner container scroll).
            container.style.height = 'auto';
            container.style.maxHeight = 'none';
            container.style.overflowY = 'visible';
            container.style.width = window.innerWidth <= 768 ? 'auto' : '100%';
        }
    }

    get visibleProductData() {
        return this.groupedProductData;
    }

    

    handleSearchChange(event) {
        this.searchVal = event.target.value?.toLowerCase().trim();
        this.applySearchFilter();
    }
    applySearchFilter() {
        let filteredGroups;
        if (this.searchVal) {
            const searchKey = this.searchVal.toLowerCase();
            filteredGroups = this.originalGroupedData
                .map(group => {
                    const matchedItems = group.items.filter(item =>
                        item.name.toLowerCase().includes(searchKey)
                    );
                    return matchedItems.length
                        ? { ...group, items: matchedItems }
                        : null;
                })
                .filter(Boolean);
        } else {
            filteredGroups = [...this.originalGroupedData];
        }
        // Re-apply ariaSelected
        filteredGroups = filteredGroups.map(group => ({
            ...group,
            items: group.items.map(item => ({
                ...item,
                ariaSelected:
                    item.id === this.selectedProductDistributorId ? 'true' : 'false'
            }))
        }));
        this.groupedProductData = [...filteredGroups];
        this.isProductDistribution = filteredGroups.length > 0;
        // VERY IMPORTANT: repopulate right-side panel
        const selectedStillVisible = this.groupedProductData
            .flatMap(g => g.items)
            .some(i => i.id === this.selectedProductDistributorId);

        if (selectedStillVisible) {
            this.handleProductClick({
                currentTarget: {
                    dataset: { id: this.selectedProductDistributorId }
                }
            });
        } else {
            this.isProductSelected = false;
        }
    }

   

    handleProductClick(event) {
        const productId = event.currentTarget.dataset.id;
        this.selectedProductDistributorId = productId;
        const selectedProduct = this.defaultData.find(prod => prod.productId === productId);
        // For SAL-328: prevent intermittent blank screen when refresh returns partial data
        if (!selectedProduct) {
            console.warn('Selected product not found after refresh:', productId); // For SAL-328
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Product Not Available',
                    message: 'The selected product is not available yet. Please refresh and try again.',
                    variant: 'warning'
                })
            ); // For SAL-328
            this.isProductSelected = false; // For SAL-328
            return;
        }
        //new code added 21-Aug-2025
        this.dropdownOpen = false;
        if (Array.isArray(this.productDistributorPicklistOptions) && selectedProduct.isDeletable) {
            if (!this.productDistributorPicklistOptions.includes("Delete")) {
                this.productDistributorPicklistOptions = [
                    ...this.productDistributorPicklistOptions,
                    "Delete"
                ];
            }
        } else if (Array.isArray(this.productDistributorPicklistOptions)) {
            this.productDistributorPicklistOptions = this.productDistributorPicklistOptions.filter(
                (option) => option !== "Delete"
            );
        }
        //end
        if (!selectedProduct || !selectedProduct.visitJobId) {
            this.selectedValue = 'Distributed';
        } else {
            this.selectedValue = selectedProduct.visitJobAnswer || 'Distributed';
        }
        const item = this.groupedProductData
            .flatMap(group => group.items)
            .find(i => i.id === productId);
        this.groupedProductData = this.groupedProductData.map(group => ({
            ...group,
            items: group.items.map(item => ({
                ...item,
                ariaSelected: item.id === productId ? 'true' : 'false'
            }))
        }));
        this.isProductSelected = true;
        this.wholesalersData = this.wholeSalerAuthProductsData
            ? this.wholeSalerAuthProductsData[productId]
            : null;
    }

   async handleDeleteVisitJob(event) {
        const productDistributionId = event.currentTarget.dataset.id;
         const result = await LightningConfirm.open({
            message: 'Are you sure want to delete the Product.',
            variant: "default",
            label: "Info"
            });
        if (result) {
            this.productDistributSpinner = true;
            try {
                await deleteRecord(productDistributionId);
                this.dispatchEvent(new ShowToastEvent({
                    title: "Product",
                    message: "Product deleted successfully",
                    variant: "success"
                }));
                await this.loadProductDistributionData();
            } catch (error) {
                console.error('Error deleting Product :', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: "Error",
                    message: "Failed to delete Product.",
                    variant: "error"
                }));
            } finally {
                this.productDistributSpinner = false;
            }
        }
    }

    updateProductStatusUI(productId, isSelected) {
        this.groupedProductData = this.groupedProductData.map(group => {
            const items = group.items.map(item => {
                if (item.id === productId) {
                    return {
                        ...item,
                        statusText: isSelected ? '' : 'OOS',
                        statusClass: isSelected ? 'status-distributed' : 'status-oos'
                    };
                }
                return item;
            });
            return { ...group, items };
        });
    }

    get selectedProductDetails() {
        return this.groupedProductData
            .flatMap(group => group.items)
            .filter(item => this.selectedProducts.includes(item.id));
    }

    navigateToStoreCockpit() {
        this.dispatchEvent(new CustomEvent('navigate'));
    }

    dropdownOpen = false;

    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }

    handleSelect(event) {
        this.selectedValue = event.target.innerText;
        this.dropdownOpen = false;
    }

    async openProductsModel() {
        this.isModalOpen = true;
        this.isLoading = true; // For SAL-328
        // For SAL-328: pre-populate from last known data to avoid empty selections
        const fallbackDistributions = this.defaultData || []; // For SAL-328
        this.selectedProductsValue = [
            ...new Set(
                fallbackDistributions
                    .map(item => item.productId)
                    .filter(Boolean)
            )
        ];
        try {
            await this.loadProductDistributionData();
            // For SAL-328: re-sync from wire when available
            //const distributions = this.wireRefreshProductDistributionData?.data?.productDistributions || []; // For SAL-328
            const distributions = this.defaultData || [];
            if (distributions.length) {
                this.selectedProductsValue = [
                    ...new Set(
                        distributions
                            .map(item => item.productId)
                            .filter(Boolean)
                    )
                ];
            }
        } finally {
            this.isLoading = false; // For SAL-328
        }
        
    }

    closeModal() {
        this.isModalOpen = false;
        this.isLoading = false; // For SAL-328
        this.selectedProductsValue = [];
    }

    captureCurrentOrder() {
        this._categoryOrderSnapshot = this.groupedProductData?.map(g => g.label) || [];
    }

    restoreOrderAfterRefresh() {
        if (!this._categoryOrderSnapshot?.length || !this.groupedProductData?.length) {
            return;
        }
        const indexMap = new Map();
        this._categoryOrderSnapshot.forEach((label, i) => indexMap.set(label, i));
        this.groupedProductData = [...this.groupedProductData].sort((a, b) => {
            const aIdx = indexMap.has(a.label) ? indexMap.get(a.label) : Number.MAX_VALUE;
            const bIdx = indexMap.has(b.label) ? indexMap.get(b.label) : Number.MAX_VALUE;
            return aIdx - bIdx;
        });
    }

    showValidationToast() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Validation Error',
                message: 'Please select at least one product to proceed.',
                variant: 'warning'
            })
        );
    }

    async handleAddProduct() {
        // Always stop previous loading state
        this.productDistributSpinner = false;
        // Step 1: Validate if anything is selected at all
        if (!this.selectedProductsValue?.length) {
            this.showValidationToast();
            return;
        }
        this.captureCurrentOrder();
        this.productDistributSpinner = true;
        // Step 3: Filter out any uniqueNewProducts that already exist in defaultData
        const baseData = this.defaultData || [];
        const defaultProductIds = new Set(baseData.map(p => p.productId));
        const trulyUniqueProducts = this.selectedProductsValue.filter(
            prod => !defaultProductIds.has(prod)
        );
        this.selectedProductDistributorId = trulyUniqueProducts.length > 0 ? trulyUniqueProducts[0] : null;
        // Step 5: Combine default data with truly unique products
        const newProductsPayload = trulyUniqueProducts.map(prodId => ({
            productId: prodId,
            visitJobAnswer: 'Distributed'
        }));
        if (!trulyUniqueProducts.length) {
            this.productDistributSpinner = false;
            this.showValidationToast();
            return;
        }
        // Step 6: Send to server if we have anything to update
        if (newProductsPayload.length > 0) {
            const payload = JSON.stringify(newProductsPayload);
            this.isModalOpen = false;
            try {
                const response = await createVisitJobs({
                    visitId: this.visitId,
                    visitJobWrapper: payload
                });
                this.selectedProductsValue = [];
                await this.loadProductDistributionData();
                this.restoreOrderAfterRefresh();

                const selectedId = this.selectedProductDistributorId;
                this.handleProductClick({ currentTarget: { dataset: { id: selectedId } } });
                this.productDistributSpinner = false;
            } catch (error) {
                console.error('Add product failed', error);
                this.productDistributSpinner = false;
            } finally {
                this.productDistributSpinner = false;
            }
        } else {
            this.productDistributSpinner = false;
        }
    }

    handleSelectProduct(event) {
        this.selectedProductsValue = event.detail.payload.values;
    }

    async handleChangeStatus(event) {
        if (this.productDistributSpinner) return; //For Missing Visit Jobs Issue
        const productId = event.currentTarget.dataset.id;
        let productStatus = event.currentTarget.dataset.name;
        productStatus = productStatus === 'OutOfStock' ? 'Distributed' : 'OutOfStock';

        const selectedProduct = this.defaultData.find(prod => prod.productId === productId);
        if (!selectedProduct) return;

        let result = [];
        if (!selectedProduct) {
            console.warn('No matching product found.');
            return;
        }
        if (selectedProduct.visitJobId && productStatus != selectedProduct.visitJobAnswer) {
            result = [{
                productId: selectedProduct.productId,
                visitJobId: selectedProduct.visitJobId,
                visitJobAnswer: productStatus,
                ...(selectedProduct.visitJobJobDef ? { visitJobJobDef: selectedProduct.visitJobJobDef } : {}),
                ...(selectedProduct.visitJobJobDefTemplate ? { visitJobJobDefTemplate: selectedProduct.visitJobJobDefTemplate } : {}),
                ...(selectedProduct.visitJobDataTypeOption ? { visitJobDataTypeOption: selectedProduct.visitJobDataTypeOption } : {})
            }];
        }
        if (result.length > 0) {
            this.productDistributSpinner = true;
            try {
                const payload = JSON.stringify(result);
                const response = await createVisitJobs({
                    visitId: this.visitId,
                    visitJobWrapper: payload
                });
                await this.loadProductDistributionData();
            } catch (error) {
                console.error('Status update failed', error);
            } finally {
                this.productDistributSpinner = false;
            }
        } else {
            this.productDistributSpinner = false;
        }
    }

    async handleChangeProductStatus(event) {
        const productId = event.currentTarget.dataset.id;
        const selectedValue = event.target.innerText;
        this.selectedValue = selectedValue;
        this.dropdownOpen = false;

        let selectedProduct = this.defaultData.find(prod => prod.productId === productId);
        if (!selectedProduct) {
            console.warn('No matching product found.');
            return;
        }

        if (selectedValue === 'Delete') {
            if (selectedProduct.visitJobId && selectedProduct.isDeletable) {
                const result = await LightningConfirm.open({
                    message: 'Are you sure want to delete the Product.',
                    variant: "default",
                    label: "Info"
                });
                if (result) {
                    this.productDistributSpinner = true;
                    try {
                        await deleteRecord(selectedProduct.visitJobId);
                        this.dispatchEvent(new ShowToastEvent({
                            title: "Product",
                            message: "Product deleted successfully",
                            variant: "success"
                        }));
                        await this.loadProductDistributionData();
                    } catch (error) {
                        console.error('Error deleting Product :', error);
                        this.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: "Failed to delete Product.",
                            variant: "error"
                        }));
                    } finally {
                        this.productDistributSpinner = false;
                    }
                }
            } else {
                console.warn('No visitJobId found to Delete.');
                this.productDistributSpinner = false;
            }
        } else {
            let result = [];
            if (!selectedProduct) {
                console.warn('No matching product found.');
                return;
            }
            if (selectedProduct.visitJobId && selectedValue != selectedProduct.visitJobAnswer) {
                result = [{
                    productId: selectedProduct.productId,
                    visitJobId: selectedProduct.visitJobId,
                    visitJobAnswer: selectedValue,
                    ...(selectedProduct.visitJobJobDef ? { visitJobJobDef: selectedProduct.visitJobJobDef } : {}),
                    ...(selectedProduct.visitJobJobDefTemplate ? { visitJobJobDefTemplate: selectedProduct.visitJobJobDefTemplate } : {}),
                    ...(selectedProduct.visitJobDataTypeOption ? { visitJobDataTypeOption: selectedProduct.visitJobDataTypeOption } : {})
                }];
            }
            if (result.length > 0) {
                this.productDistributSpinner = true;
                try {
                    const payload = JSON.stringify(result);
                    const response = await createVisitJobs({
                        visitId: this.visitId,
                        visitJobWrapper: payload
                    });
                    await this.loadProductDistributionData();
                } catch (error) {
                    console.error('Error in createVisitJobs', error);
                } finally {
                    this.productDistributSpinner = false;
                }
            } else {
                this.productDistributSpinner = false;
            }
        }
    }
}