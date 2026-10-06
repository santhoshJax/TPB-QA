public class TPB_OnlineAppController {

    public String orderId { get; set; }
    public String logoUrl { get; set; }
    //public String orderId = 'a51bc00000EIOakAAH';
    public TPB_OnlineAppController.PDFWrapperVF pdf { get; set; }
    public TPB_OnlineAppController() {
        orderId = ApexPages.currentPage().getParameters().get('orderId');
        pdf = TPB_OnlineAppController.getPDFValuesVF(orderId);
        //logoUrl = URL.getBaseUrl() + '/resource/invoiceLogo';
        logoUrl = URL.getOrgDomainUrl().toExternalForm() + '/resource/invoiceLogo';
    }
    /* Order is created when the user clicks on Create Order button */
    
    @AuraEnabled
    public static void generateAndAttachInvoice(String orderId) {
        try {
            generateInvoiceContentDocument(orderId);
        } catch (Exception e) {
            System.debug('Error generating or attaching PDF: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
    }

    @RemoteAction
    public static String generateInvoiceAndGetDocumentId(String orderId) {
        try {
            return (String) generateInvoiceContentDocument(orderId);
        } catch (Exception e) {
            System.debug('Error generating PDF for download: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
    }

    public PageReference downloadInvoice() {
        String currentOrderId = orderId;
        if (String.isBlank(currentOrderId)) {
            currentOrderId = ApexPages.currentPage().getParameters().get('orderId');
        }
        if (String.isBlank(currentOrderId)) {
            throw new AuraHandledException('Order Id is required');
        }
        PageReference pr = Page.CgCloudInvoicePdfGenerator;
        pr.getParameters().put('orderId', currentOrderId);
        pr.setRedirect(true);
        return pr;
    }

    private static Id generateInvoiceContentDocument(String orderId) {
        if (String.isBlank(orderId)) {
            throw new AuraHandledException('Order Id is required');
        }

        PageReference pdfPage = Page.CgCloudInvoicePdfGenerator;
        pdfPage.getParameters().put('orderId', orderId);
        String fileName = 'Invoice_' + orderId + '.pdf';

        Blob fileBody;
        if (Test.isRunningTest()) {
            fileBody = Blob.valueOf('Unit.Test');
        } else {
            fileBody = pdfPage.getContentAsPDF();
        }

        Id existingDocId;
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :orderId
            AND ContentDocument.Title = :fileName
            LIMIT 1
        ];
        if (!existingLinks.isEmpty()) {
            existingDocId = existingLinks[0].ContentDocumentId;
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = fileBody;
        cv.cgcloud__Usage__c = 'Printout';
        if (existingDocId != null) {
            cv.ContentDocumentId = existingDocId;
        }
        insert cv;

        Id contentDocumentId = existingDocId;
        if (contentDocumentId == null) {
            contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ].ContentDocumentId;

            ContentDocumentLink orderLink = new ContentDocumentLink();
            orderLink.ContentDocumentId = contentDocumentId;
            orderLink.LinkedEntityId = orderId;
            orderLink.ShareType = 'I';
            orderLink.Visibility = 'AllUsers';
            insert orderLink;
        }

        Id accountId = [
            SELECT cgcloud__Order_Account__c
            FROM cgcloud__Order__c
            WHERE Id = :orderId
        ].cgcloud__Order_Account__c;
        if (accountId != null) {
            List<ContentDocumentLink> acctLinks = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :contentDocumentId
                AND LinkedEntityId = :accountId
                LIMIT 1
            ];
            if (acctLinks.isEmpty()) {
                ContentDocumentLink accountLink = new ContentDocumentLink();
                accountLink.ContentDocumentId = contentDocumentId;
                accountLink.LinkedEntityId = accountId;
                accountLink.ShareType = 'I';
                accountLink.Visibility = 'AllUsers';
                insert accountLink;
            }
        }

        return contentDocumentId;
    }
    @AuraEnabled
    public static PDFWrapper getPDFValues(String orderId){
        try {
            cgcloud__Order__c order = [SELECT ID, cgcloud__Responsible__r.Name, cgcloud__Gross_Total_Value__c, 
                                                cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, cgcloud__Bill_Recipient_Account__r.ShippingState,
                                                cgcloud__Delivery_Recipient__r.Name, cgcloud__Delivery_Recipient__r.ShippingStreet, cgcloud__Delivery_Recipient__r.ShippingCity,
                                                cgcloud__Delivery_Recipient__r.ShippingState, cgcloud__Delivery_Recipient__r.ShippingCountry,
                                                cgcloud__Delivery_Recipient__r.Phone, cgcloud__Delivery_Recipient__r.State_Tobacco_Number__c, cgcloud__Delivery_Recipient__r.FEIN__c,
                                                cgcloud__Delivery_Recipient__r.State_Tax_Number__c,
                                                cgcloud__Delivery_Recipient__r.TPB_TSM_Territory__c,
                                                cgcloud__Order_Id__c
                                                FROM cgcloud__Order__c WHERE ID=: orderId];
            // Account acc =  [SELECT ID, Name, ShippingStreet, ShippingCity, ShippingState, ShippingCountry FROM Account WHERE ShippingState != null LIMIT 1];
            Organization org = [SELECT Id, Name, Street, City, State, Country FROM Organization];
            List<Invoice_Term__c> terms = [SELECT Id, NTC_Tax__c, State_Code__c, TPB_State_Use_Tax__c, Terms__c FROM Invoice_Term__c WHERE State_Code__c =: order.cgcloud__Delivery_Recipient__r.ShippingState]; 
            PDFWrapper pdfValues = new PDFWrapper();
            pdfValues.division = org.Name;
            pdfValues.address = org.Street + ', '+org.City + ', '+ org.State + ', '+ org.Country;
            pdfValues.ownerName = order.cgcloud__Responsible__r.Name;
            pdfValues.invoiceDate = order.cgcloud__Order_Date__c;
            pdfValues.deliveryDate = order.cgcloud__Delivery_Date__c;
            pdfValues.ntcTaxID = '61-1133037';
            pdfValues.orderNumber = order.cgcloud__Order_Id__c;
            if(terms.size() > 0){
                pdfValues.otherLicenseNum = terms[0].NTC_Tax__c;
                pdfValues.terms = terms[0].Terms__c;
                pdfValues.stateTax = terms[0].TPB_State_Use_Tax__c;
            }
            
            pdfValues.invoiceTotal = order.cgcloud__Gross_Total_Value__c;
            List<cgcloud__Order_Item__c> orderItems = [SELECT Id, TPB_SKU__c, cgcloud__Order_Item_Template__r.Name, cgcloud__UoM__c, cgcloud__Product__r.Name, cgcloud__Quantity__c, 
                                                    cgcloud__Value__c, cgcloud__Discount__c, cgcloud__Promotion__r.cgcloud__Slogan__c, Prebook_Wholesaler__c, Prebook_Wholesaler__r.Name
                                                    FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = : orderId];
            List<cgcloud__Order_Item__c> orderItemsCashSale = new List<cgcloud__Order_Item__c>();
            List<cgcloud__Order_Item__c> orderItemsReturn = new List<cgcloud__Order_Item__c>();
            List<cgcloud__Order_Item__c> orderItemsPrebook = new List<cgcloud__Order_Item__c>();     
            Double totalQty = 0;
            for(cgcloud__Order_Item__c orderItem : orderItems){
                if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Cash Sale' || orderItem.cgcloud__Order_Item_Template__r.Name == 'Free Item'){
                    orderItemsCashSale.add(orderItem);
                }else if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Return'){
                    orderItemsReturn.add(orderItem);
                } else if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Prebook'){
                    orderItemsPrebook.add(orderItem);
                }
                totalQty = totalQty + orderItem.cgcloud__Quantity__c;
            }         
                                    
            pdfValues.orderItemsCashSale = orderItemsCashSale;
            pdfValues.orderItemsReturn = orderItemsReturn;
            pdfValues.orderItemsPrebook = orderItemsPrebook;
                                                    
            pdfValues.qty = totalQty;
            pdfValues.storeName = order.cgcloud__Delivery_Recipient__r.Name;
            pdfValues.storeAddress = order.cgcloud__Delivery_Recipient__r.ShippingStreet + ', '+order.cgcloud__Delivery_Recipient__r.ShippingCity + ', '+ order.cgcloud__Delivery_Recipient__r.ShippingState + ', '+ order.cgcloud__Delivery_Recipient__r.ShippingCountry;
            pdfValues.storePhone = order.cgcloud__Delivery_Recipient__r.Phone;
            pdfValues.storeStateTobaccoNum = order.cgcloud__Delivery_Recipient__r.State_Tobacco_Number__c;
            pdfValues.storeStateTaxNum = order.cgcloud__Delivery_Recipient__r.State_Tax_Number__c;
            pdfValues.storefein = order.cgcloud__Delivery_Recipient__r.FEIN__c;
            pdfValues.serviceTerritory = order.cgcloud__Delivery_Recipient__r.TPB_TSM_Territory__c;

            return pdfValues;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static PDFWrapperVF getPDFValuesVF(String orderId){
        try {
            cgcloud__Order__c order = [SELECT ID, cgcloud__Responsible__r.Name, cgcloud__Gross_Total_Value__c, 
                                                cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, cgcloud__Bill_Recipient_Account__r.ShippingState,
                                                cgcloud__Delivery_Recipient__r.Name, cgcloud__Delivery_Recipient__r.ShippingStreet, cgcloud__Delivery_Recipient__r.ShippingCity,
                                                cgcloud__Delivery_Recipient__r.ShippingState, cgcloud__Delivery_Recipient__r.ShippingCountry,
                                                cgcloud__Delivery_Recipient__r.Phone, cgcloud__Delivery_Recipient__r.State_Tobacco_Number__c, cgcloud__Delivery_Recipient__r.FEIN__c,
                                                cgcloud__Delivery_Recipient__r.State_Tax_Number__c,
                                                cgcloud__Delivery_Recipient__r.TPB_TSM_Territory__c,
                                                cgcloud__Order_Id__c
                                                FROM cgcloud__Order__c WHERE ID=: orderId];
            // Account acc =  [SELECT ID, Name, ShippingStreet, ShippingCity, ShippingState, ShippingCountry FROM Account WHERE ShippingState != null LIMIT 1];
            Organization org = [SELECT Id, Name, Street, City, State, Country FROM Organization];
            String deliveryState = order.cgcloud__Delivery_Recipient__r.ShippingState;
            String billingState = order.cgcloud__Bill_Recipient_Account__r.ShippingState;

            List<Invoice_Term__c> terms = new List<Invoice_Term__c>();
            if (String.isNotBlank(deliveryState)) {
                terms = [
                    SELECT Id, NTC_Tax__c, State_Code__c, TPB_State_Use_Tax__c, Terms__c
                    FROM Invoice_Term__c
                    WHERE State_Code__c = :deliveryState
                ];
            }
            if (terms.isEmpty() && String.isNotBlank(billingState)) {
                terms = [
                    SELECT Id, NTC_Tax__c, State_Code__c, TPB_State_Use_Tax__c, Terms__c
                    FROM Invoice_Term__c
                    WHERE State_Code__c = :billingState
                ];
            }

            system.debug('account state'+ order.cgcloud__Bill_Recipient_Account__r.ShippingState);

            List<TPB_Distributor_License__c> distributorLicenceInfoList = [
                SELECT Id, TPB_Distributor_License__c
                FROM TPB_Distributor_License__c
                WHERE TPB_State__c = :order.cgcloud__Bill_Recipient_Account__r.ShippingState
                AND TPB_User__c = :UserInfo.getUserId()
                LIMIT 1
            ];

            String distributorLicenceNumberVal = null;
            if (!distributorLicenceInfoList.isEmpty()) {
                distributorLicenceNumberVal = distributorLicenceInfoList[0].TPB_Distributor_License__c;
            }
            
            PDFWrapperVF pdfValues = new PDFWrapperVF();
            pdfValues.division = org.Name;
            pdfValues.address = org.Street + ', '+org.City + ', '+ org.State + ', '+ org.Country;
            pdfValues.ownerName = order.cgcloud__Responsible__r.Name;
            pdfValues.invoiceDate = order.cgcloud__Order_Date__c;
            pdfValues.deliveryDate = order.cgcloud__Delivery_Date__c;
            pdfValues.ntcTaxID = '61-1133037';
            pdfValues.orderNumber = order.cgcloud__Order_Id__c;
            if(terms.size() > 0){
                pdfValues.otherLicenseNum = terms[0].NTC_Tax__c;
                pdfValues.terms = terms[0].Terms__c;
                pdfValues.stateTax = terms[0].TPB_State_Use_Tax__c;
            }

            pdfValues.distributorLicenceNumber = distributorLicenceNumberVal;

            pdfValues.invoiceTotal = order.cgcloud__Gross_Total_Value__c;
            List<cgcloud__Order_Item__c> orderItems = [SELECT Id, TPB_SKU__c, cgcloud__Order_Item_Template__r.Name, cgcloud__UoM__c, cgcloud__Product__r.Name, cgcloud__Quantity__c, Reimbursable_Amt__c,FInal_Unit_Price__c,
                                                    cgcloud__Value__c, cgcloud__Discount__c, cgcloud__Promotion__r.cgcloud__Slogan__c, Prebook_Wholesaler__c, Prebook_Wholesaler__r.Name
                                                    FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = : orderId];
            List<cgcloud__Order_Item__c> orderItemsCashSale = new List<cgcloud__Order_Item__c>();
            List<cgcloud__Order_Item__c> orderItemsReturn = new List<cgcloud__Order_Item__c>();
            List<cgcloud__Order_Item__c> orderItemsPrebook = new List<cgcloud__Order_Item__c>();     
            Double totalQty = 0;
            Decimal cashSalesSubtotal = 0;
            Decimal returnSubtotal = 0;
            Decimal cashSalesDiscountTotal = 0;
            Decimal cashSalesQtyTotal = 0;
            Decimal returnQtyTotal = 0;
            Decimal prebookQtyTotal = 0;
            for(cgcloud__Order_Item__c orderItem : orderItems){
                if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Cash Sale' || orderItem.cgcloud__Order_Item_Template__r.Name == 'Free Item'){
                    orderItemsCashSale.add(orderItem);
                    cashSalesSubtotal += orderItem.cgcloud__Value__c == null ? 0 : orderItem.cgcloud__Value__c;
                    cashSalesDiscountTotal += orderItem.Reimbursable_Amt__c == null ? 0 : orderItem.Reimbursable_Amt__c;
                    cashSalesQtyTotal += orderItem.cgcloud__Quantity__c == null ? 0 : orderItem.cgcloud__Quantity__c;
                }else if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Return'){
                    orderItemsReturn.add(orderItem);
                    returnSubtotal += orderItem.cgcloud__Value__c == null ? 0 : orderItem.cgcloud__Value__c;
                    returnQtyTotal += orderItem.cgcloud__Quantity__c == null ? 0 : orderItem.cgcloud__Quantity__c;
                } else if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Prebook'){
                    orderItemsPrebook.add(orderItem);
                    prebookQtyTotal += orderItem.cgcloud__Quantity__c == null ? 0 : orderItem.cgcloud__Quantity__c;
                }
                totalQty = totalQty + orderItem.cgcloud__Quantity__c;
            }         
                     
            pdfValues.orderItemsCashSale = orderItemsCashSale;
            pdfValues.orderItemsReturn = orderItemsReturn;
            pdfValues.orderItemsPrebook = orderItemsPrebook;
                                
            pdfValues.qty = totalQty;
            pdfValues.storeName = order.cgcloud__Delivery_Recipient__r.Name;
            pdfValues.storeAddress = order.cgcloud__Delivery_Recipient__r.ShippingStreet + ', '+order.cgcloud__Delivery_Recipient__r.ShippingCity + ', '+ order.cgcloud__Delivery_Recipient__r.ShippingState + ', '+ order.cgcloud__Delivery_Recipient__r.ShippingCountry;
            pdfValues.storePhone = order.cgcloud__Delivery_Recipient__r.Phone;
            pdfValues.storeStateTobaccoNum = order.cgcloud__Delivery_Recipient__r.State_Tobacco_Number__c;
            pdfValues.storeStateTaxNum = order.cgcloud__Delivery_Recipient__r.State_Tax_Number__c;
            pdfValues.storefein = order.cgcloud__Delivery_Recipient__r.FEIN__c;
            pdfValues.serviceTerritory = order.cgcloud__Delivery_Recipient__r.TPB_TSM_Territory__c;
            pdfValues.cashSalesSubtotal = cashSalesSubtotal;
            pdfValues.returnSubtotal = returnSubtotal;
            pdfValues.cashSalesDiscountTotal = cashSalesDiscountTotal;
            pdfValues.cashSalesQtyTotal = cashSalesQtyTotal;
            pdfValues.returnQtyTotal = returnQtyTotal;
            pdfValues.prebookQtyTotal = prebookQtyTotal;
            return pdfValues;
        } catch (Exception e) {
            System.debug('e.getMessage()'+e.getMessage() + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createOrder(String accountId, String visitId){
        String userId = UserInfo.getUserId();
        cgcloud__Order_Template__c orderTemplate = [SELECT ID FROM cgcloud__Order_Template__c WHERE Name = 'Standard' AND cgcloud__Active__c = true LIMIT 1];
        cgcloud__CP_Calculation_Schema__c calculationSchema = [SELECT Id,name,cgcloud__Active__c FROM cgcloud__CP_Calculation_Schema__c WHERE Name = '1003' LIMIT 1];
        cgcloud__Order__c order = new cgcloud__Order__c();
        order.cgcloud__Order_Id__c = getNextSequence('ONLINE_ORDER'); //need to deploy later

        //Account_Shipping_State__c: Formula
        //Call_Store_Id__c: Formula
        order.cgcloud__Accountable__c = userId;
        order.cgcloud__Order_Account__c = accountId;
        order.cgcloud__Bill_Recipient_Account__c = accountId;
        order.cgcloud__Calculation_Schema__c = calculationSchema.Id;
        order.cgcloud__Calculation_Status__c = '0';
        order.cgcloud__Currency__c = 'USD';
        order.cgcloud__Delivery_Date__c = system.today();
        //cgcloud__Delivery_Documents_Condition__c: Formula
        order.cgcloud__Delivery_Recipient__c = accountId;
        order.cgcloud__Distribution_Relevant__c = true;
        order.cgcloud__Document_Transaction_Type__c = 'CashOrder';
        order.cgcloud__Document_Type__c = 'OrderEntry';
        order.cgcloud__Gross_Total_Value__c  = 0;//100
        order.cgcloud__Gross_Total_Value_Receipt__c = 0;//100
        order.cgcloud__Header_Discount_Percentage__c = 0;
        order.cgcloud__Initiation_Date__c = System.today();
        order.cgcloud__Inventory_Reference_1__c = userId;
        order.cgcloud__Order_Date__c = System.today();
        order.cgcloud__Order_Template__c = orderTemplate.Id;
        order.cgcloud__Paid_Amount__c = 0;//100
        order.cgcloud__Paid_Amount_Receipt__c = 0;//100
        order.cgcloud__Payer__c = accountId;
        order.cgcloud__Payment__c = 'Debit';
        order.cgcloud__Payment_Method__c = 'Cash';
        order.cgcloud__Phase__c = 'Initial';
        order.cgcloud__Pricing_Date__c = system.today();
        order.cgcloud__Print_Status__c = 'NotPrinted';
        //cgcloud__Release_Platform__c : Formula
        order.cgcloud__Responsible__c = userId;
        order.cgcloud__Selected_Rewards__c = '';//promotions
        order.cgcloud__Total_Returned_Quantity__c = 0;
        order.cgcloud__Total_Shipped_Quantity__c = 0;
        order.cgcloud__Total_Value__c = 0;//100
        order.cgcloud__Value__c = 0;//100
        order.cgcloud__Visit__c = visitId;
        //cgcloud__Workflow__c: Formula
        //TPB_Owners_Territory__c: Formula
        order.TPB_State_Use_Tax__c = '';
        order.TPB_Tax_ID__c = '';
        insert order;
        return order.id;
    }
    public static String getNextSequence(String sequenceKey) {

        if (String.isBlank(sequenceKey)) {
            throw new AuraHandledException('Sequence key is required');
        }

        // Lock the sequence row using Name
        TPB_Sequence__c seq = [
            SELECT Id,
                   Current_Value__c,
                   Prefix__c,
                   Padding_Length__c
            FROM TPB_Sequence__c
            WHERE Name = :sequenceKey
            LIMIT 1
            FOR UPDATE
        ];

        // Increment safely
        seq.Current_Value__c += 1;
        update seq;

        // Pad the number
        String paddedNumber = String.valueOf(seq.Current_Value__c).leftPad(Integer.valueOf(seq.Padding_Length__c), '0');

        // Return final Order Id
        return seq.Prefix__c + paddedNumber;
    }
    @AuraEnabled
    public static void updateOrder(String orderId){
        List<cgcloud__Order_Item__c> orderItems = [SELECT ID, cgcloud__Value__c 
                                                        FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c =: orderId];
        Decimal totalAmt = 0;
        for(cgcloud__Order_Item__c orderItem: orderItems){
            totalAmt = totalAmt + orderItem.cgcloud__Value__c;
        }
        cgcloud__Order__c order = new cgcloud__Order__c(Id = orderId, cgcloud__Total_Value__c = totalAmt, cgcloud__Value__c = totalAmt, cgcloud__Gross_Total_Value__c = totalAmt); 
        update order;
    }    
    @AuraEnabled
    public static void cancelOrder(Id orderId) {
        try {
            cgcloud__Order__c order = [
                SELECT Id, cgcloud__Phase__c 
                FROM cgcloud__Order__c 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            order.cgcloud__Phase__c = 'Cancelled'; // use exact phase API name from your org
            update order;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to cancel order: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void createOrderLineItems(String orderId, String responseBody){
        List<OrderItemWrapper> orderItemWrapperList = (List<OrderItemWrapper>)JSON.deserialize(responseBody, List<OrderItemWrapper>.class);
        List<cgcloud__Order_Item__c> lineItemsToInsert = new List<cgcloud__Order_Item__c>();
        String accountId  = [SELECT ID, cgcloud__Delivery_Recipient__c
                                   FROM cgcloud__Order__c WHERE ID = : orderId].cgcloud__Delivery_Recipient__c;
        List<Related_Account__c> relatedAccounts = [SELECT ID, Supplier_Id__c, Wholesaler__c, Wholesaler__r.Name FROM Related_Account__c WHERE Retailer__c =: accountId];
        Account tsmVan = [SELECT ID, Name FROM Account WHERE Name = 'TSM VAN' LIMIT 1];
        Map<Id, Related_Account__c> wholesalerAccountMap = new Map<Id, Related_Account__c>();
        for(Related_Account__c acc: relatedAccounts){
            wholesalerAccountMap.put(acc.Wholesaler__c, acc);
        }
        
        Map<String, Id> orderItemTemplateMap = new Map<String, Id>();
        for(cgcloud__Order_Item_Template__c itemTemp: getOrderItemTemplates()){
            Id tempId = itemTemp.Id;
            orderItemTemplateMap.put(itemTemp.Name, tempId);
        }
        system.debug('orderItemTemplateMap::'+orderItemTemplateMap);
        for(OrderItemWrapper orderItem: orderItemWrapperList){
            cgcloud__Order_Item__c lineItem = new cgcloud__Order_Item__c();
            lineItem.Id = orderItem.orderItemId;
            lineItem.cgcloud__Promoted__c = orderItem.isPromoted;
            lineItem.cgcloud__Erp_Id__c = '10';//??
            lineItem.cgcloud__History__c = true;//??
            lineItem.cgcloud__Listed__c = false;//??
            lineItem.cgcloud__Discount__c = 0;
            if(orderItem.orderItemId == '' || orderItem.orderItemId == null){
                lineItem.cgcloud__Order__c = orderId;
            }
            //lineItem.cgcloud__Order_Item_Template__c = 'a4t6T000002kFU5QAM';
            lineItem.cgcloud__Order_Item_Template__c = orderItem.typeId;
            //{"orderItemId":"a4ubc00000080inAAA","productId":"01t3i0000089AXlAAM","specialPrice":"2.00","uom":"Each","quantity":1,"basePrice":0,"suggestedQty":0,"typeId":"a4t6T000002kFU7QAM","isPromoted":false,"wholeSalerId":null,"reimbursableAmount":0,"promotionId":null}
            Double calculatedValue =  (orderItem.specialPrice != 0) ? orderItem.specialPrice * orderItem.quantity : orderItem.basePrice * orderItem.quantity;
			if(orderItem.typeId == orderItemTemplateMap.get('Cash Sale')){ //Cash Sale
            //if(orderItem.typeId == 'a4t6T000002kFU5QAM'){ //Cash Sale
                lineItem.cgcloud__Base_Price__c = orderItem.basePrice;
                lineItem.cgcloud__Base_Price_Receipt__c = orderItem.basePrice;
                lineItem.cgcloud__Special_Price__c = orderItem.specialPrice;
                lineItem.cgcloud__Special_Price_Receipt__c = orderItem.specialPrice;
                lineItem.Reimbursable_Amt__c = orderItem.reimbursableAmount;
            } else if(orderItem.typeId == orderItemTemplateMap.get('Free Item')){ //Free Item
            //else if(orderItem.typeId == 'a4t6T000002kFU6QAM'){ //Free Item
                lineItem.cgcloud__Base_Price__c = orderItem.basePrice;
                // if (calculatedValue > 0) {
                //     calculatedValue = -calculatedValue;
                // }
                //lineItem.Reimbursable_Amt__c = orderItem.basePrice;//need to check later 
                lineItem.Reimbursable_Amt__c = calculatedValue;
            } else if(orderItem.typeId == orderItemTemplateMap.get('Prebook')){ //Prebook
            //else if(orderItem.typeId == 'a4t6T000002kFU3QAM'){ //Prebook
                if(wholesalerAccountMap.containsKey(orderItem.wholeSalerId)){
                    Related_Account__c wholeSalerInfo = wholesalerAccountMap.get(orderItem.wholeSalerId);
                    lineItem.TPB_Supplier_ID__c = wholeSalerInfo.Supplier_Id__c;
                    lineItem.TPB_Wholesaler_Name__c = wholeSalerInfo.Wholesaler__r.Name+'|'+orderItem.wholeSalerId;
                } else if(orderItem.wholeSalerId == tsmVan.Id){
                    lineItem.TPB_Wholesaler_Name__c = tsmVan.Name+'|'+tsmVan.Id;
                }
            }else if(orderItem.typeId == orderItemTemplateMap.get('Return')){ //Return
            //else if(orderItem.typeId == 'a4t6T000002kFU7QAM'){ //Return
                //calculatedValue = -1 * calculatedValue;
                lineItem.cgcloud__Base_Price__c = -1 * (orderItem.basePrice);
                lineItem.cgcloud__Base_Price_Receipt__c = -1 * (orderItem.basePrice);
                lineItem.cgcloud__Special_Price__c = -1 * (orderItem.specialPrice);
                lineItem.cgcloud__Special_Price_Receipt__c = -1 * (orderItem.specialPrice);
                //lineItem.Reimbursable_Amt__c = calculatedValue;
                if (calculatedValue > 0) {
                    calculatedValue = -calculatedValue;
                }
            }else{

            }
            System.debug('calculatedValue...'+ calculatedValue);
            lineItem.cgcloud__Gross_Value_Receipt__c = calculatedValue - orderItem.reimbursableAmount; 
            lineItem.cgcloud__Out_Of_Stock__c = true;//
            lineItem.cgcloud__Pricing_Info_1__c = calculatedValue;//??
            lineItem.cgcloud__Product__c = orderItem.productId;
            //lineItem.cgcloud__Promoted__c = false;//??
            lineItem.cgcloud__Quantity__c = orderItem.quantity;
            lineItem.cgcloud__Suggested_Quantity__c = orderItem.suggestedQty;
            lineItem.cgcloud__UoM__c = orderItem.uom;//SalesUnit for Carton, ConsumerUnit for Each
            if(orderItem.typeId == orderItemTemplateMap.get('Free Item')){ //'a4t6T000002kFU6QAM'){ //Free Item
                lineItem.cgcloud__Value__c = 0;
                lineItem.cgcloud__Value_Receipt__c = 0;
            } else {
                lineItem.cgcloud__Value__c = calculatedValue - orderItem.reimbursableAmount;//??
                lineItem.cgcloud__Value_Receipt__c = calculatedValue - orderItem.reimbursableAmount;//??
            }
            lineItem.cgcloud__Promotion__c = orderItem.promotionId;
            lineItemsToInsert.add(lineItem);
        }
        upsert lineItemsToInsert;
        updateOrder(orderId);
    }
    @AuraEnabled(cacheable= true)
    public static List<ProductWrapper> getProducts(String visitId){
        Visit visit = [SELECT ID, Account.ShippingState FROM Visit WHERE ID = : visitId];
        List<PricebookEntry> priceBookEntries = [SELECT Id, UseStandardPrice, IsActive, UnitPrice, Product2Id FROM PricebookEntry where Pricebook2.name = 'Standard Price Book' AND IsActive = true];
        Set<Id> productIds = new Set<Id>();
        for(PricebookEntry entry: priceBookEntries){
            productIds.add(entry.Product2Id);
        }
        List<Product2> products = [SELECT Id, Name, cgcloud__Consumer_Goods_Product_Code__c,cgcloud__Criterion_2_Product__r.Name  
                                   FROM Product2 WHERE Id IN : productIds];
        List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,
                                                   cgcloud__Balance__c  
                                                   FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND TPB_Tour_State__c = : visit.Account.ShippingState]; 
        Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
        for(cgcloud__Inventory__c inventory: inventories){
            productInvMap.put(inventory.cgcloud__product__c, inventory);
        }

        List<cgcloud__Unit_of_Measure__c> uoms = [SELECT Id, Name, cgcloud__Product__c,cgcloud__Pieces_per_Smallest_Unit__c FROM cgcloud__Unit_of_Measure__c WHERE cgcloud__Unit_Type__c = 'SalesUnit' and cgcloud__Product__c IN : productIds ];
        Map<Id, cgcloud__Unit_of_Measure__c> productUomMap = new Map<Id, cgcloud__Unit_of_Measure__c>();
        for(cgcloud__Unit_of_Measure__c uom: uoms){
            productUomMap.put(uom.cgcloud__Product__c, uom);
        }

        List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
        for(Product2 product: products){
            ProductWrapper productWrapper = new ProductWrapper();
            productWrapper.product = product;
            productWrapper.basePrice = (productInvMap.containsKey(product.Id)) ? productInvMap.get(product.Id).TPB_AvgPrice__c : 0;
            productWrapper.stockBalance = (productInvMap.containsKey(product.Id)) ? productInvMap.get(product.Id).cgcloud__Balance__c : 0;
            productWrapper.suggestedQty = 1;
            productWrapper.maxAllocation = 1;
            productWrapper.productSubCategory = product.cgcloud__Criterion_2_Product__r.Name;
            productWrapper.cartonPieces = (productUomMap.containsKey(product.Id)) ? productUomMap.get(product.Id).cgcloud__Pieces_per_Smallest_Unit__c : 0;
            productWrapperList.add(productWrapper);
        }
        return productWrapperList;
    }

    public static void createInventoryTransaction(String orderId){

        List<cgcloud__Inventory_Transaction__c> inventoryTransactions = new List<cgcloud__Inventory_Transaction__c>();
		cgcloud__Order__c order = [SELECT ID, cgcloud__Bill_Recipient_Account__r.ShippingState FROM cgcloud__Order__c WHERE ID=: orderId];
        List<cgcloud__Order_Item__c> orderItems = [SELECT Id, cgcloud__Order_Item_Template__c, cgcloud__Order_Item_Template__r.Name, cgcloud__Order__c, cgcloud__UoM__c, cgcloud__Product__c, cgcloud__Quantity__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = : orderId];
        List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,
                                                   cgcloud__Balance__c  
                                                   FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND cgcloud__Phase__c = 'Active' AND TPB_Tour_State__c = :order.cgcloud__Bill_Recipient_Account__r.ShippingState];
        Map<String, cgcloud__Inventory__c> productInvMap = new Map<String, cgcloud__Inventory__c>();
        for(cgcloud__Inventory__c inventory: inventories){
            productInvMap.put(inventory.cgcloud__product__c, inventory);
        }
        List<cgcloud__Unit_of_Measure__c> productUOM = [SELECT id, cgcloud__Product__c,cgcloud__Product__r.Name, cgcloud__Pieces_per_Smallest_Unit__c, cgcloud__Pieces_per_parent_unit__c, cgcloud__Unit_Type__c 
                                                        FROM cgcloud__Unit_of_Measure__c];
        Map<String, cgcloud__Unit_of_Measure__c> productUOMMap = new Map<String, cgcloud__Unit_of_Measure__c>();
        for(cgcloud__Unit_of_Measure__c uom: productUOM){
            if(uom.cgcloud__Unit_Type__c == 'SalesUnit'){
                productUOMMap.put(uom.cgcloud__Product__c, uom);
            }
        }
        cgcloud__Inventory_Transaction_Template__c invenTransTemp = [SELECT Id FROM cgcloud__Inventory_Transaction_Template__c WHERE Name = 'TPB Transaction Template (Cashsale)' LIMIT 1];
        for(cgcloud__Order_Item__c orderItem: orderItems){
            if(productInvMap.containsKey(orderItem.cgcloud__Product__c)){
                cgcloud__Inventory_Transaction__c inventoryTransaction = new cgcloud__Inventory_Transaction__c();
                inventoryTransaction.cgcloud__Order_Item__c = orderItem.Id;
                inventoryTransaction.cgcloud__Inventory__c = productInvMap.containsKey(orderItem.cgcloud__Product__c) ? productInvMap.get(orderItem.cgcloud__Product__c).Id : null;
                inventoryTransaction.cgcloud__Order_Document__c = orderId;
                inventoryTransaction.cgcloud__Inventory_Transaction_Template__c = invenTransTemp.Id;
                if(orderItem.cgcloud__Order_Item_Template__r.Name == 'Return'){
                //if(orderItem.cgcloud__Order_Item_Template__c == 'a4t6T000002kFU7QAM'){
                    inventoryTransaction.cgcloud__Amount__c = (orderItem.cgcloud__UoM__c == 'Carton') 
                                                        ? orderItem.cgcloud__Quantity__c 
                                                        : orderItem.cgcloud__Quantity__c / productUOMMap.get(orderItem.cgcloud__Product__c).cgcloud__Pieces_per_Smallest_Unit__c;
                } else {
                    inventoryTransaction.cgcloud__Amount__c = (orderItem.cgcloud__UoM__c == 'Carton') 
                                                        ? orderItem.cgcloud__Quantity__c * (-1) 
                                                        : orderItem.cgcloud__Quantity__c * (-1)/ productUOMMap.get(orderItem.cgcloud__Product__c).cgcloud__Pieces_per_Smallest_Unit__c;
                }
                inventoryTransactions.add(inventoryTransaction);
            }
        }
        insert inventoryTransactions;
    }
    @AuraEnabled
    public static cgcloud__Order__c getOrder(String accountId, String visitId){
        try {
            //return [SELECT Id, cgcloud__Payer__c FROM cgcloud__Order__c WHERE cgcloud__Order_Account__c =: accountId AND cgcloud__Phase__c = 'Initial' AND cgcloud__Visit__c =: visitId LIMIT 1];
            List<cgcloud__Order__c> orders = [SELECT Id, cgcloud__Payer__c
                FROM cgcloud__Order__c
                WHERE cgcloud__Payer__c = :accountId
                AND cgcloud__Phase__c = 'Initial'
                AND cgcloud__Visit__c = :visitId
                LIMIT 1];
            // Return the first record if it exists, otherwise return null
            return orders.isEmpty() ? null : orders[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static OrderReviewWrapper getReviewOrder(String orderId){
        system.debug('orderId'+orderId);
        cgcloud__Order__c order = [SELECT ID, cgcloud__Delivery_Recipient__r.Name, cgcloud__Delivery_Recipient__r.ShippingStreet, cgcloud__Value__c,
                                   cgcloud__Currency__c , TPB_Authorizing_Agent__c, cgcloud__Payment_Method__c, cgcloud__Delivery_Recipient__r.ShippingPostalCode,
                                   cgcloud__Delivery_Recipient__r.ShippingState, cgcloud__Delivery_Recipient__r.ShippingCity, cgcloud__Delivery_Recipient__r.Phone,
                                   cgcloud__Delivery_Recipient__r.ShippingCountry
                                   FROM cgcloud__Order__c WHERE ID = : orderId];
        OrderReviewWrapper wrap = new OrderReviewWrapper();
        wrap.accountName = order.cgcloud__Delivery_Recipient__r.Name;
        wrap.orderDate = system.today();
        wrap.deliveryDate = system.today();
        wrap.totalValue = order.cgcloud__Value__c;
        wrap.orderCurrency = order.cgcloud__Currency__c ;
        wrap.paymentMethod = order.cgcloud__Payment_Method__c;
        wrap.paidAmount = 0;
        wrap.paymentCollected = false;
        wrap.authorizingAgent = order.TPB_Authorizing_Agent__c;
        wrap.shippingStreet = order.cgcloud__Delivery_Recipient__r.ShippingStreet;
        wrap.shippingCity = order.cgcloud__Delivery_Recipient__r.ShippingCity;
        wrap.shippingState = order.cgcloud__Delivery_Recipient__r.ShippingState;
        wrap.shippingCountry = order.cgcloud__Delivery_Recipient__r.ShippingCountry;
        wrap.shippingPostalCode = order.cgcloud__Delivery_Recipient__r.ShippingPostalCode;
        wrap.accountPhone = order.cgcloud__Delivery_Recipient__r.Phone;
        return wrap;
    }
    @AuraEnabled
    public static String completeOrder(String orderBody){
        OrderReviewWrapper orderBodyWrapper = (OrderReviewWrapper)JSON.deserialize(orderBody, OrderReviewWrapper.class);
        cgcloud__Order__c order = [SELECT ID, Name FROM cgcloud__Order__c WHERE ID = : orderBodyWrapper.orderId];
        order.cgcloud__Phase__c = 'Released';
        order.cgcloud__Paid_Amount__c = orderBodyWrapper.paidAmount;
        order.cgcloud__Payment_Method__c = orderBodyWrapper.paymentMethod;
        order.TPB_Authorizing_Agent__c = orderBodyWrapper.authorizingAgent;
        order.cgcloud__Delivery_Date__c = orderBodyWrapper.deliveryDate;
        order.cgcloud__Order_Date__c = orderBodyWrapper.orderDate;
        update order;
        createInventoryTransaction(orderBodyWrapper.orderId);
        generateAndAttachInvoice(orderBodyWrapper.orderId);
        return order.Name + ': Order Complete!';
    }


    // For SAL-310: helper to identify promotions with PercentageDiscount rewards
    @AuraEnabled(cacheable=true)
    public static List<Id> getPercentageDiscountPromotionIds(List<Id> promotionIds) {
        Set<Id> uniquePromoIds = new Set<Id>();

        if (promotionIds == null || promotionIds.isEmpty()) {
            return new List<Id>();
        }

        for (AggregateResult ar : [
            SELECT cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c promoId
            FROM cgcloud__Promotion_Reward__c
            WHERE cgcloud__Reward_Type__c = 'PercentageDiscount'
            AND cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c IN :promotionIds
            GROUP BY cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c
        ]) {
            uniquePromoIds.add((Id) ar.get('promoId'));
        }

        // Convert Set → List for Aura/LWC compatibility
        return new List<Id>(uniquePromoIds);
    }

    @AuraEnabled
    public static List<OrderItemWrapper> getOrderItems(String orderId){
        try {
            List<cgcloud__Order_Item__c> orderItems = [SELECT ID, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c,cgcloud__Product__r.Name, cgcloud__Promotion__c,
                                                        cgcloud__Product__c, cgcloud__Quantity__c, cgcloud__Suggested_Quantity__c,cgcloud__Order_Item_Template__c, cgcloud__Promoted__c,
                                                        TPB_Wholesaler_ID__c,Reimbursable_Amt__c
                                                        FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c =: orderId];
            List<OrderItemWrapper> itemWrapperList = new List<OrderItemWrapper>();
            for(cgcloud__Order_Item__c orderItem : orderItems){
                OrderItemWrapper itemWrapper = new OrderItemWrapper();
                itemWrapper.orderItemId = orderItem.Id;
                itemWrapper.basePrice = (orderItem.cgcloud__Base_Price__c < 0) ? -1 * orderItem.cgcloud__Base_Price__c : orderItem.cgcloud__Base_Price__c;
                itemWrapper.specialPrice = (orderItem.cgcloud__Special_Price__c < 0) ? -1 * orderItem.cgcloud__Special_Price__c : orderItem.cgcloud__Special_Price__c;
                itemWrapper.uom = orderItem.cgcloud__UoM__c;
                itemWrapper.productId = orderItem.cgcloud__Product__c;
                itemWrapper.quantity = orderItem.cgcloud__Quantity__c;
                itemWrapper.suggestedQty = orderItem.cgcloud__Suggested_Quantity__c;
                itemWrapper.typeId = orderItem.cgcloud__Order_Item_Template__c;
                itemWrapper.wholeSalerId = orderItem.TPB_Wholesaler_ID__c;
                itemWrapper.isPromoted = orderItem.cgcloud__Promoted__c;
                itemWrapper.promotionId = orderItem.cgcloud__Promotion__c;
                itemWrapper.reimbursableAmount = orderItem.Reimbursable_Amt__c;
                itemWrapperList.add(itemWrapper); 
            }
            return itemWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable= true)
    public static List<OrderItemWrapper> getOOSItems(String visitId){
        try {
            List<cgcloud__Visit_Job__c> orderOOSItems = [SELECT ID, cgcloud__Product__c,cgcloud__Product__r.Name, cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name,cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c =: visitId AND cgcloud__Value__c = 'OutOfStock'];
			Visit visit = [SELECT ID, Account.ShippingState FROM Visit WHERE Id=:visitId];
            Set<Id> productIds = new Set<Id>();
            for(cgcloud__Visit_Job__c job: orderOOSItems){
                productIds.add(job.cgcloud__Product__c);
            }
            List<cgcloud__Unit_of_Measure__c> uoms = [SELECT Id, Name, cgcloud__Product__c,cgcloud__Pieces_per_Smallest_Unit__c FROM cgcloud__Unit_of_Measure__c WHERE cgcloud__Unit_Type__c = 'SalesUnit' and cgcloud__Product__c IN : productIds ];
            Map<Id, cgcloud__Unit_of_Measure__c> productUomMap = new Map<Id, cgcloud__Unit_of_Measure__c>();
            for(cgcloud__Unit_of_Measure__c uom: uoms){
                productUomMap.put(uom.cgcloud__Product__c, uom);
            }
            List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,cgcloud__Balance__c FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND TPB_Tour_State__c = :visit.Account.ShippingState]; 
            Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
            for(cgcloud__Inventory__c inventory: inventories){
                productInvMap.put(inventory.cgcloud__product__c, inventory);
            }

            List<OrderItemWrapper> itemOOSWrapperList = new List<OrderItemWrapper>();
            for(cgcloud__Visit_Job__c orderOOSItem : orderOOSItems){
                OrderItemWrapper itemWrapper = new OrderItemWrapper();
                itemWrapper.orderItemId = null;
                itemWrapper.basePrice = (productInvMap.containsKey(orderOOSItem.cgcloud__Product__c)) ? productInvMap.get(orderOOSItem.cgcloud__Product__c).TPB_AvgPrice__c : 0;
                itemWrapper.productName = orderOOSItem.cgcloud__Product__r.Name;
                itemWrapper.specialPrice = 0;
                //itemWrapper.uom = '';
                itemWrapper.productId = orderOOSItem.cgcloud__Product__c;
                itemWrapper.quantity = 0;
                itemWrapper.suggestedQty = 1;
                itemWrapper.maxAllocation = 1;
                itemWrapper.stockBalance = (productInvMap.containsKey(orderOOSItem.cgcloud__Product__c)) ? productInvMap.get(orderOOSItem.cgcloud__Product__c).cgcloud__Balance__c : 0;
                itemWrapper.cartonPieces = (productUomMap.containsKey(orderOOSItem.cgcloud__Product__c)) ? productUomMap.get(orderOOSItem.cgcloud__Product__c).cgcloud__Pieces_per_Smallest_Unit__c : 0;
                itemWrapper.productSubCategory = orderOOSItem.cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name;
                itemWrapper.cgcProductCode = orderOOSItem.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c;

                itemOOSWrapperList.add(itemWrapper);
            }
            System.debug('itemOOSWrapperList data...'+ itemOOSWrapperList);
            return itemOOSWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable= true)
    public static List<OrderItemWrapper> getDistributedItems(String visitId){
        try {
            List<cgcloud__Visit_Job__c> orderDistributedItems = [SELECT ID, cgcloud__Product__c,cgcloud__Product__r.Name, cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name,cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c =: visitId AND cgcloud__Value__c = 'Distributed'];
			Visit visit = [SELECT ID, Account.ShippingState FROM Visit WHERE Id=:visitId];
            Set<Id> productIds = new Set<Id>();
            for(cgcloud__Visit_Job__c job: orderDistributedItems){
                productIds.add(job.cgcloud__Product__c);
            }
            List<cgcloud__Unit_of_Measure__c> uoms = [SELECT Id, Name, cgcloud__Product__c,cgcloud__Pieces_per_Smallest_Unit__c FROM cgcloud__Unit_of_Measure__c WHERE cgcloud__Unit_Type__c = 'SalesUnit' and cgcloud__Product__c IN : productIds ];
            Map<Id, cgcloud__Unit_of_Measure__c> productUomMap = new Map<Id, cgcloud__Unit_of_Measure__c>();
            for(cgcloud__Unit_of_Measure__c uom: uoms){
                productUomMap.put(uom.cgcloud__Product__c, uom);
            }
            List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,cgcloud__Balance__c FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND TPB_Tour_State__c = :visit.Account.ShippingState]; 
            Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
            for(cgcloud__Inventory__c inventory: inventories){
                productInvMap.put(inventory.cgcloud__product__c, inventory);
            }

            List<OrderItemWrapper> itemDistributedWrapperList = new List<OrderItemWrapper>();
            for(cgcloud__Visit_Job__c orderDistributedItem : orderDistributedItems){
                OrderItemWrapper itemWrapper = new OrderItemWrapper();
                itemWrapper.orderItemId = null;
                itemWrapper.basePrice = (productInvMap.containsKey(orderDistributedItem.cgcloud__Product__c)) ? productInvMap.get(orderDistributedItem.cgcloud__Product__c).TPB_AvgPrice__c : 0;
                itemWrapper.productName = orderDistributedItem.cgcloud__Product__r.Name;
                itemWrapper.specialPrice = 0;
                //itemWrapper.uom = '';
                itemWrapper.productId = orderDistributedItem.cgcloud__Product__c;
                itemWrapper.quantity = 0;
                itemWrapper.suggestedQty = 1;
                itemWrapper.maxAllocation = 1;
                itemWrapper.stockBalance = (productInvMap.containsKey(orderDistributedItem.cgcloud__Product__c)) ? productInvMap.get(orderDistributedItem.cgcloud__Product__c).cgcloud__Balance__c : 0;
                itemWrapper.cartonPieces = (productUomMap.containsKey(orderDistributedItem.cgcloud__Product__c)) ? productUomMap.get(orderDistributedItem.cgcloud__Product__c).cgcloud__Pieces_per_Smallest_Unit__c : 0;
                itemWrapper.productSubCategory = orderDistributedItem.cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name;
                itemWrapper.cgcProductCode = orderDistributedItem.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c;

                itemDistributedWrapperList.add(itemWrapper);
            }
            System.debug('itemDistributedWrapperList data...'+ itemDistributedWrapperList);
            return itemDistributedWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void ensureVisitJobsExist(Id accountId,Id visitId) {

        try {
            if (String.isBlank(visitId)) {
                throw new AuraHandledException('Visit Id is required.');
            }
        } catch (Exception e) {
            System.debug('Error in ensureVisitJobsExist: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage() + '---' + e.getStackTraceString());
        }

        List<cgcloud__Visit_Job__c> visitJobsToInsert = new List<cgcloud__Visit_Job__c>();
        List<cgcloud__Visit_Job__c> visitJobsToUpdate = new List<cgcloud__Visit_Job__c>();
        List<cgcloud__Job_Definition_List_Product__c> missedDistributedProducts = new List<cgcloud__Job_Definition_List_Product__c>();

        List<cgcloud__Visit_Job__c> productDistVisitJobs = [SELECT ID, cgcloud__Visit__c, cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, cgcloud__Value__c,cgcloud__Job_Definition__c,cgcloud__Job_Definition_Template__c,cgcloud__Data_Type_Option__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c =: visitId];
        Map<Id, cgcloud__Visit_Job__c> productIdToVisitJobMap = new Map<Id, cgcloud__Visit_Job__c>();
        if(productDistVisitJobs.size() > 0){
            for (cgcloud__Visit_Job__c job : productDistVisitJobs) {
                if (job.cgcloud__Product__c != null) {
                    productIdToVisitJobMap.put(job.cgcloud__Product__c, job);
                }
            }
        }

        Set<Id> activityCustomerIds = TPB_OnlineAppController.getActivityProducts(accountId); 
        System.debug('activityCustomerIds data...'+ activityCustomerIds);

        if (activityCustomerIds == null || activityCustomerIds.isEmpty()) {
            return;
        }


        List<cgcloud__Job_Definition_List_Product__c> activityProducts = [SELECT Id,Name,cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, TPB_EOV__c,cgcloud__Job_Definition_List__c FROM cgcloud__Job_Definition_List_Product__c WHERE cgcloud__Job_Definition_List__c  IN : activityCustomerIds];

        //New Code 16-Dec-2025
        List<cgcloud__Job_DL_Job_Definition_Template__c> activityDataTypes = [SELECT Id,
                            cgcloud__Job_Definition_List__c,
                            cgcloud__Job_Definition_Template__c,
                            cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
                    FROM cgcloud__Job_DL_Job_Definition_Template__c
                    WHERE cgcloud__Job_Definition_List__c IN :activityCustomerIds];
        system.debug('activityDataTypes'+ activityDataTypes);

        Map<Id, cgcloud__Job_DL_Job_Definition_Template__c> activityJobDefsMap = new Map<Id, cgcloud__Job_DL_Job_Definition_Template__c>();
        Set<Id> dataTypeOptionIds = new Set<Id>();

        for (cgcloud__Job_DL_Job_Definition_Template__c activityJobDef : activityDataTypes) {
            activityJobDefsMap.put(activityJobDef.cgcloud__Job_Definition_List__c, activityJobDef);
            dataTypeOptionIds.add(activityJobDef.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c);
        }

        system.debug('activityJobDefsMap'+ activityJobDefsMap);
        system.debug('dataTypeOptionIds'+ dataTypeOptionIds);

        List<cgcloud__Data_Type_Option__c> dataTypeOptions = [SELECT Id,Name,cgcloud__Description__c,cgcloud__Data_Type__c,
                    cgcloud__Data_Type__r.Name FROM cgcloud__Data_Type_Option__c
                    WHERE cgcloud__Data_Type__c IN :dataTypeOptionIds];
        system.debug('dataTypeOptions'+ dataTypeOptions);
        Map<Id, Map<String, Id>> dataTypeOptionsMap = new Map<Id, Map<String, Id>>();

        for (cgcloud__Data_Type_Option__c option : dataTypeOptions) {

            Id dataTypeId = option.cgcloud__Data_Type__c;

            // Initialize sub-map if this DataType Id is not added yet
            if (!dataTypeOptionsMap.containsKey(dataTypeId)) {
                dataTypeOptionsMap.put(dataTypeId, new Map<String, Id>());
            }

            // Add option to that DataType's map
            dataTypeOptionsMap.get(dataTypeId).put(option.cgcloud__Description__c, option.Id);
        }
        system.debug('dataTypeOptionsMap'+ dataTypeOptionsMap);
        //End

        for (cgcloud__Job_Definition_List_Product__c actProd : activityProducts) {
            if (!productIdToVisitJobMap.containsKey(actProd.cgcloud__Product__c)) {
                cgcloud__Visit_Job__c vj = new cgcloud__Visit_Job__c();
                vj.cgcloud__Visit__c = visitId;
                vj.cgcloud__Product__c = actProd.cgcloud__Product__c;
                vj.cgcloud__Value__c = actProd.TPB_EOV__c != null ?  actProd.TPB_EOV__c : 'Distributed';
               // vj.Calculated_Distribution__c =actProd.TPB_EOV__c != null ?  actProd.TPB_EOV__c : 'Distributed';
                //vj.Via_Scanner__c = true; //For SAL-281


                if(actProd.cgcloud__Product__c != null){
                    vj.cgcloud__Job_Definition__c = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                            ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).Id
                                            : null;

                    vj.cgcloud__Job_Definition_Template__c = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                                        ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__c
                                                        : null;
                    String dataTypeId = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                                        ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
                                                        : null;
                    
                    vj.cgcloud__Data_Type_Option__c = dataTypeOptionsMap.containsKey(dataTypeId) &&
                                                        dataTypeOptionsMap.get(dataTypeId).containsKey(vj.cgcloud__Value__c)
                                                        ? dataTypeOptionsMap.get(dataTypeId).get(vj.cgcloud__Value__c)
                                                        : null;
                }
                visitJobsToInsert.add(vj);
            }
        }


       

        System.debug('visitJobsToInsert...'+visitJobsToInsert);
        if (!visitJobsToInsert.isEmpty()) {
            insert visitJobsToInsert;
        }


    }
    @AuraEnabled
    public static VisitJobResult createVisitJobs(String visitId, String visitJobWrapper) {
        VisitJobResult result = new VisitJobResult();
        result.insertedCount = 0;
        result.updatedCount = 0;
        result.hasErrors = false;
        result.errorMessage = null;
        try {
            if (String.isBlank(visitId) || String.isBlank(visitJobWrapper)) {
                throw new AuraHandledException('Invalid input: visitId or payload is missing.');
            }
            List<ProductDistributionData> visitJobWrapperList = (List<ProductDistributionData>) JSON.deserialize(visitJobWrapper,List<ProductDistributionData>.class);
            
            if (visitJobWrapperList.isEmpty()) return result;
  
            Map<Id, cgcloud__Visit_Job__c> existingJobsByProduct = new Map<Id, cgcloud__Visit_Job__c>();

            for (cgcloud__Visit_Job__c vj : [
                SELECT Id, cgcloud__Product__c,cgcloud__Visit_Date__c
                FROM cgcloud__Visit_Job__c
                WHERE cgcloud__Visit__c = :visitId
            ]) {
                if (vj.cgcloud__Product__c != null) {
                    existingJobsByProduct.put(vj.cgcloud__Product__c, vj);
                }
            }
            List<cgcloud__Visit_Job__c> toInsert = new List<cgcloud__Visit_Job__c>();
            List<cgcloud__Visit_Job__c> toUpdate = new List<cgcloud__Visit_Job__c>();
            List<String> errors = new List<String>();
            for (ProductDistributionData job : visitJobWrapperList) {
                if (job == null || job.productId == null) {
                    continue;
                }
                if (existingJobsByProduct.containsKey(job.productId)) {
                    // UPDATE
                    cgcloud__Visit_Job__c upd = existingJobsByProduct.get(job.productId);
                    upd.cgcloud__Value__c = job.visitJobAnswer;
                   // upd.cgcloud__Last_Value__c = job.visitJobAnswer;
                   // upd.Calculated_Distribution__c = job.visitJobAnswer;
                    upd.cgcloud__Done__c = true;
                    if (upd.cgcloud__Visit_Date__c == null) {
                        upd.cgcloud__Visit_Date__c = Date.today();
                    }
                    toUpdate.add(upd);
                } else {
                    // INSERT
                    cgcloud__Visit_Job__c ins = new cgcloud__Visit_Job__c();
                    ins.cgcloud__Visit__c = visitId;
                    ins.cgcloud__Product__c = job.productId;
                    ins.cgcloud__Value__c = job.visitJobAnswer;
                   // ins.cgcloud__Last_Value__c = job.visitJobAnswer;
                    //ins.Calculated_Distribution__c = job.visitJobAnswer;
                    ins.cgcloud__Visit_Date__c = Date.today();
                    ins.cgcloud__Done__c = true;
                    
                    if (job.visitJobJobDef != null) {
                        ins.cgcloud__Job_Definition__c = job.visitJobJobDef;
                    }
                    if (job.visitJobJobDefTemplate != null) {
                        ins.cgcloud__Job_Definition_Template__c = job.visitJobJobDefTemplate;
                    }
                    if (job.visitJobDataTypeOption != null) {
                        ins.cgcloud__Data_Type_Option__c = job.visitJobDataTypeOption;
                    }

                    toInsert.add(ins);
                }
            }

            // if (!toInsert.isEmpty())
            //     Database.insert(toInsert, false);

            // if (!toUpdate.isEmpty())
            //     Database.update(toUpdate, false);

            // INSERT
            if (!toInsert.isEmpty()) {
                Database.SaveResult[] insResults = Database.insert(toInsert, false);
                for (Integer i = 0; i < insResults.size(); i++) {
                    if (insResults[i].isSuccess()) {
                        result.insertedCount++;
                    } else {
                        result.hasErrors = true;
                        errors.add(
                            'Insert failed (Product ' +
                            toInsert[i].cgcloud__Product__c +
                            '): ' +
                            insResults[i].getErrors()[0].getMessage()
                        );
                    }
                }
            }

            // UPDATE
            if (!toUpdate.isEmpty()) {
                Database.SaveResult[] updResults = Database.update(toUpdate, false);
                for (Integer i = 0; i < updResults.size(); i++) {
                    if (updResults[i].isSuccess()) {
                        result.updatedCount++;
                    } else {
                        result.hasErrors = true;
                        errors.add(
                            'Update failed (Product ' +
                            toUpdate[i].cgcloud__Product__c +
                            '): ' +
                            updResults[i].getErrors()[0].getMessage()
                        );
                    }
                }
            }

            // If any failures → return detailed error
            if (!errors.isEmpty()) {
                result.errorMessage = String.join(errors, '\n');
            }

            return result;
        } catch (AuraHandledException e) {
            // Business-safe error for LWC
            result.hasErrors = true;
            result.errorMessage = e.getMessage();
            return result;

        } catch (Exception e) {
            // Unexpected system error
            result.hasErrors = true;
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
            return result;
        }
    }

   
    @AuraEnabled
    public static ProductDistributionWrapper getProductDistributionProducts(String accountId, String visitId){
        try {
            // Ensure visit jobs exist before returning data
            //ensureVisitJobsExist(accountId, visitId);

            Set<Id> activityCustomerIds = getActivityProducts(accountId); 
            System.debug('activityCustomerIds data...'+ activityCustomerIds);

            
            //SELECT Id,name,cgcloud__Description__c, cgcloud__Data_Type__c,cgcloud__Data_Type__r.Name FROM cgcloud__Data_Type_Option__c WHERE cgcloud__Data_Type__c   = 'a4H6T000000xVi3UAE'

            List<cgcloud__Visit_Job__c> productDistVisitJobs = [SELECT ID, cgcloud__Visit__c, cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, cgcloud__Value__c,cgcloud__Job_Definition__c,cgcloud__Job_Definition_Template__c,cgcloud__Data_Type_Option__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c =: visitId];

            //Updated code on 21-Aug-2025    
            List<cgcloud__Job_Definition_List_Product__c> activityProducts = [SELECT Id,Name,cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, TPB_EOV__c,cgcloud__Job_Definition_List__c FROM cgcloud__Job_Definition_List_Product__c WHERE cgcloud__Job_Definition_List__c  IN : activityCustomerIds];


            Set<Id> productDistributionProductIds = new Set<Id>();
            for(cgcloud__Job_Definition_List_Product__c actProduct : activityProducts){
                productDistributionProductIds.add(actProduct.cgcloud__Product__c);
            }
            system.debug('productDistributionProductIds'+ productDistributionProductIds);
            

            Set<Id> notInProductDistribution = new Set<Id>();
            for(cgcloud__Visit_Job__c job : productDistVisitJobs){
                if(!productDistributionProductIds.contains(job.cgcloud__Product__c)){
                    notInProductDistribution.add(job.cgcloud__Product__c);
                }
            }
            system.debug('notInProductDistribution'+ notInProductDistribution);
            //End

            //New Code 27-Nov-2025


            // List<cgcloud__Job_DL_Job_Definition_Template__c> activityDataTypes = [SELECT Id,
            //                     cgcloud__Job_Definition_List__c,
            //                     cgcloud__Job_Definition_Template__c,
            //                     cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
            //             FROM cgcloud__Job_DL_Job_Definition_Template__c
            //             WHERE cgcloud__Job_Definition_List__c IN :activityCustomerIds];

            // system.debug('activityDataTypes'+ activityDataTypes);

            // Map<Id, cgcloud__Job_DL_Job_Definition_Template__c> activityJobDefsMap = new Map<Id, cgcloud__Job_DL_Job_Definition_Template__c>();
            // Set<Id> dataTypeOptionIds = new Set<Id>();

            // for (cgcloud__Job_DL_Job_Definition_Template__c activityJobDef : activityDataTypes) {
            //     activityJobDefsMap.put(activityJobDef.cgcloud__Job_Definition_List__c, activityJobDef);
            //     dataTypeOptionIds.add(activityJobDef.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c);
            // }

            // system.debug('activityJobDefsMap'+ activityJobDefsMap);
            // system.debug('dataTypeOptionIds'+ dataTypeOptionIds);

            // List<cgcloud__Data_Type_Option__c> dataTypeOptions = [SELECT Id,Name,cgcloud__Description__c,cgcloud__Data_Type__c,
            //             cgcloud__Data_Type__r.Name FROM cgcloud__Data_Type_Option__c
            //             WHERE cgcloud__Data_Type__c IN :dataTypeOptionIds];
            // system.debug('dataTypeOptions'+ dataTypeOptions);
            // Map<Id, Map<String, Id>> dataTypeOptionsMap = new Map<Id, Map<String, Id>>();

            // for (cgcloud__Data_Type_Option__c option : dataTypeOptions) {

            //     Id dataTypeId = option.cgcloud__Data_Type__c;

            //     // Initialize sub-map if this DataType Id is not added yet
            //     if (!dataTypeOptionsMap.containsKey(dataTypeId)) {
            //         dataTypeOptionsMap.put(dataTypeId, new Map<String, Id>());
            //     }

            //     // Add option to that DataType's map
            //     dataTypeOptionsMap.get(dataTypeId).put(option.cgcloud__Description__c, option.Id);
            // }
            // system.debug('dataTypeOptionsMap'+ dataTypeOptionsMap);
            //End


            List<ProductDistributionData> productDistributions = new List<ProductDistributionData>();
            ProductDistributionWrapper wrapper = new ProductDistributionWrapper();
            if(productDistVisitJobs.size() > 0){
                for(cgcloud__Visit_Job__c job : productDistVisitJobs){
                    ProductDistributionData  jobData = new ProductDistributionData();
                    jobData.productName = job.cgcloud__Product__r.Name;
                    jobData.productId = job.cgcloud__Product__c;
                    jobData.visitJobAnswer = job.cgcloud__Value__c;
                    jobData.visitJobId = job.Id;
                    jobData.productSubCategory = job.cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name;
                    jobData.isDeletable = notInProductDistribution.contains(job.cgcloud__Product__c);

                    jobData.visitJobJobDef = job.cgcloud__Job_Definition__c;
                    jobData.visitJobJobDefTemplate = job.cgcloud__Job_Definition_Template__c;
                    jobData.visitJobDataTypeOption = job.cgcloud__Data_Type_Option__c;

                    productDistributions.add(jobData);
                }
                wrapper.visitJob = true;
            }else{
                // //List<cgcloud__Job_Definition_List_Product__c> activityProducts = [SELECT Id,Name,cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, TPB_EOV__c FROM cgcloud__Job_Definition_List_Product__c WHERE cgcloud__Job_Definition_List__c  IN : activityCustomerIds];
                // for(cgcloud__Job_Definition_List_Product__c product : activityProducts){
                //     ProductDistributionData  productData = new ProductDistributionData();
                //     productData.productId = product.cgcloud__Product__c;
                //     productData.productName = product.cgcloud__Product__r.Name;
                //     productData.productSubCategory = product.cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name;
                //     productData.visitJobAnswer = (product.TPB_EOV__c != null) ? product.TPB_EOV__c : 'Distributed';
                //     productData.isDeletable = false;
                    
                //     productData.visitJobJobDef = activityJobDefsMap.containsKey(product.cgcloud__Job_Definition_List__c)
                //                                 ? activityJobDefsMap.get(product.cgcloud__Job_Definition_List__c).Id
                //                                 : null;

                //     productData.visitJobJobDefTemplate = activityJobDefsMap.containsKey(product.cgcloud__Job_Definition_List__c)
                //                                         ? activityJobDefsMap.get(product.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__c
                //                                         : null;
                //     String dataTypeId = activityJobDefsMap.containsKey(product.cgcloud__Job_Definition_List__c)
                //                                         ? activityJobDefsMap.get(product.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
                //                                         : null;
                    
                //     productData.visitJobDataTypeOption = dataTypeOptionsMap.containsKey(dataTypeId) &&
                //                                         dataTypeOptionsMap.get(dataTypeId).containsKey(productData.visitJobAnswer)
                //                                         ? dataTypeOptionsMap.get(dataTypeId).get(productData.visitJobAnswer)
                //                                         : null;
                //     productDistributions.add(productData);
                // }
                // wrapper.visitJob = false;
            }
            wrapper.productDistributions = productDistributions;
            wrapper.productDistributionPicklist = getPicklistValues('cgcloud__Job_Definition_List_Product__c', 'TPB_EOV__c');
            System.debug('productDistWarpper data...'+ wrapper);
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<String> getPicklistValues(String objectName, String fieldName){        
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> picklistValues = new List<String>();
        for( Schema.PicklistEntry pickListVal : ple){
            System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
            picklistValues.add(pickListVal.getValue());
        }
        return picklistValues;
    }
    
    public static Set<Id> getActivityProducts(String accountId){
        try {
            Map<Id, cgcloud__Job_Definition_List_Account__c> activityCustomersMap = new Map<Id, cgcloud__Job_Definition_List_Account__c>([SELECT Id,name,cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c, cgcloud__Job_Definition_List__r.cgcloud__Active__c,cgcloud__Job_Definition_List__c
                FROM cgcloud__Job_Definition_List_Account__c 
                WHERE cgcloud__Account__c  =: accountId AND cgcloud__Job_Definition_List__r.cgcloud__Consider_Products__c = true 
                AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true]);
            //return activityCustomersMap.keySet();
            Set<Id> activityIds = new Set<Id>();
            for(cgcloud__Job_Definition_List_Account__c activityCustomer : activityCustomersMap.values()){
                activityIds.add(activityCustomer.cgcloud__Job_Definition_List__c);
            }
            return activityIds;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Map<Id, List<AuthorizedProducts>> getWholesalerAuthProducts(String accountId){
        try {
            List<Related_Account__c> relatedWholesalers = [SELECT Id, Wholesaler__r.Name, Wholesaler__c, TPB_Primary_Wholesaler__c, TPB_Promotional_Wholesaler__c FROM Related_Account__c WHERE  Retailer__c =: accountId];
      
            Map<Id, Related_Account__c> wholesalersIdMap = new Map<Id, Related_Account__c>();            
            for(Related_Account__c wholesaler : relatedWholesalers){
                wholesalersIdMap.put(wholesaler.Wholesaler__c, wholesaler);
            }
            List<Account_Product__c> authorizedProducts = getAuthorizedProducts(wholesalersIdMap.keySet());
            // Map<Id, List<Account_Product__c>> productsMap = new Map<Id, List<Account_Product__c>>();
            Map<Id, List<AuthorizedProducts>> productsMap = new Map<Id, List<AuthorizedProducts>>();
            for(Account_Product__c product: authorizedProducts){
                //System.debug('product data...'+ product);
                List<AuthorizedProducts> products = productsMap.containsKey(product.Product__c) ? productsMap.get(product.Product__c) : new List<AuthorizedProducts>();
                AuthorizedProducts authProd = new AuthorizedProducts();
                authProd.productId = product.Product__c;
                authProd.accountId = product.Account__c;
                authProd.accountName = product.Account__r.Name;
                authProd.sku = product.SKU__c;
                authProd.clearingHouse = product.Account__r.Clearing_House_Participant__c;
                authProd.primaryAccount = wholesalersIdMap.get(product.Account__c).TPB_Primary_Wholesaler__c;
                authProd.promotionalAccount = wholesalersIdMap.get(product.Account__c).TPB_Promotional_Wholesaler__c;
                products.add(authProd);
                productsMap.put(product.Product__c, products);
            }
            return productsMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    
    public static List<Account_Product__c> getAuthorizedProducts(Set<Id> wholesalersIds){
        return [SELECT
          Id,Product__c,Account__c,Account__r.Name,SKU__c, Account__r.Clearing_House_Participant__c
        FROM Account_Product__c
        WHERE Account__c IN: wholesalersIds];
    }

    @AuraEnabled
    public static List<AuthorizedProducts> getPrebookWholesaler(String accountId, String productId){
        try {
            List<Related_Account__c> relatedWholesalers = [SELECT Id, Wholesaler__r.Name, Wholesaler__c FROM Related_Account__c WHERE  Retailer__c =: accountId];
            Set<Id> wholesalersIds = new Set<Id>();  
                  
            for(Related_Account__c wholesaler : relatedWholesalers){
                wholesalersIds.add(wholesaler.Wholesaler__c);
            }
            Account tsmVan = [SELECT ID, Name FROM Account WHERE Name = 'TSM VAN' LIMIT 1];
            // wholesalersIds.add(tsmVan.ID);
            List<Account_Product__c> accountProducts = getAuthorizedProducts(wholesalersIds, productId);
            // system.debug(accountProducts[0].Account__r.Name);
            List<AuthorizedProducts> authProdList = new List<AuthorizedProducts>();
            for(Account_Product__c prod: accountProducts){
                AuthorizedProducts authProd = new AuthorizedProducts();
                authProd.productId = prod.Product__c;
                authProd.accountId = prod.Account__c;
                authProd.accountName = prod.Account__r.Name;
                authProd.sku = prod.SKU__c;
                authProd.clearingHouse = prod.Account__r.Clearing_House_Participant__c;
                authProdList.add(authProd);
            }
            AuthorizedProducts authProdTSM = new AuthorizedProducts();
            authProdTSM.accountId = tsmVan.Id;
            authProdTSM.accountName = tsmVan.Name;
            authProdList.add(authProdTSM);
            return authProdList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    
    public class AuthorizedProducts{
        @AuraEnabled public String productId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String sku;
        @AuraEnabled public Boolean clearingHouse;
        @AuraEnabled public Boolean primaryAccount;
        @AuraEnabled public Boolean promotionalAccount;
    }

       
    @AuraEnabled(cacheable= true)
    public static List<SuggestedOrderPrebbokWrapper> suggestedOrderPrebook(String accountId, String orderId, Boolean tpbPromo){
        try {
            String query = 'SELECT Id, Quantity__c, Price__c, TPB_Max_Allocation__c, Product__c, Product__r.Name ' +
               'FROM Ideal_Kit__c WHERE Account__c = :accountId ' +
               'AND Item_Type__c = \'Suggested Order\' ' +
               'AND Product__r.Current_Shiplist_Item__c = :tpbPromo';

            String promo = 'Promo';
            query = (tpbPromo) ? query + ' AND Product__r.NTC_Item_Classification__c = :promo' : query;
            List<Ideal_Kit__c> idealKits = Database.query(query);//NTC_Item_Classification__c
            Id prebookTemplateId=  [SELECT Id,Name
                                    FROM cgcloud__Order_Item_Template__c
                                    WHERE Name = 'Prebook' LIMIT 1].Id;
                                            
            List<cgcloud__Order_Item__c> orderItems = [SELECT Id, cgcloud__Product__c,cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c, cgcloud__Quantity__c,TPB_Wholesaler_ID__c,cgcloud__Order_Item_Template__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = : orderId AND cgcloud__Order_Item_Template__c =: prebookTemplateId];
            Map<Id, cgcloud__Order_Item__c> orderItemMap = new Map<Id, cgcloud__Order_Item__c>();
            for(cgcloud__Order_Item__c orderItem: orderItems){
                orderItemMap.put(orderItem.cgcloud__Product__c, orderItem);
            }
            List<SuggestedOrderPrebbokWrapper> prebookWrapper = new List<SuggestedOrderPrebbokWrapper>();
            for(Ideal_Kit__c kit : idealKits){
                SuggestedOrderPrebbokWrapper kitWrap = new SuggestedOrderPrebbokWrapper();
                kitWrap.minQty = kit.Quantity__c;
                kitWrap.maxQty = kit.TPB_Max_Allocation__c;
                kitWrap.productId = kit.Product__c;
                kitWrap.productName = kit.Product__r.Name;
                kitWrap.price = kit.Price__c;
                kitWrap.lineItemId = orderItemMap.containsKey(kit.Product__c) ? orderItemMap.get(kit.Product__c).Id : null;
                kitWrap.lineItemQty = orderItemMap.containsKey(kit.Product__c) ? orderItemMap.get(kit.Product__c).cgcloud__Quantity__c : 0;
                kitWrap.wholeSalerId = orderItemMap.containsKey(kit.Product__c) ? orderItemMap.get(kit.Product__c).TPB_Wholesaler_ID__c : null;
                kitWrap.typeId = orderItemMap.containsKey(kit.Product__c) ? orderItemMap.get(kit.Product__c).cgcloud__Order_Item_Template__c : null;
                kitWrap.cgcProductCode = orderItemMap.containsKey(kit.Product__c) ? orderItemMap.get(kit.Product__c).cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c : null;
                prebookWrapper.add(kitWrap);
            }

            return prebookWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<Account_Product__c> getAuthorizedProducts(Set<Id> wholesalersIds, String productId){
        return [SELECT
          Id,Product__c,Account__c,Account__r.Name,SKU__c, Account__r.Clearing_House_Participant__c
        FROM Account_Product__c
        WHERE Account__c IN: wholesalersIds AND Product__c =: productId];
    }


    @AuraEnabled
    public static List<cgcloud__Order_Item_Template__c> getOrderItemTemplates(){
        return [SELECT
          Id,Name
        FROM cgcloud__Order_Item_Template__c
        WHERE Name IN ('Cash Sale','Return', 'Prebook','Free Item')];
    }
    @AuraEnabled(cacheable= true)
    public static List<cgcloud__Promotion__c> getPromotions(String accountId){
        try {
            List<cgcloud__Account_Set_Account__c> accountSets = [SELECT Id, cgcloud__Account_Set__c, cgcloud__Account_Set_Account__c 
                                                                FROM cgcloud__Account_Set_Account__c 
                                                                WHERE cgcloud__Account_Set_Account__c =: accountId];
            Set<Id> accountSetIds = new Set<Id>();
            for(cgcloud__Account_Set_Account__c accSet : accountSets){
                accountSetIds.add(accSet.cgcloud__Account_Set__c);
            }
            Date today = Date.today();
            List<cgcloud__Promotion__c> advancedPromotionsMap = new List<cgcloud__Promotion__c>([SELECT ID,cgcloud__Slogan__c,TPB_Promotion_Type__c FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account_Set__c IN: accountSetIds AND cgcloud__Active__c = true AND cgcloud__Date_From__c <= :today AND cgcloud__Date_Thru__c >= :today]);
            System.debug('advancedPromotionsMap'+ advancedPromotionsMap);
            return advancedPromotionsMap;
            
                         
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getTacticProducts(String visitId, String promotionId, String orderId){
        Visit visit = [SELECT ID, Account.ShippingState FROM Visit WHERE ID = : visitId];
        List<cgcloud__Tactic_Product__c> tacticProducts = [SELECT Id, cgcloud__Product__c, cgcloud__Tactic__r.cgcloud__Promotion__c
                                                           FROM cgcloud__Tactic_Product__c WHERE cgcloud__Tactic__r.cgcloud__Promotion__c =: promotionId];
        
        List<cgcloud__Promotion_Reward_Product__c> rewardProducts =  [SELECT ID, cgcloud__Default_Value__c, cgcloud__Included__c, 
                        cgcloud__Logistic_Unit__c, cgcloud__Max_Value__c, cgcloud__Product__c, 
                        cgcloud__Product_Name__c, cgcloud__Reward_Type__c 
                        FROM cgcloud__Promotion_Reward_Product__c 
                        WHERE cgcloud__Promotion_Reward__r.cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c =:promotionId];

        List<cgcloud__Order_Item__c> orderItems = [SELECT ID, cgcloud__Base_Price__c, cgcloud__Promotion__c, cgcloud__Special_Price__c, cgcloud__UoM__c,cgcloud__Product__r.Name,
                                    cgcloud__Product__c, cgcloud__Quantity__c, cgcloud__Suggested_Quantity__c,cgcloud__Order_Item_Template__c,cgcloud__Order_Item_Template__r.Name,cgcloud__Promoted__c,TPB_Wholesaler_ID__c,Reimbursable_Amt__c
                                    FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c =: orderId AND cgcloud__Promoted__c = true AND cgcloud__Promotion__c =: promotionId ];


        Map<String, List<cgcloud__Order_Item__c>> orderItemsMap = new Map<String, List<cgcloud__Order_Item__c>>();//multiple order items of product
        for(cgcloud__Order_Item__c orderItem: orderItems){
            List<cgcloud__Order_Item__c> orderItemsList = orderItemsMap.containsKey(orderItem.cgcloud__Product__c) ? orderItemsMap.get(orderItem.cgcloud__Product__c) : new List<cgcloud__Order_Item__c>();
            orderItemsList.add(orderItem);
            orderItemsMap.put(orderItem.cgcloud__Product__c, orderItemsList);
        }

		Set<Id> productIds = new Set<Id>();
        for(cgcloud__Tactic_Product__c product: tacticProducts){
            productIds.add(product.cgcloud__Product__c);
        }    
        for(cgcloud__Promotion_Reward_Product__c product: rewardProducts){
            if(orderItemsMap.containsKey(product.cgcloud__Product__c)){  
                productIds.add(product.cgcloud__Product__c);
            }
        } 
        List<Product2> products = [SELECT Id, Name, cgcloud__Consumer_Goods_Product_Code__c,cgcloud__Criterion_2_Product__r.Name  
                                   FROM Product2 WHERE Id IN : productIds];
        List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,
                                                   cgcloud__Balance__c  
                                                   FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND TPB_Tour_State__c = : visit.Account.ShippingState]; 
        Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
        for(cgcloud__Inventory__c inventory: inventories){
            productInvMap.put(inventory.cgcloud__product__c, inventory);
        }

        List<cgcloud__Unit_of_Measure__c> uoms = [SELECT Id, Name, cgcloud__Product__c,cgcloud__Pieces_per_Smallest_Unit__c FROM cgcloud__Unit_of_Measure__c WHERE cgcloud__Unit_Type__c = 'SalesUnit' and cgcloud__Product__c IN : productIds ];
        Map<Id, cgcloud__Unit_of_Measure__c> productUomMap = new Map<Id, cgcloud__Unit_of_Measure__c>();
        for(cgcloud__Unit_of_Measure__c uom: uoms){
            productUomMap.put(uom.cgcloud__Product__c, uom);
        }
        
       
        System.debug('products...'+products);
        System.debug('orderItemsMap...'+orderItemsMap);
        List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
        for(Product2 product: products){
            ProductWrapper productWrapper = new ProductWrapper();
            productWrapper.product = product;
            productWrapper.basePrice = (productInvMap.containsKey(product.Id)) ? productInvMap.get(product.Id).TPB_AvgPrice__c : 0;
            productWrapper.stockBalance = (productInvMap.containsKey(product.Id)) ? productInvMap.get(product.Id).cgcloud__Balance__c : 0;
            productWrapper.suggestedQty = 1;
            productWrapper.maxAllocation = 1;
            productWrapper.productSubCategory = product.cgcloud__Criterion_2_Product__r.Name;
            productWrapper.cartonPieces = (productUomMap.containsKey(product.Id)) ? productUomMap.get(product.Id).cgcloud__Pieces_per_Smallest_Unit__c : 0;
            
            if(orderItemsMap.containsKey(product.Id)){  
                List<OrderItemWrapper> orderItemWrapperList = new List<OrderItemWrapper>();
                for(cgcloud__Order_Item__c orderItem: orderItemsMap.get(product.Id)){
                   // cgcloud__Order_Item__c orderItem = orderItemsMap.get(product.Id);
                    OrderItemWrapper orderItemWrapper = new OrderItemWrapper();
                    orderItemWrapper.orderItemId = orderItem.Id;
                    orderItemWrapper.productId = product.Id;
                    orderItemWrapper.productName = product.Name;
                    orderItemWrapper.specialPrice = orderItem.cgcloud__Special_Price__c;
                    orderItemWrapper.uom = orderItem.cgcloud__UoM__c;
                    orderItemWrapper.quantity = orderItem.cgcloud__Quantity__c;
                    orderItemWrapper.typeId = orderItem.cgcloud__Order_Item_Template__c;
                    orderItemWrapper.promotionId = orderItem.cgcloud__Promotion__c;
                    orderItemWrapper.templateName = orderItem.cgcloud__Order_Item_Template__r.Name;

                    orderItemWrapper.isPromoted = orderItem.cgcloud__Promoted__c;
                    orderItemWrapper.wholeSalerId = orderItem.TPB_Wholesaler_ID__c;
                    orderItemWrapper.suggestedQty = orderItem.cgcloud__Suggested_Quantity__c;
                    orderItemWrapper.reimbursableAmount = orderItem.Reimbursable_Amt__c;
                    orderItemWrapper.basePrice = orderItem.cgcloud__Base_Price__c;

                    
                    orderItemWrapperList.add(orderItemWrapper);

                }
        
                productWrapper.orderItemList = orderItemWrapperList;
                
                
            }

            productWrapperList.add(productWrapper); 
            
        }
        System.debug('productWrapperList (Pretty JSON): ' + JSON.serializePretty(productWrapperList));
        System.debug('productWrapperList...'+productWrapperList);
        return productWrapperList;
    }

    @AuraEnabled
    public static List<CriteriaMatchWrapper> rewardCriteriaCheck(String promotionId,String orderId) {
        try {
            List<cgcloud__Promotion_Hurdle__c> hurdles = [SELECT ID  FROM cgcloud__Promotion_Hurdle__c 
                                                            WHERE cgcloud__Classification__c = 'C1' AND cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c =: promotionId ]; //AND cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__r.TPB_Promotion_Type__c = 'Discount'
            List<CriteriaMatchWrapper> results = new List<CriteriaMatchWrapper>();
            if(hurdles.size() > 0){
                results.addAll(rewardCriteriaMatchWithClassification(promotionId, orderId));
                
            } else {
                results.addAll(rewardCriteriaDiscountWithoutClassification(promotionId, orderId));
                
            }
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    public static List<CriteriaMatchWrapper> rewardCriteriaMatchWithClassification(String promotionId,String orderId) {
        try {
            // Promotion
            cgcloud__Promotion__c promotion = [
                SELECT Id, TPB_Promotion_Type__c
                FROM cgcloud__Promotion__c
                WHERE Id = :promotionId
            ];

            // Reward Groups
            List<cgcloud__Promotion_Reward_Group__c> rewardGroups = [
                SELECT Id, Name
                FROM cgcloud__Promotion_Reward_Group__c
                WHERE cgcloud__Promotion__c = :promotionId AND cgcloud__Included__c = true 
            ];

            if (rewardGroups.isEmpty()) return new List<CriteriaMatchWrapper>();

            // Hurdles grouped by Reward Group
            Map<Id, List<cgcloud__Promotion_Hurdle__c>> hurdlesByGroup = new Map<Id, List<cgcloud__Promotion_Hurdle__c>>();
            for (cgcloud__Promotion_Hurdle__c h : [
                SELECT Id,
                    cgcloud__Promotion_Reward_Group__c,
                    cgcloud__Classification__c,
                    cgcloud__Operator__c,
                    cgcloud__Numeric_Value__c,
                    cgcloud__Sort__c
                FROM cgcloud__Promotion_Hurdle__c
                WHERE cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c = :promotionId
                ORDER BY cgcloud__Sort__c
            ]) {
                if (!hurdlesByGroup.containsKey(h.cgcloud__Promotion_Reward_Group__c)) {
                    hurdlesByGroup.put(h.cgcloud__Promotion_Reward_Group__c, new List<cgcloud__Promotion_Hurdle__c>());
                }
                hurdlesByGroup.get(h.cgcloud__Promotion_Reward_Group__c).add(h);
            }

            // Rewards grouped by Reward Group
            Map<Id, Map<Id, Double>> rewardsByGroup = new Map<Id, Map<Id, Double>>();
            for (cgcloud__Promotion_Reward__c r : [
                SELECT Id,
                    cgcloud__Promotion_Reward_Group__c,
                    cgcloud__Hurdle__c,
                    cgcloud__Numeric_Value__c
                FROM cgcloud__Promotion_Reward__c
                WHERE cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c = :promotionId
            ]) {
                if (!rewardsByGroup.containsKey(r.cgcloud__Promotion_Reward_Group__c)) {
                    rewardsByGroup.put(r.cgcloud__Promotion_Reward_Group__c, new Map<Id, Double>());
                }
                rewardsByGroup.get(r.cgcloud__Promotion_Reward_Group__c)
                    .put(r.cgcloud__Hurdle__c, r.cgcloud__Numeric_Value__c);
            }

            // Tactic Products → Classification → Products
            Map<String, List<Id>> productClassificationIds = new Map<String, List<Id>>();
            for (cgcloud__Tactic_Product__c tp : [
                SELECT cgcloud__Product__c, cgcloud__Classification__c
                FROM cgcloud__Tactic_Product__c
                WHERE cgcloud__Tactic__r.cgcloud__Promotion__c = :promotionId
            ]) {
                if (!productClassificationIds.containsKey(tp.cgcloud__Classification__c)) {
                    productClassificationIds.put(tp.cgcloud__Classification__c, new List<Id>());
                }
                productClassificationIds.get(tp.cgcloud__Classification__c).add(tp.cgcloud__Product__c);
            }

            Id orderItemTemplateId = [
                SELECT Id
                FROM cgcloud__Order_Item_Template__c
                WHERE Name = 'Cash Sale'
            ].Id;

            // Order Items
            Map<Id, cgcloud__Order_Item__c> orderItemMap = new Map<Id, cgcloud__Order_Item__c>();
            List<cgcloud__Order_Item__c> orderItems = [
                SELECT Id, cgcloud__Product__c, cgcloud__Quantity__c
                FROM cgcloud__Order_Item__c
                WHERE cgcloud__Order__c = :orderId
                AND cgcloud__Promotion__c = :promotionId
                AND cgcloud__Promoted__c = true
                AND cgcloud__Order_Item_Template__c = :orderItemTemplateId
                AND cgcloud__UoM__c = 'Carton'
            ];
            for (cgcloud__Order_Item__c oi : orderItems) {
                orderItemMap.put(oi.cgcloud__Product__c, oi);
            }

            // FINAL RESULTS
            List<CriteriaMatchWrapper> results = new List<CriteriaMatchWrapper>();

            // Evaluate EACH reward group independently
            for (cgcloud__Promotion_Reward_Group__c rewardGroup : rewardGroups) {
                List<cgcloud__Promotion_Hurdle__c> hurdles = hurdlesByGroup.get(rewardGroup.Id);
                if (hurdles == null || hurdles.isEmpty()) continue;

                Map<Id, Double> rewardMap = rewardsByGroup.containsKey(rewardGroup.Id)
                    ? rewardsByGroup.get(rewardGroup.Id)
                    : new Map<Id, Double>();

                CriteriaMatchWrapper result = new CriteriaMatchWrapper();
                result.rewardGroupId = rewardGroup.Id;
                result.rewardFulfilled = true;
                result.promotionType = promotion.TPB_Promotion_Type__c;

                String mainOperator;
                Double mainNumVal = 0;
                Double orderItemQuantities = 0;

                // Detect main operator
                for (cgcloud__Promotion_Hurdle__c h : hurdles) {
                    if (h.cgcloud__Classification__c == null && h.cgcloud__Operator__c != 'PER') {
                        mainOperator = h.cgcloud__Operator__c;
                        mainNumVal = h.cgcloud__Numeric_Value__c;
                    } else if (h.cgcloud__Classification__c == null) {
                        mainOperator = 'PER';
                        mainNumVal = rewardMap.containsKey(h.Id) ? rewardMap.get(h.Id) : 0;
                    }
                }

                // Evaluate classification hurdles
                for (cgcloud__Promotion_Hurdle__c h : hurdles) {
                    if (!result.rewardFulfilled || h.cgcloud__Classification__c == null) continue;

                    List<Id> productIds = productClassificationIds.get(h.cgcloud__Classification__c);
                    if (productIds == null) continue;

                    for (Id pid : productIds) {
                        if (!orderItemMap.containsKey(pid)) continue;

                        Decimal qty = orderItemMap.get(pid).cgcloud__Quantity__c;
                        Decimal nv = h.cgcloud__Numeric_Value__c;

                        Boolean match =
                            h.cgcloud__Operator__c == 'eq' ? qty == nv :
                            h.cgcloud__Operator__c == 'ge' ? qty >= nv :
                            h.cgcloud__Operator__c == 'le' ? qty <= nv :
                            h.cgcloud__Operator__c == 'gt' ? qty > nv :
                            h.cgcloud__Operator__c == 'lt' ? qty < nv :
                            false;

                        if (!match) {
                            result.rewardFulfilled = false;
                            break;
                        }
                        orderItemQuantities += qty;
                        break;
                    }
                }

                // Final main hurdle check
                if (result.rewardFulfilled) {
                    result.rewardFulfilled =
                        mainOperator == 'eq' ? orderItemQuantities == mainNumVal :
                        mainOperator == 'ge' ? orderItemQuantities >= mainNumVal :
                        mainOperator == 'le' ? orderItemQuantities <= mainNumVal :
                        mainOperator == 'gt' ? orderItemQuantities > mainNumVal :
                        mainOperator == 'lt' ? orderItemQuantities < mainNumVal :
                        mainOperator == 'PER' ? orderItemQuantities >= mainNumVal :
                        false;
                }

                if (!result.rewardFulfilled) {
                    result.rewardHelpText = String.valueOf(mainNumVal - orderItemQuantities);
                }

                results.add(result);
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static List<CriteriaMatchWrapper> rewardCriteriaDiscountWithoutClassification(String promotionId,String orderId) {
        try {
            // Promotion
            cgcloud__Promotion__c promotion = [
                SELECT Id, TPB_Promotion_Type__c
                FROM cgcloud__Promotion__c
                WHERE Id = :promotionId
            ];

            String uom =
                (promotion.TPB_Promotion_Type__c == 'Product Purchase')
                ? 'Each'
                : 'Carton';

            // Reward Groups
            List<cgcloud__Promotion_Reward_Group__c> rewardGroups = [
                SELECT Id, Name
                FROM cgcloud__Promotion_Reward_Group__c
                WHERE cgcloud__Promotion__c = :promotionId AND cgcloud__Included__c = true
            ];

            if (rewardGroups.isEmpty()) {
                return new List<CriteriaMatchWrapper>();
            }

            // Hurdles grouped by Reward Group
            Map<Id, List<cgcloud__Promotion_Hurdle__c>> hurdlesByGroup =
                new Map<Id, List<cgcloud__Promotion_Hurdle__c>>();

            for (cgcloud__Promotion_Hurdle__c h : [
                SELECT Id,cgcloud__Classification__c,
                    cgcloud__Promotion_Reward_Group__c,
                    cgcloud__Operator__c,
                    cgcloud__Numeric_Value__c,
                    cgcloud__Sort__c
                FROM cgcloud__Promotion_Hurdle__c
                WHERE cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c = :promotionId
                ORDER BY cgcloud__Sort__c
            ]) {
                if (!hurdlesByGroup.containsKey(h.cgcloud__Promotion_Reward_Group__c)) {
                    hurdlesByGroup.put(
                        h.cgcloud__Promotion_Reward_Group__c,
                        new List<cgcloud__Promotion_Hurdle__c>()
                    );
                }
                hurdlesByGroup.get(h.cgcloud__Promotion_Reward_Group__c).add(h);
            }

            // Tactic Products → Product Ids
            Set<Id> productIds = new Set<Id>();
            for (cgcloud__Tactic_Product__c tp : [
                SELECT cgcloud__Product__c
                FROM cgcloud__Tactic_Product__c
                WHERE cgcloud__Tactic__r.cgcloud__Promotion__c = :promotionId
            ]) {
                productIds.add(tp.cgcloud__Product__c);
            }

            Id orderItemTemplateId = [
                SELECT Id
                FROM cgcloud__Order_Item_Template__c
                WHERE Name = 'Cash Sale'
            ].Id;

            // Order Items
            Double orderItemQuantities = 0;
            List<cgcloud__Order_Item__c> orderItems = [
                SELECT Id, cgcloud__Quantity__c
                FROM cgcloud__Order_Item__c
                WHERE cgcloud__Order__c = :orderId
                AND cgcloud__Promotion__c = :promotionId
                AND cgcloud__Promoted__c = true
                AND cgcloud__Product__c IN :productIds
                AND cgcloud__Order_Item_Template__c = :orderItemTemplateId
                AND cgcloud__UoM__c = :uom
            ];
            system.debug('orderItems::'+orderItems);
            

            

            

            for (cgcloud__Order_Item__c oi : orderItems) {
                orderItemQuantities += oi.cgcloud__Quantity__c;
            }

            // Final Results
            List<CriteriaMatchWrapper> results = new List<CriteriaMatchWrapper>();

            // Evaluate EACH reward group independently
            for (cgcloud__Promotion_Reward_Group__c rewardGroup : rewardGroups) {

                List<cgcloud__Promotion_Hurdle__c> hurdles =
                    hurdlesByGroup.get(rewardGroup.Id);

                if (hurdles == null || hurdles.isEmpty()) continue;

                CriteriaMatchWrapper criteriaMatch = new CriteriaMatchWrapper();
                criteriaMatch.rewardGroupId = rewardGroup.Id;
                criteriaMatch.promotionType = promotion.TPB_Promotion_Type__c;
                criteriaMatch.rewardFulfilled = true;

                if (orderItems.isEmpty()) {
                    criteriaMatch.rewardFulfilled = false;
                    results.add(criteriaMatch);
                    continue;
                }

                // Evaluate group hurdles
                for (cgcloud__Promotion_Hurdle__c h : hurdles) {
                    if(h.cgcloud__Classification__c == null && h.cgcloud__Operator__c != 'PER'){  
                        String operator = h.cgcloud__Operator__c;
                        Double hurdleValue = h.cgcloud__Numeric_Value__c;

                        Boolean match;

                        switch on operator {
                            when 'eq' {
                                match = orderItemQuantities == hurdleValue;
                            }
                            when 'ge' {
                                match = orderItemQuantities >= hurdleValue;
                            }
                            when 'le' {
                                match = orderItemQuantities <= hurdleValue;
                            }
                            when 'gt' {
                                match = orderItemQuantities > hurdleValue;
                            }
                            when 'lt' {
                                match = orderItemQuantities < hurdleValue;
                            }
                            when 'PER' {
                                match = orderItemQuantities >= hurdleValue;
                            }
                            when else {
                                match = false;
                            }
                        }

                        criteriaMatch.rewardFulfilled =
                            criteriaMatch.rewardFulfilled && match;

                        if (!criteriaMatch.rewardFulfilled) {
                            criteriaMatch.rewardHelpText =
                                String.valueOf(hurdleValue - orderItemQuantities);
                            break;
                        }
                    }
                }

                results.add(criteriaMatch);
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void paperPickUpMethod(){
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    @AuraEnabled
    public static PromotionRewardsHurdles getRewardsAndHurdles(String promotionId) {
        PromotionRewardsHurdles response = new PromotionRewardsHurdles();
        response.rewardGroups = new List<RewardGroupWrapper>();

        // 1️⃣ Get all reward groups for the promotion
        List<cgcloud__Promotion_Reward_Group__c> rewardGroups = [
            SELECT Id, Name
            FROM cgcloud__Promotion_Reward_Group__c
            WHERE cgcloud__Promotion__c = :promotionId AND cgcloud__Included__c = true
            ORDER BY cgcloud__Sort__c
        ];

        if (rewardGroups.isEmpty()) {
            return response;
        }

        Set<Id> rewardGroupIds = new Set<Id>();
        for (cgcloud__Promotion_Reward_Group__c rg : rewardGroups) {
            rewardGroupIds.add(rg.Id);
        }

        // 2️⃣ Fetch hurdles grouped by reward group
        Map<Id, List<cgcloud__Promotion_Hurdle__c>> hurdlesByGroup = new Map<Id, List<cgcloud__Promotion_Hurdle__c>>();
        for (cgcloud__Promotion_Hurdle__c h : [
            SELECT Id,
                cgcloud__Promotion_Reward_Group__c,
                cgcloud__Classification__c,
                cgcloud__Title__c,
                cgcloud__Operation__c,
                cgcloud__Numeric_Value__c,
                cgcloud__Operator__c,
                cgcloud__Sort__c
            FROM cgcloud__Promotion_Hurdle__c
            WHERE cgcloud__Promotion_Reward_Group__c IN :rewardGroupIds
            AND cgcloud__Operator__c != 'PER'
            ORDER BY cgcloud__Sort__c
        ]) {
            if (!hurdlesByGroup.containsKey(h.cgcloud__Promotion_Reward_Group__c)) {
                hurdlesByGroup.put(h.cgcloud__Promotion_Reward_Group__c, new List<cgcloud__Promotion_Hurdle__c>());
            }
            hurdlesByGroup.get(h.cgcloud__Promotion_Reward_Group__c).add(h);
        }

        // 3️⃣ Fetch rewards grouped by reward group
        Map<Id, List<cgcloud__Promotion_Reward__c>> rewardsByGroup = new Map<Id, List<cgcloud__Promotion_Reward__c>>();
        for (cgcloud__Promotion_Reward__c r : [
            SELECT Id,
                cgcloud__Promotion_Reward_Group__c,
                cgcloud__Default_Value__c,
                cgcloud__Title__c,
                cgcloud__Free_Item__c,
                cgcloud__Hurdle__c,
                cgcloud__Included__c,
                cgcloud__Reward_Type__c,
                cgcloud__Sort__c
            FROM cgcloud__Promotion_Reward__c
            WHERE cgcloud__Promotion_Reward_Group__c IN :rewardGroupIds
            ORDER BY cgcloud__Sort__c
        ]) {
            if (!rewardsByGroup.containsKey(r.cgcloud__Promotion_Reward_Group__c)) {
                rewardsByGroup.put(r.cgcloud__Promotion_Reward_Group__c, new List<cgcloud__Promotion_Reward__c>());
            }
            rewardsByGroup.get(r.cgcloud__Promotion_Reward_Group__c).add(r);
        }

        // 4️⃣ Build final response per reward group
        for (cgcloud__Promotion_Reward_Group__c rg : rewardGroups) {
            RewardGroupWrapper groupWrapper = new RewardGroupWrapper();
            groupWrapper.rewardGroupId = rg.Id;
            groupWrapper.rewardGroupName = rg.Name;
            groupWrapper.hurdleList = hurdlesByGroup.get(rg.Id);
            groupWrapper.rewardList = rewardsByGroup.get(rg.Id);

            if (groupWrapper.hurdleList == null) {
                groupWrapper.hurdleList = new List<cgcloud__Promotion_Hurdle__c>();
            }
            if (groupWrapper.rewardList == null) {
                groupWrapper.rewardList = new List<cgcloud__Promotion_Reward__c>();
            }

            response.rewardGroups.add(groupWrapper);
        }

        System.debug('PromotionRewardsHurdles response => ' + response);
        return response;
    }

    @AuraEnabled
    public static List<RewardWrapper> getRewardProductsGratis(String rewardId, String orderId){
        List<RewardWrapper> rewardWrap = new List<RewardWrapper>();
        String templateId = [SELECT
          Id
        FROM cgcloud__Order_Item_Template__c
        WHERE Name='Free Item' LIMIT 1].Id;// 'a4t6T000002kFU6QAM';

        cgcloud__Order__c order = [SELECT ID, cgcloud__Bill_Recipient_Account__r.ShippingState FROM cgcloud__Order__c WHERE ID=: orderId];
                             
        List<cgcloud__Order_Item__c> orderItems = [SELECT Id, cgcloud__Product__c, cgcloud__Quantity__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = : orderId AND cgcloud__Order_Item_Template__c =: templateId];
        Map<Id, cgcloud__Order_Item__c> orderItemMap = new Map<Id, cgcloud__Order_Item__c>();
        for(cgcloud__Order_Item__c orderItem: orderItems){
            orderItemMap.put(orderItem.cgcloud__Product__c, orderItem);
        }
        List<cgcloud__Promotion_Reward_Product__c> rewardProducts =  [SELECT ID, cgcloud__Default_Value__c, cgcloud__Included__c, 
                        cgcloud__Logistic_Unit__c, cgcloud__Max_Value__c, cgcloud__Product__c, 
                        cgcloud__Product_Name__c, cgcloud__Reward_Type__c 
                        FROM cgcloud__Promotion_Reward_Product__c 
                        WHERE cgcloud__Promotion_Reward__c =:rewardId];
        Set<Id> productIds = new Set<Id>();
        for(cgcloud__Promotion_Reward_Product__c rp:    rewardProducts){
            productIds.add(rp.cgcloud__Product__c);
        }
        List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,
                                                   cgcloud__Balance__c  
                                                   FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND cgcloud__product__c IN: productIds AND TPB_Tour_State__c = :order.cgcloud__Bill_Recipient_Account__r.ShippingState]; //AND cgcloud__Tour__c = : visit.Account.ShippingState
        Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
        for(cgcloud__Inventory__c inventory: inventories){
            productInvMap.put(inventory.cgcloud__product__c, inventory);
        }
        for(cgcloud__Promotion_Reward_Product__c rp: rewardProducts){
            RewardWrapper rwp = new RewardWrapper();
            rwp.productId = rp.cgcloud__Product__c;
            rwp.productName = rp.cgcloud__Product_Name__c;
            rwp.inventoryBalance = productInvMap.containsKey(rp.cgcloud__Product__c) ? productInvMap.get(rp.cgcloud__Product__c).cgcloud__Balance__c: 0;
            rwp.rewardProductId = rp.Id;
            rwp.basePrice = productInvMap.containsKey(rp.cgcloud__Product__c) ? productInvMap.get(rp.cgcloud__Product__c).TPB_AvgPrice__c :0;
            rwp.lineItemId = orderItemMap.containsKey(rp.cgcloud__Product__c) ? orderItemMap.get(rp.cgcloud__Product__c).Id : null;
            rwp.lineItemQty = orderItemMap.containsKey(rp.cgcloud__Product__c) ? orderItemMap.get(rp.cgcloud__Product__c).cgcloud__Quantity__c : 0;
            rewardWrap.add(rwp);
        }        
        return rewardWrap;
    }

    @AuraEnabled
    public static Online_App_Custom_Setting__c getCustomSettings(){
        return Online_App_Custom_Setting__c.getOrgDefaults();
    }



    @AuraEnabled
    public static Map<Id, cgcloud__Promotion_Reward_Product__c> getRewardDiscount(String promotionId){ //List<Id> productIds
        try {
            List<cgcloud__Promotion_Reward_Product__c> rewardProducts = [SELECT ID, cgcloud__Default_Value__c, cgcloud__Included__c, 
                        cgcloud__Logistic_Unit__c, cgcloud__Max_Value__c, cgcloud__Product__c, 
                        cgcloud__Product_Name__c, cgcloud__Reward_Type__c 
                        FROM cgcloud__Promotion_Reward_Product__c 
                        WHERE cgcloud__Promotion_Reward__r.cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c =:promotionId AND cgcloud__Promotion_Reward__r.cgcloud__Included__c = true];
            Map<Id, cgcloud__Promotion_Reward_Product__c> rewardProductDiscountMap = new Map<Id, cgcloud__Promotion_Reward_Product__c>();
            for(cgcloud__Promotion_Reward_Product__c pr : rewardProducts){
                // if(productIds.contains(pr.cgcloud__Product__c)){
                    rewardProductDiscountMap.put(pr.cgcloud__Product__c, pr);//
                // }
            }
            system.debug('rewardProductDiscountMap::'+rewardProductDiscountMap);
            return rewardProductDiscountMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    
    @AuraEnabled
    public static void uploadFile(String base64Data, String fileName, Id orderId) {
        if (String.isBlank(base64Data) || String.isBlank(fileName) || orderId == null) {
            throw new AuraHandledException('Missing file data or Order Id.');
        }
        // Decode and upload the file as ContentVersion
        Blob fileBody = EncodingUtil.base64Decode(base64Data);
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = fileBody;
        insert cv;
        // Retrieve ContentDocumentId using ContentVersion
        ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        // Create ContentDocumentLink for Order
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = orderId;
        cdl.ShareType = 'V'; // Viewer access
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

    @AuraEnabled(cacheable=true)
    public static Map<ID, String> getWholesalePromotions(String accountId) {
        Map<ID, String> mapIdTitle = new Map<ID, String>();

        // Get wholesalers
        List<Related_Account__c> relatedWholesalers = [
            SELECT Wholesaler__c 
            FROM Related_Account__c 
            WHERE Retailer__c = :accountId
        ];
            
        Set<Id> wholesalersIds = new Set<Id>();
        for (Related_Account__c ra : relatedWholesalers) {
            if (ra.Wholesaler__c != null) {
                wholesalersIds.add(ra.Wholesaler__c);
            }
        }

        // ⚠️ Only query if you have IDs
        if (!wholesalersIds.isEmpty()) {
            List<ContentDocumentLink> files = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :wholesalersIds
            ];

            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink cdl : files) {
                if (cdl.ContentDocumentId != null) {
                    fileIDs.add(cdl.ContentDocumentId);
                }
            }

            if (!fileIDs.isEmpty()) {
                List<ContentVersion> docs = [
                    SELECT ContentDocumentId, FileExtension, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :fileIDs
                    AND TPB_IsWholesaleInvoice__c = false
                    AND FileExtension IN ('pdf', 'jpg', 'jpeg', 'png', 'docx', 'doc', 'ppt', 'pptx')
                ];

                for (ContentVersion cv : docs) {
                    mapIdTitle.put(cv.ContentDocumentId, cv.Title);
                }
            }
        }

        return mapIdTitle;
    }

    @AuraEnabled(cacheable=true)
    public static Map<ID, String> getChainAccountOverview(String accountId) {
        Map<ID, String> mapIdTitle = new Map<ID, String>();

        List<Account> parentAccounts = [
            SELECT Id, ParentId
            FROM Account 
            WHERE Id = :accountId
        ];
        
        Set<Id> parentAccountIds = new Set<Id>();
        for (Account ra : parentAccounts) {
            if (ra.ParentId != null) {
                parentAccountIds.add(ra.ParentId);
            }
        }

        if (!parentAccountIds.isEmpty()) {
            List<ContentDocumentLink> files = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :parentAccountIds
            ];

            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink cdl : files) {
                if (cdl.ContentDocumentId != null) {
                    fileIDs.add(cdl.ContentDocumentId);
                }
            }

            if (!fileIDs.isEmpty()) {
                List<ContentVersion> docs = [
                    SELECT ContentDocumentId, FileExtension, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :fileIDs
                    AND TPB_IsHQAttachment__c = true
                    AND FileExtension IN ('pdf', 'jpg', 'jpeg', 'png', 'docx', 'doc', 'ppt', 'pptx')
                ];

                for (ContentVersion cv : docs) {
                    mapIdTitle.put(cv.ContentDocumentId, cv.Title);
                }
            }
        }

        return mapIdTitle;
    }

    

    

    public class PromotionRewardsHurdles{
        // @AuraEnabled public List<cgcloud__Promotion_Reward__c> rewardsProgramList;   
        // @AuraEnabled public List<cgcloud__Promotion_Hurdle__c> hurdleList;
        // @AuraEnabled public List<CriteriaMatchWrapper> criteriaMatchList;

        @AuraEnabled public List<RewardGroupWrapper> rewardGroups;
    }
    public class RewardGroupWrapper {
        @AuraEnabled public Id rewardGroupId;
        @AuraEnabled public String rewardGroupName;
        @AuraEnabled public List<cgcloud__Promotion_Hurdle__c> hurdleList;
        @AuraEnabled public List<cgcloud__Promotion_Reward__c> rewardList;
    }
    public class CriteriaMatchWrapper{
        @AuraEnabled public String hurdleName; 
        @AuraEnabled public Boolean rewardFulfilled; 
        @AuraEnabled public String rewardHelpText; 
        @AuraEnabled public String classification;   
        @AuraEnabled public String promotionType;
        @AuraEnabled public String rewardGroupId;
        
    }
    public class ProductWrapper{
        @AuraEnabled public Product2 product;
        @AuraEnabled public Double basePrice;
        @AuraEnabled public Double stockBalance;
        @AuraEnabled public Double suggestedQty;
        @AuraEnabled public Double maxAllocation;
        @AuraEnabled public Double cartonPieces;
        @AuraEnabled public String productSubCategory;
        @AuraEnabled public List<OrderItemWrapper> orderItemList; //added for tactic products
        
    }
    

    public class RewardWrapper{
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Double inventoryBalance;
        @AuraEnabled public String rewardProductId;
        @AuraEnabled public Double basePrice;
        @AuraEnabled public String lineItemId;
        @AuraEnabled public Double lineItemQty;
    }

    public class SuggestedOrderPrebbokWrapper{
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Double price;
        @AuraEnabled public String lineItemId;
        @AuraEnabled public Double lineItemQty;
        @AuraEnabled public Double minQty;
        @AuraEnabled public Double maxQty;
        @auraEnabled public String wholeSalerId;
        @AuraEnabled public String typeId;
        @AuraEnabled public String cgcProductCode;
    }
    
    public class OrderItemWrapper{
        @AuraEnabled public String orderItemId;
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal specialPrice;
        @AuraEnabled public String uom;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal basePrice;
        @AuraEnabled public Double suggestedQty;
        @AuraEnabled public Double cartonPieces;
        @AuraEnabled public String typeId;
        @AuraEnabled public Double maxAllocation;
        @AuraEnabled public Double stockBalance;
        @auraEnabled public String productSubCategory;
        @auraEnabled public Boolean isPromoted;
        @auraEnabled public String wholeSalerId;
        @auraEnabled public Double reimbursableAmount;
        @auraEnabled public String promotionId;
        @auraEnabled public String cgcProductCode;
        @AuraEnabled public String templateName;

         
    }
    
    public class OrderReviewWrapper{
        @AuraEnabled public String orderId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Date orderDate;
        @AuraEnabled public Date deliveryDate;
        @AuraEnabled public Decimal totalValue;
        @AuraEnabled public String orderCurrency;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public Decimal paidAmount;
        @AuraEnabled public Boolean paymentCollected;
        @AuraEnabled public String authorizingAgent;
        @AuraEnabled public String shippingStreet;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingPostalCode;
        @AuraEnabled public String shippingCountry;
        @AuraEnabled public String accountPhone;
        @AuraEnabled public String accountStateTobaccoNumber;
        @AuraEnabled public String accountStateTaxNumber;
        @AuraEnabled public String fein;
    }

    public class ProductDistributionWrapper{
        @AuraEnabled public Boolean visitJob;
        @AuraEnabled public List<ProductDistributionData> productDistributions;
        @AuraEnabled public List<String> productDistributionPicklist;
    }
    public class ProductDistributionData{
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;
        @AuraEnabled public String visitJobId;
        @AuraEnabled public String visitJobAnswer;
        @AuraEnabled public String templateDescription;
        @AuraEnabled public String productSubCategory;
        @AuraEnabled public Boolean isDeletable;

        @AuraEnabled public String visitJobJobDef;
        @AuraEnabled public String visitJobJobDefTemplate;
        @AuraEnabled public String visitJobDataTypeOption;
    }
    public class VisitJobResult {
        @AuraEnabled public Integer insertedCount;
        @AuraEnabled public Integer updatedCount;
        @AuraEnabled public Boolean hasErrors;
        @AuraEnabled public String errorMessage;   // combined, user-readable
    }

    public class PDFWrapper{
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String division;
        @AuraEnabled public String address;
        @AuraEnabled public String serviceTerritory;
        @AuraEnabled public String distributorLicenseNum;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Date invoiceDate;
        @AuraEnabled public Date deliveryDate;
        @AuraEnabled public String licenseNum;
        @AuraEnabled public String otherNTCStateUseTaxNum;
        @AuraEnabled public String ntcStateUseTaxNum;
        @AuraEnabled public String ntcTaxID;
        @AuraEnabled public Double qty;
        @AuraEnabled public Double invoiceTotal;
        @AuraEnabled public String storePhone;
        @AuraEnabled public String storeAddress;
        @AuraEnabled public String storeName;
        @AuraEnabled public String storeStateTobaccoNum;
        @AuraEnabled public String storeStateTaxNum;
        @AuraEnabled public String storefein;
        @AuraEnabled public String otherLicenseNum;
        @AuraEnabled public String terms;
        @AuraEnabled public String stateTax;
        @AuraEnabled public List<cgcloud__Order_Item__c> orderItemsCashSale;
        @AuraEnabled public List<cgcloud__Order_Item__c> orderItemsReturn;
        @AuraEnabled public List<cgcloud__Order_Item__c> orderItemsPrebook;
        
    }
    public class PDFWrapperVF{
        public String orderNumber { get; set; }
        public String division { get; set; }
        public String address { get; set; }
        public String serviceTerritory { get; set; }
        public String distributorLicenseNum { get; set; }
        public String ownerName { get; set; }
        public String licenseNum { get; set; }
        public String ntcStateUseTaxNum { get; set; }
        public String otherNTCStateUseTaxNum { get; set; }
        public Date invoiceDate { get; set; }
        public Date deliveryDate { get; set; }
        public String ntcTaxID { get; set; }
        public String otherLicenseNum { get; set; }
        public String terms { get; set; }
        public String stateTax { get; set; }
        public Decimal invoiceTotal { get; set; }
        public Decimal qty { get; set; }
        
        public String storeName { get; set; }
        public String storeAddress { get; set; }
        public String storePhone { get; set; }
        public String storeStateTobaccoNum { get; set; }
        public String storeStateTaxNum { get; set; }
        public String storefein { get; set; }
        public String distributorLicenceNumber { get; set; }
        public Decimal cashSalesSubtotal { get; set; }
        public Decimal returnSubtotal { get; set; }
        public Decimal cashSalesDiscountTotal { get; set; }
        public Decimal cashSalesQtyTotal { get; set; }
        public Decimal returnQtyTotal { get; set; }
        public Decimal prebookQtyTotal { get; set; }

        public List<cgcloud__Order_Item__c> orderItemsCashSale { get; set; }
        public List<cgcloud__Order_Item__c> orderItemsReturn { get; set; }
        public List<cgcloud__Order_Item__c> orderItemsPrebook { get; set; }
    }


}