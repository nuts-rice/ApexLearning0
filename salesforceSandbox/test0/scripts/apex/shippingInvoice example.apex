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
}