// 24. Sum Of A Digits Of Number
package main

import (
	"fmt"
	"strconv"
)

func main() {
	var num int
	fmt.Scan(&num)
	lenOfNum := len(strconv.Itoa(num))
	var sum = 0
	for i := 0; i <= lenOfNum; i++ {
		digit := num % 10
		sum += digit
		num /= 10
	}
	fmt.Println("Sum of digit of num : ", sum)
}
