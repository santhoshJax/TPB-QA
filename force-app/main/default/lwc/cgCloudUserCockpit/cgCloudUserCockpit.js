import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import LightningConfirm from "lightning/confirm";
//import getVisitTemplates from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitTemplates';
//import getVisitTypePicklistValues from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitTypePicklistValues';
import getCustomerAccounts from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerAccounts';
//import createVisit from '@salesforce/apex/TPBOnlineAppVisitProcess.createVisit';
import getCustomerTaskTemplates from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerTaskTemplates';
import createCustomerTask from '@salesforce/apex/TPBOnlineAppVisitProcess.createCustomerTask';
import getCustomerTasks from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerTasks';
import getDashboardLinks from '@salesforce/apex/TPBOnlineAppVisitProcess.getDasboardLinks';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
//import ShippingState from '@salesforce/schema/Account.ShippingState';
//import RefreshFilterChannel from '@salesforce/messageChannel/refreshMessageChannel__c';
//import { subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
//import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';
export default class CgCloudUserCockpit extends NavigationMixin(LightningElement) {
    //@wire(MessageContext)
    context;
    @track visitTemplateOptions = [];
    @track visitTypeOptions = [];
    @track customerAccounts = [];
    @track selectedCustomerValue = '';
    //@track selectedAccountValue = '';
    @track isModalOpen = false;
    @track isLoading = false;
    //@track storeCockpit = false;
    @track isVisitsFinalData = false;
    @track selectedVisitTemplate = '';
    @track selectedVisitType = '';
    @track selectedVisitDate = '';
    //@track selectedCustomerName;
    @track selectedCalendarDate = new Date().toISOString();
    @track selectedVisitTime = '';
    @track visitsFinalData = '';
    //@track selectedVisitId;
    //@track isVisitDone = false;
    @track totalVisits = 0;
    @track userName = '';
    @track selectedCustomerTaskDate;
    @track customerTasksData = [];
    @track dashboardLinksData = [];
    @track selectedCustomerType;
    @track wireRefreshCustomerTasks = '';
    @track isCustomerTaskData = false;
    @track accountRecordTypeOptions = [];
    @track selectedAccountRecordTypeId = '';
    @track isRecordTypeModalOpen = false;

    // @track wireRefreshVisitsData;
    // Defalut selected template
    @track setDefaultVisitTemplate = '';
    @track setDefaultVisitType = '';

