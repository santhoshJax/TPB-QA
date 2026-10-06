import { LightningElement, track, api,wire } from 'lwc';
import getVisitTemplates from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitTemplates';
import getCustomerAccounts from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerAccounts';
import getVisitTypePicklistValues from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitTypePicklistValues';
import getMyVisits from '@salesforce/apex/TPBOnlineAppVisitProcess.getMyVisits';
import createVisit from '@salesforce/apex/TPBOnlineAppVisitProcess.createVisit';
import getCustomerTasks from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerTasks';
import createCustomerTask from '@salesforce/apex/TPBOnlineAppVisitProcess.createCustomerTask';
import getCustomerTaskTemplates from '@salesforce/apex/TPBOnlineAppVisitProcess.getCustomerTaskTemplates';
import cancelVisit from '@salesforce/apex/TPBOnlineAppVisitProcess.cancelVisit';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';


export default class CgCloudVisitsList extends NavigationMixin(LightningElement) {
   @api selectedCalendarDate = new Date().toISOString();
   @track selectedVisitTime = '';
   @api selectedAccountId;
   @track visitsFinalData = [];
   @track selectedVisitDate = '';
   @track selectedVisitType = '';
   @track customerAccounts = [];
   @track visitTypeOptions = [];
   @track customerTasksData = [];
   @track selectedVisitTemplate = '';
   @track selectedCustomerValue = '';
   @track setDefaultVisitTemplate = '';
   @track wireRefreshVisitsData = '';
   @track isModalOpen = false;
   @track visitsData;
   @track isLoading = false;
   @track isTaskLoading = false;
    @track storeCockpit = false;
   @track isVisitsFinalData = false;
   @track isCustomerTaskModalOpen = false;
   @track visitTemplateOptions = [];
   isDisabled = false;
   @track selectedCustomerTaskValue;
    @track selectedCustomerType;
   @track wireRefreshCustomerTasks = '';
   @track customerTaskTemplateOptions = [];
   @track isCustomerTaskData = false;


   @track description;
   @track selectedCustomerTaskDate;
   currentPageReference;
   isAccountPage = false;
   @track cardSize =  12;
   //recordId;
   @api recordId;
   isCustomerAccountsExist = true;
   @track isVisitStarted = false;


   selectedVisitId;


  
     closeModal() {
       this.isModalOpen = false;
       this.selectedVisitTemplate = '';
       this.selectedVisitType = '';
       this.selectedVisitDate = '';
       this.selectedVisitTime = '';
         this.selectedCustomerValue = '';
         this.selectedCustomerTaskValue = ''
          this.selectedCustomerTaskDate = '';
       this.description = '';
       this.selectedCustomerType = '';
         this.isDisabled = false;
         this.isTaskDisabled = false;
         this.isTaskLoading = false;
         this.isCustomerTaskModalOpen = false;


     }
   async connectedCallback() {
       console.log('connectedCallback...');
       //await this.loadCustomerAccounts();
       // ✅ add outside click listener
       this._handleOutsideClick = this.handleOutsideClick.bind(this);
       document.addEventListener('click', this._handleOutsideClick);
   }
   renderedCallback() {
       if (!this._loaded) {
           this._loaded = true;
           this.loadCustomerAccounts();
       }
   }


   disconnectedCallback(){
       console.log('disconnectedCallback...');
       // ✅ remove outside click listener
       if (this._handleOutsideClick) {
           document.removeEventListener('click', this._handleOutsideClick);
       }
   }
   handleOutsideClick() {
       if (!Array.isArray(this.visitsFinalData)) {
           return;
       }
       this.visitsFinalData = this.visitsFinalData.map(v => ({
           ...v,
           showMenu: false
       }));
   }
   addnewCustomerTask() {
       this.isCustomerTaskModalOpen = true;
       this.selectedCustomerTaskDate = '';
       this.selectedCustomerType = '';
       this.loadCustomerAccounts();
   }
   @wire(getVisitTypePicklistValues)
   getVisitTypePicklistValues({ error, data }) {
       if (data) {
           console.log('data...' + JSON.stringify(data));
           this.visitTypeOptions = data.map(item => ({
               label: item,
               value: item
           }));
           // Set default to the first item
           const defaultVistType = data.find(item => item === 'In-Store Visit');
           if (defaultVistType) {
               this.selectedVisitType = defaultVistType;
               this.setDefaultVisitType = this.selectedVisitType;
           }
       } else if (error) {
           console.error(error);
       }
   }
  
