// 1. [Build Array from Permutation]
// (https://leetcode.com/problems/build-array-from-permutation/)

/*
Given a zero-based permutation nums (0-indexed), build an array ans of
the same length where ans[i] = nums[nums[i]] for each 0 <= i < nums.length and return it.

A zero-based permutation nums is an array of distinct integers
from 0 to nums.length - 1 (inclusive).
*/

package main

import "fmt"

func main() {
	var nums []int = []int{}
	nums = []int{0, 2, 1, 5, 3, 4}
	result := buildArray(nums)
	fmt.Println(result)
}
func buildArray(nums []int) []int {
	var ans []int = []int{}
	for i := 0; i <= len(nums)-1; i++ {
		ans = append(ans, nums[nums[i]])
	}
	return ans
}
