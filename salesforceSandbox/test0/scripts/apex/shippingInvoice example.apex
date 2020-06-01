// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

exports 

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);
//these are the data structures we work with in Ajax
List <Integer> list0 = new List<Integer>();
Set<string> string0 = new Set<string>{'a', 'b','c'};
Map<Integer, String> map0 = new Map<Integer, String>{1 => 'a', 2 => 'b', 3 => 'c'};

//let's try a trigger for the Item/Sales Invoice example
//shipping invoice example on Salesforce documentation

/* 
1. user clicks order|new, names the shipping invoice and *saves*
2. user clicks on New Item, fills out info, then *saves*
3.Calculate trigger runs, updates the shipping invoice
4.ShippingDiscount trigger runs
5.user can add, delete, change items in invoice  
*/


trigger Calculate on Item__c(after insert, after update, after delete)
//use a Map, so no duplicate items
{
Map<ID, Shipping_Invoice__C> updateMap = new Map<ID, Shipping_Invoice__C>();
//set integer to -1 if we're deleting
Integer subtract;
//populate list of items based on type of trigger
List<Item__c> itemList;
    if(trigger.isInsert || trigger.isUpdate)
    {
        itemList = Trigger.new;
        subtract = 1;
    }
    else if (trigger.isDelete)
    {
     //no trigger.new if delete 
     itemList = trigger.old;
     subtract = -1;   
    }

    //retrieve all info we need through SINGLE query
    //best practice for bulkifying requests
    set<Id> AllItems = new set<id>();
    for (item__c i:itemList)
    {
        //assert that numbers are not negative
        System.assert(i.quantity__c > 0, 'Quantity must be positive');
        System.assert(i.weight__c >= 0, 'Weight must be positive');
        System.assert(i.price__c >= 0, 'Price must be positive');

        AllItems.add(i.Shipping_Invoice__C);
        
    }
    //returns list of all shipping invoices for items effected by this trigger
    List <Shipping_Invoice__C> AllShippingInvoices = [SELECT Id, ShippingDiscount__c, SubTotal__c,
    TotalWeight__c, Tax__c, GrandTotal__c FROM Shipping_Invoice__C WHERE Id IN :AllItems
    ];  
    //takes this new list and put it in a map
    //makes it easier to look up invoices 
    //because we can just lookup a map as opposed iterating by each index of list
    Map<ID, Shipping_Invoice__C> SIMap = new Map<ID, Shipping_Invoice__C>();
    for Shipping_Invoice__C sc : AllShippingInvoices
    {
        SIMap.put(sc.Id, sc);
    }
    //process this list of items
    if (Trigger.isUpdate)
    {
        //treats the update like the removal as old item and addition
        //of a revised item rather than figuring out the differences of each field
        //note that updates have both trigger.new + trigger.old
        for (Integer x = 0; x < Trigger.old.Size(); x++)
        {
            Shipping_Invoice__C myOrder;
            myOrder = SIMap.get(trigger.old[x].Shipping_Invoice__C);
             // Decrement the previous value from the subtotal and weight.
             myOrder.SubTotal__c -= (trigger.old[x].price__c * 
             trigger.old[x].quantity__c);
             myOrder.TotalWeight__c -= (trigger.old[x].weight__c *
             trigger.old[x].quantity__c);

             //increment the new subtotal and weight
             myOrder.SubTotal__c += (trigger.new[x].price__c *
             trigger.new[x].quantity__c);
             myOrder.TotalWeight__c+= (trigger.new[x].weight__c*
             trigger.new[x].quantity__c);

        }
        for (Shipping_Invoice__C myOrder : AllShippingInvoices)
        {
            /* 
            sets tax rate to 9.25%
            ** THIS IS JUST FOR EXAMPLE USE**
            ** BAD PRACTICE TO HARD CODE VALUES LIKE THIS**
            ** LEVERAVING CUSTOM SETTINGS FOR TAX RATES IS BETTER **
             */
            myOrder.Tax__c = myOrder.SubTotal__c * .0925;
            //reset shipping discount
            myOrder.ShippingDiscount__c = 0;

            // set shipping rate to 75 cents per pound
            // ** Again, best practice is to use custom settings**
            myOrder.Shipping__c = (myOrder.TotalWeight__c * .75);
            myOrder.GrandTotal__c = myOrder.SubTotal__c + myOrder.tax__c +
            myOrder.Shipping__c;
            updateMap.put(myOrder.id, myOrder);

        }
    }
    //else logic operator for previous .isUpdate
    else 
    {
        //for each Item within itemList: have an iterator itemToProcess
        for(Item__c itemToProcess: itemList)
        {
            Shipping_Invoice__C myOrder;

            //Look up for correct shipping invoice from the ones we retrieved earlier
            //again, we can just look up using a map instead of iterating over a list
            //Ain't these new-fangled data structs just the coolest thing?
            myOrder = SIMap.get(itemToProcess.Shipping_Invoice__C);
            myOrder.SubTotal__c += (itemToProcess.price__c*
            itemToProcess.quantity__c * subtract);
            myOrder.TotalWeight__c += (itemToProcess.weight__c *
            itemToProcess.quantity__c * subtract);

        }

    }
    //DML update here
    //only use one at a time
    //this minimizes the number of DML requests generated from this trigger
    //Bulkification
    update updateMap.value();
    
}