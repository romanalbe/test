@isTest
private class ScreeningEmailServiceHandlerTest {
    
    @isTest
    static void testHandleInboundEmail() {
        
        // Create test data
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@example.com';
        //testContact.Email = 'test@example.com';
        //testContact.Phone = '1';
        insert testContact;

        System.assertEquals(true, result.success);
        System.assertNotEquals(true, result.success);

        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Subject';
        testEmail.fromAddress = 'test@example.com';
        testEmail.fromName = 'Test Sender';
        testEmail.plainTextBody = 'Test Email Body';
        testEmail.htmlBody = '<p>Test Email HTML Body</p>';
        testEmail.ccAddresses = new List<String>{'test2@example.com', 'test2@example.com'};
        
        Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();

        Test.startTest();//
        Test.startTest();//


        ScreeningEmailServiceHandler emailHandler = new ScreeningEmailServiceHandler();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(testEmail, testEnvelope);

        System.assertEquals(true, result.success);
        
        List<EmailMessage> createdEmailMessages = [SELECT Subject, HtmlBody, FromAddress, FromName, ToAddress FROM EmailMessage];
        System.assertEquals(1, createdEmailMessages.size());
        EmailMessage createdEmailMessage = createdEmailMessages[0];
        System.assertEquals('Test Subject', createdEmailMessage.Subject);
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress);
        System.assertEquals('irapscreeningteam@refugeerights.org', createdEmailMessage.ToAddress);
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleInboundEmail_ContactCreation() {

        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Subject';
        testEmail.fromAddress = 'test@example.com';
        testEmail.fromName = 'Test Sender';
        testEmail.plainTextBody = 'Test Email Body';
        testEmail.htmlBody = '<p>Test Email HTML Body</p>';
        
        Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        
        ScreeningEmailServiceHandler emailHandler = new ScreeningEmailServiceHandler();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(testEmail, testEnvelope);

        System.assertEquals(true, result.success);
        

        List<Contact> createdContacts = [SELECT LastName, Email, Contact_to_review__c FROM Contact];
        System.assertEquals(1, createdContacts.size());
        Contact createdContact = createdContacts[0];
        System.assertEquals('Test Sender', createdContact.LastName);
        System.assertEquals('test@example.com', createdContact.Email);
        System.assertEquals(true, createdContact.Contact_to_review__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleInboundEmail_Attachments() {

        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Subject';
        testEmail.fromAddress = 'test@example.com';
        testEmail.fromName = 'Test Sender';
        testEmail.plainTextBody = 'Test Email Body';
        testEmail.htmlBody = '<p>Test Email HTML Body</p>';
        
        Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
        
        // Create binary attachments
        Messaging.InboundEmail.BinaryAttachment attachment1 = new Messaging.InboundEmail.BinaryAttachment();
        attachment1.fileName = 'Attachment 1.txt';
        attachment1.body = Blob.valueOf('Test Attachment 1');
        
        Messaging.InboundEmail.BinaryAttachment attachment2 = new Messaging.InboundEmail.BinaryAttachment();
        attachment2.fileName = 'Attachment 2.txt';
        attachment2.body = Blob.valueOf('Test Attachment 2');
        
        testEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{ attachment1, attachment2 };

        Test.startTest();
        
        ScreeningEmailServiceHandler emailHandler = new ScreeningEmailServiceHandler();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(testEmail, testEnvelope);
        
        System.assertEquals(true, result.success);
    
        
        Test.stopTest();
    }
    @isTest 
    static void testSendErrorMailScenario() {

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.htmlBody = '<p>Test Email HTML Body</p>';


        Test.startTest();

        //ScreeningEmailServiceHandler.sendErrroMail('error message', email);
        
        Test.stopTest();

    }


    @isTest 
    static void testContactNotFullyScreeningsScenario() {

        Contact testContact = new Contact(Email = 'test@example.com', LastName = 'Test');
        insert testContact;

        Screening__c testScreening = new Screening__c(Status__c = 'Completed', 
                                                        Date_Completed__c = Date.Today(), 
                                                        Potential_Client__c = testContact.Id,
                                                        Screening_Office__c = 'US Legal');
        insert testScreening;


        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.htmlBody = '<p>Test Email HTML Body</p>';

        ScreeningEmailServiceHandler handler = new ScreeningEmailServiceHandler();
        handler.handleInboundEmail(email, new Messaging.InboundEnvelope());

    }

    @isTest 
    static void testContactFullyCompletedScreeningsScenario() {

        Contact testContact = new Contact(Email = 'test@example.com', LastName = 'Test');
        insert testContact;

        Screening__c testScreening = new Screening__c(Status__c = 'Completed', 
                                                        Date_Completed__c = Date.Today()-15, 
                                                        Potential_Client__c = testContact.Id,
                                                        Screening_Office__c = 'US Legal');
        Insert testScreening;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.htmlBody = '<p>Test Email HTML Body</p>';

        ScreeningEmailServiceHandler handler = new ScreeningEmailServiceHandler();
        handler.handleInboundEmail(email, new Messaging.InboundEnvelope());

    }
 
    @isTest
    static void testEmailHandlerScenarios() {
        //Create a Contact
        Contact testContact = new Contact(FirstName='John', LastName='Doe', Email='john.doe@example.com');
        insert testContact;

        // Scenario 1: Screening is not Completed and is not Fully Closed
        Screening__c screening1 = new Screening__c(Status__c = 'New Request (To be Assigned)', 
                                                    Screening_Office__c = 'US Legal',
                                                    Potential_Client__c = testContact.Id);
        insert screening1;

        EmailMessage emailMessage1 = new EmailMessage(FromAddress='john.doe@example.com', relatedToId=screening1.Id, MessageIdentifier='12345', Status='0');
        insert emailMessage1;

        Messaging.InboundEmail email1 = new Messaging.InboundEmail();
        email1.fromAddress = 'john.doe@example.com';
        email1.htmlBody = '<p>Test Email HTML Body</p>';
        email1.messageId = '12345';
        email1.inReplyTo = '12345';

        ScreeningEmailServiceHandler handler = new ScreeningEmailServiceHandler();
        handler.handleInboundEmail(email1, new Messaging.InboundEnvelope());

        // Scenario 2: Screening is Completed but not Fully Closed
        Screening__c screening2 = new Screening__c(Status__c = 'Completed', 
                                            Date_Completed__c = Date.Today(), 
                                            Screening_Office__c = 'US Legal',
                                            Potential_Client__c = testContact.Id);
        insert screening2;

        EmailMessage emailMessage2 = new EmailMessage(FromAddress='john.doe@example.com', relatedToId=screening2.Id, MessageIdentifier='67890', Status='0');
        insert emailMessage2;

        Messaging.InboundEmail email2 = new Messaging.InboundEmail();
        email2.fromAddress = 'john.doe@example.com';
        email2.htmlBody = '<p>Test Email HTML Body</p>';
        email2.messageId = '67890';
        email2.inReplyTo = '67890';

        ScreeningEmailServiceHandler handler2 = new ScreeningEmailServiceHandler();
        handler2.handleInboundEmail(email2, new Messaging.InboundEnvelope());

        // Scenario 3: Screening is Completed and Fully Closed
        Screening__c screening3 = new Screening__c(Status__c = 'Completed', 
                                                    Date_Completed__c = Date.Today()-15, 
                                                    Screening_Office__c = 'US Legal',
                                                    Potential_Client__c = testContact.Id);
        
        insert screening3;

        EmailMessage emailMessage3 = new EmailMessage(FromAddress = 'john.doe@example.com', relatedToId = screening3.Id, MessageIdentifier='11223', Status='0');
        insert emailMessage3;
        
        Messaging.InboundEmail email3 = new Messaging.InboundEmail();
        email3.fromAddress = 'john.doe@example.com';
        email3.htmlBody = '<p>Test Email HTML Body</p>';
        email3.messageId = '11223';
        email3.inReplyTo = '11223';

        ScreeningEmailServiceHandler handler3 = new ScreeningEmailServiceHandler();
        handler3.handleInboundEmail(email3, new Messaging.InboundEnvelope());

        Messaging.InboundEmail email3 = new Messaging.InboundEmail();
        email3.fromAddress = 'john.doe@example.com';
        email3.htmlBody = '<p>Test Email HTML Body</p>';
        email3.messageId = '11223';
        email3.inReplyTo = '11223';

        ScreeningEmailServiceHandler handler3 = new ScreeningEmailServiceHandler();
        handler3.handleInboundEmail(email3, new Messaging.InboundEnvelope());

    }

    @isTest
    static void testEmailHandlerScenariosAdditional() {
//
    }


}
