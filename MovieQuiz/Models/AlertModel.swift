//
//  AlertModel.swift
//  MovieQuiz

import UIKit

struct AlertModel {
    let titel: String
    let message: String
    let buttonText: String
    let completion: (() -> Void)
}

