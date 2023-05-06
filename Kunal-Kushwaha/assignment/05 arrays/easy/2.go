/*
2. [Concatenation of Array](https://leetcode.com/problems/concatenation-of-array/)
*/
/*
Given an integer array nums of length n, you want to create an array ans of length 2n where ans[i] == nums[i] and ans[i + n] == nums[i] for 0 <= i < n (0-indexed).

Specifically, ans is the concatenation of two nums arrays.

Return the array ans.
*/

package main

import "fmt"

func main() {
	var nums []int = []int{1, 2, 1, 222, 555}
	fmt.Println(getConcatenation(nums))
}

///////////////// getConcatenation ///////////////////

func getConcatenation(nums []int) []int {
	var n = len(nums)
	ans := make([]int, n*2)
	for i := 0; i < n; i++ {
		ans[i] = nums[i]
		ans[i+n] = nums[i]
	}
	return ans
}
