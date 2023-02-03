// 16. Reverse A String In Java

package main

import "fmt"

func main() {
	var string1 string
	fmt.Scan(&string1)
	var array []string = []string{}
	var revString = ""
	for i := 0; i < len(string1); i++ {
		strChar := string(string1[i])
		array = append(array, strChar)
	}
	for i := len(array) - 1; i >= 0; i-- {
		revString += array[i]
	}
	fmt.Println(revString)
}
