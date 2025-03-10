//
//  ServiceTableViewCell.swift
import CoreBluetooth
import UIKit

class ServiceTableViewCell: UITableViewCell {
    @IBOutlet var labelServiceUUID: UILabel!
    @IBOutlet var labelCharUUID: UILabel!

    var service: CBService?
    var characteristic: CBCharacteristic?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
