import { api, LightningElement, track, wire } from 'lwc';
import getPromotions from '@salesforce/apex/TPB_OnlineAppController.getPromotions';
export default class CgCloudStorePromotionsList extends LightningElement {
    @api selectedAccountId;
    @track customerPromotionList = [];
    @track isPromotionsExists = false;

    @wire(getPromotions, { accountId: '$selectedAccountId' })
    wiregetPromotions(result) {
        this.refreshGetPromotions = result;
        const { data, error } = result;
        if (data) {
            console.log('getPromotions data....' + JSON.stringify(data));

            this.customerPromotionList = data;
            //this.updatePromotionOptions(data);
            if(this.customerPromotionList.length > 0){
                this.isPromotionsExists = true;
            }


        } else if (error) {
            console.error('getPromotions error: ', error);
        }
    }
}