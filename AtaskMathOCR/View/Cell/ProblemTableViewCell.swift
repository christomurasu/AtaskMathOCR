//
//  ProblemTableViewCell.swift
//  AtaskMathOCR
//
//  Created by Christopher Pratama on 15/05/23.
//

import UIKit

class ProblemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var problemLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupView(mathProblem: MathProblemModel) {
        problemLabel.text = "Problem : \(mathProblem.problem)"
        resultLabel.text = "Result : \(mathProblem.result)"
    }
}
