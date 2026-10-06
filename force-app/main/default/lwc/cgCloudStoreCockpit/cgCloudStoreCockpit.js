import { api, LightningElement, track, wire } from 'lwc';
import LightningConfirm from "lightning/confirm";
import startvisitUpdate from '@salesforce/apex/TPBOnlineAppVisitProcess.startvisitUpdate';
import endvisitUpdate from '@salesforce/apex/TPBOnlineAppVisitProcess.endvisitUpdate';
import endvisitValidate from '@salesforce/apex/TPBOnlineAppVisitProcess.endvisitValidate';
import createOrder from '@salesforce/apex/TPB_OnlineAppController.createOrder';
import getOrder from '@salesforce/apex/TPB_OnlineAppController.getOrder';
import { updateRecord } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import ID_FIELD from '@salesforce/schema/Visit.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import VISIT_NOTE_FIELD from '@salesforce/schema/Visit.cgcloud__Note__c';
import getVisitInfo from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitInfo';
import getVisitFiles from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitFiles';
import deleteVisitFile from '@salesforce/apex/TPBOnlineAppVisitProcess.deleteVisitFile';
import uploadVisitFile from '@salesforce/apex/TPBOnlineAppVisitProcess.uploadVisitFile';
import getWholesalePromotions from '@salesforce/apex/TPB_OnlineAppController.getWholesalePromotions';
import getChainAccountOverview from '@salesforce/apex/TPB_OnlineAppController.getChainAccountOverview';
import ensureVisitJobsExist from '@salesforce/apex/TPB_OnlineAppController.ensureVisitJobsExist';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation'
export default class CgCloudStoreCockpit extends NavigationMixin(LightningElement) {
    @api isVisitStarted = false;
    @api selectedAccountId;
    @api customerAccountName;
    @api visitId;
    @track visitNotes;
    @track visitDate;
    @track initiatorName = '';
    @track ChainAccountOverviewData = [];
    @track wholesalePromotionsData = [];
    @track isLoading = false;
    @track isModalOpen = false;
    @track isOrderPage = false;
    @track isReviewPage = false;
    @track isSurveyPage = false;
    @track isProductDistribution = false;
    @track isWholesalePromotionsData = false;
    @track isChainAccountOverviewData = false;
    @track orderId;
    @track location;
    @track isDisabled = false;
    @track isSpinner = false;
    @track _wireVisitInfo; 
    @track _wireVisitFiles;
    @track isProductDistributionAccessed = false;
    @track visitFiles = [];
    @track isVisitFiles = false;
    visitInfoRevalidated = false;
    isVisitFileUploadInProgress = false;
    navigateToUserCockpit() {
        this.dispatchEvent(new CustomEvent('navigate'));
    }
    navigateToUserCockpitDeferred() {
        setTimeout(() => this.navigateToUserCockpit(), 500);
    }
    get isHomePage() {
        return !this.isOrderPage && !this.isReviewPage && !this.isProductDistribution && !this.isSurveyPage;
    }
    get isVisitJobsCreated() {
        return this.isProductDistributionAccessed;
    }
    async connectedCallback() {
        //await this.loadCustomerAccounts();
        console.log('this.isVisitStarted111...'+this.isVisitStarted);
    }
    async handleVisitFieldsUpdated() {
        console.log('[StoreCockpit] Visit fields updated — refreshing wire');
        if (this._wireVisitInfo) {
            await refreshApex(this._wireVisitInfo); // ← forces wire to re-fire with fresh data
        }
    }
    @wire(getWholesalePromotions, { accountId: '$selectedAccountId' })
    wireWholesalePromotions(value) {
        const { data, error } = value;
        if (data) {
            console.log(data)
            this.wholesalePromotionsData = Object.keys(data).map(item => ({
                "label": data[item],
                "value": item,
                "url": `/sfc/servlet.shepherd/document/download/${item}`
            }))
            //console.log('this.wholesalePromotionsData' + JSON.stringify(this.wholesalePromotionsData));
            this.isWholesalePromotionsData = this.wholesalePromotionsData.length > 0;
        }
        if (error) {
            console.error('error...' + JSON.stringify(error));
            this.isWholesalePromotionsData = false;
        }
    }
    @wire(getChainAccountOverview, { accountId: '$selectedAccountId' })
    wireChainAccountOverview(value) {
        const { data, error } = value;
        if (data) {
            console.log(data)
            this.ChainAccountOverviewData = Object.keys(data).map(item => ({
                "label": data[item],
                "value": item,
                "url": `/sfc/servlet.shepherd/document/download/${item}`
            }))
            console.log('this.ChainAccountOverviewData' + JSON.stringify(this.ChainAccountOverviewData));
            this.isChainAccountOverviewData = this.ChainAccountOverviewData.length > 0;
        }
        if (error) {
            console.error('error...' + JSON.stringify(error));
            this.isChainAccountOverviewData = false;
        }
    }
    // @wire(getVisitInfo, { visitId: '$visitId' })
    // getVisitInfo({ error, data }) {
    //     if (data) {
    //         console.log('getVisitInfo data...' + JSON.stringify(data));
    //         this.visitNotes = data[0].cgcloud__Note__c || null;
    //         this.initiatorName = data[0].cgcloud__Responsible__r?.Name;
    //         const dateObj = new Date(data[0].PlannedVisitStartTime);
    //         const formattedDate = dateObj.toISOString().split('T')[0];
    //         this.visitDate = formattedDate;
    //         this.isVisitStarted = data[0].TPB_InProgress__c || false;
    //         this.isProductDistributionAccessed = data[0].Product_Distribution_Accessed__c || false;
    //     } else if (error) {
    //         console.error('error...' + JSON.stringify(error));
    //     }
    // }
    @wire(getVisitInfo, { visitId: '$visitId' })
    getVisitInfo(result) {                    // ← change signature
        this._wireVisitInfo = result;         // ← store for refreshApex
        const { error, data } = result;
        if (data && data.length > 0) {
            console.log('getVisitInfo data...' + JSON.stringify(data));
            this.visitNotes = data[0].cgcloud__Note__c || null;
            this.initiatorName = data[0].cgcloud__Responsible__r?.Name;
            const dateObj = new Date(data[0].PlannedVisitStartTime);
            const formattedDate = dateObj.toISOString().split('T')[0];
            this.visitDate = formattedDate;
            this.isVisitStarted = Boolean(data[0].TPB_InProgress__c);
            this.isProductDistributionAccessed = 
                Boolean(data[0].Product_Distribution_Accessed__c);

            // Force one server revalidation to avoid occasional stale storable-wire state on reload.
            if (this.visitId && !this.visitInfoRevalidated) {
                this.visitInfoRevalidated = true;
                refreshApex(this._wireVisitInfo).catch(err => {
                    console.error('Error revalidating visit info...', JSON.stringify(err));
                });
            }
        } else if (data && data.length === 0) {
            this.isVisitStarted = false;
            this.isProductDistributionAccessed = false;
        } else if (error) {
            console.error('error...' + JSON.stringify(error));
        }
    }

