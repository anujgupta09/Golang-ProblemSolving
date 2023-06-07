/*
10. [Check if the Sentence Is Pangram]
(https://leetcode.com/problems/check-if-the-sentence-is-pangram/)
*/
package main

import "fmt"

func main() {
	fmt.Println(checkIfPangram("abcdefghijklmnopqrstuvwxyz"))
}

func checkIfPangram(sentence string) bool {
	uniqueLetter := make(map[rune]bool) // map only store unique value
	for index, char := range sentence {
		fmt.Println(index, char)
		uniqueLetter[char] = true // char is key and true is value
	}
	return len(uniqueLetter) == 26 // len of map
}

// func checkIfPangram(sentence string) bool {
// 	for j := 'a'; j <= 'z'; j++ {
// 		var Present = false
// 		for i := 0; i < len(sentence); i++ {
// 			if j == rune(sentence[i]) { // type conversion
// 				fmt.Println(j, " ", i, sentence[i])
// 				Present = true
// 			}
// 		}
// 		if Present == false {
// 			return false
// 		}
// 	}
// 	return true
// }
