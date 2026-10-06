public class MockHttpServiceReport implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);

        return response;
    }

}