    @wire(getVisitFiles, { visitId: '$visitId' })
    wiredVisitFiles(result) {
        this._wireVisitFiles = result;
        const { data, error } = result;
        if (data) {
            this.visitFiles = data.map(file => ({
                ...file,
                createdDateLabel: file.createdDate ? new Date(file.createdDate).toLocaleDateString() : '',
                sizeLabel: this.formatFileSize(file.contentSize)
            }));
            this.isVisitFiles = this.visitFiles.length > 0;
        } else if (error) {
            console.error('error loading visit files...' + JSON.stringify(error));
            this.visitFiles = [];
            this.isVisitFiles = false;
        }
    }

    formatFileSize(bytes) {
        if (!bytes || bytes <= 0) {
            return '0 KB';
        }
        const kb = bytes / 1024;
        if (kb < 1024) {
            return `${Math.round(kb)} KB`;
        }
        return `${(kb / 1024).toFixed(1)} MB`;
    }

    handleVisitUploadClick(event) {
        const container = event.currentTarget.closest('.visit-upload-control');
        const fileInput = container?.querySelector('.hidden-visit-file-input');
        if (fileInput) {
            fileInput.click();
        }
    }

    readBrowserFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const result = typeof reader.result === 'string' ? reader.result : '';
                const parts = result.split(',');
                const base64 = parts.length > 1 ? parts[1] : '';
                if (!base64) {
                    reject(new Error('Unable to read file data'));
                    return;
                }
                resolve(base64);
            };
            reader.onerror = () => reject(reader.error || new Error('Unable to read file'));
            reader.readAsDataURL(file);
        });
    }

    readBrowserFileAsDataUrl(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(typeof reader.result === 'string' ? reader.result : '');
            reader.onerror = () => reject(reader.error || new Error('Unable to read file'));
            reader.readAsDataURL(file);
        });
    }

    async compressImageFile(file, maxDimension = 1600, quality = 0.75) {
        const dataUrl = await this.readBrowserFileAsDataUrl(file);
        if (!dataUrl) {
            throw new Error('Unable to read image');
        }
        const image = await new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => resolve(img);
            img.onerror = () => reject(new Error('Unable to process image'));
            img.src = dataUrl;
        });

        let targetWidth = image.width;
        let targetHeight = image.height;
        const larger = Math.max(targetWidth, targetHeight);
        if (larger > maxDimension) {
            const scale = maxDimension / larger;
            targetWidth = Math.round(targetWidth * scale);
            targetHeight = Math.round(targetHeight * scale);
        }

        const canvas = document.createElement('canvas');
        canvas.width = targetWidth;
        canvas.height = targetHeight;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
            throw new Error('Canvas not supported on this browser');
        }
        ctx.drawImage(image, 0, 0, targetWidth, targetHeight);

        const outType = 'image/jpeg';
        const compressedDataUrl = canvas.toDataURL(outType, quality);
        const parts = compressedDataUrl.split(',');
        const base64Data = parts.length > 1 ? parts[1] : '';
        if (!base64Data) {
            throw new Error('Unable to compress image');
        }

        const normalizedName = (file.name || 'photo.jpg').replace(/\.[^.]+$/, '') + '.jpg';
        return {
            fileName: normalizedName,
            contentType: outType,
            base64Data
        };
    }

    async buildUploadPayload(file) {
        const isImage = (file.type || '').startsWith('image/');
        if (isImage) {
            // Camera photos can be large; compress for Apex-safe payload size.
            return this.compressImageFile(file);
        }
        const base64Data = await this.readBrowserFileAsBase64(file);
        return {
            fileName: file.name,
            contentType: file.type,
            base64Data
        };
    }

    sleep(ms) {
        return new Promise(resolve => window.setTimeout(resolve, ms));
    }

    isApexRateLimitError(error) {
        const message = (error?.body?.message || error?.message || '').toLowerCase();
        return message.includes('hit rate limit while running apex action')
            || message.includes('rate limit');
    }

    async uploadVisitFileWithRetry(params, retries = 2) {
        let attempt = 0;
        let waitMs = 400;
        while (true) {
            try {
                return await uploadVisitFile(params);
            } catch (error) {
                const shouldRetry = this.isApexRateLimitError(error) && attempt < retries;
                if (!shouldRetry) {
                    throw error;
                }
                await this.sleep(waitMs);
                waitMs = Math.min(waitMs * 2, 1600);
                attempt++;
            }
        }
    }

    async handleVisitFileSelected(event) {
        const files = Array.from(event.target.files || []);
        if (!this.visitId || files.length === 0) {
            return;
        }
        if (this.isVisitFileUploadInProgress) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Info',
                    message: 'Upload is already in progress. Please wait.',
                    variant: 'info'
                })
            );
            event.target.value = '';
            return;
        }

        this.isSpinner = true;
        this.isVisitFileUploadInProgress = true;
        let uploadedCount = 0;
        const failedFiles = [];
        try {
            for (const file of files) {
                try {
                    const payload = await this.buildUploadPayload(file);
                    await this.uploadVisitFileWithRetry({
                        visitId: this.visitId,
                        fileName: payload.fileName,
                        base64Data: payload.base64Data,
                        contentType: payload.contentType
                    });
                    uploadedCount++;
                    await this.sleep(200);
                } catch (fileError) {
                    console.error('Error uploading single visit file...', JSON.stringify(fileError));
                    failedFiles.push(file?.name || 'Unknown file');
                }
            }
            if (this._wireVisitFiles) {
                await refreshApex(this._wireVisitFiles);
            }
            if (uploadedCount > 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: failedFiles.length > 0 ? 'Partial Success' : 'Success',
                        message: failedFiles.length > 0
                            ? `${uploadedCount} file(s) uploaded, ${failedFiles.length} failed`
                            : `${uploadedCount} file(s) uploaded`,
                        variant: failedFiles.length > 0 ? 'warning' : 'success'
                    })
                );
            } else if (failedFiles.length > 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to upload file(s). Please retry.',
                        variant: 'error'
                    })
                );
            }
        } catch (error) {
            console.error('Error uploading visit file...', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'Unable to upload file',
                    variant: 'error'
                })
            );
        } finally {
            this.isSpinner = false;
            this.isVisitFileUploadInProgress = false;
            event.target.value = '';
        }
    }

    async handleDeleteVisitFile(event) {
        const contentDocumentId = event.currentTarget?.dataset?.id;
        if (!contentDocumentId || !this.visitId) {
            return;
        }
        const confirmed = await LightningConfirm.open({
            message: "Do you want to delete this file?",
            variant: "default",
            label: "Confirm"
        });
        if (!confirmed) {
            return;
        }
        this.isSpinner = true;
        try {
            await deleteVisitFile({ visitId: this.visitId, contentDocumentId });
            if (this._wireVisitFiles) {
                await refreshApex(this._wireVisitFiles);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Deleted',
                    message: 'File deleted successfully',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Error deleting visit file...', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'Unable to delete file',
                    variant: 'error'
                })
            );
        } finally {
            this.isSpinner = false;
        }
    }
   

    async startVisit() {
        try {
            console.log('this.visitId...' + this.visitId);
            const result = await LightningConfirm.open({
                message: "Are you sure you want to Start Visit?",
                variant: "default",
                label: "Info"
            });
            if (result) {
                this.isSpinner = true;

                //let locationInfo;

                this.deviceLocationService = getLocationService();
                if (this.deviceLocationService.isAvailable()) {
                    // Perform geolocation operations using native capabilities
                    this.test = 'Test 3';
                    await this.calculateLocationFromMobileDevice();

                }
                else {
                    // LocationService not available
                    // Fallback to using browser geolocation API
                    await this.calculateLocationFromBrowser();
                }
                // this.mobileDevice = this.deviceLocationService.isAvailable();
                // console.log('this.deviceLocationService.isAvailable()...' + this.deviceLocationService.isAvailable());

                if (this.location) {
                    //console.log('this.location...' + JSON.stringify(this.location));

                    const latitude1 = this.location.coords.latitude;

                    const longitude1 = this.location.coords.longitude;
                    //startvisitUpdate(Id visitId, Id accountId, Double startVisitLatitude, Double startVisitLongitude)
                    const response = await startvisitUpdate({
                        visitId: this.visitId,
                        accountId: this.selectedAccountId,
                        startVisitLatitude: latitude1,
                        startVisitLongitude: longitude1
                    });
                    console.log('response...' + JSON.stringify(response));
                    if (response === true) {
                        this.isVisitStarted = true;
                        if (this._wireVisitInfo) {
                            await refreshApex(this._wireVisitInfo);
                        }
                    } else {
                        await LightningConfirm.open({
                            message: "You cannot start this visit because there are other in progress visits.",
                            variant: "default",
                            label: "Info"
                        });
                    }
                }


            }
        } catch (error) {
            this.isSpinner = false;
            console.error('error StartVisit...', JSON.stringify(error));
        } finally {
            this.isSpinner = false;
        }
    }

    
    async endVisit() {
        let navigationTriggered = false;
        try {
            console.log('this.visitId...' + this.visitId);

            this.isSpinner = true;
            this.deviceLocationService = getLocationService();
            if (this.deviceLocationService.isAvailable()) {
                // Perform geolocation operations using native capabilities
                await this.calculateLocationFromMobileDevice();
            }
            else {
                // LocationService not available
                // Fallback to using browser geolocation API
                await this.calculateLocationFromBrowser();
            }
            //console.log('this.location...' + JSON.stringify(this.location));
            if (this.location) {
                //console.log('this.location...' + JSON.stringify(this.location));
                const latitude2 = this.location.coords.latitude;
                const longitude2 = this.location.coords.longitude;

                //New Code
                const response = await endvisitValidate({
                    visitId: this.visitId,
                    accountId: this.selectedAccountId,
                    validateEndVisitDistribution: true,
                    validateEndVisitSurvey: true
                });
                console.log('response...' + response);

                this.isSpinner = false;

                // A) Open Orders Block
                if (response === 'open_orders') {
                    await LightningConfirm.open({
                        message: "There are still open orders assigned to the visit.",
                        variant: "default",
                        label: "Info"
                    });
                    return;
                }

                // B) Customer Tasks Block
                if (response === 'open_customerTasks') {
                    await LightningConfirm.open({
                        message: "It is not possible to complete the visit because there are still open customer tasks.",
                        variant: "default",
                        label: "Info"
                    });
                    return;
                }

                // C) Pending Product Distribution - ask override
                if (response === 'pending_product_distribution') {
                    const result = await LightningConfirm.open({
                        message: "You have not done Product Distribution, do you really want to End the visit?",
                        variant: "default",
                        label: "Info"
                    });

                    if (!result) return; // user cancelled

                    // user confirmed → bypass validation
                    this.isSpinner = true;
                    await this.updateVisitJobsWithEndVisitValidation();

                    const response2 = await endvisitValidate({
                        visitId: this.visitId,
                        accountId: this.selectedAccountId,
                        validateEndVisitDistribution: false,
                        validateEndVisitSurvey: true
                    });
                    this.isSpinner = false;
                    console.log('response2...' + response2);
                    if (response2 === 'pending_survey_questions') {
                            const result = await LightningConfirm.open({
                            message: "You have not done Surveys, do you really want to End the visit?",
                            variant: "default",
                            label: "Info"
                        });

                        if (!result) return; // user cancelled
                        // user confirmed

                        this.isSpinner = true;
                        await endvisitUpdate({
                            visitId: this.visitId,
                            endVisitLatitude: latitude2,
                            endVisitLongitude: longitude2,
                            accountId: this.selectedAccountId
                        });

                        this.isSpinner = false;
                        this.navigateToUserCockpitDeferred();
                        return;
                    }
                    if(response2 === 'validated'){
                        this.isSpinner = true;
                        await endvisitUpdate({
                            visitId: this.visitId,
                            endVisitLatitude: latitude2,
                            endVisitLongitude: longitude2,
                            accountId: this.selectedAccountId
                        });

                        this.isSpinner = false;
                        this.navigateToUserCockpitDeferred();
                        return;
                    } 
                }
                if (response === 'pending_survey_questions') {
                    const result = await LightningConfirm.open({
                        message: "You have not done Surveys, do you really want to End the visit?",
                        variant: "default",
                        label: "Info"
                    });

                    if (!result) return; // user cancelled

                    // user confirmed 

                    this.isSpinner = true;
                    await endvisitUpdate({
                        visitId: this.visitId,
                        endVisitLatitude: latitude2,
                        endVisitLongitude: longitude2,
                        accountId: this.selectedAccountId,
                    });

                    this.isSpinner = false;
                    this.navigateToUserCockpitDeferred();
                    return;
                
                }
                if(response === 'validated'){

                    const finalConfirm = await LightningConfirm.open({
                        message: "Are you sure you want to End Visit?",
                        variant: "default",
                        label: "Info"
                    });

                    if (!finalConfirm) return; // user cancelled

                    // -----------------------------------------
                    // 5. End visit
                    // -----------------------------------------
                    this.isSpinner = true;

                    await endvisitUpdate({
                        visitId: this.visitId,
                        endVisitLatitude: latitude2,
                        endVisitLongitude: longitude2,
                        accountId: this.selectedAccountId,
                    });
                    navigationTriggered = true;
                    this.isSpinner = false;
                    this.navigateToUserCockpitDeferred();
                    return;
                } 
                //End
                
            } else {
                console.log('result444...' + result);
            }

        } catch (error) {
            this.isSpinner = false;
            
            const message =
                error?.body?.message ||
                error?.message ||
                (Array.isArray(error?.body?.pageErrors) && error.body.pageErrors.length
                    ? error.body.pageErrors[0].message
                    : null) ||
                'Unexpected error during End Visit.';
            console.error('endVisit error...', error);
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'End Visit Error',
            //         message,
            //         variant: 'error'
            //     })
            // );
        } finally {
            //this.isSpinner = false;
            if (!navigationTriggered) { // ← ONLY reset if not navigating
                this.isSpinner = false;
            }
        }
    }


  
    async updateVisitJobsWithEndVisitValidation() {
        this.isSpinner = true;
        try {
            await ensureVisitJobsExist({
                accountId: this.selectedAccountId,
                visitId: this.visitId
            });
            console.log('ensureVisitJobsExist completed successfully');
        } catch (error) {
            this.isSpinner = false;
            console.error('ensureVisitJobsExist failed:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to initialize visit jobs. Please retry.',
                variant: 'error'
            }));
        } finally {
            this.isSpinner = false;
        }
    }


    async calculateLocationFromMobileDevice() {
        try {
            this.location = await this.deviceLocationService.getCurrentPosition(
                {
                    enableHighAccuracy: true
                }
            );
            //this.location = JSON.stringify(this.location);
            //console.log('this.location111...' + JSON.stringify(this.location));
            // this.calculateDistance();
        } catch (error) {
            this.error = error;
        }
    }


    calculateLocationFromBrowser() {
   

        return new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(
                (result) => {
                    this.location = result;
                    //console.log('this.location222...' + JSON.stringify(this.location));
                    resolve(result);
                },
                (error) => {
                    this.error = error;
                    reject(error);
                }
            );
        });
    }
    handleCreateOrder() {
        try {
            console.log('this.selectedAccountId...', this.selectedAccountId);
            console.log('this.visitId...', this.visitId);
            this.isSpinner = true;
            this.isDisabled = true;
            getOrder({
                accountId: this.selectedAccountId,
                visitId: this.visitId
            })
                .then(response => {
                    console.log('response...', JSON.stringify(response));

                    if (response && response.Id) {
                        this.orderId = response.Id;

                        LightningConfirm.open({
                            message: "You already have one open order for this visit. Do you want to navigate to the existing order?",
                            variant: "default",
                            label: "Info"
                        }).then(result => {
                            if (result) {
                                this.isOrderPage = true;
                            }else{
                                this.isDisabled = false;
                            }
                        });
                        this.isSpinner = false;

                    } else {
                        console.log('No existing order found. Creating a new one...');

                        createOrder({
                            accountId: this.selectedAccountId,
                            visitId: this.visitId
                        }).then(createResponse => {
                            this.orderId = createResponse;
                            console.log('Created order:', JSON.stringify(createResponse));
                            this.isSpinner = false;
                            this.isDisabled = false;
                            this.isOrderPage = true;
                        }).catch(createErr => {
                            console.error('Error creating order:', JSON.stringify(createErr));
                        });
                    }
                })
                .catch(error => {
                    console.error('Error getting order:', JSON.stringify(error));
                });


        } catch (error) {
            console.error('error...', JSON.stringify(error));
            this.isSpinner = false;
        } finally {
            this.isSpinner = false;
        }
    }
    handleReturnToStoreCockpit() {
        this.isDisabled = false;
        this.isReviewPage = false;
        this.isOrderPage = false;
        this.isSurveyPage = false;
        this.isProductDistribution = false;

    }
    handleReturnToOrderPage() {
        this.isReviewPage = false;
        this.isOrderPage = true;
        this.isSurveyPage = false;
        this.isProductDistribution = false;

    }
    handleNavigateToProductDistribution() {
        this.isReviewPage = false;
        this.isOrderPage = false;
        this.isSurveyPage = false;
        this.isProductDistribution = true;
    }
    handleNavigationToSuvery() {
        this.isSurveyPage = true;
        this.isProductDistribution = false;
        this.isOrderPage = false;
        this.isReviewPage = false;
    }
    handleReview() {
        //console.log('Review')
        this.isReviewPage = true;
        this.isOrderPage = false;
        this.isSurveyPage = false;
        this.isProductDistribution = false;
    }
    handleCompleteOrder() {
        this.isReviewPage = false;
        this.isOrderPage = false;
        this.isSurveyPage = false;
        this.isProductDistribution = false;
        this.isDisabled = false;
    }
    editVisitNotes() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
        this.isLoading = false;
    }
    handleInput(event) {
        console.log('Visit Notes:', event.target.value);
        this.visitNotes = event.target.value;

    }

    handleSaveNote() {

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.visitId;
        fields[VISIT_NOTE_FIELD.fieldApiName] = this.visitNotes;

        const recordInput = { fields };
        console.log('recordInput...' + JSON.stringify(recordInput));
        this.isLoading = true;
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated successfully',
                        variant: 'success'
                    })
                );
                this.closeModal();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    previewHandler(event) {
        //console.log(event.currentTarget.dataset.id)
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.currentTarget.dataset.id
            }
        })
    }

    handleVisitFilePreview(event) {
        const contentDocumentId = event.currentTarget?.dataset?.id;
        const fileType = (event.currentTarget?.dataset?.type || '').toUpperCase();
        if (!contentDocumentId) {
            return;
        }

        const imageTypes = ['PNG', 'JPG', 'JPEG', 'GIF', 'BMP', 'WEBP', 'HEIC', 'HEIF'];
        if (imageTypes.includes(fileType)) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/sfc/servlet.shepherd/document/download/${contentDocumentId}`
                }
            });
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocumentId
            }
        });
    }
}