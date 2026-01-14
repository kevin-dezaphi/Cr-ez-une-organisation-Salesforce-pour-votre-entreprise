@isTest
private class OpportunityLineItemTableControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Création du Pricebook standard
        Id pricebookId = Test.getStandardPricebookId();
        
        // Création d'un compte
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Création d'une opportunité
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert testOpportunity;
        
        // Création de produits
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Product With Sufficient Stock',
                IsActive = true,
                QuantityInStock__c = 100
            ),
            new Product2(
                Name = 'Product With Insufficient Stock',
                IsActive = true,
                QuantityInStock__c = 5
            ),
            new Product2(
                Name = 'Product With No Stock',
                IsActive = true,
                QuantityInStock__c = 0
            )
        };
        insert products;
        
        // Création des PricebookEntry pour chaque produit
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 product : products) {
            pricebookEntries.add(new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = pricebookId,
                UnitPrice = 100.00,
                IsActive = true
            ));
        }
        insert pricebookEntries;
        
        // Création des OpportunityLineItem
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = testOpportunity.Id,
                PricebookEntryId = pricebookEntries[0].Id,
                Quantity = 10,
                UnitPrice = 100.00
            ),
            new OpportunityLineItem(
                OpportunityId = testOpportunity.Id,
                PricebookEntryId = pricebookEntries[1].Id,
                Quantity = 20,
                UnitPrice = 100.00
            ),
            new OpportunityLineItem(
                OpportunityId = testOpportunity.Id,
                PricebookEntryId = pricebookEntries[2].Id,
                Quantity = 15,
                UnitPrice = 100.00
            )
        };
        insert lineItems;
    }
    
    @isTest
    static void testGetOpportunityLineItem_WithValidData() {
        // Récupération de l'opportunité créée dans le setup
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results = 
            OpportunityLineItemTableController.getOpportunityLineItem(testOpportunity.Id);
        Test.stopTest();
        
        // Assertions
        Assert.areNotEqual(null, results, 'La liste ne devrait pas être nulle');
        Assert.areEqual(3, results.size(), 'Devrait retourner 3 lignes de produits');
        
        // Vérification des champs d'un wrapper
        OpportunityLineItemTableController.OpportunityLineItemWrapper firstWrapper = results[0];
        Assert.areNotEqual(null, firstWrapper.opportunityLineItemId, 'L\'ID du line item ne devrait pas être nul');
        Assert.areNotEqual(null, firstWrapper.productId, 'L\'ID du produit ne devrait pas être nul');
        Assert.areNotEqual(null, firstWrapper.productName, 'Le nom du produit ne devrait pas être nul');
        Assert.areNotEqual(null, firstWrapper.unitPrice, 'Le prix unitaire ne devrait pas être nul');
        Assert.areNotEqual(null, firstWrapper.totalPrice, 'Le prix total ne devrait pas être nul');
        Assert.areNotEqual(null, firstWrapper.quantity, 'La quantité ne devrait pas être nulle');
        Assert.areNotEqual(null, firstWrapper.quantityInStock, 'La quantité en stock ne devrait pas être nulle');
        Assert.areNotEqual(null, firstWrapper.colorQuantity, 'La couleur ne devrait pas être nulle');
    }
    
    @isTest
    static void testGetOpportunityLineItem_WithSufficientStock() {
        // Récupération du line item avec stock suffisant
        OpportunityLineItem lineItemWithSufficientStock = [
            SELECT OpportunityId 
            FROM OpportunityLineItem 
            WHERE Quantity = 10 
            LIMIT 1
        ];
        
        Test.startTest();
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results = 
            OpportunityLineItemTableController.getOpportunityLineItem(lineItemWithSufficientStock.OpportunityId);
        Test.stopTest();
        
        // Recherche du wrapper correspondant
        OpportunityLineItemTableController.OpportunityLineItemWrapper wrapperWithSufficientStock;
        for (OpportunityLineItemTableController.OpportunityLineItemWrapper wrapper : results) {
            if (wrapper.quantity == 10) {
                wrapperWithSufficientStock = wrapper;
                break;
            }
        }
        
        // Assertions
        Assert.areNotEqual(null, wrapperWithSufficientStock, 'Le wrapper devrait exister');
        Assert.areEqual('slds-text-color_success', wrapperWithSufficientStock.colorQuantity, 
            'La couleur devrait être success car le stock est suffisant');
        System.assert(wrapperWithSufficientStock.quantity <= wrapperWithSufficientStock.quantityInStock, 
            'La quantité commandée devrait être inférieure ou égale au stock');
    }
    
    @isTest
    static void testGetOpportunityLineItem_WithInsufficientStock() {
        // Récupération du line item avec stock insuffisant
        OpportunityLineItem lineItemWithInsufficientStock = [
            SELECT OpportunityId 
            FROM OpportunityLineItem 
            WHERE Quantity = 20 
            LIMIT 1
        ];
        
        Test.startTest();
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results = 
            OpportunityLineItemTableController.getOpportunityLineItem(lineItemWithInsufficientStock.OpportunityId);
        Test.stopTest();
        
        // Recherche du wrapper correspondant
        OpportunityLineItemTableController.OpportunityLineItemWrapper wrapperWithInsufficientStock;
        for (OpportunityLineItemTableController.OpportunityLineItemWrapper wrapper : results) {
            if (wrapper.quantity == 20) {
                wrapperWithInsufficientStock = wrapper;
                break;
            }
        }
        
        // Assertions
        Assert.areNotEqual(null, wrapperWithInsufficientStock, 'Le wrapper devrait exister');
        Assert.areEqual('slds-text-color_error slds-theme_error', wrapperWithInsufficientStock.colorQuantity, 
            'La couleur devrait être error car le stock est insuffisant');
        System.assert(wrapperWithInsufficientStock.quantity > wrapperWithInsufficientStock.quantityInStock, 
            'La quantité commandée devrait être supérieure au stock');
    }
    
    @isTest
    static void testGetOpportunityLineItem_WithNoLineItems() {
        // Création d'une nouvelle opportunité sans line items
        Account newAccount = new Account(Name = 'New Account');
        insert newAccount;
        
        Opportunity emptyOpportunity = new Opportunity(
            Name = 'Empty Opportunity',
            AccountId = newAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert emptyOpportunity;
        
        Test.startTest();
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results = 
            OpportunityLineItemTableController.getOpportunityLineItem(emptyOpportunity.Id);
        Test.stopTest();
        
        // Assertions
        Assert.areNotEqual(null, results, 'La liste ne devrait pas être nulle');
        Assert.areEqual(0, results.size(), 'La liste devrait être vide');
    }
    
    @isTest
    static void testGetOpportunityLineItem_WithInvalidId() {
        // Utilisation d'un ID invalide (fake ID)
        String fakeOpportunityId = '006000000000000AAA';
        
        Test.startTest();
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results = 
            OpportunityLineItemTableController.getOpportunityLineItem(fakeOpportunityId);
        Test.stopTest();
        
        // Assertions
        Assert.areNotEqual(null, results, 'La liste ne devrait pas être nulle');
        Assert.areEqual(0, results.size(), 'La liste devrait être vide pour un ID invalide');
    }
    
    @isTest
    static void testGetOpportunityLineItem_Cacheable() {
        // Récupération de l'opportunité créée dans le setup
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        // Premier appel
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results1 = 
            OpportunityLineItemTableController.getOpportunityLineItem(testOpportunity.Id);
        
        // Deuxième appel (devrait utiliser le cache)
        List<OpportunityLineItemTableController.OpportunityLineItemWrapper> results2 = 
            OpportunityLineItemTableController.getOpportunityLineItem(testOpportunity.Id);
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(results1.size(), results2.size(), 
            'Les deux appels devraient retourner le même nombre de résultats');
    }
    
    @isTest
    static void testDeleteOpportunityLineItem_Success() {
        // Récupération d'un line item à supprimer
        OpportunityLineItem lineItemToDelete = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        String lineItemId = lineItemToDelete.Id;
        
        // Vérification que le line item existe avant suppression
        Integer countBefore = [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :lineItemId];
        Assert.areEqual(1, countBefore, 'Le line item devrait exister avant suppression');
        
        Test.startTest();
        OpportunityLineItemTableController.deleteOpportunityLineItem(lineItemId);
        Test.stopTest();
        
        // Vérification que le line item a été supprimé
        Integer countAfter = [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :lineItemId];
        Assert.areEqual(0, countAfter, 'Le line item devrait avoir été supprimé');
    }
    
    @isTest
    static void testDeleteOpportunityLineItem_WithInvalidId() {
        // Utilisation d'un ID invalide (fake ID)
        String fakeLineItemId = '00k000000000000AAA';
        
        Boolean exceptionThrown = false;
        String exceptionMessage;
        
        Test.startTest();
        try {
            OpportunityLineItemTableController.deleteOpportunityLineItem(fakeLineItemId);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        // Assertions
        System.assert(exceptionThrown, 'Une exception devrait avoir été levée pour un ID invalide');
        Assert.areNotEqual(null, exceptionMessage, 'Le message d\'erreur ne devrait pas être nul');
    }
    
    @isTest
    static void testDeleteOpportunityLineItem_VerifyOpportunityIntegrity() {
        // Récupération de l'opportunité et comptage initial
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Integer initialCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id];
        
        // Récupération d'un line item à supprimer
        OpportunityLineItem lineItemToDelete = [
            SELECT Id 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :testOpportunity.Id 
            LIMIT 1
        ];
        
        Test.startTest();
        OpportunityLineItemTableController.deleteOpportunityLineItem(lineItemToDelete.Id);
        Test.stopTest();
        
        // Vérification que le comptage a diminué de 1
        Integer finalCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id];
        Assert.areEqual(initialCount - 1, finalCount, 
            'Le nombre de line items devrait avoir diminué de 1');
    }
    
    @isTest
    static void testOpportunityLineItemWrapper_AllFields() {
        // Test de la classe wrapper pour s'assurer que tous les champs sont accessibles
        OpportunityLineItemTableController.OpportunityLineItemWrapper wrapper = 
            new OpportunityLineItemTableController.OpportunityLineItemWrapper();
        
        // Set des valeurs
        wrapper.opportunityLineItemId = '00k000000000001AAA';
        wrapper.productId = '01t000000000001AAA';
        wrapper.productName = 'Test Product';
        wrapper.unitPrice = 99.99;
        wrapper.totalPrice = 999.90;
        wrapper.quantity = 10;
        wrapper.quantityInStock = 50;
        wrapper.colorQuantity = 'slds-text-color_success';
        
        // Assertions
        Assert.areEqual('00k000000000001AAA', wrapper.opportunityLineItemId);
        Assert.areEqual('01t000000000001AAA', wrapper.productId);
        Assert.areEqual('Test Product', wrapper.productName);
        Assert.areEqual(99.99, wrapper.unitPrice);
        Assert.areEqual(999.90, wrapper.totalPrice);
        Assert.areEqual(10, wrapper.quantity);
        Assert.areEqual(50, wrapper.quantityInStock);
        Assert.areEqual('slds-text-color_success', wrapper.colorQuantity);
    }
}