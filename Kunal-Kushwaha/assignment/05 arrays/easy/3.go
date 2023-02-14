/*
Given an array nums. We define a running sum of an array as runningSum[i] = sum(nums[0]…nums[i]).
Return the running sum of nums.
*/

package main

import "fmt"

func main() {
	var nums []int = []int{1, 2, 3}
	result := runningSum(nums)
	fmt.Println(result)
}

/////////////// runningSum ///////////////////

func runningSum(nums []int) []int {
	var runningSum = 0
	ans := make([]int, len(nums))
	for i := 0; i < len(nums); i++ {
		runningSum += nums[i]
		ans[i] = runningSum
	}
	return ans
}