   @wire(getCustomerTasks,{selectedDate :'$selectedCalendarDate'})
   wireGetCustomerTasks(value) {
       this.wireRefreshCustomerTasks = value;
       const { error, data } = value;
       if (data) {
           console.log('wireGetCustomerTasks data...' + JSON.stringify(data));
          const customerTasksData = data.map(item => {
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
           this.customerTasksData = customerTasksData.filter(
               task => task.accountId === this.recordId
           );
           console.log('customerTasksData...' + JSON.stringify(customerTasksData));
           console.log('this.customerTasksData...' + JSON.stringify(this.customerTasksData));
              this.isCustomerTaskData = this.customerTasksData.length > 0 ? true : false;
       } else if (error) {
           console.error(error);
           this.isCustomerTaskData = false;
       }
   }
   @wire(getVisitTemplates)
   getVisitTemplates({ error, data }) {
       if (data) {
           console.log('data...' + JSON.stringify(data));
           this.visitTemplateOptions = data.map(item => ({
               label: item.Name,
               value: item.Id
           }));
           // Set specific template by name
           const defaultTemplate = data.find(item => item.Name === 'Distribution Visit Template');
           if (defaultTemplate) {
               this.selectedVisitTemplate = defaultTemplate.Id;
               this.setDefaultVisitTemplate = this.selectedVisitTemplate;
               console.log('selectedVisitTemplate...' + this.selectedVisitTemplate);
           }
       } else if (error) {
           console.error(error);
       }
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
   @wire(CurrentPageReference)
   async getStateParameters(currentPageReference) {
       console.log('getStateParameters111...' );
       console.log('this.isVisitStarted777...' + this.isVisitStarted);
       await refreshApex(this.wireRefreshVisitsData);
       if (currentPageReference) {
           this.currentPageReference = currentPageReference;
           const { attributes } = currentPageReference;
           console.log('getStateParameters222...');
           // Check if on a record page and the object is Account
           if (
               attributes &&
               attributes.objectApiName === 'Account' &&
               attributes.recordId
           ) {
               this.isAccountPage = true;
               this.cardSize =  this.isAccountPage ? 6 : 12;
               //this.recordId = attributes.recordId;
               console.log('recordId...' + this.recordId);
               console.log('isAccountPage...' + this.isAccountPage );
           }
       }
       if (currentPageReference && currentPageReference.state) {
           console.log('storeCockpit Load...'+currentPageReference.state.c__storecockpit);
           console.log('selectedVisitId Load...'+currentPageReference.state.c__selectedVisitId || null);
           this.selectedVisitId = currentPageReference.state.c__selectedVisitId || null;
           this.storeCockpit = currentPageReference.state.c__storecockpit;
           this.selectedCustomerName = currentPageReference.state.c__customername;
           this.selectedAccountValue = currentPageReference.state.c__selectedaccount;
           this.isVisitStarted = currentPageReference.state.c__visitdone || false;
           this.selectedAccountType = currentPageReference.state.c__selectedaccounttype;
           console.log('visitList this.isVisitStarted111...'+this.isVisitStarted);
       }
   }


   @wire(getMyVisits, { selectedDate: '$selectedCalendarDate' })
   getVisitData(result) {
       console.log('selectedCalendarDate...' + this.selectedCalendarDate);
       this.visitSpinner = true;
       this.wireRefreshVisitsData = result;
       const { error, data } = result;
       if (data) {
           const filteredResult = this.recordId
               ? data.filter(record => record.AccountId === this.recordId)
               : data;
               console.log('filteredResult...' + JSON.stringify(filteredResult));


               this.visitsData = filteredResult;


           const safeDate = (value) => value ? new Date(value).getTime() : 0;


        
           const plannedInProgress = filteredResult
               .filter(v => v.Status === 'Planned' && v.TPB_InProgress__c === true)
               .sort((a, b) => safeDate(a.PlannedVisitStartTime) - safeDate(b.PlannedVisitStartTime));


           const plannedNotInProgress = filteredResult
               .filter(v => v.Status === 'Planned' && v.TPB_InProgress__c === false)
               .sort((a, b) => safeDate(a.PlannedVisitStartTime) - safeDate(b.PlannedVisitStartTime));


           const completed = filteredResult
               .filter(v => v.Status === 'Completed')
               .sort((a, b) => safeDate(b.ActualVisitEndTime) - safeDate(a.ActualVisitEndTime));


           const sortedVisits = [...plannedInProgress, ...plannedNotInProgress, ...completed];


           console.log('Sorted Visits:', sortedVisits);




           this.visitSpinner = false;


           console.log('VisitsData...' + JSON.stringify(sortedVisits));
           this.visitsFinalData = sortedVisits.map((item) => {
               let statusClass = '';
               let circleClass = '';


               if (item.Status === 'Completed') {
                   statusClass = 'completed';
                   circleClass = 'circle-completed';
               } else if (item.Status === 'Planned' && item.TPB_InProgress__c) {
                   statusClass = 'in-progress';
                   circleClass = 'circle-inprogress';
               } else {
                   statusClass = 'planned';
                   circleClass = 'circle-default';
               }
               return {
                   circleClass,
                   computedClass: `row slds-grid slds-grid_vertical-align-center ${statusClass}`,
                   name: item.Account_Name__c,
                   id: item.Id,
                   address: `${item.cgcloud__Account_Street__c}, ${item.cgcloud__Account_City__c}`,
                   accountId: item.AccountId,
                   accountType: item.TPB_VisitType__c
               };
           });
           this.isVisitsFinalData = this.visitsFinalData.length > 0;
           this.totalVisits = this.visitsFinalData.length;
           this.dispatchEvent(new CustomEvent('totalvisits', {
               detail: {totalvisits:this.totalVisits, spinner: false}
           }));
       } else if (error) {
           console.error(error);
       }
    }
  
   async loadCustomerAccounts() { console.log('accountId...'+this.recordId);
       // Pass null or '' if recordId empty — your Apex logic should handle that
       await getCustomerAccounts({ accountId: this.recordId ? this.recordId : null })
           .then(data => {
               console.log('getCustomerAccounts data...' + JSON.stringify(data));
               if (data.length <= 0) {
                   this.isCustomerAccountsExist = false;
               }
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
 
      handleChangeVisit(event) {
       if (event.target.name == 'Visit Date') {
           this.selectedVisitDate = event.target.value;
       } else if (event.target.name == 'Visit Time') {
           this.selectedVisitTime = event.target.value;
       } else if (event.target.name == 'Visit Template') {
           this.selectedVisitTemplate = event.detail.value;
       } else if (event.target.name == 'Visit Type') {
           this.selectedVisitType = event.detail.value;
       }
      }


     handleChangeCustomer(event) {
       this.selectedCustomerValue = event.detail.payload.values;
       console.log('selectedCustomerValue...' + this.selectedCustomerValue);
     }
  
     handleChangeCustomerTask(event) {
       this.selectedCustomerTaskValue = event.detail.payload.values;
       console.log('selectedCustomerTaskValue...' + this.selectedCustomerTaskValue);
     }
  
   handleChangeTask(event) {
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
       } else if (selectedDate >= today){
           this.selectedCustomerTaskDate = event.target.value;
       }
       } else if (event.target.name == 'description') {
           this.description = event.target.value;
       } else if (event.target.name == 'Customer Type') {
            this.selectedCustomerType = event.detail.value;
           console.log('selectedCustomerType...' + this.selectedCustomerType);
       }
         this.isTaskDisabled = false;
      }
   addnewVisit() {


       this.selectedVisitTemplate = this.setDefaultVisitTemplate;
       this.selectedVisitType = this.setDefaultVisitType;
       // Set default date to today
       this.selectedVisitDate = new Date().toISOString().split('T')[0];


       // Set default time to current time + 30 minutes (HH:MM)
       const now = new Date();
       now.setMinutes(now.getMinutes() + 30);


       const hours = String(now.getHours()).padStart(2, '0');
       const minutes = String(now.getMinutes()).padStart(2, '0');


       this.selectedVisitTime = `${hours}:${minutes}`;


       this.isModalOpen = true;
   }
   handleVisitClick(e) {
       const visitId = e.currentTarget.dataset.id;
   this.isVisitStarted = this.visitsData?.some(item =>
           item.Id === visitId && item.TPB_InProgress__c === true
       );
       // show toast msg
       if (this.isVisitStarted) {
           this.dispatchEvent(
               new ShowToastEvent({
                   title: 'Visit In Progress',
                   message: 'This visit is already in progress.',
                   variant: 'warning',
                   mode: 'dismissable'
               })
           );
       }
       console.log('this.isVisitStarted UserCockpit'+this.isVisitStarted);
       this.selectedAccountValue = e.currentTarget.dataset.accid;
       this.selectedAccountType = e.currentTarget.dataset.acctype;
       const matchedVisit = Array.isArray(this.visitsFinalData)
           ? this.visitsFinalData.find(item => item.accountId === this.selectedAccountValue)
           : null;
       this.selectedCustomerName = matchedVisit ? matchedVisit.name : null;
       console.log('accName...' + (matchedVisit ? matchedVisit.name : ''));
       // console.log('this.visitsFinalData...' + JSON.stringify(this.visitsFinalData));
       console.log('this.selectedAccountValue..' + this.selectedAccountValue);
       console.log('this.selectedAccountType..' + this.selectedAccountType);
       this.selectedVisitId = visitId;
       console.log('Visit ID:', visitId);
       if(!this.isAccountPage){
           if(this.selectedAccountType == 'Retailer'){
            
                   console.log('this.storeCockpit;;'+this.storeCockpit);
               this[NavigationMixin.Navigate]({
                   type: 'standard__recordPage',
                   attributes: {
                       recordId: this.selectedAccountValue, // Replace with dynamic Account Id
                       objectApiName: 'Account',
                       actionName: 'view'
                   },
                   state: {
                       c__selectedVisitId: this.selectedVisitId,
                       c__visitdone: this.isVisitStarted,
                       c__selectedaccount: this.selectedAccountValue,
                       c__customername: this.selectedCustomerName,
                       c__storecockpit: true,
                       c__selectedaccounttype: this.selectedAccountType
                   }
               });
              
           }else{
                this[NavigationMixin.Navigate]({
                   type: 'standard__recordPage',
                   attributes: {
                       recordId: visitId, // Replace with dynamic Account Id
                       objectApiName: 'Visit',
                       actionName: 'view'
                   }
               });
              
           }


          
       }else{
           this.storeCockpit = true;
           console.log('this.isVisitStarted444...' + this.isVisitStarted);
       }
   }
   async handleNavigation() {
       console.log('Navigation11');
        if(this.isAccountPage){
           this[NavigationMixin.Navigate]({
               type: 'standard__recordPage',
               attributes: {
                   recordId: this.selectedAccountValue, // Replace with dynamic Account Id
                   objectApiName: 'Account',
                   actionName: 'view'
               }
           });
       }else{
           this.storeCockpit = false;
       }
       //this.getVisitData(this.selectedCalendarDate);
       await refreshApex(this.wireRefreshVisitsData);
       // this.visitSpinner = true;
   }

   hasValue(value) {
       if (Array.isArray(value)) {
           return value.length > 0;
       }
       return value !== null && value !== undefined && String(value).trim() !== '';
   }

   getSelectedVisitCustomerValue() {
       const customerLookup = this.template.querySelector('[data-id="visitCustomerLookup"]');
       const lookupValue = customerLookup?.getSelectedValue ? customerLookup.getSelectedValue() : '';
       return this.hasValue(this.selectedCustomerValue) ? this.selectedCustomerValue : lookupValue;
   }
  
   async CreateVisit() {
           const selectedCustomerValue = this.getSelectedVisitCustomerValue();
           console.log('time..' + this.selectedVisitTime);
           console.log('time..' + this.selectedVisitDate);
           console.log('tttt..' +  selectedCustomerValue, this.selectedVisitTemplate,  this.selectedVisitType,  this.selectedVisitDate, this.selectedVisitTime );
           if (this.hasValue(this.selectedVisitTemplate) && this.hasValue(this.selectedVisitType) && this.hasValue(this.selectedVisitDate) && this.hasValue(this.selectedVisitTime) && this.hasValue(selectedCustomerValue)) {
               this.selectedCustomerValue = selectedCustomerValue;
               this.isDisabled = true;
               this.isLoading = true;
               await createVisit({ customerId: selectedCustomerValue, visitTemplateId: this.selectedVisitTemplate, visitType: this.selectedVisitType, visitDateStr: this.selectedVisitDate, visitTimeStr: this.selectedVisitTime })
                   .then(async (response) => {
                       // this.visitSpinner = true;
  
                       console.log('response...' + JSON.stringify(response));
                       this.dispatchEvent(new ShowToastEvent({
                           title: "Success",
                           message: "Visit Created Successfully",
                           variant: "Success"
                       }));
                       this.isModalOpen = false;
                       this.isLoading = false;
                       this.selectedVisitTemplate = '';
                       this.selectedVisitType = '';
                       this.selectedVisitDate = '';
                       this.selectedVisitTime = '';
                       this.selectedCustomerValue = '';
                       //this.getVisitData(this.selectedCalendarDate);
                       await refreshApex(this.wireRefreshVisitsData);
                    //    if (this.wireRefreshCustomerTasks) {
                    //        await refreshApex(this.wireRefreshCustomerTasks);
                    //    }
                       this.dispatchEvent(new CustomEvent('visitcreated'));
                       this.isDisabled = false;

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




    createTask() {
           console.log('time..' + this.selectedCustomerTaskDate);
           console.log('time..' + this.selectedCustomerTaskDate);
           if (this.selectedCustomerType &&  this.selectedCustomerTaskDate && this.selectedCustomerTaskValue && this.description) {
               this.isTaskDisabled = true;
               this.isTaskLoading = true;
               createCustomerTask({ customerId: this.selectedCustomerTaskValue, customerTaskTemplateId:this.selectedCustomerType, dueDateStr: this.selectedCustomerTaskDate, descriptionStr: this.description })
                   .then((response) => {
                       // this.visitSpinner = true;
  
                       console.log('response...' + JSON.stringify(response));
                       this.dispatchEvent(new ShowToastEvent({
                           title: "Success",
                           message: "Task Created Successfully",
                           variant: "Success"
                       }));
                       this.isCustomerTaskModalOpen = false;
                       this.isTaskLoading = false;
                       this.description = '';
                       this.isTaskDisabled = false;
                       this.selectedCustomerTaskDate = '';
                       this.selectedCustomerType = '';
                       this.selectedCustomerTaskValue = '';
                       refreshApex(this.wireRefreshCustomerTasks);
                   })
                   .catch((error) => {
                       this.isTaskLoading = false;
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
      
   handleTaskClick(event){ console.log('here in CT click');
       const customerTaskId = event.currentTarget.dataset.id;
       console.log('customerTaskId...'+customerTaskId);
       this[NavigationMixin.Navigate]({
               type: 'standard__recordPage',
               attributes: {
                   recordId: customerTaskId, // Replace with dynamic Account Id
                   objectApiName: 'cgcloud__Account_Task__c',
                   actionName: 'view'
               }
           });
   }
  
   stopPropagation(event) {
       event.stopPropagation();
   }
   toggleMenu(event) {
       event.stopPropagation();
       const visitId = event.currentTarget.dataset.id;
       if (!Array.isArray(this.visitsFinalData)) {
           return;
       }


       this.visitsFinalData = this.visitsFinalData.map(v => {
           return {
               ...v,
               showMenu: v.id === visitId ? !v.showMenu : false
           };
       });
   }
   async handleCancelClick(event) {
       event.stopPropagation();
       const visitId = event.currentTarget.dataset.id;
       await this.handleCancelVisit(visitId);
   }
   async handleCancelVisit(visitId) {


	       this.isLoading = true;
	       //console.log('Cancel visit clicked:', visitId);
	       await cancelVisit({ visitId })
	           .then(async () => {
	               console.log('Visit abandoned successfully');
	               await refreshApex(this.wireRefreshVisitsData);
	               this.dispatchEvent(new CustomEvent('visitcancelled'));

	               this.isLoading = false;
	           }).catch(error => {
	               console.error('cancelVisit error... ', JSON.stringify(error));
	               this.isLoading = false;
	           })
   }
}