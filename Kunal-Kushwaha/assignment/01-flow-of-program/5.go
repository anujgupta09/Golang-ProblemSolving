// 5. Keep taking numbers as inputs till the user enters ‘x’, after that print sum of all.

package main

import (
	"fmt"
	"strconv"
)

func main() {
	var input string
	var sum int
	for {
		fmt.Scan(&input)
		if input == "x" {
			fmt.Println(sum)
			break
		}
		numStrToInt, err := strconv.Atoi(input)
		if err != nil {
			fmt.Println("Some error plz check the value")
		}
		sum += numStrToInt
	}
}
