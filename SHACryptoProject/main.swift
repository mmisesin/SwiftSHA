//
//  main.swift
//  SHACryptoProject
//
//  Created by Artem Misesin on 5/3/17.
//  Copyright © 2017 Artem Misesin. All rights reserved.
//

import Foundation

var GLOBAL_K = ""

func adaptForBlocks(string: inout String, each: Int){ // дополняем нулями для разделения на блоки
    while string.characters.count % each != 0{
        string.insert("0", at: string.startIndex)
    }
}

func adapt32(_ string: String) -> String{
    var result = string
    while result.characters.count < 32{
        result.insert("0", at: string.startIndex)
    }
    return result
}

func trunc32(_ string: String) -> String{
    var result = string
    while result.characters.count > 32{
        result.remove(at: result.startIndex)
    }
    return result
}

func slice(_ string: String, each count: Int) -> [String]{ // режем на блоки
    var blocksCount = string.characters.count / count
    var slices: [String] = []
    var i = 0
    var j = count - 1
    while (blocksCount > 0){
        let startIndex = string.index(string.startIndex, offsetBy: i)
        let sliceIndex = string.index(string.startIndex, offsetBy: j)
        slices.append(string[startIndex...sliceIndex])
        i += count
        j += count
        blocksCount -= 1
    }
    return slices
}

func performXOR(data: String, key: String)->String{
    var result: [Character] = []
    for (index, value) in data.characters.enumerated(){
        if value == key[index]{
            result.append("0")
        } else {
            result.append("1")
        }
    }
    return String(result)
}

func performAND(data: String, key: String) -> String {
    var result: [Character] = []
    for (index, value) in data.characters.enumerated(){
        if value == "1" && key[index] == "1"{
            result.append("1")
        } else {
            result.append("0")
        }
    }
    return String(result)
}

func performNOT(_ data: String) -> String {
    var result: [Character] = []
    for value in data.characters{
        if value == "1"{
            result.append("0")
        } else {
            result.append("1")
        }
    }
    return String(result)
}

func performOR(data: String, key: String) -> String {
    var result: [Character] = []
    for (index, value) in data.characters.enumerated(){
        if value == "1" || key[index] == "1"{
            result.append("1")
        } else {
            result.append("0")
        }
    }
    return String(result)
}

func nonLinear(_ a: String, _ b: String, _ c: String, _ d: String, _ e:String, _ t: Int) -> String {
    // перетворення в 32-бітні слова
    let tempA = adapt32(a)
    let tempB = adapt32(b)
    let tempC = adapt32(c)
    let tempD = adapt32(d)
    let tempE = adapt32(e)
    // визначення кроку та константи
    /*
     00 ≤ t ≤ 19     Ch(x, y, z) = (x AND y) XOR ( NOT x AND z)
     20 ≤ t ≤ 39     Parity(x, y, z) = x XOR y XOR z
     40 ≤ t ≤ 59     Maj(x, y, z) = (x AND y) XOR (x AND z) XOR (y AND z)
     60 ≤ t ≤ 79     Parity(x, y, z) = x XOR y XOR z
    */
    switch t{
    case 0...19:
        let first = performAND(data: tempB, key: tempC)
        let last = performAND(data: performNOT(tempB), key: tempD)
        GLOBAL_K = "01011010100000100111100110011001"
        return performOR(data: first, key: last)
    case 20...39:
        GLOBAL_K = "01101110110110011110101110100001"
        return performXOR(data: performXOR(data: tempB, key: tempC), key: tempD)
    case 40...59:
        let first = performAND(data: tempB, key: tempC)
        let second = performAND(data: tempB, key: tempD)
        let third = performAND(data: tempC, key: tempD)
        GLOBAL_K = "10001111000110111011110011011100"
        return performOR(data: performOR(data: first, key: second), key: third)
    case 60...79:
        GLOBAL_K = "11001010011000101100000111010110"
        return performXOR(data: performXOR(data: tempB, key: tempC), key: tempD)
    default: return ""
    }
}

var data = Data()
var text = "Hello World."
var string = ""

var i = 1

// перетворення тексту у бінарний код
for char in text.characters {
    var temp = String(char)
    data = temp.data(using: String.Encoding.utf8)!
    var hexText = data.hexEncodedString()
    
    guard let hexInt = Int(hexText, radix: 16) else {
        print("Error while evaluating")
        abort()
    }
    
    var binary = String(hexInt, radix: 2)
    adaptForBlocks(string: &binary, each: 8)
    string += binary
}
print(string)

// заповнення бінарного коду символами для досягнення кратності 512
string += "1"
let sLength = string.characters.count
print(sLength - 1)
var count = 448 - sLength % 512
print(count)
var index = 0
while (index < count){
    string += "0"
    index += 1
}
print(string.characters.count)
var tempBin = String(sLength - 1, radix: 2)
adaptForBlocks(string: &tempBin, each: 64)
string += tempBin

// нарізання коду на 16 32-бітних слова
var array = slice(string, each: 32)

var h1 = "01100111010001010010001100000001"
var h2 = "11101111110011011010101110001001"
var h3 = "10011000101110101101110011111110"
var h4 = "00010000001100100101010001110110"
var h5 = "11000011110100101110000111110000"

// перетворення 32 слів у 80
for t in 16...79{
    var temp = performXOR(data: array[t - 3], key: array[t - 8])
    temp = performXOR(data: temp, key: array[t-14])
    temp = performXOR(data: temp, key: array[t-16])
    var tempArray = Array(temp.characters)
    tempArray = tempArray.rotate(shift: 1)
    array.append(String(tempArray))
}

var a = h1
var b = h2
var c = h3
var d = h4
var e = h5

var f = ""

// головний цикл
for (index, t) in array.enumerated(){
    f = nonLinear(a, b, c, d, e, index)
    
    var first = Int(String(Array(a.characters).rotate(shift: 5)), radix: 2)!
    var second = Int(f, radix: 2)!
    var third = Int(e, radix: 2)!
    var fourth = Int(GLOBAL_K, radix: 2)!
    var fifth = Int(t, radix: 2)!
    var temp = String(first + second + third + fourth + fifth, radix: 2)
    e = d
    d = c
    c = String(Array(b.characters).rotate(shift: 30))
    b = a
    a = trunc32(String(temp))
}

// фінальний етап
var ta = Int(a, radix: 2)!
var th1 = Int(h1, radix: 2)!
var tsum = ta + th1
h1 = trunc32(String(tsum, radix: 2))
ta = Int(b, radix: 2)!
th1 = Int(h2, radix: 2)!
tsum = ta + th1
h2 = trunc32(String(tsum, radix: 2))
ta = Int(c, radix: 2)!
th1 = Int(h3, radix: 2)!
tsum = ta + th1
h3 = trunc32(String(tsum, radix: 2))
ta = Int(d, radix: 2)!
th1 = Int(h4, radix: 2)!
tsum = ta + th1
h4 = trunc32(String(tsum, radix: 2))
ta = Int(e, radix: 2)!
th1 = Int(h5, radix: 2)!
tsum = ta + th1
h5 = trunc32(String(tsum, radix: 2))
let fh1 = String(Int(h1, radix: 2)!, radix: 16)
let fh2 = String(Int(h2, radix: 2)!, radix: 16)
let fh3 = String(Int(h3, radix: 2)!, radix: 16)
let fh4 = String(Int(h4, radix: 2)!, radix: 16)
let fh5 = String(Int(h5, radix: 2)!, radix: 16)

print(fh1 + fh2 + fh3 + fh4 + fh5)
