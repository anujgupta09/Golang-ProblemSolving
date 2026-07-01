// 18. [Add to Array-Form of Integer](https://leetcode.com/problems/add-to-array-form-of-integer/)

// The array-form of an integer num is an array representing its digits in left to right order.

// For example, for num = 1321, the array form is [1,3,2,1].
// Given num, the array-form of an integer, and an integer k, return the array-form of the integer num + k.

package main

import (
	"fmt"
	"slices"
)

func main() {
	var nums []int

	nums = []int{1, 2, 3, 0, 0}
	var k = 999

	addToArrayForm(nums, k)
}

func addToArrayForm(num []int, k int) []int {
	total := 0
	for _, digit := range num {
		fmt.Println(digit)
		total = (total * 10) + digit
	}

	total += k
	fmt.Println(total)
	newnum := []int{}

	for total > 0 {
		digit := total % 10
		newnum = append(newnum, digit)
		total /= 10
	}
	slices.Reverse(newnum)
	fmt.Println(newnum)
	return newnum
}
