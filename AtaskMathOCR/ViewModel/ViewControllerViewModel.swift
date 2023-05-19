//
//  ViewControllerViewModel.swift
//  AtaskMathOCR
//
//  Created by Christopher Pratama on 13/05/23.
//

enum FileSaveType {
    case file
    case db
}

enum PickingFileType {
    case camera
    case gallery
}

enum CalcOperator {
    case plus
    case minus
    case divide
    case times
}

import Foundation
import Vision
import CoreImage
import UIKit
import SwiftyJSON
import CoreData

public class ViewControllerViewModel {
    var calcOperator: CalcOperator = .plus
    var calcResult: Int = 0
    var mathProblems: [MathProblemModel] = []
    var dataMathProblems: [NSManagedObject] = []
    
    func getResult(saveToFile: FileSaveType, image: UIImage) -> [MathProblemModel] {
        let problem = checkText(image: image)
        let result = calculateOCRResult(textResult: problem)
        let mathProblem = MathProblemModel.init(problem: problem, result: result)
        mathProblems.append(mathProblem)
        if saveToFile == .file {
            self.saveToFile()
        } else {
            self.saveToData(problem: mathProblem)
        }
        return mathProblems
    }
    
    func getExisting(saveTofile: FileSaveType) -> [MathProblemModel] {
        if saveTofile == .file {
            readFromFile()
        } else {
            readFromData()
        }
        return mathProblems
    }
    
    private func checkText(image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "" }
        var textResult = ""
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {return}
            let text = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: ",")
            textResult = text.removeWhitespace().lowercased()
        }
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        do {
            try handler.perform([request])
        } catch {
            print("error")
        }
        return textResult
    }
    
    private func calculateOCRResult(textResult: String) -> Int {
        //getting the position of the operator, operator that didn't exist will become nil
        let charPlus = textResult.indexInt(of: "+")
        let charMinus = textResult.indexInt(of: "-")
        let charTimes = textResult.indexInt(of: "x")
        let charDivide = textResult.indexInt(of: "/")
        
        //determine position of the operator
        var position: Int = 0
        if charPlus != nil {
            position = charPlus ?? 0
            calcOperator = .plus
        } else if charMinus != nil {
            position = charMinus ?? 0
            calcOperator = .minus
        } else if charTimes != nil {
            position = charTimes ?? 0
            calcOperator = .times
        } else if charDivide != nil {
            position = charDivide ?? 0
            calcOperator = .divide
        }
        
        //filtering the text to only decimal, and splitting the number based on operator position
        let firstNumber = Int(textResult.substring(to: position).filter { ("0"..."9").contains($0) }) ?? 0
        let secondNumber = Int(textResult.substring(from: position+1).filter { ("0"..."9").contains($0) }) ?? 0
        
        //calculating
        switch calcOperator {
        case .plus:
            calcResult = firstNumber+secondNumber
        case .minus:
            calcResult = firstNumber-secondNumber
        case .divide:
            calcResult = firstNumber/secondNumber
        case .times:
            calcResult = firstNumber*secondNumber
        }
        
        //        //return calculation result
        return calcResult
    }
    
    func saveToFile() {
        var arrModels: [[String:Any]] = []
        for item in mathProblems {
            let model: [String:Any] = [
                "problem": item.problem,
                "result": item.result
            ]
            arrModels.append(model)
        }
        let jsonModel = JSON(arrModels)
        let stringJson = jsonModel.description
        writeToDocumentsFile(value: stringJson)
        readFromFile()
    }
    
    func readFromFile() {
        mathProblems.removeAll()
        let resultRead = readFromDocumentsFile()
        let mathProblems = Data(base64Encoded: resultRead, options: Data.Base64DecodingOptions(rawValue: 0))
        let json = JSON(mathProblems)
        for item in json.arrayValue {
            let problem = MathProblemModel.init(problem: item["problem"].stringValue, result: item["result"].intValue)
            self.mathProblems.append(problem)
        }
    }
    
    func writeToDocumentsFile(value:String) {
        guard let string = value.description.data(using: .utf8)?.base64EncodedString() else { return }
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("problems.txt")
        do {
            try string.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("failed to save to file")
        }
    }
    
    func readFromDocumentsFile() -> String {
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("problems.txt")
        do {
            return try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            print("failed to retrieve file")
        }
        return ""
    }
    
    func saveToData(problem: MathProblemModel) {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
        appDelegate.persistentContainer.viewContext
        
        let entity =
        NSEntityDescription.entity(forEntityName: "Problem",
                                   in: managedContext)!
        
        let problemObject = NSManagedObject(entity: entity,
                                            insertInto: managedContext)

        problemObject.setValue(problem.problem, forKeyPath: "problem")
        problemObject.setValue(problem.result, forKeyPath: "result")
        
        do {
            try managedContext.save()
            print("saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        readFromData()
    }
    
    func readFromData() {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
        appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
        NSFetchRequest<NSManagedObject>(entityName: "Problem")
        
        do {
            mathProblems.removeAll()
            let problems = try managedContext.fetch(fetchRequest)
            for item in problems {
                let problems = MathProblemModel.init(problem: item.value(forKey: "problem") as? String ?? "", result: item.value(forKey: "result") as? Int ?? 0)
                mathProblems.append(problems)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
}
