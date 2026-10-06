public inherited sharing class ServiceReportCalloutHelper {

   /* public static HttpResponse callout(Id workOrderId, String templateId, String token, String signedBy, String signature, String note) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();

        ServiceReportObj.SignatureObj signatureObj = new ServiceReportObj.SignatureObj();
        //Encoded signature
        signatureObj.data = signature;
        signatureObj.contentType = 'image/png';
        signatureObj.signatureType = 'Store Rep';
        signatureObj.signedBy = signedBy;
        signatureObj.place = note;

        ServiceReportObj.InputObj input = new ServiceReportObj.InputObj();
        input.entityId = workOrderId;
        input.templateId = templateId;
        input.signatures = new List<ServiceReportObj.SignatureObj>();
        input.signatures.add(signatureObj);

        ServiceReportObj srObj = new ServiceReportObj();
        srObj.inputs = new List<ServiceReportObj.InputObj>();
        srObj.inputs.add(input);

        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v50.0/actions/standard/createServiceReport/';
        String body = JSON.serialize(srObj);

        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        system.debug(body);

        return http.send(request);
    } */

}