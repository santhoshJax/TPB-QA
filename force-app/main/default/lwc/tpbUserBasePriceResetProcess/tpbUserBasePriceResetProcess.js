/**************************************************************************************************   
LWC Name             :  TpbUserBasePriceResetProcess
Version              :  1.0                                                                          
Created Date         :  August 01, 2024                                                               
Function             :  This cmp used to mass update user base pricing and Inventory                                                       
Modification Log     :        
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* ------------------------------------------------------------------------------------------------- 
*                           01/08/2024             Initial Release
*/
import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors }   from 'c/tpbUtils';

import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';

import fetchUserInventories from '@salesforce/apex/TpbUserBasePriceResetProcessCtrl.fetchUserInventories';
import executeBatch         from '@salesforce/apex/TpbUserBasePriceResetProcessCtrl.executeBatch';

const ALLOWED_PROFILE_NAMES    = ["System Administrator"];
const INVENTORY_DOES_NOT_EXIST = "There is no Inventory for the selected user and the Price Group, so there is no need to update the base price.";
export default class TpbUserBasePriceResetProcess extends LightningElement {
    @track isLoadingSpinner = false;
    @track userRecordData   = {};
    @track tableData        = null;
    @track tableColumn      = [];
    acceptedFormats         = ".csv";
    acceptedCSVHeaders      = ["UserId", "TourState", "PriceGroupId", "NewBasePrice", "Reason"];
    currentProcessingStage  = "Loading...";
    disabledProcessButton   = false;
    lstSaveCSVData          = [];

