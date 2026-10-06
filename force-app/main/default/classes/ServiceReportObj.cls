public inherited sharing class ServiceReportObj {

    @AuraEnabled
    public List<InputObj> inputs;

    public class InputObj {
        @AuraEnabled
        public String entityId;

        @AuraEnabled
        public String templateId;

        @AuraEnabled
        public List<SignatureObj> signatures;
    }

    public class SignatureObj {
        @AuraEnabled
        public String data;

        @AuraEnabled
        public String contentType;

        @AuraEnabled
        public String signatureType;

        @AuraEnabled
        public String signedBy;

        @AuraEnabled
        public String place;
    }

}