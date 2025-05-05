/**
 * @description REST resource to handle incoming webhooks from various systems
 * Current implementation supports Jira webhooks at /webhook/jira
 *  
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 * 
 * @author Malcolm Philips
 */
@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
    
    /**
     * @description Handles POST requests from webhooks
     * @return Returns a simple success response
     * 
     * STUDENT TASK:
     * Implement this method to:
     * 1. Get the REST request and response objects
     * 2. Extract the webhook type from the URL path using getWebhookTypeFromPath
     * 3. Process the webhook using WebhookFactory.processWebhook
     * 4. Return an appropriate ResponseWrapper
     * 5. Add error handling using try-catch
     */
    @HttpPost
    global static ResponseWrapper doPost() {

        // Get REST request and response objects
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try{            
            // Extract webhook's URI (what comes after .../apexrest in URL)
            String webhookType = getWebhookTypeFromPath(request.requestURI);
            System.debug('webhookType: ' + webhookType);

            // Process the webhook if successful, return success message
            WebhookFactory.processWebhook(webhookType, request);

            return new ResponseWrapper('success', 'Webhook processed successfully');
        } catch (Exception e) {
            return new ResponseWrapper('error', e.getMessage());
        }
    }
        
    
    /**
     * @description Extracts the webhook type from the URL path
     * @param path The request URI
     * @return The webhook type (e.g., "jira")
     */
    private static String getWebhookTypeFromPath(String path) {
        
        // Expected formats: /webhook/jira or /services/apexrest/webhook/jira
        if (path == null) {
            return '';
        }
        
        // Look for the webhook segment in the path
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            // Extract the part after /webhook/
            String remaining = path.substring(webhookIndex + 9);
            
            // If there are additional slashes, only take the first segment
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            
            return remaining.toLowerCase();
        }
        
        return '';
    }
    
    /**
     * @description Response wrapper class for consistent response format
     */
    global class ResponseWrapper {
        public String status;
        public String message;
        
        public ResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
} 