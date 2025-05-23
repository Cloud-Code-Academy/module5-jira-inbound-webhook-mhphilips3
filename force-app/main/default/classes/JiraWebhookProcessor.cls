/**
 * @description Processor for Jira webhooks
 * Handles issue and project events from Jira
 * 
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 * 
 * @author Malcolm Philips
 */
public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
    
    // Constants for webhook event types
    private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
    private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
    private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
    private static final String EVENT_PROJECT_CREATED = 'project_created';
    private static final String EVENT_PROJECT_UPDATED = 'project_updated';
    private static final String EVENT_PROJECT_DELETED = 'project_deleted';
    
    /**
     * @description Validates the incoming Jira webhook request
     * @param request The REST request containing the webhook payload
     * @return Boolean True if the request is valid, false otherwise
     * 
     * STUDENT TASK:
     * Implement validation logic for Jira webhooks
     * - Check for valid JSON by deserializing the request body
     * - Verify the 'webhookEvent' field exists in the payload
     * - You can add further validation like checking for specific headers
     * - Return true if valid, false otherwise
     * 
     * HINT:
     * 1. Use try-catch to handle JSON deserialization errors
     * 2. Cast the deserialized JSON to Map<String, Object>
     * 3. Check if required keys exist using containsKey()
     * 4. Example: if (!payload.containsKey('webhookEvent')) { return false; }
     */
    public Boolean validate(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            return payload.containsKey('webhookEvent');

        } catch (Exception e) {
            // Log the error and return false
            System.debug(LoggingLevel.ERROR, 'Error validating webhook: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Processes the Jira webhook request
     * @param request The REST request containing the webhook payload
     * 
     * STUDENT TASK:
     * Implement the main processing logic
     * - Parse the JSON payload from the request body
     * - Extract the 'webhookEvent' field to determine the event type
     * - Call the appropriate handler method based on the event type
     * 
     * HINT:
     * 1. Use JSON.deserializeUntyped() to convert the request body to a Map
     * 2. Extract the event type: String webhookEvent = (String) payload.get('webhookEvent');
     * 3. Use if/else or switch statements to call the appropriate handler
     * 4. Example: if (webhookEvent == EVENT_ISSUE_CREATED) { processIssueCreated(payload); }
     */
    public void process(RestRequest request) {
        try {

            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String webhookEvent = (String) payload.get('webhookEvent');

            if (webhookEvent == EVENT_ISSUE_CREATED) {
                processIssueCreated(payload);
            } else if (webhookEvent == EVENT_ISSUE_UPDATED) {
                processIssueUpdated(payload);
            } else if (webhookEvent == EVENT_ISSUE_DELETED) {
                processIssueDeleted(payload);
            } else if (webhookEvent == EVENT_PROJECT_CREATED) {
                processProjectCreated(payload);
            } else if (webhookEvent == EVENT_PROJECT_UPDATED) {
                processProjectUpdated(payload);
            } else if (webhookEvent == EVENT_PROJECT_DELETED) {
                processProjectDeleted(payload);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing webhook: ' + e.getMessage());
            throw e; // Re-throw to let the caller handle it
        }
    }
    
    /**
     * @description Process an issue_created event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Use this example as a template for other event handlers
     */
    private void processIssueCreated(Map<String, Object> payload) {

        try {
            // Example implementation:
            
            // 1. Extract issue data from the payload
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            
            // 2. Create a new Jira_Issue__c record using the helper method
            Jira_Issue__c newIssue = createIssueRecord(issueData);

            // Set context flag to avoid trigger recursion
            JiraWebhookContext.isWebhookContext = true;
            
            // 3. Insert the new record
            insert newIssue;
            
            // 4. Log success
            System.debug('Created Jira issue record: ' + newIssue.Id);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_created event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Process an issue_updated event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Implement logic to update an existing Jira_Issue__c record
     * If the record doesn't exist, create it
     */
    private void processIssueUpdated(Map<String, Object> payload) {
        
        try{
            // Get issue data
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            // Update issue using helper method
            Jira_Issue__c issueToUpdate = updateIssueRecord(issueData);

            // Set context flag to avoid trigger recursion
            JiraWebhookContext.isWebhookContext = true;

            // Upsert issue record
            upsert issueToUpdate Issue_Key__c;
            // Log success message
            System.debug('Updated Jira issue record: ' + issueToUpdate.Id);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_updated event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Process an issue_deleted event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Implement logic to delete a Jira_Issue__c record
     */
    private void processIssueDeleted(Map<String, Object> payload) {
        
        try{
            // Get issue data
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            // Check for existing issue
            String issueKey = (String) issueData.get('key');
        
            List<Jira_Issue__c> existingIssues = [SELECT Id FROM Jira_Issue__c WHERE Issue_Key__c = :issueKey LIMIT 1];
            if (existingIssues == null){
                return;
            }
            
            // Delete issue record
            delete existingIssues[0]; 
            // Log success message
            System.debug('Deleted Jira issue record: ' + existingIssues[0].Id);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_deleted event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Process a project_created event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Implement logic to create a Jira_Project__c record
     */
    private void processProjectCreated(Map<String, Object> payload) {
        
        try{
            // Get project data
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');

            // Create project record
            Jira_Project__c project = createProjectRecord(projectData);

            // Set context flag to avoid trigger recursion
            JiraWebhookContext.isWebhookContext = true;

            // Insert project record
            insert project;

            // Log success message
            System.debug('Created Jira project record: ' + project.Id);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_created event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Process a project_updated event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Implement logic to update an existing Jira_Project__c record
     * If the record doesn't exist, create it
     */
    private void processProjectUpdated(Map<String, Object> payload) {
        
        try{
            // Get project data
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            // Build project record
            Jira_Project__c project = updateProjectRecord(projectData);

            // Set context flag to avoid trigger recursion
            JiraWebhookContext.isWebhookContext = true;

            // Upsert project record
            upsert project Project_Key__c;
            // Log success message
            System.debug('Updated Jira project record: ' + project.Id);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_updated event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Process a project_deleted event
     * @param payload The webhook payload
     * 
     * STUDENT TASK:
     * Implement logic to delete a Jira_Project__c record
     */
    private void processProjectDeleted(Map<String, Object> payload) {

                try{
            // Get project data
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');

            // Check for existing project
            String projectId = String.valueOf(projectData.get('id'));
        
            List<Jira_Project__c> existingProjects = [SELECT Id FROM Jira_Project__c WHERE Project_ID__c = :projectId LIMIT 1];
            if (existingProjects == null){
                return;
            }
            
            // Delete project record
            delete existingProjects[0];

            // Log success message
            System.debug('Deleted Jira project record: ' + existingProjects[0].Id);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_created event: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Create a Jira_Issue__c record from issue data
     * @param issueData The issue data from the webhook
     * @return Jira_Issue__c The newly created issue record
     * 
     * STUDENT TASK:
     * Implement logic to extract issue fields and create a record
     * 
     * HINT:
     * 1. Extract data from the issueData map (key, summary, status, etc.)
     * 2. Map the fields to a new Jira_Issue__c record
     */
    private Jira_Issue__c createIssueRecord(Map<String, Object> issueData) {

        // Extract component maps
        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        Map<String, Object> project = (Map<String, Object>) fields.get('project');
        Map<String, Object> status = (Map<String, Object>) fields.get('status');
        Map<String, Object> issueType = (Map<String, Object>) fields.get('issuetype');
        
        Jira_Issue__c issue = new Jira_Issue__c();
        issue.Issue_Key__c = (String) issueData.get('key');
        issue.Summary__c = (String) fields.get('summary');
        issue.Name = (String) fields.get('summary');
        issue.Project_Key__c = project != null ? (String) project.get('key') : null;
        issue.Description__c = (String) fields.get('description') != null ? (String) fields.get('description') : null;
        issue.Status__c = status != null ? (String)status.get('name') : null;
        issue.Issue_Type__c = issueType != null ? (String) issueType.get('name') : null;
        
        // Add other fields as needed
        if (project !=null){
            List<Jira_Project__c> relatedProject = [SELECT Id FROM Jira_Project__c WHERE Project_ID__c = :(String.valueOf(project.get('id'))) LIMIT 1];
            if (!relatedProject.isEmpty()){
                issue.Jira_Project__c = relatedProject[0].Id;        
            }
        }
        
        return issue;
    }
    
    /**
     * @description Update a Jira_Issue__c record from issue data
     * @param existingIssue The existing issue record
     * @param issueData The updated issue data from the webhook
     * @return Jira_Issue__c The updated issue record
     * 
     * STUDENT TASK:
     * Implement logic to extract issue fields and update a record
     */
    private Jira_Issue__c updateIssueRecord(Map<String, Object> issueData) {
        
        // Extract component maps
        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        Map<String, Object> status = (Map<String, Object>) fields.get('status');
        Map<String, Object> issueType = (Map<String, Object>) fields.get('issuetype');

        // Check for existing issue
        String issueKey = (String) issueData.get('key');
        
        List<Jira_Issue__c> existingIssues = [SELECT Id, Issue_Key__c FROM Jira_Issue__c WHERE Issue_Key__c = :issueKey LIMIT 1];
        if (existingIssues.isEmpty()){
            return createIssueRecord(issueData); // use create record if no issue is found
        }

        // update existing issue
        Jira_Issue__c issue = existingIssues[0];
        if (fields.containsKey('summary')){
            issue.Summary__c = (String) fields.get('summary');
            issue.Name = issue.Summary__c;
        }

        if (fields.containsKey('description')){
            issue.Description__c = (String) fields.get('description');
        }

        if (status != null){
            issue.Status__c = (String) status.get('name');
        }

        if (issueType != null){
            issue.Issue_Type__c = (String) issueType.get('name');
        }
        
        return issue;
    }
    
    /**
     * @description Create a Jira_Project__c record from project data
     * @param projectData The project data from the webhook
     * @return Jira_Project__c The newly created project record
     * 
     * STUDENT TASK:
     * Implement logic to extract project fields and create a record
     */
    private Jira_Project__c createProjectRecord(Map<String, Object> projectData) {

        Jira_Project__c project = new Jira_Project__c();
        project.Name = (String) projectData.get('name');
        project.Project_Name__c = (String) projectData.get('name');
        project.Project_ID__c = String.valueOf(projectData.get('id'));
        project.Project_Key__c = (String) projectData.get('key');
        project.Description__c = (String) projectData.get('description');

        return project;
    }
    
    /**
     * @description Update a Jira_Project__c record from project data
     * @param existingProject The existing project record
     * @param projectData The updated project data from the webhook
     * @return Jira_Project__c The updated project record
     * 
     * STUDENT TASK:
     * Implement logic to extract project fields and update a record
     */
    private Jira_Project__c updateProjectRecord(Map<String, Object> projectData) {

        // Check for existing project
        String projectId = String.valueOf(projectData.get('id'));
        
        List<Jira_Project__c> existingProjects = [SELECT Id, Project_ID__c, Project_Key__c FROM Jira_Project__c WHERE Project_ID__c = :projectId LIMIT 1];
        if (existingProjects.isEmpty()){
            return createProjectRecord(projectData); // use create record if no project is found
        }

        // update existing project
        Jira_Project__c project = existingProjects[0];
        if (projectData.containsKey('name')){
            project.Name = (String) projectData.get('name');
            project.Project_Name__c = project.Name;
        }

        if (projectData.containsKey('description')){
            project.Description__c = (String) projectData.get('description');
        }
        
        return project;
    }    
} 