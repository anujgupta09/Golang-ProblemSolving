// 26. Write a program to print the sum of negative numbers, sum of positive
// even numbers and the sum of positive odd numbers from a list of numbers (N)
// entered by the user. The list terminates when the user enters a zero.

package main

import "fmt"

func main() {
	var nums []int = []int{-10, -10, 10, 10, 9, 7, 3, 1}
	var sumOfNegativeNums = 0
	var sumOfPosEvenNums = 0
	var sumOfPosOddNums = 0
	for i := 0; i < len(nums); i++ {
		if nums[i] < 0 {
			sumOfNegativeNums += nums[i]
		}
		if nums[i] > 0 && nums[i]%2 == 0 {
			sumOfPosEvenNums += nums[i]
		}
		if nums[i] > 0 && nums[i]%2 != 0 {
			sumOfPosOddNums += nums[i]
		}
	}
	fmt.Println(sumOfNegativeNums)
	fmt.Println(sumOfPosEvenNums)
	fmt.Println(sumOfPosOddNums)
}
