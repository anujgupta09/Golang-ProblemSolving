/*
9. [Create Target Array in the Given Order]
(https://leetcode.com/problems/create-target-array-in-the-given-order/)
*/

package main

import "fmt"

func main() {
	nums := []int{0, 1, 2, 3, 4}
	index := []int{0, 1, 2, 2, 1}
	fmt.Println(createTargetArray(nums, index))
}

func createTargetArray(nums []int, index []int) []int {
	n := len(nums)
	ans := make([]int, len(nums))
	for i := 0; i < n; i++ {
		fmt.Println("Before : ", ans, "index", index[i])
		copy(ans[index[i]+1:], ans[index[i]:]) // copy very useful
		fmt.Println("After : ", ans)
		ans[index[i]] = nums[i]
	}
	return ans
}
