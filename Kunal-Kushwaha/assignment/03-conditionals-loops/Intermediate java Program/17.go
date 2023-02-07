// 17. Find if a number is palindrome or not

package main

import (
	"fmt"
)

func main() {
	var num string
	fmt.Print("Enter a num to chek whether its a palindrom or not : ")
	fmt.Scan(&num)
	var array []string = []string{}
	var revString = ""
	for i := 0; i < len(num); i++ {
		strChar := string(num[i])
		array = append(array, strChar)
	}
	for i := len(array) - 1; i >= 0; i-- {
		revString += array[i]
	}
	if num == revString {
		fmt.Println("Its a Palindrome")
	} else {
		fmt.Println("Its not a palindrome")
	}
}
