// 21. Java Program Vowel Or Consonant

package main

import "fmt"

func main() {
	var letter string
	fmt.Scan(&letter)
	if letter == "a" || letter == "e" || letter == "i" || letter == "o" || letter == "u" {
		fmt.Println("Vowels")
	} else {
		fmt.Println("Consonants")
	}
}
