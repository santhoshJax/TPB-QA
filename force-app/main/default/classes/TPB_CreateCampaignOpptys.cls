public with sharing class TPB_CreateCampaignOpptys {
    
    @InvocableMethod(label='TPB_CreateCampaignOpptys' category='Campaign' description='Creates Opportunities + Products from Campaign members - idempotent by Account')
    public static void createOppAndOppProd(List<InputParameters> inputs) {
        if (inputs == null || inputs.isEmpty()) return;
        InputParameters input = inputs[0];
        
        if (input.campaignId == null || String.isBlank(input.recordTypeId)) return;
        
        createOppsAsync(input.campaignId, input.recordTypeId);
    }
    
    @future
    public static void createOppsAsync(Id campaignId, String recordTypeId) {
        try {
            // 1. Get Campaign details
            Campaign camp = [ SELECT Id, Name, Type, StartDate, EndDate, OwnerId  FROM Campaign WHERE Id = :campaignId LIMIT 1 ];
            
            if (camp == null) return;
            
            // 2. Get all existing Opps for this Campaign (to enforce idempotency)
            Map<Id, Opportunity> existingOppsByAccount = new Map<Id, Opportunity>();
            for (Opportunity opp : [ SELECT Id, AccountId  FROM Opportunity WHERE CampaignId = :campaignId AND AccountId != null and (StageName!='Closed Won' OR StageName!='Closed Lost' )])
                  // Optional: AND TPB_Created_by_Campaign__c = true  (if you want stricter filter)
             {
                existingOppsByAccount.put(opp.AccountId, opp);
            }
            
            Integer skippedCount = existingOppsByAccount.size();
            
            // 3. Collect unique Accounts from Campaign Members
            Set<Id> accountIdsFromMembers = new Set<Id>();
            Map<Id, Id> contactToAccountMap = new Map<Id, Id>(); // for resolving Contact → Account
            
            List<CampaignMember> members = [ SELECT Id, AccountId, ContactId, LeadId, Lead.Company 
                                            FROM CampaignMember WHERE CampaignId = :campaignId ];
            
            for (CampaignMember cm : members) {
                if (cm.AccountId != null) {
                    accountIdsFromMembers.add(cm.AccountId);
                } else if (cm.ContactId != null) {
                    contactToAccountMap.put(cm.ContactId, null); // will query later
                }
                // Lead-only → skip or handle separately if no Account required
            }
            
            // Resolve Contact → Account
            if (!contactToAccountMap.isEmpty()) {
                for (Contact con : [ SELECT Id, AccountId  FROM Contact  WHERE Id IN :contactToAccountMap.keySet() 
                      AND AccountId != null ]) 
                {
                    accountIdsFromMembers.add(con.AccountId);
                    contactToAccountMap.put(con.Id, con.AccountId);
                }
            }
            
            // 4. Filter only net-new Accounts
            List<Id> newAccountIds = new List<Id>();
            for (Id accId : accountIdsFromMembers) {
                if (!existingOppsByAccount.containsKey(accId)) {
                    newAccountIds.add(accId);
                }
            }
            
            if (newAccountIds.isEmpty()) {
                System.debug('No new Accounts to process for Campaign ' + campaignId);
                return;
            }
            
            // 5. Query needed Account + Owner info
            Map<Id, Account> accountsMap = new Map<Id, Account>([ SELECT Id, Name, OwnerId, Owner.IsActive FROM Account 
                                                                 WHERE Id IN :newAccountIds ]);
            
            // 6. Create Opportunities for new Accounts only
            List<Opportunity> newOpps = new List<Opportunity>();
            for (Id accId : newAccountIds) {
                Account acc = accountsMap.get(accId);
                if (acc == null) continue;   
                System.debug('79 acc :'+acc);
                System.debug('79 camp :'+camp);
				String OppName  = 'Camp ' + camp.Id + ' - ' + (acc.Name != null ? acc.Name.abbreviate(100) : 'Account') + (String.isNotBlank(camp.Type) ? ' (' + camp.Type + ')' : '');
				System.debug('82 OppName :'+OppName)              ;
                Opportunity opp = new Opportunity(
                    AccountId                  = accId,
                    CampaignId                 = campaignId,
                    RecordTypeId               = recordTypeId,
                    Type                       = camp.Type,                    // <-- as requested
                    Name                       = OppName,
                    StageName                  = 'Prospecting',
                    CloseDate                  = camp.EndDate != null ? camp.EndDate : Date.today().addDays(90),
                    TPB_Start_Date__c          = camp.StartDate,
                    TPB_Origin__c              = 'Auto-created by Campaign',
                    TPB_Created_by_Campaign__c = true,
                    TPB_Created_by_Admin__c    = false,
                    TPB_Created_by_Self__c     = false,
                    OwnerId                    = acc.OwnerId

                );
                newOpps.add(opp);
            }
            
            if (!newOpps.isEmpty()) {
                insert newOpps;
                
                Set<Id> createdOppIds = new Map<Id, Opportunity>(newOpps).keySet();
                createOppProductsForNewOpps(campaignId, createdOppIds);
                
                System.debug('Created ' + newOpps.size() + ' new Opportunities | Skipped ' + skippedCount + ' existing for Campaign ' + campaignId);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in TPB_CreateCampaignOpptys for Campaign ' + campaignId + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
            // → Add Platform Event / Custom Log object insert here in production
        }
    }
    
    private static void createOppProductsForNewOpps(Id campaignId, Set<Id> newOppIds) {
        if (newOppIds.isEmpty()) return;
        
        // Get Campaign Products
        List<TPB_Campaign_Product__c> campProds = [ SELECT Id, TPB_Product__c   FROM TPB_Campaign_Product__c 
                                                   WHERE TPB_Campaign__c = :campaignId ];
        
        if (campProds.isEmpty()) return;
        
        // Create line items only for new Opps
        List<TPB_Opportunity_Product__c> lineItems = new List<TPB_Opportunity_Product__c>();
        
        for (Id oppId : newOppIds) {
            for (TPB_Campaign_Product__c cp : campProds) {
                TPB_Opportunity_Product__c oli = new TPB_Opportunity_Product__c( TPB_Opportunity__c = oppId, TPB_Product__c     = cp.TPB_Product__c );
                // Name is not set → assume auto-number / formula or leave blank
                lineItems.add(oli);
            }
        }
        
        if (!lineItems.isEmpty()) {
            insert lineItems; // Consider Database.insert with partial success + logging
            System.debug('Created ' + lineItems.size() + ' Opportunity Products');
        }
    }
    
    public class InputParameters {
        @InvocableVariable(required=true description='Campaign Id')
        public Id campaignId;
        
        @InvocableVariable(required=true description='Opportunity Record Type Id')
        public String recordTypeId;
        
        @InvocableVariable(required=false description='Opportunities to deactivate/close')
        public List<Opportunity> oppsToDeactivate;
        
        // oppsToDeactivate removed - not used in current idempotent create logic
    }
}