    get isInValidUser(){
        return !ALLOWED_PROFILE_NAMES.includes(this.userRecordData?.ProfileName);
    }

    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME] })
    wireUserRecord({ error, data }) {
        if(data){
            this.handleUserRecordData(data);
        }else if(error){
            this.handleError(error);
        }
    }

    connectedCallback(){
        this.tableColumn = [
            { label: 'User Id', fieldName: 'UserId', type: 'string', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
            { label: 'Tour State', fieldName: 'TourState', type: 'string', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
            { label: 'Price Group', fieldName: 'PriceGroupId', type: 'string', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
            { label: 'New Base Price', fieldName: 'NewBasePrice', type: 'string', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
            { label: 'Reason', fieldName: 'Reason', type: 'string', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
            { label: 'Validation Status', fieldName: 'validationStatus', type: 'string', hideDefaultActions: true, wrapText : true, cellAttributes: { alignment: 'left' } }
        ];
    }

    handleUserRecordData(data){
        this.userRecordData = {
            Id : data?.Id,
            ProfileName : data?.fields?.Profile?.value?.fields?.Name?.value,
        };

        //validating current User Profile against allowed profiles
        if(this.isInValidUser){
            this.showToast("Error","Only system administrators can perform this operation!");
        }
    }

    handleUploadFile(event) {
        if (event.detail.files && event.detail.files.length) {
            const csvFile = event.detail.files[0];
            this.readFile(csvFile);
            this.isLoadingSpinner = false;
        }
    }

    handleOnProcess(event){
        let lstSaveCSVData = this.lstSaveCSVData;
        if(!lstSaveCSVData || lstSaveCSVData.length == 0){
            this.showToast("Error", "No valid data to process, as all uploaded records are invalid !!");
            return;
        }

        this.disabledProcessButton = true;
        this.isLoadingSpinner = true;
        this.currentProcessingStage = "Submitting...";

        executeBatch({lstCSVData : lstSaveCSVData})
        .then(result =>{
            this.tableData = null;
            this.showToast("Success", "Successfuly submitted valid records for processing...")
        })
        .catch(error =>{
            this.handleError(error);
        })
        .finally(()=>{
           this.isLoadingSpinner = false; 
           this.disabledProcessButton = false;
        });
    }

    readFile(csvFile){
        this.currentProcessingStage = "Reading...";
        this.isLoadingSpinner = true;
        const fileReader = new FileReader();
        fileReader.onloadend = () => {
            const fileBody = fileReader.result;

            this.validateUploadedFile(fileBody);
        };
        fileReader.readAsText(csvFile);
    }

    async validateUploadedFile(fileBody) {
        try {
            this.currentProcessingStage = "Validating...";
            this.isLoadingSpinner = true;
    
            // Split file into lines and get the header
            const lstCSVData = fileBody.split('\n');
            if (lstCSVData.length === 0 || !lstCSVData[0].trim()) {
                this.showToast("Error", "CSV file is empty or has no headers.");
                return;
            }
    
            const csvHeader = lstCSVData[0].trim();
            if (!this.validateFileHeader(csvHeader)) {
                return;
            }
    
            // Extract user IDs and states, skipping the header line
            const [lstUserId, lstStates, lstPriceGorupId] = this.extractUserIdsStatesAndPriceGorupId(lstCSVData.slice(1));
    
            // Fetch user inventories based on user IDs and states
            const userVsInventoryMap = await fetchUserInventories({ lstUserId, lstStates, lstPriceGorupId });
    
            // Convert Apex map to JavaScript map for easier handling
            const userVsInventoryJSMap = new Map(
                Object.entries(userVsInventoryMap).map(([key, value]) => [key, value])
            );
    
            // Process CSV data and build the table data and inventory update list
            const tableData  = this.processCSVData(lstCSVData.slice(1), userVsInventoryJSMap);
    
            this.tableData = tableData;
        } catch (error) {
            console.error('Error in validateUploadedFile:', error);
            this.showToast("Error", "An error occurred during file validation.");
        } finally {
            this.isLoadingSpinner = false;
        }
    }
    
    extractUserIdsStatesAndPriceGorupId(lstCSVData) {
        const lstUserId = [];
        const lstStates = [];
        const lstPriceGorupId = [];

        lstCSVData.forEach(csvData => {
            if (csvData.trim()) {
                const lstData = csvData.split(',');
                lstUserId.push(lstData[0]);
                lstStates.push(lstData[1]);
                lstPriceGorupId.push( lstData[2] );
            }
        });
    
        return [lstUserId, lstStates, lstPriceGorupId];
    }
    
    processCSVData(lstCSVData, userVsInventoryJSMap) {
        this.currentProcessingStage = "Processing...";
        const tableData = [];
        let lstSaveCSVData = [];

        lstCSVData.forEach(csvData => {
            if (csvData.trim()) {
                const lstData = csvData.split(',');
    
                const userIdStateKey = `${lstData[0]}~${lstData[1]}~${lstData[2]}`;
                const isInventoryExist = userVsInventoryJSMap.has(userIdStateKey);
                tableData.push({
                    UserId           : lstData[0],
                    TourState        : lstData[1],
                    PriceGroupId     : lstData[2],
                    NewBasePrice     : lstData[3],
                    Reason           : lstData[4],
                    validationStatus : isInventoryExist ? "Inventory Exist" : INVENTORY_DOES_NOT_EXIST
                });

                if(isInventoryExist){
                    const inventories = userVsInventoryJSMap.get(userIdStateKey);
                    inventories.forEach(inventory=>{
                        lstSaveCSVData.push({
                            UserId           : lstData[0],
                            TourState        : lstData[1],
                            PriceGroupId     : lstData[2],
                            NewBasePrice     : lstData[3],
                            Reason           : lstData[4],
                            validationStatus : "Inventory Exist",
                            InventoryId      : inventory.Id
                        })
                    });
                }
            }
        });
    
        this.lstSaveCSVData = lstSaveCSVData;
        return tableData;
    }        

    validateFileHeader(csvHeader){
        let isValidHeader = true;
        let lstCSVHeader = csvHeader.split(',').map(header => header.trim().toLowerCase());
        let missingHeader = [];
        this.acceptedCSVHeaders.forEach(header => {
            if (!lstCSVHeader.includes(header.toLowerCase())) {
                missingHeader.push(header);
            }
        });
    
        if (missingHeader.length > 0) {
            this.showToast("Error", "Mismatch in CSV file header. Missing headers: " + missingHeader.join(', '));
            isValidHeader = false;
        }
        return isValidHeader;
    }

    handleError(error) {
        this.showToast("Error", reduceErrors(error));
    }

    showToast(toastType, toastMessage) {
        const event = new ShowToastEvent({
            title: toastType + ' !',
            message: toastMessage,
            variant : toastType.toLowerCase()
        });
        this.dispatchEvent(event);
    }
}