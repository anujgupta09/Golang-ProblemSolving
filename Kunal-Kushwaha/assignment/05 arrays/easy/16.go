// 16. [Find Numbers with Even Number of Digits]
// (https://leetcode.com/problems/find-numbers-with-even-number-of-digits/)

package main

import (
	"fmt"
	"strconv"
)

func main() {
	var nums []int = []int{1111, 21, 311, 3, 333, 44444, 44444444}
	fmt.Println(findNumbers(nums))
}
func findNumbers(nums []int) int {
	noOfEvennumbers := 0
	for i, _ := range nums {
		if len(strconv.Itoa(nums[i]))%2 == 0 {
			noOfEvennumbers += 1
			fmt.Println("Number ", nums[i], " has even digit")
		}
	}
	return noOfEvennumbers
}
