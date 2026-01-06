public with sharing class OpportunityLineItemTableController {
    public class OpportunityLineItemWrapper {
        @AuraEnabled public String opportunityLineItemId {get; set;}
        @AuraEnabled public String productId {get; set;}
        @AuraEnabled public String productName {get; set;}
        @AuraEnabled public Double unitPrice {get; set;}
        @AuraEnabled public Double totalPrice {get; set;}
        @AuraEnabled public Double quantity {get; set;}
        @AuraEnabled public Double quantityInStock {get; set;}
        @AuraEnabled public String colorQuantity {get; set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItemWrapper> getOpportunityLineItem(String opportunityId){
        try {
            List<OpportunityLineItemWrapper> opportunityLineItemWrapperList = new List<OpportunityLineItemWrapper>();
            List<OpportunityLineItem> opportunityLineItemList = [
                SELECT Id, Product2.Id, Product2.Name, UnitPrice, TotalPrice, Quantity, Product2.QuantityInStock__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
            ];
            for (OpportunityLineItem opportunityLineItem : opportunityLineItemList) {
                OpportunityLineItemWrapper opportunityLineItemWrapper = new OpportunityLineItemWrapper();
                opportunityLineItemWrapper.opportunityLineItemId = opportunityLineItem.Id;
                opportunityLineItemWrapper.productId = opportunityLineItem.Product2.Id;
                opportunityLineItemWrapper.productName = opportunityLineItem.Product2.Name;
                opportunityLineItemWrapper.unitPrice = opportunityLineItem.UnitPrice;
                opportunityLineItemWrapper.totalPrice = opportunityLineItem.TotalPrice;
                opportunityLineItemWrapper.quantity = opportunityLineItem.Quantity;
                opportunityLineItemWrapper.quantityInStock = opportunityLineItem.Product2.QuantityInStock__c;
                opportunityLineItemWrapper.colorQuantity = opportunityLineItem.Quantity > opportunityLineItem.Product2.QuantityInStock__c ? 'slds-text-color_error slds-theme_error' : 'slds-text-color_success';
                opportunityLineItemWrapperList.add(opportunityLineItemWrapper);
            }
            return opportunityLineItemWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteOpportunityLineItem(String opportunityLineItemId) {
        try {
            OpportunityLineItem opportunityLineItem = [SELECT Id FROM OpportunityLineItem WHERE Id = :opportunityLineItemId];
            delete opportunityLineItem;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}