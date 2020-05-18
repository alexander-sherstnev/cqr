//
//  ContactsViewController.swift
//  CQR
//
//  Created by Alexander Sherstnev on 5/16/20.
//  Copyright © 2020 Alexander Sherstnev. All rights reserved.
//

import UIKit
import Contacts

class ContactsViewController: UITableViewController {

    var _contacts: [Contact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadContacts()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = _contacts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Table Cell", for: indexPath)
        cell.textLabel?.text = "\(contact.firstName) \(contact.lastName)"
        cell.detailTextLabel?.text = contact.phone
        
        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Contact QR" {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let contact = _contacts[indexPath.row] as Contact

            let contactQRViewController = segue.destination as! ContactQRViewController
            contactQRViewController.contact = contact
        }
    }
    
    // MARK: - Methods
    
    func loadContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("Failed to request access", error)
                return
            }
            
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                do {
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        self._contacts.append(Contact(firstName: contact.givenName,
                                                      lastName: contact.familyName,
                                                      phone: contact.phoneNumbers.first?.value.stringValue ?? ""))
                    })
                    DispatchQueue.main.async { self.tableView.reloadData() }
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("Access denied")
            }
        }
    }
}