    childFound = false;
    @track isDisabled = false;
    visitSpinner = false;
    userId = Id;
    @wire(getRecord, { recordId: '$userId', fields: NAME_FIELD })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.Name.value != null) {
                this.userName = data.fields.Name.value;
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: 'Account' })
    accountObjectInfo({ error, data }) {
        if (data) {
            const recordTypeInfos = data.recordTypeInfos || {};
            const options = Object.keys(recordTypeInfos)
                .filter(
                    recordTypeId =>
                        recordTypeInfos[recordTypeId].available &&
                        !recordTypeInfos[recordTypeId].master
                )
                .map(recordTypeId => ({
                    label: recordTypeInfos[recordTypeId].name,
                    value: recordTypeId
                }))
                .sort((a, b) => a.label.localeCompare(b.label));

            this.accountRecordTypeOptions = options;

            if (!this.selectedAccountRecordTypeId && options.length === 1) {
                this.selectedAccountRecordTypeId = options[0].value;
            }
        } else if (error) {
            console.error(error);
        }
    }

    handleAccountRecordTypeChange(event) {
        this.selectedAccountRecordTypeId = event.detail.value;
    }

    closeRecordTypeModal() {
        this.isRecordTypeModalOpen = false;
    }

    handleRecordTypeContinue() {
        if (!this.selectedAccountRecordTypeId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Record Type Required',
                    message: 'Select a record type before creating a new Account.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isRecordTypeModalOpen = false;
        this.navigateToNewAccount(this.selectedAccountRecordTypeId);
    }

    get isRecordTypeContinueDisabled() {
        return !this.selectedAccountRecordTypeId;
    }

    handleNewAccount() {
        if (!this.accountRecordTypeOptions || this.accountRecordTypeOptions.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Store Types Unavailable',
                    message: 'Record types are not available yet. Please try again.',
                    variant: 'error'
                })
            );
            return;
        }
        if (this.accountRecordTypeOptions.length === 1) {
            this.selectedAccountRecordTypeId = this.accountRecordTypeOptions[0].value;
        } else {
            this.selectedAccountRecordTypeId = '';
        }
        this.isRecordTypeModalOpen = true;
    }

    navigateToNewAccount(recordTypeId) {
        const defaultFieldValues = encodeDefaultFieldValues({
            Created_from_Online_App__c: true
        });
        // Standard navigation to "New Account" modal
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                ...(recordTypeId ? { recordTypeId } : {}),
                defaultFieldValues
            }
        });
    }

    @wire(getCustomerTaskTemplates)
    wireGetCustomerTaskTemplates({ error, data }) {
        if (data) {
            console.log(' getCustomerTaskTemplates data...' + JSON.stringify(data));
            this.customerTaskTemplateOptions = data.map(item => ({
                label: item.cgcloud__Description__c,
                value: item.Id
            }));

        } else if (error) {
            console.error(error);
        }
    }
    @wire(getDashboardLinks)
    wireGetDashboardLinks(value) {
        const { error, data } = value;
        if (data) {
            console.log('wireGetDashboardLinks data...' + JSON.stringify(data));
            this.dashboardLinksData = data.map(item => ({
                Id: item.Id,
                description: item.cgcloud__Description__c,
                url: this.normalizeUrl(item.cgcloud__URL__c)
            }));
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getCustomerTasks, { selectedDate: '$selectedCalendarDate' })
    wireGetCustomerTasks(value) {
        this.wireRefreshCustomerTasks = value;
        const { error, data } = value;
        if (data) {
            console.log('wireGetCustomerTasks data...' + JSON.stringify(data));
            this.customerTasksData = data.map(item => {
                const dueDate = new Date(item.cgcloud__Due_Date__c);
                dueDate.setHours(0, 0, 0, 0);
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                return {
                    Name: item.cgcloud__Account__r?.Name,
                    Id: item.Id,
                    accountId: item.cgcloud__Account__c,
                    description: item.cgcloud__Description_Language_1__c,
                    due_date: item.cgcloud__Due_Date__c,
                    isPresentOrPast: dueDate <= today
                };
            });
            this.isCustomerTaskData = this.customerTasksData.length > 0 ? true : false;
        } else if (error) {
            console.error(error);
            this.isCustomerTaskData = false;
        }
    }
    // [{"Id":"0016T00002wbzliQAA","Name":"GROCERS SUPPLY","Type":"Retail","ShippingStreet":"5760 Dorinda Drive","ShippingCity":"Louisville","ShippingState":"OH","Account_Number_old__c":"641839"}]
    async loadCustomerAccounts() {
        await getCustomerAccounts({ accountId: this.recordId ? this.recordId : null })
            .then(data => {
                console.log('getCustomerAccounts data...' + JSON.stringify(data));
                this.customerAccounts = data.map(item => ({
                    label: item.Name,
                    value: item.Id,
                    sublabel: [
                        item.ShippingStreet || '',
                        item.ShippingCity || '',
                        item.ShippingState || ''
                    ].filter(Boolean).join(', '),
                    ShippingStreet: item.ShippingStreet,
                    ShippingCity: item.ShippingCity,
                    ShippingState: item.ShippingState,
                    ShippingPostalCode: item.ShippingPostalCode,
                    AccountNumberold: item.Account_Number_old__c,
                    type: item.Type
                }));

                const singleCombobox = this.template.querySelector('c-custom-lookup-search');
                if (singleCombobox && this.customerAccounts) {
                    singleCombobox.refreshOptions(this.customerAccounts);
                }
            })
            .catch(error => {
                console.error(error);
                this.customerAccounts = [];
            });
    }


    handleChangeCustomer(event) {
        this.selectedCustomerValue = event.detail.payload.values;
        console.log('selectedCustomerValue...' + this.selectedCustomerValue);
    }


    handleTotalVisits(event) {
        this.totalVisits = event.detail.totalvisits;
        this.visitSpinner = event.detail.spinner;
        console.log('Received total visits:', this.totalVisits);
        // You can now use `totalVisitsFromChild` in parent logic
    }

    async handleVisitListChanged() {
        if (this.wireRefreshCustomerTasks) {
            await refreshApex(this.wireRefreshCustomerTasks);
        }
    }

    handleChangeCustomerTask(event) {
        if (event.target.name == 'Due Date') {
            const selectedDate = new Date(event.target.value);
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            if (selectedDate < today) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Invalid Date',
                        message: 'Due Date must be greater than or equal to Initiation Date.',
                        variant: 'error'
                    })
                );
                this.selectedCustomerTaskDate = null;
            } else if (selectedDate >= today) {
                this.selectedCustomerTaskDate = event.target.value;
            }
        } else if (event.target.name == 'description') {
            this.description = event.target.value;
        } else if (event.target.name == 'Customer Type') {
            this.selectedCustomerType = event.detail.value;
            console.log('selectedCustomerType...' + this.selectedCustomerType);
        }
        this.isDisabled = false;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedCustomerTaskDate = '';
        this.description = '';
        this.selectedCustomerType = '';
        this.selectedCustomerValue = '';
    }

    @track tempFinalData = [];

    handleCurrentDay() {
        this.selectedCalendarDate = new Date().toISOString();
        this.visitSpinner = true;

    }

    handleNavigation() {
        console.log('Navigation');
        //this.storeCockpit = false;
        this.childFound = false;

    }
    get formatSelectedDate() {
        const date = new Date(this.selectedCalendarDate);
        return date.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: '2-digit'
        });
    }

    handlePrevDay() {
        const date = new Date(this.selectedCalendarDate);
        date.setDate(date.getDate() - 1);
        this.selectedCalendarDate = date.toISOString();
        this.visitSpinner = true;

    }

    // Navigate to the next day
    handleNextDay() {
        const date = new Date(this.selectedCalendarDate);
        date.setDate(date.getDate() + 1);
        this.selectedCalendarDate = date.toISOString();
        this.visitSpinner = true;


    }
    addnewCustomerTask() {
        this.isModalOpen = true;
        this.selectedCustomerTaskDate = '';
        this.selectedCustomerType = '';
        this.loadCustomerAccounts();

    }
    createTask() {
        console.log('time..' + this.selectedCustomerTaskDate);
        console.log('time..' + this.selectedCustomerTaskDate);
        if (this.selectedCustomerType && this.selectedCustomerTaskDate && this.selectedCustomerValue && this.description) {
            this.isDisabled = true;
            this.isLoading = true;
            createCustomerTask({ customerId: this.selectedCustomerValue, customerTaskTemplateId: this.selectedCustomerType, dueDateStr: this.selectedCustomerTaskDate, descriptionStr: this.description })
                .then((response) => {
                    // this.visitSpinner = true;

                    console.log('response...' + JSON.stringify(response));
                    this.dispatchEvent(new ShowToastEvent({
                        title: "Success",
                        message: "Task Created Successfully",
                        variant: "Success"
                    }));
                    this.isModalOpen = false;
                    this.isLoading = false;
                    this.description = '';
                    this.selectedCustomerTaskDate = '';
                    this.selectedCustomerType = '';
                    this.selectedCustomerValue = '';
                    refreshApex(this.wireRefreshCustomerTasks);
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('error...' + JSON.stringify(error));
                });

        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: "Fill the following fields",
                message: "Please fill the following fields",
                variant: "Warning"
            }));
        }
    }

    handleTaskClick(event) {
        console.log('here in CT click');
        const customerTaskId = event.currentTarget.dataset.id;
        console.log('customerTaskId...' + customerTaskId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: customerTaskId, // Replace with dynamic Account Id
                objectApiName: 'cgcloud__Account_Task__c',
                actionName: 'view'
            }
        });
    }

    normalizeUrl(url) {
        if (!url) return 'javascript:void(0)';

        // If it's already starting with "/analytics", keep it as is
        if (url.startsWith('/')) return url;

        // If it contains "/analytics/", strip everything before it
        const analyticsIndex = url.indexOf('/analytics/');
        if (analyticsIndex > -1) {
            return url.substring(analyticsIndex);
        }

        // Otherwise just return as-is
        return url;
    }


}