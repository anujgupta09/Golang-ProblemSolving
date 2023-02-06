// 16. Reverse A String In Java

package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {

	var scanBufio = bufio.NewScanner(os.Stdin) //v2 with bufio
	scanBufio.Scan()
	var string1 = scanBufio.Text()

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
