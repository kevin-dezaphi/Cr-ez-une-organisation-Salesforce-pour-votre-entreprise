import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityLineItem from '@salesforce/apex/OpportunityLineItemTableController.getOpportunityLineItem';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemTableController.deleteOpportunityLineItem';

import productName from '@salesforce/label/c.ProductName';
import unitPrice from '@salesforce/label/c.UnitPrice';
import totalPrice from '@salesforce/label/c.TotalPrice';
import quantity from '@salesforce/label/c.Quantity';
import quantityStock from '@salesforce/label/c.QuantityStock';
import deleteLabel from '@salesforce/label/c.DeleteLabel';
import viewProduct from '@salesforce/label/c.ViewProduct';
import noProductMessage from '@salesforce/label/c.NoProductMessage';
import warningQuantityMessage from '@salesforce/label/c.WarningQuantityMessage';
import refresh from '@salesforce/label/c.Refresh';

import Id from '@salesforce/user/Id';
import profileName from '@salesforce/schema/User.Profile.Name';

const labels = {
    productName,
    unitPrice,
    totalPrice,
    quantity,
    quantityStock,
    deleteLabel,
    viewProduct,
    noProductMessage,
    warningQuantityMessage,
    refresh
};

const columns = [
    {
        label: labels.productName,
        type: 'text',
        fieldName: 'productName',
        cellAttributes: {
            alignment: 'left'
        }
    }, {
        label: labels.unitPrice,
        type: 'currency',
        fieldName: 'unitPrice',
        cellAttributes: {
            alignment: 'left'
        }
    }, {
        label: labels.totalPrice,
        type: 'currency',
        fieldName: 'totalPrice',
        cellAttributes: {
            alignment: 'left'
        }
    }, {
        label: labels.quantity,
        type: 'number',
        fieldName: 'quantity',
        cellAttributes: {
            class: {
                fieldName: 'colorQuantity'
            },
            alignment: 'left'
        }
    }, {
        label: labels.quantityStock,
        type: 'number',
        fieldName: 'quantityInStock',
        cellAttributes: {
            alignment: 'left'
        }
    }, {
        label: labels.deleteLabel,
        type: 'button-icon',
        typeAttributes: {
            iconName: 'utility:delete',
            alternativeText: labels.deleteLabel,
            title: labels.deleteLabel,
            name: 'deleteRow'
        },
        cellAttributes: {
            alignment: 'left'
        }
    }
];

export default class OpportunityLineItemTable extends NavigationMixin(LightningElement) {
    @api recordId;

    @track data = undefined;
    @track error = undefined;
    @track userProfileName = undefined;

    labels = labels;
    columns = columns;
    userId = Id;

    @wire(getRecord, { recordId: Id, fields: [profileName]})
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
            this.data = undefined;
        } else if (data) {
            this.userProfileName = data.fields.Profile.value.fields.Name.value;
            if (this.userProfileName.includes('Admin')) {
                columns.push({
                    label: labels.viewProduct,
                    type: 'button',
                    typeAttributes: {
                        label: labels.viewProduct,
                        iconName: 'utility:preview',
                        alternativeText: labels.viewProduct,
                        title: labels.viewProduct,
                        variant: 'brand',
                        name: 'viewProduct'
                    },
                    cellAttributes: { alignment: 'left' }
                });
            }
        }
    }

    @wire(getOpportunityLineItem, { opportunityId: '$recordId' })
    wiredOpportunityLineItem (value) {
        this.opportunityLineItemValue = value;
        const { error, data } = value;
        if (data) {
            if (data.length === 0) {
                this.data = null;
            } else {
                this.data = data;
                this.warningQuantity = false;
                for (let i = 0; i < data.length; i++) {
                    if (data[i].colorQuantity.includes('slds-text-color_error')) {
                        this.warningQuantity = true;    
                    }
                }
            }
            this.error = undefined;
        } else if (error) {
            this.data = undefined;
            this.error = error;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'deleteRow') {
            deleteOpportunityLineItem({ opportunityLineItemId: row.opportunityLineItemId })
                .then(() => {
                    this.handleRefresh();
                })
                .catch(error => {
                    this.error = error;
                    this.data = undefined;
                });
        } else if (actionName === 'viewProduct') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.productId,
                    objectApiName: 'Product2',
                    actionName: 'view'
                }
            });
        }
    }

    handleRefresh() {
        refreshApex(this.opportunityLineItemValue);
    }
}